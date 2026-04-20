# Static external IP for the Tailscale exit node — feed this into
# Cloud Armor allowed_ip_ranges so traffic egressing the exit node
# is allowlisted at the LB.
resource "google_compute_address" "exit_node_ip" {
  project      = var.project_id
  name         = "${var.instance_name}-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static external IP for Tailscale exit node"
}

resource "google_compute_instance" "exit_node" {
  project      = var.project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  # Required for exit-node functionality — the VM forwards traffic
  # from Tailscale peers to the public internet.
  can_ip_forward = true

  tags = [var.instance_name]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = var.boot_disk_size_gb
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      nat_ip = google_compute_address.exit_node_ip.address
    }
  }

  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }
}

# Tailscale WireGuard listens on UDP 41641. Source must be 0.0.0.0/0
# because peers connect from arbitrary public IPs.
resource "google_compute_firewall" "tailscale" {
  project     = var.project_id
  name        = "${var.instance_name}-tailscale"
  network     = var.network
  description = "Allow Tailscale (UDP 41641) inbound to the exit node"

  allow {
    protocol = "udp"
    ports    = ["41641"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.instance_name]
}

# SSH is split from the Tailscale rule so its source range can be
# locked down (or the rule toggled off with enable_ssh = false)
# after initial setup.
resource "google_compute_firewall" "ssh" {
  count = var.enable_ssh ? 1 : 0

  project     = var.project_id
  name        = "${var.instance_name}-ssh"
  network     = var.network
  description = "Allow SSH inbound to the Tailscale exit node"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
  target_tags   = [var.instance_name]
}
