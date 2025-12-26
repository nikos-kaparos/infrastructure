# ------------------- #
#       Cloud SQL     #  
# ------------------- #
variable "authorized_ip" {
    type        = string
    description = "Public IP allowed to connect to Cloud SQL"
}

variable "db_name" {
    type        = string
    description = "name of database"
}

variable "db_user" {
    type        = string
    description = "name of user"
}

variable "db_password" {
    type        = string
    description = "pass of database"
    sensitive   = true
}

# ------------------- #
#       Cloud RUN     #  
# ------------------- #
variable "service_name" {
    type        = string
    description = "Το όνομα του Cloud Run service"
}

variable "image" {
    type        = string
    description = "Το container image για το Cloud Run"
}

# ------------------- #
#   Cloud Storage     #  
# ------------------- #
variable "region" {
    type        = string
    default     = "eu-central1"
}

variable "bucket_name" {
    type        = string
    description = "Unique bucket name"
}
