import json
import dagger
from dagger import dag, object_type, function

@object_type
class IacPipeline:

    @function
    async def tofu_init(self, src: dagger.Directory, infracost_api_key: dagger.Secret, budget_eur: float = 50.0 ) -> str:
        
        """
        IaC pipeline χωρισμένο σε:
        - Container 1: OpenTofu (init, plan, output)
        - Container 2: Infracost (breakdown)
        - Από JSON παίρνω public_ip + μηνιαίο κόστος
        - Αν το κόστος είναι <= budget -> tofu apply
        """

        # Crate container with tofu and mount the IaC files

        tofu = (
            dag.container()
                .from_("opentofu/opentofu:latest")
                .with_mounted_directory("/src", src)
                .with_workdir("/src")
        ) 

        tofu_planed = (
            tofu
                .with_exec(["tofu", "init"])
                .with_exec(["tofu", "plan", "-out=plan.tfplan"])
                .with_exec(["sh", "-c", "tofu show -json plan.tfplan > vm.json"])
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

        # 5) Διαβάζω τα αρχεία JSON από το *ίδιο* directory (plan_dir)
        tofu_outputs_json = await plan_dir.file("vm.json").contents()
        infracost_json = await infracost.file("cost.json").contents()

        tofu_data = json.loads(tofu_outputs_json)
        infracost_data = json.loads(infracost_json)

        # Προσαρμόζεις αυτό στο όνομα του output σου (π.χ. vm_ip, instance_ip, οτιδήποτε έχεις στο .tf)
        public_ip = tofu_data["public_ip"]
        
        total_monthly_cost = float(
            infracost_data["projects"][0]["summary"]["totalMonthlyCost"]
        )
        
        return f"Public IP: {public_ip}, Monthly cost: {total_monthly_cost:.2f}"