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

resource "random_id" "random_id" {
  byte_length = 4
}

resource "google_compute_firewall" "http-server" {
  name    = "default-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "22", "3000", "3001"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

output "random-id" {
  value = random_id.random_id.hex
}