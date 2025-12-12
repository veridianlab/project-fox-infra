resource "google_secret_manager_secret" "secret" {
  secret_id = var.secret_id
  project   = var.project_id

  labels = {
    environment = var.environment
    managed-by  = "terraform"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_version" {
  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_value
}

resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = toset(var.accessor_service_accounts)

  project   = var.project_id
  secret_id = google_secret_manager_secret.secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value}"

  depends_on = [google_secret_manager_secret_version.secret_version]
}
