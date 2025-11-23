# Secret Manager Module - Input Variables

# Project Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project identifier."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

# Additional Secrets
variable "additional_secrets" {
  description = "Additional secrets to create beyond defaults"
  type = map(object({
    description     = string
    rotation_period = string
  }))
  default = {}
}

# IAM Configuration
variable "app_runtime_service_account" {
  description = "Service account email for application runtime (secretAccessor role)"
  type        = string
  default     = ""
}

variable "deployment_service_account" {
  description = "Service account email for deployment automation (secretVersionAdder role)"
  type        = string
  default     = ""
}

variable "admin_members" {
  description = "List of admin members (user:email, group:email, serviceAccount:email) with secretViewer role"
  type        = list(string)
  default     = []
}

# Notifications
variable "notification_topic" {
  description = "Pub/Sub topic for secret rotation notifications (optional)"
  type        = string
  default     = ""
}
