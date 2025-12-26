terraform {
    required_providers {
        google = {
            source  = "hashicorp/google"
            version = "~> 5.0"
        }
    }
}

provider "google" {
    project     = "tf-project-1763286414"
    region      = "europe-west4" 
}