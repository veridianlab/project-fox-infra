variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region where the scheduler job will be created"
  type        = string
}

variable "job_name" {
  description = "The name of the Cloud Scheduler job"
  type        = string
}

variable "description" {
  description = "A description of the Cloud Scheduler job"
  type        = string
  default     = ""
}

variable "schedule" {
  description = "The cron schedule for the job (e.g., '*/5 * * * *' for every 5 minutes)"
  type        = string
}

variable "time_zone" {
  description = "The timezone for the cron schedule"
  type        = string
  default     = "UTC"
}

variable "uri" {
  description = "The Cloud Run URL to ping"
  type        = string
}

variable "http_method" {
  description = "The HTTP method to use"
  type        = string
  default     = "GET"
}

variable "paused" {
  description = "Whether the job is paused"
  type        = bool
  default     = false
}

variable "app_engine_instance" {
  description = "App Engine instance"
  type        = string
  default     = null
}

variable "app_engine_relative_uri" {
  description = "The relative URI for the App Engine target"
  type        = string
  default     = "/"
}

variable "app_engine_http_method" {
  description = "The HTTP method for App Engine target"
  type        = string
  default     = "POST"
}

variable "app_engine_body" {
  description = "The body of the App Engine request (base64 encoded)"
  type        = string
  default     = null
}

variable "app_engine_headers" {
  description = "HTTP headers for App Engine request"
  type        = map(string)
  default     = {}
}
