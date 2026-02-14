resource "google_cloud_run_v2_service" "this" {
    name     = var.service_name
    location = "europe-west1"  # ίδια με το region του provider

    template {
        containers {
            image = var.image
            ports {
                container_port = 80
            }
            env {
                name  = "BACKEND_URL"
                value = var.backend_url
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