variable "node_count" {
  default = "2"
 }
 resource "google_compute_instance_from_machine_image" "from-pre-loaded-image" {
  provider     = google-beta
  count        = "${var.node_count}"
  name         = "tf-vm-${count.index}-${random_id.random_id.hex}"
  machine_type = "e2-standard-2"
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

output "vm-ips" {
  value = google_compute_instance_from_machine_image.from-pre-loaded-image[*].network_interface.0.access_config.0.nat_ip
}
