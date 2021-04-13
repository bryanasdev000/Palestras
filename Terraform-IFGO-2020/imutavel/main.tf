resource "google_compute_network" "vpc" {
  name                    = "vpc-4linux"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "subnet-gitea"
  ip_cidr_range = "10.128.0.0/20"
  region        = "southamerica-east1"
  network       = google_compute_network.vpc.self_link
}


resource "google_compute_firewall" "gitea-fw" {
  name    = "fw-gitea"
  network = google_compute_network.vpc.self_link
  allow {
    protocol = "tcp"
    ports    = ["22", "3000"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "internal-fw" {
  name    = "fw-internal"
  network = google_compute_network.vpc.self_link
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
  source_ranges = ["10.128.0.0/20"]
}

resource "google_compute_address" "ip-database" {
  name         = "db-ip-internal"
  address      = "10.128.15.227"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet.self_link
}

resource "google_compute_address" "ip-gitea" {
  name = "gitea-ip-external"
}

data "google_compute_image" "db-image" {
  name = "nixos-20-03-database"
}

data "google_compute_image" "gitea-image" {
  name = "nixos-20-03-gitea"
}

# Mudanças aqui não tem problema pois o disco sempre virá junto
# e o NixOS garantira o SO
resource "google_compute_instance" "vm-database" {
  name         = "db-instance-1"
  machine_type = "n1-standard-1"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.db-image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    network_ip = google_compute_address.ip-database.address
    access_config {
    
    }
  }

  lifecycle {
    ignore_changes = [ attached_disk ]
  }
}

# Mudanças aqui não tem problema pois o disco sempre virá junto
# e o NixOS garantira o SO
resource "google_compute_instance" "vm-gitea" {
  name         = "gitea-instance"
  machine_type = "n1-standard-1"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.gitea-image.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.self_link
    access_config {
      nat_ip = google_compute_address.ip-gitea.address
    }
  }
  
  lifecycle { 
    ignore_changes = [ attached_disk ]
  }
}

resource "google_compute_disk" "disk-database" {
  name                      = "database-disk"
  type                      = "pd-ssd"
  zone                      = "southamerica-east1-a"
  size                      = 30
  physical_block_size_bytes = 4096
}

resource "google_compute_disk" "disk-gitea" {
  name                      = "gitea-disk"
  type                      = "pd-ssd"
  zone                      = "southamerica-east1-a"
  size                      = 30
  physical_block_size_bytes = 4096
}

resource "google_compute_attached_disk" "at-db" {
  disk        = google_compute_disk.disk-database.self_link
  instance    = google_compute_instance.vm-database.self_link
  device_name = "database"
}

resource "google_compute_attached_disk" "at-gitea" {
  disk        = google_compute_disk.disk-gitea.self_link
  instance    = google_compute_instance.vm-gitea.self_link
  device_name = "gitea"
}

