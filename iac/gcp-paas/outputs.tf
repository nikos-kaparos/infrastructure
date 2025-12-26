output "db_public_ip" {
    description = "Public ip of Cloud SQL PostreSQL instance"
    value = module.cloud_sql.db_public_ip
}

output "db_connection_name" {
    description = "Connection name for Cloud SQL"
    value = module.cloud_sql.db_connection_name
}

output "db_name" {
    description = "Database name"
    value = module.cloud_sql.db_name
}

output "db_user" {
    description = "Database user"
    value = module.cloud_sql.db_user
}

# ------------------- #
#       Cloud RUN     #  
# ------------------- #

output "cloud_run_url" {
    description = "Public URL του Cloud Run service"
    value       = module.cloud_run.cloud_run_url
}

# ------------------- #
#   Cloud Storage     #  
# ------------------- #

output "frontend_url" {
    value = module.cloud_storage.frontend_url
}
