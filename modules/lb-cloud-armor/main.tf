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

# Cloud Armor security policy: default deny
# Allow rules are managed by the application at runtime, not by Terraform.
#
# GCP automatically creates a default-deny rule at priority 2147483647 when
# the policy is created. This rule cannot be deleted, only modified. We do
# not declare it here — with ignore_changes enabled, a declared block would
# be write-once and never drift-corrected, offering no benefit over GCP's
# implicit default.
resource "google_compute_security_policy" "cloud_armor" {
  project = var.project_id
  name    = "${var.lb_name}-armor"
  type    = "CLOUD_ARMOR"

  # Bootstrap rule for zero-downtime migration from Terraform-managed to
  # app-managed IP rules. Uses priority 500 (below the app's 1000+ range)
  # so both can coexist during the transition. Clear once app sync is live.
  dynamic "rule" {
    for_each = length(var.bootstrap_allow_ranges) > 0 ? [1] : []
    content {
      action      = "allow"
      priority    = 500
      description = "Bootstrap: transitional allow during app-managed migration"
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.bootstrap_allow_ranges
        }
      }
    }
  }

  # The application manages allow rules at runtime (priorities 1000+).
  # Without ignore_changes, terraform apply would plan removal of all
  # undeclared rules added by lynx-haven's Cloud Armor sync.
  #
  # Trade-off: Terraform will not detect drift on ANY rule, including
  # the implicit default-deny at priority 2147483647. However, GCP does
  # not allow deleting that rule (only modifying its action), and the
  # app sync only operates at priority 1000+, so accidental modification
  # of the default-deny is extremely unlikely.
  lifecycle {
    ignore_changes = [rule]
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
