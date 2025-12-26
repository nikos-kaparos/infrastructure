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
        image        = var.image
}

module "cloud_storage" {
    source = "./cloud-storage"
        bucket_name= var.bucket_name
}