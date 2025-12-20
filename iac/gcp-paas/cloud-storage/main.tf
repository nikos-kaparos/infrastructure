resource "google_storage_bucket" "frontend" {
    name     = var.bucket_name
    location = "EU"
    
    # if this has files tofu can destroy it
    force_destroy = true

    uniform_bucket_level_access = true

    website {
        main_page_suffix = "index.html"
        not_found_page   = "index.html" # για SPA routing
    }

    cors {
        origin          = ["*"]
        method          = ["GET", "HEAD", "OPTIONS"]
        response_header = ["Content-Type"]
        max_age_seconds = 3600
    }
}

resource "google_storage_bucket_iam_binding" "public_read" {
    bucket = google_storage_bucket.frontend.name
    role   = "roles/storage.objectViewer"
    members = ["allUsers"]
}
