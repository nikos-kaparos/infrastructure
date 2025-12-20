# variable "project_id" {
#     type        = string
#     description = "GCP Project ID"
# }

variable "region" {
    type        = string
    default     = "eu-central1"
}

variable "bucket_name" {
    type        = string
    description = "Unique bucket name"
}
