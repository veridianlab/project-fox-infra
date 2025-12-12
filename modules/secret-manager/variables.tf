variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "secret_id" {
  description = "ID of the secret (name)"
  type        = string
}

variable "secret_value" {
  description = "Value of the secret"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (staging/production)"
  type        = string
}

variable "accessor_service_accounts" {
  description = "List of service account emails that can access this secret"
  type        = list(string)
  default     = []
}
