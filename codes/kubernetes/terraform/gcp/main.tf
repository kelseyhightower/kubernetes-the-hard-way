# networks
resource "google_compute_network" "vnet" {
  name                    = "${var.environment}-vnet"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "container"
  ip_cidr_range = var.address_prefix
  region        = var.region
  network       = google_compute_network.vnet.id
}

resource "google_compute_firewall" "internal" {
  name    = "internal"
  network = google_compute_network.vnet.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
  }
  allow {
    protocol = "udp"
  }

  source_ranges = var.internal_cidr
}

resource "google_compute_firewall" "external" {
  name    = "external"
  network = google_compute_network.vnet.id

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["22", "6443"]
  }
  source_ranges = var.external_cidr
}

resource "google_compute_address" "extip" {
  name    = "external-ip"
  region  = var.region
}

# Compute instances (we use instance template here)
data "google_compute_image" "ubuntu" {
  family  = "ubuntu-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_instance" "controller" {
  count          = var.controller_count
  name           = "${var.environment}-controller-${count.index}"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.vnet.self_link
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = element(var.controller_ip_list, count.index)
    # we dont have enough quota for external ip address
    # access_config {}
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  service_account {
    scopes = var.controller_scopes
  }

  # resize VM after initial creation
  allow_stopping_for_update = true

  description = "kubernetes Controller Nodes"

  tags = var.controller_node_tags

}

resource "google_compute_instance" "worker" {
  count          = var.worker_count
  name           = "${var.environment}-worker-${count.index}"
  machine_type   = var.vm_size
  zone           = var.zone
  can_ip_forward = true

  network_interface {
    network    = google_compute_network.vnet.self_link
    subnetwork = google_compute_subnetwork.subnet.name
    network_ip = element(var.worker_ip_list, count.index)
    # we dont have enough quota for external ip address
    # access_config {}
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.self_link
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  metadata = {
    pod-cidr = element(var.pod_address_prefix, count.index)
  }

  service_account {
    scopes = var.worker_scopes
  }

  # resize VM after initial creation
  allow_stopping_for_update = true

  description = "kubernetes Worker Nodes"

  tags = var.worker_node_tags

}
