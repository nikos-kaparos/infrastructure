import json
import dagger
from dagger import dag, function, object_type
from datetime import datetime
import sys


@object_type
class Iac:
    @function
    def container_echo(self, string_arg: str) -> dagger.Container:
        """Returns a container that echoes whatever string argument is provided"""
        return dag.container().from_("alpine:latest").with_exec(["echo", string_arg])

    @function
    async def grep_dir(self, directory_arg: dagger.Directory, pattern: str) -> str:
        """Returns lines that match a pattern in the files of the provided Directory"""
        return await (
            dag.container()
            .from_("alpine:latest")
            .with_mounted_directory("/mnt", directory_arg)
            .with_workdir("/mnt")
            .with_exec(["grep", "-R", pattern, "."])
            .stdout()
        )

    @function
    async def tofu_init(
            self, 
            src: dagger.Directory,
            gcp_paas: dagger.Directory,
            infracost_api_key: dagger.Secret,  
            ssh_private_key: dagger.Secret,
            ssh_public_key: dagger.Secret,        
            gcp_sa_key: dagger.Secret,
            budget_eur: float = 50.0 
        ) -> dagger.Directory:
        
        """
            Cloud architecture cost estimation per subfolder with use case senaria.
        """

        async def process_environment(base_dir: dagger.Directory, env: str, workdir_prefix: str):
            """Γενική function για να επεξεργαστούμε ένα environment"""
            # Create container with tofu and mount the IaC files
            tofu = (
                dag.container()
                    .from_("ghcr.io/opentofu/opentofu:latest")
                    .with_exec(["mkdir", "-p", "/root/.ssh"])
                    .with_mounted_secret("/tmp/ssh_key", ssh_private_key)
                    .with_mounted_secret("/tmp/ssh_key.pub", ssh_public_key)
                    .with_exec(["cp", "/tmp/ssh_key", "/root/.ssh/gcphua_rsa"])
                    .with_exec(["cp", "/tmp/ssh_key.pub", "/root/.ssh/gcphua_rsa.pub"])
                    .with_exec(["chmod", "600", "/root/.ssh/gcphua_rsa"])
                    .with_exec(["chmod", "644", "/root/.ssh/gcphua_rsa.pub"])
                    .with_mounted_secret("/tmp/gcp-key.json", gcp_sa_key)
                    .with_env_variable("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/gcp-key.json")
                    .with_mounted_directory(workdir_prefix, base_dir)
                    .with_workdir(f"{workdir_prefix}/{env}")
            ) 

            tofu_planed = (
                tofu
                    .with_exec(["tofu", "init"])
                    .with_exec(["tofu", "plan", "-out=plan.tfplan"])
                    .with_exec(["sh", "-c", "tofu show -json plan.tfplan > plan.json"])
            )
            
            plan_dir = tofu_planed.directory(".")

            infracost = (
                dag.container()
                .from_("infracost/infracost:latest")
                .with_mounted_directory("/src", plan_dir)
                .with_workdir("/src")
                .with_secret_variable("INFRACOST_API_KEY", infracost_api_key)
                .with_exec([
                    "sh", "-c",
                    "infracost configure set api_key $INFRACOST_API_KEY"
                ])
                .with_exec([
                    "infracost", "breakdown",
                    "--path", ".",
                    "--format", "json",
                    "--out-file", "cost.json",
                ])
            )

            # Read JSON from plan_dir
            tofu_outputs_json = await plan_dir.file("plan.json").contents()
            infracost_json = await infracost.file("cost.json").contents()

            tofu_data = json.loads(tofu_outputs_json)
            infracost_data = json.loads(infracost_json)

            total_monthly_cost = float(
                infracost_data["totalMonthlyCost"]
            )

            resource_changes = tofu_data.get("resource_changes", [])
            resources = []

            resource_type_fields = {
                "google_compute_instance": {
                    "name_field": "name",
                    "extract_fields": ["machine_type", "zone", "tags"]
                },
                "google_sql_database_instance": {
                    "name_field": "name",
                    "extract_fields": ["database_version", "tier", "region", "settings"]
                },
                "google_cloud_run_service": {
                    "name_field": "name",
                    "extract_fields": ["location", "template"]
                },
                "google_storage_bucket": {
                    "name_field": "name",
                    "extract_fields": ["location", "storage_class", "versioning"]
                },
                "google_cloud_run_v2_service": {
                    "name_field": "name",
                    "extract_fields": ["location", "template"]
                },
                "google_sql_database": {
                    "name_field": "name",
                    "extract_fields": ["instance", "charset", "collation"]
                }
            }

            for rc in resource_changes:
                resource_type = rc.get("type", "")
                
                # Safe extraction - αποφεύγουμε None values
                change = rc.get("change") or {}
                after = change.get("after") or {}
                
                # Base info που είναι κοινά για όλα τα resources
                resource_info = {
                    "address": rc.get("address", ""),
                    "type": resource_type,
                    "provider_name": rc.get("provider_name", ""),
                    "actions": change.get("actions", []),
                    "resource_name": rc.get("name", ""),
                }
                
                # Αν γνωρίζουμε τον τύπο, παίρνουμε specific fields
                if resource_type in resource_type_fields:
                    config = resource_type_fields[resource_type]
                    
                    # Προσθήκη των specific fields
                    for field in config["extract_fields"]:
                        resource_info[field] = after.get(field)
                else:
                    # Για άγνωστους τύπους, απλά παίρνουμε τα βασικά
                    resource_info["details"] = after
                
                # Πάντα προσθέτουμε το project αν υπάρχει
                if after and "project" in after:
                    resource_info["project"] = after.get("project")
                
                resources.append(resource_info)

            return {
                "monthly_cost": round(total_monthly_cost, 2),
                "resources": resources,
            }

        # Ορίζουμε τα enviroments (ονόματα φακέλων που έχουν τα αρχεία .tf)
        gcloud_environments = ["native", "docker-vm", "k8s-vm"]
        env_costs = {}
        
        # Υπολογισμός του κόστους για κάθε env ∈ gcloud_environments
        # με την βοήθεια της process_environment
        # για να βρούμε το ατομικό κόστος του κάθε env
        for env in gcloud_environments:
            env_costs[f"gcloud-{env}"] = await process_environment(src, env, "/src")
        
        # Ορίζουμε τα enviroments (ονόματα φακέλων που έχουν τα αρχεία .tf)
        gcp_paas_environments = ["cloud-run", "cloud-sql", "cloud-storage"]

        # Υπολογισμός του κόστους για κάθε env ∈ gcp_paas_environments
        # με την βοήθεια της process_environment 
        # για να βρούμε το ατομικό κόστος του κάθε env
        for env in gcp_paas_environments:
            env_costs[f"gcp-paas-{env}"] = await process_environment(gcp_paas, env, "/gcp-paas")

        # Συνολικό κόστος με use case senario. 
        infracost_gcp_paas_total = (
            dag.container()
            .from_("infracost/infracost:latest")
            .with_mounted_directory("/gcp-paas", gcp_paas)
            .with_workdir("/gcp-paas")
            .with_secret_variable("INFRACOST_API_KEY", infracost_api_key)
            .with_exec([
                "sh", "-c",
                "infracost configure set api_key $INFRACOST_API_KEY"
            ])
            .with_exec([
                "infracost", "breakdown",
                "--config-file", "infracost.yml",
                "--format", "json",
                "--out-file", "gcp-paas-total-cost.json"
            ])
        )

        # Getting total cost in json from infracost.yml use case senario
        gcp_paas_total_json = await infracost_gcp_paas_total.file("gcp-paas-total-cost.json").contents()
        gcp_paas_total_data = json.loads(gcp_paas_total_json)
        # Υπολογισμός συνολικού κόστους από το infracost.yml
        gcp_paas_total_cost = float(gcp_paas_total_data.get("totalMonthlyCost", 0))

        # Add summary
        result = {
            "environments": env_costs,
            "gcp_paas_total_from_config": round(gcp_paas_total_cost, 2),
        }

        json_string = json.dumps(result, indent=2)

        # Return directory with costs.json 
        output_dir = dag.directory().with_new_file("costs.json", json_string)
        return output_dir

    @function
    async def tofu_apply_cheapest(
        self,
        src: dagger.Directory,
        gcp_paas: dagger.Directory,
        costs_json: dagger.File,
        gcp_sa_key: dagger.Secret,
        ssh_private_key: dagger.Secret,
        ssh_public_key: dagger.Secret,
        deployment_id: str,
    ) -> dagger.Directory:
        """
        Διαβάζει το costs.json, βρίσκει το φθηνότερο environment
        και κάνει tofu apply σε αυτό.
        """

        costs_content = await costs_json.contents()
        env_costs = json.loads(costs_content)

        environments = env_costs["environments"]
        
        # Βρήσκει όλα vms
        vm_envs = {
            k: v for k, v in environments.items()
            if k.startswith("gcloud-")
        }
        
        # Bρήσκει το πιο φτοινό vm 
        cheapest_env = min(
            vm_envs.items(),
            key=lambda x: x[1]["monthly_cost"]
        )

        vm_name = cheapest_env[0]
        vm_monthly_cost = cheapest_env[1]["monthly_cost"]
        
        # Get tolta cost for paas
        paas_total = env_costs["gcp_paas_total_from_config"]

        # Create scenaria
        if paas_total < vm_monthly_cost:
            env_name = "gcp-paas"
            monthly_cost = paas_total
            scenario = "paas"
        else: 
            env_name = vm_name
            monthly_cost = vm_cost
            scenario = "vm"

        result = f"Cheapest environment: {env_name} (€{monthly_cost}/month)\n"

        tofu_base = (
            dag.container()
            .from_("ghcr.io/opentofu/opentofu:latest")
            # Handle cache issues
            .with_env_variable("DEPLOYMENT_ID", deployment_id)
            # Making .ssh directory
            .with_exec(["mkdir", "-p", "/root/.ssh"])
            # Mount to tmp ssh keys 
            .with_mounted_secret("/tmp/ssh_key", ssh_private_key)
            .with_mounted_secret("/tmp/ssh_key.pub", ssh_public_key)
            .with_exec(["cp", "/tmp/ssh_key", "/root/.ssh/gcphua_rsa"])
            .with_exec(["cp", "/tmp/ssh_key.pub", "/root/.ssh/gcphua_rsa.pub"])
            .with_exec(["chmod", "600", "/root/.ssh/gcphua_rsa"])
            .with_exec(["chmod", "644", "/root/.ssh/gcphua_rsa.pub"])
            .with_mounted_secret("/tmp/gcp-key.json", gcp_sa_key)
            .with_env_variable("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/gcp-key.json")
        )

        if scenario == "vm":
            tofu = (
                tofu_base
                .with_mounted_directory("/src", src)
                .with_workdir(f"/src/{env_name}")
                .with_exec(["tofu", "init"])
                .with_exec(["tofu", "apply", "-auto-approve"])
                .with_exec(["sh", "-c", "tofu output -json > /tmp/outputs.json"])
            )
        else:
            # Μηχανισμό για url & cred βάσης στο application properties
            tofu = (
                tofu_base
                .with_mounted_directory("/paas", gcp_paas)
                .with_workdir("/paas")
                .with_exec(["tofu", "init"])
                .with_exec(["tofu", "apply", "-auto-approve"])
                .with_exec(["sh", "-c", "tofu output -json > /tmp/outputs.json"])
            )

            outputs = await tofu.file("/tmp/outputs.json").contents()


        deployment_info = {
        "deployment_id": deployment_id,
        "chosen": env_name,
        "monthly_cost": monthly_cost,
        "vm_cheapest": {
            "name": vm_name,
            "monthly_cost": vm_monthly_cost,
        },
        "paas_total": paas_total,
        "message": result.strip(),
    }

        output_dir = dag.directory().with_new_file(
            "deployment.json",
            json.dumps(deployment_info, indent=2)
        )
        return output_dir
