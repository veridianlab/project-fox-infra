variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the static IP (e.g. asia-southeast1)"
  type        = string
}

variable "zone" {
  description = "GCP zone for the VM (e.g. asia-southeast1-b)"
  type        = string
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "instance_name" {
  description = "VM and resource name prefix"
  type        = string
  default     = "tailscale-exit-node"
}

variable "machine_type" {
  description = "Compute Engine machine type"
  type        = string
  default     = "e2-micro"
}

variable "os_image" {
  description = "Boot disk image. Default is Ubuntu 22.04 LTS."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 10
}

variable "network" {
  description = "VPC network name the VM and firewall rules attach to"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name. Leave null to auto-select for the given network."
  type        = string
  default     = null
}

variable "enable_ssh" {
  description = "Whether to create the SSH firewall rule. Set to false after setup to remove SSH access."
  type        = bool
  default     = true
}

variable "ssh_source_ranges" {
  description = "CIDRs allowed to SSH into the VM. Default is open; narrow this to your office/VPN CIDRs after setup."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
