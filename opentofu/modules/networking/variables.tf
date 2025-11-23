# VPC Networking Module - Input Variables

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

# Network Configuration
variable "network_name" {
  description = "Base name for VPC network (environment will be appended)"
  type        = string
  default     = "coditect-vpc"
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "Routing mode must be REGIONAL or GLOBAL."
  }
}

variable "mtu" {
  description = "Maximum Transmission Unit in bytes"
  type        = number
  default     = 1460

  validation {
    condition     = var.mtu >= 1300 && var.mtu <= 8896
    error_message = "MTU must be between 1300 and 8896."
  }
}

variable "delete_default_routes_on_create" {
  description = "Delete default routes when VPC is created"
  type        = bool
  default     = false
}

# Subnet Configuration
variable "primary_subnet_cidr" {
  description = "CIDR range for primary subnet (GKE nodes)"
  type        = string
  default     = "10.0.0.0/20" # 4,096 IPs
}

variable "pods_secondary_range_name" {
  description = "Name of secondary IP range for GKE pods"
  type        = string
  default     = "pods"
}

variable "pods_secondary_cidr" {
  description = "CIDR range for GKE pods"
  type        = string
  default     = "10.4.0.0/14" # 262,144 IPs
}

variable "services_secondary_range_name" {
  description = "Name of secondary IP range for GKE services"
  type        = string
  default     = "services"
}

variable "services_secondary_cidr" {
  description = "CIDR range for GKE services"
  type        = string
  default     = "10.8.0.0/20" # 4,096 IPs
}

# Flow Logs Configuration
variable "flow_logs_interval" {
  description = "Flow logs aggregation interval"
  type        = string
  default     = "INTERVAL_5_SEC"

  validation {
    condition     = contains(["INTERVAL_5_SEC", "INTERVAL_30_SEC", "INTERVAL_1_MIN", "INTERVAL_5_MIN", "INTERVAL_10_MIN", "INTERVAL_15_MIN"], var.flow_logs_interval)
    error_message = "Invalid flow logs interval."
  }
}

variable "flow_logs_sampling" {
  description = "Flow logs sampling rate (0.0-1.0)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.flow_logs_sampling >= 0.0 && var.flow_logs_sampling <= 1.0
    error_message = "Flow logs sampling must be between 0.0 and 1.0."
  }
}

# Cloud Router Configuration
variable "bgp_asn" {
  description = "BGP ASN for Cloud Router"
  type        = number
  default     = 64512 # Private ASN range: 64512-65534
}

# Cloud NAT Configuration
variable "nat_ip_allocate_option" {
  description = "NAT IP allocation option"
  type        = string
  default     = "AUTO_ONLY"

  validation {
    condition     = contains(["AUTO_ONLY", "MANUAL_ONLY"], var.nat_ip_allocate_option)
    error_message = "NAT IP allocate option must be AUTO_ONLY or MANUAL_ONLY."
  }
}

variable "nat_ips" {
  description = "List of NAT IP resource names (for MANUAL_ONLY)"
  type        = list(string)
  default     = []
}

variable "enable_nat_logging" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = true
}

variable "nat_log_filter" {
  description = "NAT log filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "NAT log filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

variable "min_ports_per_vm" {
  description = "Minimum ports per VM for NAT"
  type        = number
  default     = 64

  validation {
    condition     = var.min_ports_per_vm >= 2 && var.min_ports_per_vm <= 65536
    error_message = "Min ports per VM must be between 2 and 65536."
  }
}

variable "enable_dynamic_port_allocation" {
  description = "Enable dynamic port allocation for NAT"
  type        = bool
  default     = true
}

# NAT Timeouts
variable "tcp_established_idle_timeout_sec" {
  description = "TCP established connection idle timeout (seconds)"
  type        = number
  default     = 1200 # 20 minutes
}

variable "tcp_transitory_idle_timeout_sec" {
  description = "TCP transitory connection idle timeout (seconds)"
  type        = number
  default     = 30
}

variable "tcp_time_wait_timeout_sec" {
  description = "TCP time wait timeout (seconds)"
  type        = number
  default     = 120
}

variable "udp_idle_timeout_sec" {
  description = "UDP connection idle timeout (seconds)"
  type        = number
  default     = 30
}

variable "icmp_idle_timeout_sec" {
  description = "ICMP connection idle timeout (seconds)"
  type        = number
  default     = 30
}

# Private Service Connection (Cloud SQL)
variable "private_service_cidr_prefix" {
  description = "Prefix length for private service connection CIDR"
  type        = number
  default     = 16 # Allocates /16 range (65,536 IPs)

  validation {
    condition     = var.private_service_cidr_prefix >= 16 && var.private_service_cidr_prefix <= 24
    error_message = "Private service CIDR prefix must be between /16 and /24."
  }
}

# Private DNS Zone
variable "create_private_dns_zone" {
  description = "Create private DNS zone for VPC"
  type        = bool
  default     = false
}

variable "private_dns_domain" {
  description = "DNS domain for private zone (must end with .)"
  type        = string
  default     = "coditect.internal."
}
