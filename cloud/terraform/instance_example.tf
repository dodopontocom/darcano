resource "google_compute_instance" "vm" {
  provider     = google-beta
  name         = "tf-vm2-${random_id.random_id.hex}"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
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
  name         = "tf-image-${random_id.random_id.hex}"
  source_instance = google_compute_instance.vm.self_link
}

output "vm2-ip" {
  value = google_compute_instance.vm.network_interface.0.access_config.0.nat_ip
}


