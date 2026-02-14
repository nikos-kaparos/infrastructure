output "cloud_run_url" {
    value       = google_cloud_run_v2_service.this.uri
    description = "Public URL του Cloud Run service"
}

# output "frontend_build_complete" {
#     value = null_resource.build_frontend.id
# }
# output "frontend_build_complete" {
#     value = null_resource.build_frontend.id
# }