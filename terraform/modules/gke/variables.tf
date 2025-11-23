# GKE Cluster Module - Input Variables

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

# Cluster Configuration
variable "cluster_name" {
  description = "Base name for the GKE cluster (environment will be appended)"
  type        = string
  default     = "coditect-citus"
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "node_zones" {
  description = "List of zones for multi-zone deployment"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

# Network Configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for GKE nodes"
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range for pods"
  type        = string
  default     = "pods"
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range for services"
  type        = string
  default     = "services"
}

# Private Cluster Configuration
variable "enable_private_endpoint" {
  description = "Enable private endpoint (master API not accessible from public internet)"
  type        = bool
  default     = false # Set to true for production
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks authorized to access the master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = null
}

# Node Pool Configuration
variable "initial_node_count" {
  description = "Initial number of nodes per zone"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes per zone"
  type        = number
  default     = 3

  validation {
    condition     = var.min_node_count >= 1
    error_message = "Minimum node count must be at least 1."
  }
}

variable "max_node_count" {
  description = "Maximum number of nodes per zone"
  type        = number
  default     = 20

  validation {
    condition     = var.max_node_count >= var.min_node_count
    error_message = "Maximum node count must be greater than or equal to minimum node count."
  }
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "n1-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB for each node"
  type        = number
  default     = 100

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

variable "use_preemptible_nodes" {
  description = "Use preemptible nodes for cost savings (not recommended for production)"
  type        = bool
  default     = false
}

variable "node_service_account" {
  description = "Service account email for GKE nodes"
  type        = string
}

variable "node_tags" {
  description = "Network tags for GKE nodes (used in firewall rules)"
  type        = list(string)
  default     = ["gke-node", "allow-health-check"]
}

variable "node_taints" {
  description = "Node taints for workload isolation"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# Upgrade Configuration
variable "max_surge" {
  description = "Maximum number of nodes that can be created beyond the current size during upgrade"
  type        = number
  default     = 1
}

variable "max_unavailable" {
  description = "Maximum number of nodes that can be unavailable during upgrade"
  type        = number
  default     = 0
}

# Release Channel
variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE)"
  type        = string
  default     = "STABLE"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE"], var.release_channel)
    error_message = "Release channel must be RAPID, REGULAR, or STABLE."
  }
}

# Maintenance Window
variable "maintenance_start_time" {
  description = "Start time for daily maintenance window (HH:MM format, UTC)"
  type        = string
  default     = "03:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance_start_time))
    error_message = "Maintenance start time must be in HH:MM format (24-hour)."
  }
}

# Security
variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for deployment validation"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_managed_prometheus" {
  description = "Enable managed Prometheus for monitoring"
  type        = bool
  default     = true
}
