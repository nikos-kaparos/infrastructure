resource "google_cloud_run_v2_service" "this" {
    name     = var.service_name
    location = "europe-west1"  # ίδια με το region του provider
    

    template {
        containers {
            image = var.image

            
                ##################################################
                #               Billing Settings                 #
                # By default gcp is Request-based billing        #
                # If cpu_idle is true is Request-based billing   #
                # If cpu_idle is false is Instance-based billing #
                ##################################################

            # This an example with Instance-based billing

            # resources {
            #     cpu_idle   = false   # κρατά CPU allocated όταν έχει traffic
            #     # limits = {
            #     #     cpu    = "1"       # 1 vCPU
            #     #     memory = "512Mi"   # 512 MB RAM
            #     # }
            # }
            
            ports {
                container_port = 8080
            }
        }
    }

    traffic {
        type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
        percent = 100
    }
}

# IAM policy για να το καλούν όλοι (public URL)
data "google_iam_policy" "public_policy" {
    binding {
        role = "roles/run.invoker"
            members = [
                "allUsers",
            ]
        }
    }

resource "google_cloud_run_v2_service_iam_policy" "public_policy" {
    location = google_cloud_run_v2_service.this.location
    name = google_cloud_run_v2_service.this.name
    policy_data = data.google_iam_policy.public_policy.policy_data
}
