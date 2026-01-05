output "nat_ip_address" {
  description = "The static external IP address used by Cloud NAT"
  value       = google_compute_address.nat_ip.address
}

output "nat_name" {
  description = "The name of the Cloud NAT gateway"
  value       = google_compute_router_nat.nat.name
}

output "router_name" {
  description = "The name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_ip_self_link" {
  description = "The self_link of the NAT IP address"
  value       = google_compute_address.nat_ip.self_link
}
