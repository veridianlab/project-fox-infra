variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "image" {
  description = "Container image URL"
  type        = string
}

variable "port" {
  description = "Container port"
  type        = number
  default     = 3000
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 1
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "env_vars" {
  description = "Environment variables"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secret environment variables from Secret Manager"
  type = map(object({
    secret_name = string
    version     = string
  }))
  default = {}
}

variable "vpc_connector_name" {
  description = "VPC Access Connector name for private network access"
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress setting: 'ALL_TRAFFIC' routes all traffic through VPC (required for Cloud NAT), 'PRIVATE_RANGES_ONLY' routes only private IP traffic through VPC"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "vpc_egress must be either 'ALL_TRAFFIC' or 'PRIVATE_RANGES_ONLY'"
  }
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service"
  type        = string
  default     = null
}

variable "cpu_idle" {
  description = "Whether CPU is throttled when the container is not handling a request. true = request-based billing (CPU only allocated during requests), false = instance-based billing (CPU always allocated). Set to false if your service needs background processing or low-latency startup."
  type        = bool
  default     = true
}

variable "ingress" {
  description = "Cloud Run ingress setting. Use INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER when fronting with a global HTTPS LB + Cloud Armor."
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "ingress must be one of INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}
