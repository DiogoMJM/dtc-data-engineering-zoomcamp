variable "credentials" {
    description = "Path to the GCP credentials JSON file."
    default     = "./keys/dtc-de-course-dmjm26-bf3812156f46.json"
}

variable "project" {
    description = "The GCP project ID where resources will be created."
    default     = "dtc-de-course-dmjm26"
}

variable "location" {
  description = "The GCP region where resources will be deployed."
  default     = "EU"
}

variable "region" {
  description = "The short form of the GCP region."
  default     = "europe-west1"
}

variable "bq_dataset_name" {
  description = "The name of the BigQuery dataset."
  default     = "dtc_de_course_dmjm_dataset"
}

variable "gcs_bucket_name" {
  description = "The name of the Google Cloud Storage bucket."
  default     = "dtc-de-course-dmjm26-bucket"
}

variable "gcs_storage_class" {
  description = "The storage class of the GCS bucket."
  default     = "STANDARD"
}