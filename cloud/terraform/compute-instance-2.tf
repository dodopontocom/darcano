resource "google_compute_instance" "vm" {
  provider     = google-beta
  name         = "vm"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata_startup_script = "echo hi > /test.txt; sleep 500"

  network_interface {
    network = "default"
    access_config { }
  }
  tags = ["http-server", "https-server"]
}

resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name            = "image-hello"
  source_instance = google_compute_instance.vm.self_link
}

output "vm2-ip" {
  value = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}
