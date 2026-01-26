terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.16.0"
    }
  }
}

provider "google" {
  project = "dtc-de-course-dmjm26"
  region = "europe-west1"
}

resource "google_storage_bucket" "dtc-bucket" {
  name          = "dtc-de-course-dmjm26-bucket"
  location      = "EU"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}