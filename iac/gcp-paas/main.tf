module "cloud_sql" {
    source = "./cloud-sql"
        authorized_ip = var.authorized_ip
        db_name       = var.db_name
        db_user       = var.db_user
        db_password   = var.db_password
}


module "cloud_run" {
    source = "./cloud-run"
        service_name = var.service_name
        image = var.image
        # Περνάμε τις τιμές από το ένα module στο άλλο
        db_connection_name = module.cloud_sql.db_connection_name
        db_name = module.cloud_sql.db_name
        db_user = var.db_user
        db_password = var.db_password
        # depends_on = [ module.cloud_sql ]
}

module "cloud-run-frontend" {
    source = "./cloud-run-frontend"
    service_name = var.frontend-service_name
    image = var.frontend-image
    backend_url   = module.cloud_run.cloud_run_url
}

# module "cloud_storage" {

#     build_trigger = module.cloud_run.frontend_build_complete
    
#     source = "./cloud-storage"
#         bucket_name= var.bucket_name
# }