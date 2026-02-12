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
    default = "name_for_plan"
    description = "Db name for app properties"
}

variable "db_user" {
    type = string
    default = "user_for_plan"
    description = "Db user name for app properties"

}

variable "db_connection_name" {
    type = string
    default = "url_for_plan"
    description = "Db conection url for app properties"

}

variable "db_password" {
    type = string
    default = "pass_fro_plan"
    sensitive = true
    description = "Db password for app properties sensitive enable"

}
