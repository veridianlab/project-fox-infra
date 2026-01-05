variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-southeast1"
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "backend_image" {
  description = "Backend container image"
  type        = string
}

variable "backend_port" {
  description = "Backend container port"
  type        = number
  default     = 8080
}

variable "backend_cpu_limit" {
  description = "Backend CPU limit"
  type        = string
  default     = "1"
}

variable "backend_memory_limit" {
  description = "Backend memory limit"
  type        = string
  default     = "512Mi"
}

variable "backend_min_instances" {
  description = "Backend minimum instances"
  type        = number
  default     = 0
}

variable "backend_max_instances" {
  description = "Backend maximum instances"
  type        = number
  default     = 10
}

variable "database_name" {
  description = "Name of the database"
  type        = string
  default     = "lynx_haven"
}

variable "db_tier" {
  description = "Cloud SQL tier"
  type        = string
  default     = "db-f1-micro"
}

variable "db_availability_type" {
  description = "Cloud SQL availability type"
  type        = string
  default     = "ZONAL"
}

variable "db_disk_size" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 10
}

variable "db_deletion_protection" {
  description = "Enable deletion protection for Cloud SQL"
  type        = bool
  default     = false
}

variable "db_require_ssl" {
  description = "Require SSL for Cloud SQL connections"
  type        = bool
  default     = false
}

variable "vpc_connector_ip_range" {
  description = "IP CIDR range for VPC connector"
  type        = string
  default     = "10.8.0.0/28"
}

variable "vpc_connector_machine_type" {
  description = "VPC connector machine type"
  type        = string
  default     = "e2-micro"
}

variable "vpc_connector_min_instances" {
  description = "VPC connector minimum instances"
  type        = number
  default     = 2
}

variable "vpc_connector_max_instances" {
  description = "VPC connector maximum instances"
  type        = number
  default     = 3
}

variable "additional_env_vars" {
  description = "Additional environment variables for the backend service"
  type        = map(string)
  default     = {}
}

variable "enable_nat_logging" {
  description = "Enable logging for Cloud NAT"
  type        = bool
  default     = true
}

variable "nat_log_filter" {
  description = "Cloud NAT log filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"
}
