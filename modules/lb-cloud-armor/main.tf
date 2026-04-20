# Static external IPv4 address for the global forwarding rule
resource "google_compute_global_address" "lb_ip" {
  project = var.project_id
  name    = "${var.lb_name}-ip"
}

# Serverless NEG pointing at the Cloud Run service
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = "${var.lb_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.cloudrun_service_location

  cloud_run {
    service = var.cloudrun_service_name
  }
}

# Cloud Armor security policy: default deny, allow listed IPs
resource "google_compute_security_policy" "cloud_armor" {
  project = var.project_id
  name    = "${var.lb_name}-armor"
  type    = "CLOUD_ARMOR"

  rule {
    action   = "allow"
    priority = 1000
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = var.allowed_ip_ranges
      }
    }
    description = "Allow allowlisted IPs"
  }

  # Default rule is immutable in existence (priority 2147483647) but its action is editable.
  # Declaring it here makes the deny(403) default explicit.
  rule {
    action   = "deny(403)"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny all"
  }
}

# Backend service wrapping the serverless NEG, with Cloud Armor attached
resource "google_compute_backend_service" "backend" {
  project               = var.project_id
  name                  = "${var.lb_name}-backend"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  security_policy = google_compute_security_policy.cloud_armor.id

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL map routes all traffic to the single backend service
resource "google_compute_url_map" "url_map" {
  project         = var.project_id
  name            = "${var.lb_name}-urlmap"
  default_service = google_compute_backend_service.backend.id
}

# Suffix on the managed cert name so domain-list changes trigger create-before-destroy
resource "random_id" "cert_suffix" {
  byte_length = 4
  keepers = {
    domains = join(",", var.domains)
  }
}

resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = "${var.lb_name}-cert-${random_id.cert_suffix.hex}"

  managed {
    domains = var.domains
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_target_https_proxy" "https_proxy" {
  project          = var.project_id
  name             = "${var.lb_name}-https-proxy"
  url_map          = google_compute_url_map.url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

resource "google_compute_global_forwarding_rule" "https" {
  project               = var.project_id
  name                  = "${var.lb_name}-fr-https"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}
