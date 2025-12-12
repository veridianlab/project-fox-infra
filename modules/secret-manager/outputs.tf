output "secret_id" {
  description = "The ID of the secret"
  value       = google_secret_manager_secret.secret.id
}

output "secret_name" {
  description = "The name of the secret"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_version_name" {
  description = "The version name of the secret"
  value       = google_secret_manager_secret_version.secret_version.name
}
