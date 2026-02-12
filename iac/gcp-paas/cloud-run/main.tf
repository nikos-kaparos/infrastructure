resource "google_cloud_run_v2_service" "this" {
    name     = var.service_name
    location = "europe-west1"  # ίδια με το region του provider
    
    # depends_on = [ m ]

    template {

        volumes {
            name = "cloudsql"
            cloud_sql_instance {
                instances = [var.db_connection_name]
            }
        }

        containers {
            image = var.image
            
            ports {
                container_port = 8080
            }

            # Mount point για Cloud SQL socket
            volume_mounts {
                name       = "cloudsql"
                mount_path = "/cloudsql"
            }

            env {
                name  = "SPRING_DATASOURCE_URL"
                value = "jdbc:postgresql:///${var.db_name}?cloudSqlInstance=${var.db_connection_name}&socketFactory=com.google.cloud.sql.postgres.SocketFactory"
            }

            env {
                name  = "SPRING_DATASOURCE_USERNAME"
                value = var.db_user
            }
            env {
                name  = "SPRING_DATASOURCE_PASSWORD"
                value = var.db_password
            }


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
        }
        annotations = {
            "run.googleapis.com/cloudsql-instances" = var.db_connection_name
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
