output "db_public_ip" {
    description = "Public ip of Cloud SQL PostreSQL instance"
    value = google_sql_database_instance.postgres.public_ip_address
}

output "db_connection_name" {
    description = "Connection name for Cloud SQL"
    value = google_sql_database_instance.postgres.connection_name
}

output "db_name" {
    description = "Database name"
    value = google_sql_database.app_db.name
}

output "db_user" {
    description = "Database user"
    value = google_sql_user.app_user.name
}