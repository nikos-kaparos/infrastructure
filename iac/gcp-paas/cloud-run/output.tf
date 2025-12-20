output "cloud_run_url" {
    value       = google_cloud_run_v2_service.this.uri
    description = "Public URL του Cloud Run service"
}