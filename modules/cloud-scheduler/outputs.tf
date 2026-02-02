output "job_id" {
  description = "The ID of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.id
}

output "job_name" {
  description = "The name of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.job.name
}
