variable "service_name" {
    type        = string
    description = "Το όνομα του Cloud Run service"
}

variable "image" {
    type        = string
    description = "Το container image για το Cloud Run"
}

variable "db_name" {
    type = string
    description = "Db name for app properties"
}

variable "db_user" {
    type = string
    description = "Db user name for app properties"

}

variable "db_connection_name" {
    type = string
    description = "Db conection url for app properties"

}

variable "db_password" {
    type = string
    sensitive = true
    description = "Db password for app properties sensitive enable"

}
