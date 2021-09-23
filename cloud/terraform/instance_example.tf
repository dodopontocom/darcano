resource "google_compute_instance" "base_vm" {
  provider     = google-beta
  name         = "tf-base-${random_id.random_id.hex}"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  boot_disk {
    source      = google_compute_disk.base_disk.name
  }

  metadata_startup_script = "${file("${var.startup_script}")}"

  network_interface {
    network = "default"
    access_config { }
  }
  tags = ["http-server", "https-server"]
}

data "google_compute_image" "ubuntu_image" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_disk" "base_disk" {
  name  = "base-disk"
  image = data.google_compute_image.ubuntu_image.self_link
  size  = 40
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name         = "tf-image-${random_id.random_id.hex}"
  source_instance = google_compute_instance.base_vm.self_link
}

output "base_vm-ip" {
  value = google_compute_instance.base_vm.network_interface.0.access_config.0.nat_ip
}


