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

resource "google_bigquery_dataset" "dtc-dataset" {
  dataset_id = "dtc_de_course_dmjm_dataset"
  location = "EU"
}