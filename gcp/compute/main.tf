provider "google" {
  project = var.project
}

resource "google_compute_instance" "instance" {
  name         = "instance"
  machine_type = "n1-standard-1"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }

  network_interface {
    network = "benchmarkvpc"
  }
}
