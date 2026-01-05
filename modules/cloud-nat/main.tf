# Reserve a static external IP address for Cloud NAT
resource "google_compute_address" "nat_ip" {
  project      = var.project_id
  name         = "${var.nat_name}-ip"
  region       = var.region
  address_type = "EXTERNAL"
  description  = "Static IP for Cloud NAT egress traffic"
}

# Cloud Router is required for Cloud NAT
resource "google_compute_router" "router" {
  project = var.project_id
  name    = "${var.nat_name}-router"
  region  = var.region
  network = var.vpc_network_name

  bgp {
    asn = 64514
  }
}

# Cloud NAT configuration
resource "google_compute_router_nat" "nat" {
  project                            = var.project_id
  name                               = var.nat_name
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  nat_ips = [google_compute_address.nat_ip.self_link]

  log_config {
    enable = var.enable_logging
    filter = var.log_filter
  }

  # Optional: Configure min and max ports per VM
  min_ports_per_vm                   = var.min_ports_per_vm
  max_ports_per_vm                   = var.max_ports_per_vm
  enable_dynamic_port_allocation     = var.enable_dynamic_port_allocation
  enable_endpoint_independent_mapping = var.enable_endpoint_independent_mapping
}
