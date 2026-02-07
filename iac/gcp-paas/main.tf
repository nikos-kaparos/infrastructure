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

module "cloud_storage" {
    source = "./cloud-storage"
        bucket_name= var.bucket_name
}