resource "google_vpc_access_connector" "connector" {
  project = var.project_id
  name    = var.connector_name
  region  = var.region

  subnet {
    name = google_compute_subnetwork.vpc_connector_subnet.name
  }

  machine_type  = var.machine_type
  min_instances = var.min_instances
  max_instances = var.max_instances
}

resource "google_compute_subnetwork" "vpc_connector_subnet" {
  project       = var.project_id
  name          = "${var.connector_name}-subnet"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = var.vpc_network_name
}
