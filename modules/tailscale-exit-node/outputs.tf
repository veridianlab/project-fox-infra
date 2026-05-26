output "exit_node_ip" {
  description = "Static external IP of the Tailscale exit node. Add this IP to your Cloud Armor address group to allowlist traffic egressing the exit node."
  value       = google_compute_address.exit_node_ip.address
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
