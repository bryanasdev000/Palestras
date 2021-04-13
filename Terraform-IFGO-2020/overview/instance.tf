resource "google_compute_network" "vpc" {
  name = "vpc"
}

data "google_compute_network" "linux" {
  name = "linux"
  project = "rubeus-proxysql"
}


resource "google_compute_instance" "default" {
  name         = format("%s-%s",terraform.workspace,var.nomevm)
  machine_type = "n1-standard-1"
  zone         = "southamerica-east1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    #network = google_compute_network.vpc.self_link
    network = data.google_compute_network.linux.self_link

    access_config {
      // Ephemeral IP
    }
  }

}

variable "nomevm" {
  default = "vm-0"
  description = "Nome da VM da GCP"
  type = "string"
}

output "dump" {
  value = google_compute_instance.default 
  description = "Full dump da API"
}
