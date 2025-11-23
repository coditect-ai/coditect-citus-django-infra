# Cloud SQL PostgreSQL Module - Input Variables

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

# Instance Configuration
variable "instance_name" {
  description = "Base name for Cloud SQL instance (environment will be appended)"
  type        = string
  default     = "coditect-citus"
}

variable "region" {
  description = "GCP region for Cloud SQL instance"
  type        = string
  default     = "us-central1"
}

variable "database_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "POSTGRES_16"

  validation {
    condition     = can(regex("^POSTGRES_[0-9]+$", var.database_version))
    error_message = "Database version must be in format POSTGRES_XX."
  }
}

variable "tier" {
  description = "Machine tier for Cloud SQL instance"
  type        = string
  default     = "db-custom-4-16384" # 4 vCPUs, 16GB RAM

  validation {
    condition     = can(regex("^db-(custom|standard|highmem)", var.tier))
    error_message = "Tier must be a valid Cloud SQL machine type."
  }
}

variable "availability_type" {
  description = "Availability type (ZONAL or REGIONAL for HA)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "Availability type must be ZONAL or REGIONAL."
  }
}

variable "disk_size_gb" {
  description = "Initial disk size in GB"
  type        = number
  default     = 100

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size in GB for autoresize (0 = no limit)"
  type        = number
  default     = 1000
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

# Network Configuration
variable "private_network" {
  description = "VPC network for private IP (format: projects/{project}/global/networks/{network})"
  type        = string
}

variable "enable_public_ip" {
  description = "Enable public IP address (not recommended for production)"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

# Database Configuration
variable "database_name" {
  description = "Name of the default database"
  type        = string
  default     = "coditect"
}

variable "app_user_name" {
  description = "Application database user name"
  type        = string
  default     = "app_user"
}

variable "app_user_password" {
  description = "Application database user password (use Secret Manager)"
  type        = string
  sensitive   = true
}

variable "create_readonly_user" {
  description = "Create read-only user for analytics"
  type        = bool
  default     = true
}

variable "readonly_user_name" {
  description = "Read-only database user name"
  type        = string
  default     = "readonly_user"
}

variable "readonly_user_password" {
  description = "Read-only database user password (use Secret Manager)"
  type        = string
  sensitive   = true
  default     = ""
}

# Backup Configuration
variable "backup_start_time" {
  description = "Start time for automated backups (HH:MM format, UTC)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.backup_start_time))
    error_message = "Backup start time must be in HH:MM format (24-hour)."
  }
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Transaction log retention days for PITR"
  type        = number
  default     = 7

  validation {
    condition     = var.transaction_log_retention_days >= 1 && var.transaction_log_retention_days <= 35
    error_message = "Transaction log retention must be between 1 and 35 days."
  }
}

variable "backup_retention_count" {
  description = "Number of automated backups to retain"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_count >= 1
    error_message = "Backup retention count must be at least 1."
  }
}

# Maintenance Configuration
variable "maintenance_window_day" {
  description = "Day of week for maintenance (1=Monday, 7=Sunday)"
  type        = number
  default     = 7

  validation {
    condition     = var.maintenance_window_day >= 1 && var.maintenance_window_day <= 7
    error_message = "Maintenance window day must be between 1 (Monday) and 7 (Sunday)."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance window (0-23, UTC)"
  type        = number
  default     = 3

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

variable "maintenance_update_track" {
  description = "Maintenance update track (stable or canary)"
  type        = string
  default     = "stable"

  validation {
    condition     = contains(["stable", "canary"], var.maintenance_update_track)
    error_message = "Maintenance update track must be stable or canary."
  }
}

# Database Flags (Citus Configuration)
variable "max_connections" {
  description = "Maximum number of concurrent connections"
  type        = string
  default     = "200"
}

variable "shared_buffers" {
  description = "Shared buffer size (e.g., '4096MB')"
  type        = string
  default     = "4096MB"
}

variable "effective_cache_size" {
  description = "Effective cache size (e.g., '12GB')"
  type        = string
  default     = "12GB"
}

variable "maintenance_work_mem" {
  description = "Maintenance work memory (e.g., '1GB')"
  type        = string
  default     = "1GB"
}

variable "work_mem" {
  description = "Work memory per operation (e.g., '16MB')"
  type        = string
  default     = "16MB"
}

variable "additional_database_flags" {
  description = "Additional database flags to set"
  type        = map(string)
  default     = {}
}

# Query Insights
variable "enable_query_insights" {
  description = "Enable query insights for performance monitoring"
  type        = bool
  default     = true
}

# Read Replica Configuration
variable "create_read_replica" {
  description = "Create read replica for scaling read operations"
  type        = bool
  default     = false
}

variable "replica_region" {
  description = "Region for read replica (empty = same as primary)"
  type        = string
  default     = ""
}

variable "replica_tier" {
  description = "Machine tier for read replica (empty = same as primary)"
  type        = string
  default     = ""
}
