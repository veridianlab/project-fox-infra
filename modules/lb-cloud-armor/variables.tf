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

variable "bootstrap_allow_ranges" {
  description = "Transitional allow-list applied during migration to app-managed rules. Set to current CIDRs while flipping over, then back to [] once the app has populated runtime rules. WARNING: Clearing this before the application has synced at least one allow rule will block all inbound traffic until the sync completes."
  type        = list(string)
  default     = []

  validation {
    condition = length(var.bootstrap_allow_ranges) == 0 || alltrue([
      for r in var.bootstrap_allow_ranges : can(cidrhost(r, 0))
    ])
    error_message = "Each entry in bootstrap_allow_ranges must be a valid CIDR (e.g. 203.0.113.0/24)."
  }
}
