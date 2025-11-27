resource "google_compute_instance" "default" {
  project = "tf-project-1763286414"
  name  = "vm-docker"
  zone = "europe-west4-a"
  # Custom Machine Type (2 vCPU / 2GB RAM)
  machine_type = "custom-2-2048"

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size = 50
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    "ssh-keys" = "rg:${file("~/.ssh/gcphua_rsa.pub")}"
  }

  tags = ["allow-ssh-http-https-8080"]

  provisioner "remote-exec" {
    inline = [ 
        "sudo apt update"
    ]

    connection {
      type = "ssh"
      user = "rg"
      private_key = file("~/.ssh/gcphua_rsa")
      host = self.network_interface[0].access_config[0].nat_ip
    }
  }
}

resource "google_compute_firewall" "allow-ssh-http-https-custom_ports" {
    project = "tf-project-1763286414"
    name = "allow-ssh-http-https-8080"
    network = "default"

    allow {
      protocol = "tcp"
      ports = [ "22", "80", "443", "8080" ]
    }

    source_ranges = [ "0.0.0.0/0" ]

    target_tags = ["allow-ssh-http-https-8080"]
}
