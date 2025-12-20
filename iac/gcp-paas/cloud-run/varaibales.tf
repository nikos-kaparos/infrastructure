variable "service_name" {
    type        = string
    description = "Το όνομα του Cloud Run service"
}

variable "image" {
    type        = string
    description = "Το container image για το Cloud Run"
}