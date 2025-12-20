variable "db_name" {
    type = string
    description = "name of database"
}

variable "db_password" {
    type = string
    description = "pass of database"
}

variable "db_user" {
    type = string
    description = "name of user"
}

variable "authorized_ip" {
    type = string
    description = "Public IP allowed to connect to Cloud SQL"
}