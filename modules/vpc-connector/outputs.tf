output "connector_id" {
  description = "ID of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.id
}

output "connector_name" {
  description = "Name of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.name
}

output "connector_self_link" {
  description = "Self-link of the VPC Access Connector"
  value       = google_vpc_access_connector.connector.self_link
}
