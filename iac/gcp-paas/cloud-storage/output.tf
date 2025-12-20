output "frontend_url" {
    value = "https://storage.googleapis.com/${google_storage_bucket.frontend.name}/index.html"
}
