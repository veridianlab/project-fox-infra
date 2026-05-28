output "exit_node_ip" {
  description = "Static external IP of the Tailscale exit node. Add to the application's IP whitelist via the settings page."
  value       = google_compute_address.exit_node_ip.address
}

output "exit_node_ip_cidr" {
  description = "Exit node IP formatted as a /32 CIDR, ready to add to the application's IP whitelist."
  value       = "${google_compute_address.exit_node_ip.address}/32"
}

output "exit_node_name" {
  description = "Name of the exit node VM"
  value       = google_compute_instance.exit_node.name
}

output "exit_node_self_link" {
  description = "Self link of the exit node VM"
  value       = google_compute_instance.exit_node.self_link
}

output "exit_node_zone" {
  description = "Zone of the exit node VM"
  value       = google_compute_instance.exit_node.zone
}
