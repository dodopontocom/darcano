resource "google_compute_instance" "bp_node" {
  provider     = google-beta
  name         = "tf-blockproducer-${random_id.random_id.hex}"
  machine_type = var.machine_type
  zone         = var.zone

  labels       = {
      "env" = "testnet"
  }

  boot_disk {
    source      = google_compute_disk.bp_node_disk.name
  }
  
  metadata = {
    DARLENE1_TOKEN = "${var.DARLENE1_TOKEN}"
    DARCANO_TOKEN = "${var.DARCANO_TOKEN}"
    TELEGRAM_ID = "${var.TELEGRAM_ID}"
    COLD_DELEG_CERT = "${var.COLD_DELEG_CERT}"
    COLD_NODE_CERT = "${var.COLD_NODE_CERT}"
    COLD_NODE_COUNTER = "${var.COLD_NODE_COUNTER}"
    COLD_NODE_SKEY = "${var.COLD_NODE_SKEY}"
    COLD_NODE_VKEY = "${var.COLD_NODE_VKEY}"
    COLD_PAY_ADDR = "${var.COLD_PAY_ADDR}"
    COLD_PAY_SKEY = "${var.COLD_PAY_SKEY}"
    COLD_PAY_VKEY = "${var.COLD_PAY_VKEY}"
    COLD_POOL_CERT = "${var.COLD_POOL_CERT}"
    COLD_STAKE_ADDR = "${var.COLD_STAKE_ADDR}"
    COLD_STAKE_CERT = "${var.COLD_STAKE_CERT}"
    COLD_STAKE_SKEY = "${var.COLD_STAKE_SKEY}"
    COLD_STAKE_VKEY = "${var.COLD_STAKE_VKEY}"
    EVOLVING_SKEY = "${var.EVOLVING_SKEY}"
    EVOLVING_VKEY = "${var.EVOLVING_VKEY}"
    VRF_SKEY = "${var.VRF_SKEY}"
    VRF_VKEY = "${var.VRF_VKEY}"
    POOL_METADATA_HASH = "${var.POOL_METADATA_HASH}"
  }

  network_interface {
    network = "default"
    access_config { }
  }
  tags = ["http-server", "https-server"]
}

data "google_compute_image" "bp_ubuntu_image" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_disk" "bp_node_disk" {
  name  = "tf-disk-blockproducer-${random_id.random_id.hex}"
  image = data.google_compute_image.bp_ubuntu_image.self_link
  size  = 40
  type  = "pd-ssd"
  zone  = var.zone
}

output "bp_node-ip" {
  value = google_compute_instance.bp_node.network_interface.0.network_ip
}
