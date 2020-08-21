provider "google" {
  project = var.project
}

resource "google_compute_network" "benchmark_vpc" {
  name                    = "benchmark-vpc"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "benchmark_public_subnet" {
  name          = "benchmark-public-subnet"
  ip_cidr_range = var.public_subnet
  region        = var.region
  network       = google_compute_network.benchmark_vpc.id
}

resource "google_compute_subnetwork" "benchmark_private_subnet" {
  name          = "benchmark-private-subnet"
  ip_cidr_range = var.private_subnet
  region        = var.region
  network       = google_compute_network.benchmark_vpc.id
}


resource "google_compute_firewall" "benchmark_internal" {
  name          = "benchmark-firewall-internal"
  network       = google_compute_network.benchmark_vpc.name
  source_ranges = [var.private_subnet, var.public_subnet]

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }
}

resource "google_compute_firewall" "allow-bastion" {
  name          = "benchmark-firewall-bastion"
  network       = google_compute_network.benchmark_vpc.name
  source_ranges = [var.public_subnet]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  target_tags = ["ssh"]
}

resource "google_compute_instance" "benchmark_bastion" {
  name         = "benchmark-bastion"
  machine_type = "n1-standard-1"
  zone         = var.zone
  tags         = ["ssh"]
  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.benchmark_public_subnet.name
    access_config {
    }
  }
}

resource "google_compute_instance" "benchmark_instance" {
  count        = var.instance_count
  name         = "benchmark-instance-${count.index}"
  machine_type = "n2-standard-4"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.compute_image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.benchmark_private_subnet.name
  }
}
