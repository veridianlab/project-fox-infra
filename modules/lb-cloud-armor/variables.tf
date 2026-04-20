variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region (kept for parity with sibling modules; not used by global LB resources directly)"
  type        = string
}

variable "lb_name" {
  description = "Name prefix applied to all load balancer resources"
  type        = string
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "cloudrun_service_name" {
  description = "Name of the Cloud Run service to put behind the LB"
  type        = string
}

variable "cloudrun_service_location" {
  description = "Region of the Cloud Run service (used as the Serverless NEG region)"
  type        = string
}

variable "domains" {
  description = "Domains served by the Google-managed SSL certificate (up to 100 SANs)"
  type        = list(string)

  validation {
    condition     = length(var.domains) > 0
    error_message = "domains must contain at least one domain."
  }
}

variable "allowed_ip_ranges" {
  description = "CIDR ranges allowed through Cloud Armor. Everything else is denied with HTTP 403."
  type        = list(string)

  validation {
    condition     = length(var.allowed_ip_ranges) > 0
    error_message = "allowed_ip_ranges must contain at least one CIDR — an empty list would make the LB deny all traffic."
  }
}
