# Redis Cluster Module - Input Variables

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
  description = "Base name for Redis instance (environment will be appended)"
  type        = string
  default     = "coditect-cache"
}

variable "region" {
  description = "GCP region for Redis instance"
  type        = string
  default     = "us-central1"
}

variable "location_id" {
  description = "Zone where the instance will be provisioned (e.g., us-central1-a)"
  type        = string
  default     = "us-central1-a"
}

variable "alternative_location_id" {
  description = "Alternative zone for STANDARD_HA tier (e.g., us-central1-b)"
  type        = string
  default     = "us-central1-b"
}

variable "tier" {
  description = "Service tier (BASIC or STANDARD_HA)"
  type        = string
  default     = "STANDARD_HA"

  validation {
    condition     = contains(["BASIC", "STANDARD_HA"], var.tier)
    error_message = "Tier must be BASIC or STANDARD_HA."
  }
}

variable "memory_size_gb" {
  description = "Memory size in GB for Redis instance"
  type        = number
  default     = 5

  validation {
    condition     = var.memory_size_gb >= 1 && var.memory_size_gb <= 300
    error_message = "Memory size must be between 1 and 300 GB."
  }
}

variable "redis_version" {
  description = "Redis version"
  type        = string
  default     = "REDIS_7_2"

  validation {
    condition     = can(regex("^REDIS_[0-9]_[0-9]$", var.redis_version))
    error_message = "Redis version must be in format REDIS_X_Y."
  }
}

# Network Configuration
variable "authorized_network" {
  description = "VPC network authorized to access Redis (format: projects/{project}/global/networks/{network})"
  type        = string
}

variable "connect_mode" {
  description = "Network connection mode (DIRECT_PEERING or PRIVATE_SERVICE_ACCESS)"
  type        = string
  default     = "DIRECT_PEERING"

  validation {
    condition     = contains(["DIRECT_PEERING", "PRIVATE_SERVICE_ACCESS"], var.connect_mode)
    error_message = "Connect mode must be DIRECT_PEERING or PRIVATE_SERVICE_ACCESS."
  }
}

# High Availability Configuration
variable "replica_count" {
  description = "Number of read replicas (0-5, only for STANDARD_HA)"
  type        = number
  default     = 0

  validation {
    condition     = var.replica_count >= 0 && var.replica_count <= 5
    error_message = "Replica count must be between 0 and 5."
  }
}

variable "read_replicas_mode" {
  description = "Read replicas mode (READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED)"
  type        = string
  default     = "READ_REPLICAS_DISABLED"

  validation {
    condition     = contains(["READ_REPLICAS_DISABLED", "READ_REPLICAS_ENABLED"], var.read_replicas_mode)
    error_message = "Read replicas mode must be READ_REPLICAS_DISABLED or READ_REPLICAS_ENABLED."
  }
}

# Security Configuration
variable "auth_enabled" {
  description = "Enable Redis AUTH for authentication"
  type        = bool
  default     = true
}

variable "transit_encryption_mode" {
  description = "Transit encryption mode (DISABLED or SERVER_AUTHENTICATION)"
  type        = string
  default     = "SERVER_AUTHENTICATION"

  validation {
    condition     = contains(["DISABLED", "SERVER_AUTHENTICATION"], var.transit_encryption_mode)
    error_message = "Transit encryption mode must be DISABLED or SERVER_AUTHENTICATION."
  }
}

# Redis Configuration
variable "maxmemory_policy" {
  description = "Eviction policy when memory limit is reached"
  type        = string
  default     = "allkeys-lru"

  validation {
    condition = contains([
      "noeviction", "allkeys-lru", "volatile-lru",
      "allkeys-random", "volatile-random", "volatile-ttl",
      "allkeys-lfu", "volatile-lfu"
    ], var.maxmemory_policy)
    error_message = "Invalid maxmemory policy."
  }
}

variable "notify_keyspace_events" {
  description = "Keyspace notifications configuration"
  type        = string
  default     = ""
}

variable "additional_redis_configs" {
  description = "Additional Redis configuration parameters"
  type        = map(string)
  default     = {}
}

# Maintenance Configuration
variable "maintenance_window_day" {
  description = "Day of week for maintenance (MONDAY, TUESDAY, etc.)"
  type        = string
  default     = "SUNDAY"

  validation {
    condition = contains([
      "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
      "FRIDAY", "SATURDAY", "SUNDAY"
    ], var.maintenance_window_day)
    error_message = "Invalid maintenance window day."
  }
}

variable "maintenance_window_hour" {
  description = "Hour of day for maintenance window (0-23, UTC)"
  type        = number
  default     = 4

  validation {
    condition     = var.maintenance_window_hour >= 0 && var.maintenance_window_hour <= 23
    error_message = "Maintenance window hour must be between 0 and 23."
  }
}

variable "maintenance_window_minute" {
  description = "Minute of hour for maintenance window (0 or 30)"
  type        = number
  default     = 0

  validation {
    condition     = contains([0, 30], var.maintenance_window_minute)
    error_message = "Maintenance window minute must be 0 or 30."
  }
}
