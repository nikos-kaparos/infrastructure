import json
import dagger
from dagger import dag, function, object_type


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
    async def tofu_init(self, src: dagger.Directory, infracost_api_key: dagger.Secret,  ssh_private_key: dagger.Secret, gcp_sa_key: dagger.Secret,
                        ssh_public_key: dagger.Secret, budget_eur: float = 50.0 ) -> dagger.Directory:
        
        """
        IaC pipeline χωρισμένο σε: 
        Container 1: OpenTofu (init, plan, output)
        Container 2: Infracost (breakdown)
        Από JSON μηνιαίο κόστος από τα tofu files
        """

        environments = ["native", "docker-vm", "k8s-vm"]

        env_costs = {}
        
        for env in environments:
            env_dir = src.directory(env)

        # Crate container with tofu and mount the IaC files
            tofu = (
                dag.container()
                    .from_("ghcr.io/opentofu/opentofu:latest")
                    # Δημιούργησε το .ssh directory
                    .with_exec(["mkdir", "-p", "/root/.ssh"])
                    # Mount τα SSH keys ως secrets σε temporary location
                    .with_mounted_secret("/tmp/ssh_key", ssh_private_key)
                    .with_mounted_secret("/tmp/ssh_key.pub", ssh_public_key)
                    # Αντίγραψε τα από το read-only mount στο writable .ssh directory
                    .with_exec(["cp", "/tmp/ssh_key", "/root/.ssh/gcphua_rsa"])
                    .with_exec(["cp", "/tmp/ssh_key.pub", "/root/.ssh/gcphua_rsa.pub"])
                    # Τώρα μπορείς να κάνεις chmod
                    .with_exec(["chmod", "600", "/root/.ssh/gcphua_rsa"])
                    .with_exec(["chmod", "644", "/root/.ssh/gcphua_rsa.pub"])
                    # 👉 GCP service account key ως secret file
                    .with_mounted_secret("/tmp/gcp-key.json", gcp_sa_key)
                    # 👉 ADC env var για τον google provider
                    .with_env_variable("GOOGLE_APPLICATION_CREDENTIALS", "/tmp/gcp-key.json")
                    .with_mounted_directory("/src", src)
                    .with_workdir(f"/src/{env}")
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

            # Διαβάζω τα αρχεία JSON από το plan_dir
            tofu_outputs_json = await plan_dir.file("plan.json").contents()
            infracost_json = await infracost.file("cost.json").contents()


            tofu_data = json.loads(tofu_outputs_json)
            infracost_data = json.loads(infracost_json)

            total_monthly_cost = float(
                infracost_data["totalMonthlyCost"]
            )

            resource_changes = tofu_data.get("resource_changes", [])

            instances = []

            for rc in resource_changes:
                if rc.get("type") == "google_compute_instance":
                    after = rc.get("change", {}).get("after", {})

                    instances.append({
                        "address": rc.get("address"),
                        "type": rc.get("type"),
                        "provider_name": rc.get("provider_name"),
                        "actions": rc.get("change", {}).get("actions", []),
                        "machine_type": after.get("machine_type"),
                        "project": after.get("project"),
                        "tags": after.get("tags", []),
                        "zone": after.get("zone"),
                        "vm_name": rc.get("name"),
                    })

            env_costs[env] = {
                "monthly_cost": round(total_monthly_cost, 2),
                "instances": instances,
            }

            json_string = json.dumps(env_costs)

        # Δημιουργώ ένα directory object με το αρχείο costs.json
        output_dir = dag.directory().with_new_file("costs.json", json_string)
        return output_dir
        