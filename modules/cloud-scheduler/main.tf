/**
 * Cloud Scheduler Module
 * 
 * Simple module to ping a Cloud Run service on a schedule.
 */

resource "google_cloud_scheduler_job" "job" {
  project     = var.project_id
  region      = var.region
  name        = var.job_name
  description = var.description
  schedule    = var.schedule
  time_zone   = var.time_zone
  paused      = var.paused

  http_target {
    uri         = var.uri
    http_method = var.http_method
  }
}
