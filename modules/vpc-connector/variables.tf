variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "connector_name" {
  description = "Name of the VPC Access Connector"
  type        = string
}

variable "vpc_network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "ip_cidr_range" {
  description = "IP CIDR range for the connector subnet (must be /28)"
  type        = string
  default     = "10.8.0.0/28"
}

variable "machine_type" {
  description = "Machine type for connector instances"
  type        = string
  default     = "e2-micro"
}

variable "min_instances" {
  description = "Minimum number of connector instances"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of connector instances"
  type        = number
  default     = 3
}
