output "backend_url" {
  description = "Backend API URL"
  value       = module.backend_service.service_url
}

output "backend_service_name" {
  description = "Backend service name"
  value       = module.backend_service.service_name
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.cloudsql.instance_connection_name
}

output "database_private_ip" {
  description = "Cloud SQL private IP"
  value       = module.cloudsql.private_ip_address
  sensitive   = true
}

output "database_name" {
  description = "Database name"
  value       = module.cloudsql.database_name
}

output "vpc_network_name" {
  description = "VPC network name"
  value       = module.vpc_network.network_name
}

output "vpc_connector_name" {
  description = "VPC connector name"
  value       = module.vpc_connector.connector_name
}

output "cloud_nat_ip_address" {
  description = "Static external IP address for Cloud NAT - provide this to third-party API providers for IP allowlisting"
  value       = module.cloud_nat.nat_ip_address
}

output "cloud_nat_name" {
  description = "Cloud NAT gateway name"
  value       = module.cloud_nat.nat_name
}

output "secret_name" {
  description = "Database password secret name"
  value       = module.db_password_secret.secret_name
}
