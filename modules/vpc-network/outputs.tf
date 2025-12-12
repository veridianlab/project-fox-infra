output "network_id" {
  description = "The ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "The name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "private_ip_range_name" {
  description = "Name of the private IP range for Cloud SQL"
  value       = google_compute_global_address.private_ip_range.name
}

output "private_vpc_connection" {
  description = "The private VPC connection for dependency management"
  value       = google_service_networking_connection.private_vpc_connection
}
