variable "node_count" {
  default = "2"
}

resource "google_compute_instance" "pool_nodes" {
  provider     = google-beta
  count        = "${var.node_count}"
  name         = "tf-pn-${count.index}-${random_id.random_id.hex}"
  machine_type = "e2-standard-2"
  zone         = "us-central1-a"

  labels       = {
      "env" = "testnet"
  }

  boot_disk {
    source      = google_compute_disk.pool_nodes_disk[count.index].name
  }

  metadata_startup_script = "${file("${var.startup_script}")}"
  
  metadata = {
    TELEGRAM_TOKEN = "${var.TELEGRAM_TOKEN}"
    TELEGRAM_ID = "${var.TELEGRAM_ID}"
  }

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

resource "google_compute_disk" "pool_nodes_disk" {
  count        = "${var.node_count}"
  name  = "tf-disk-${count.index}-${random_id.random_id.hex}"
  image = data.google_compute_image.ubuntu_image.self_link
  size  = 40
  type  = "pd-ssd"
  zone  = "us-central1-a"
}

/*
resource "google_compute_machine_image" "image" {
  provider        = google-beta
  name         = "tf-image-${random_id.random_id.hex}"
  source_instance = google_compute_instance.pool_nodes.self_link
}
*/

output "pool_nodes-ip" {
  value = google_compute_instance.pool_nodes[*].network_interface.0.access_config.0.nat_ip
}


