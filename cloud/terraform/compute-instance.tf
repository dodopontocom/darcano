resource "random_id" "instance_id" {
  byte_length = 3
}

resource "google_compute_instance_from_machine_image" "from-pre-loaded-image" {
  provider     = "google-beta"
  name         = "vm-tf-${random_id.instance_id.hex}"
  machine_type = "n1-standard-4"
  zone         = "us-central1-a"

  labels       = {
    "env" = "testnet"
  }
  
  source_machine_image = "projects/theta-inkwell-326216/global/machineImages/pre-loaded-node"
  
  network_interface {
    network = "default"
    access_config { }
  }
  tags = ["http-server", "https-server"]
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
output "vm1-ip" {
  value = google_compute_instance_from_machine_image.from-pre-loaded-image.network_interface.0.access_config.0.nat_ip
}
