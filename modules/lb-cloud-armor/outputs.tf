output "lb_ip_address" {
  description = "Static external IPv4 address of the load balancer. Point DNS A records for each domain here."
  value       = google_compute_global_address.lb_ip.address
}

output "backend_service_id" {
  description = "ID of the backend service fronting the Cloud Run serverless NEG"
  value       = google_compute_backend_service.backend.id
}

output "security_policy_id" {
  description = "ID of the Cloud Armor security policy"
  value       = google_compute_security_policy.cloud_armor.id
}

output "security_policy_name" {
  description = "Name of the Cloud Armor security policy"
  value       = google_compute_security_policy.cloud_armor.name
}

output "ssl_certificate_id" {
  description = "ID of the Google-managed SSL certificate"
  value       = google_compute_managed_ssl_certificate.cert.id
}

output "url_map_id" {
  description = "ID of the URL map"
  value       = google_compute_url_map.url_map.id
}
