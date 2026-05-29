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

# Cloud Armor security policy — the policy itself is a container; rules are
# managed via separate google_compute_security_policy_rule resources below.
# This allows default-deny enforcement and bootstrap rules to be drift-corrected
# independently of ignore_changes, while the application manages allow rules at
# runtime (priorities 1000+) without Terraform interference.
resource "google_compute_security_policy" "cloud_armor" {
  project = var.project_id
  name    = "${var.lb_name}-armor"
  type    = "CLOUD_ARMOR"

  # Without ignore_changes, terraform apply would plan removal of all
  # undeclared rules added by the application's Cloud Armor sync.
  # Standalone google_compute_security_policy_rule resources (default_deny,
  # bootstrap_allow) are NOT affected by this — they are separate resources
  # with their own lifecycle management.
  lifecycle {
    ignore_changes = [rule]
  }
}

# Default deny rule — ensures all traffic is blocked unless explicitly allowed.
# GCP creates this rule at priority 2147483647 with action "allow" by default;
# this resource overrides it to deny(403). As a standalone resource it is
# immune to the parent policy's ignore_changes, so Terraform will drift-correct
# it on every plan.
resource "google_compute_security_policy_rule" "default_deny" {
  project         = var.project_id
  security_policy = google_compute_security_policy.cloud_armor.name
  action          = "deny(403)"
  priority        = 2147483647
  description     = "Default deny all traffic"

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = ["*"]
    }
  }
}

# Bootstrap allow rule for zero-downtime migration from Terraform-managed to
# app-managed IP rules. Uses priority 500 (higher precedence than the app's
# 1000+ range) so both can coexist during the transition.
# As a standalone resource with count, Terraform creates it when
# bootstrap_allow_ranges is non-empty and removes it when the list is cleared.
resource "google_compute_security_policy_rule" "bootstrap_allow" {
  count           = length(var.bootstrap_allow_ranges) > 0 ? 1 : 0
  project         = var.project_id
  security_policy = google_compute_security_policy.cloud_armor.name
  action          = "allow"
  priority        = 500
  description     = "Bootstrap: transitional allow during app-managed migration"

  match {
    versioned_expr = "SRC_IPS_V1"
    config {
      src_ip_ranges = var.bootstrap_allow_ranges
    }
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
