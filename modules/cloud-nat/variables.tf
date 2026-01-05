variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the Cloud NAT"
  type        = string
}

variable "nat_name" {
  description = "Name of the Cloud NAT gateway"
  type        = string
}

variable "vpc_network_name" {
  description = "Name of the VPC network (not the self_link)"
  type        = string
}

variable "enable_logging" {
  description = "Enable logging for Cloud NAT"
  type        = bool
  default     = true
}

variable "log_filter" {
  description = "Logging filter for Cloud NAT (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"
}

variable "min_ports_per_vm" {
  description = "Minimum number of ports allocated to a VM from this NAT config"
  type        = number
  default     = 64
}

variable "max_ports_per_vm" {
  description = "Maximum number of ports allocated to a VM from this NAT config"
  type        = number
  default     = 65536
}

variable "enable_dynamic_port_allocation" {
  description = "Enable dynamic port allocation"
  type        = bool
  default     = false
}

variable "enable_endpoint_independent_mapping" {
  description = "Enable endpoint independent mapping"
  type        = bool
  default     = true
}
