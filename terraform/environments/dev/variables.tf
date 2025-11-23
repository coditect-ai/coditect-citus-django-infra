# Terraform Variables - Development Environment

# Project Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "Project ID must be a valid GCP project identifier."
  }
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "This configuration is for dev environment only."
  }
}

# Network Configuration
variable "network_name" {
  description = "VPC network name"
  type        = string
  default     = "coditect-vpc"
}

variable "primary_subnet_cidr" {
  description = "CIDR range for primary subnet"
  type        = string
  default     = "10.10.0.0/20" # 4,096 IPs
}

variable "pods_secondary_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.14.0.0/14" # 262,144 IPs
}

variable "services_secondary_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.18.0.0/20" # 4,096 IPs
}

# GKE Configuration
variable "cluster_name" {
  description = "GKE cluster base name"
  type        = string
  default     = "coditect-citus"
}

variable "min_node_count" {
  description = "Minimum nodes per zone"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum nodes per zone"
  type        = number
  default     = 5
}

variable "machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "n1-standard-2" # Cost-optimized for dev
}

variable "disk_size_gb" {
  description = "Node disk size in GB"
  type        = number
  default     = 50
}

variable "node_zones" {
  description = "Zones for GKE nodes"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

# Cloud SQL Configuration
variable "db_instance_name" {
  description = "Cloud SQL instance base name"
  type        = string
  default     = "coditect-citus"
}

variable "db_tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-custom-2-8192" # 2 vCPU, 8GB RAM
}

variable "db_disk_size_gb" {
  description = "Cloud SQL disk size in GB"
  type        = number
  default     = 50
}

variable "db_availability_type" {
  description = "Cloud SQL availability type"
  type        = string
  default     = "ZONAL" # Single-zone for cost savings
}

variable "db_backup_enabled" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

# Redis Configuration
variable "redis_instance_name" {
  description = "Redis instance base name"
  type        = string
  default     = "coditect-redis"
}

variable "redis_memory_size_gb" {
  description = "Redis memory in GB"
  type        = number
  default     = 1
}

variable "redis_tier" {
  description = "Redis tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "BASIC" # No HA for cost savings
}

# Service Account Configuration
variable "gke_service_account_email" {
  description = "Service account email for GKE nodes"
  type        = string
  default     = "" # Will be created by module if empty
}

# Database Credentials (use Secret Manager in production)
variable "db_app_user_password" {
  description = "Application database user password"
  type        = string
  sensitive   = true
  default     = "" # Must be provided via tfvars or environment variable
}

variable "db_readonly_user_password" {
  description = "Read-only database user password"
  type        = string
  sensitive   = true
  default     = "" # Must be provided via tfvars or environment variable
}

# Tags
variable "common_tags" {
  description = "Common resource labels"
  type        = map(string)
  default = {
    environment = "dev"
    project     = "coditect-citus"
    managed_by  = "terraform"
    cost_center = "development"
  }
}
