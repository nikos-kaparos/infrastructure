resource "google_sql_database_instance" "postgres" {
    project = "tf-project-1763286414"
    name = "pg"
    database_version = "POSTGRES_15"
    region = "europe-west4"

    settings {
        tier = "db-f1-micro"

        ip_configuration{
            ipv4_enabled = true
            authorized_networks {
            name  = "home-network"
            value = "${var.authorized_ip}/32"
            }
        }
        # true to enable
        backup_configuration {
            enabled = false
        }
    }
    deletion_protection = false
}

resource "google_sql_database" "app_db" {
    name = var.db_name
    instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app_user" {
    name = var.db_user
    instance = google_sql_database_instance.postgres.name
    password = var.db_password
}