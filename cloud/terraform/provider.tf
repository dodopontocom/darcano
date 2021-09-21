terraform {
  required_version = ">= 1.0.6"
}
provider "google" {
  credentials = "${file("${var.key}")}"
  project     = var.project_id
  region      = var.region
}
provider "google-beta" {
  credentials = "${file("${var.key}")}"
  project     = var.project_id
  region      = var.region
}
