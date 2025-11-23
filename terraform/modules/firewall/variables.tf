# Firewall Rules Module - Input Variables

# Project Configuration
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

# Internal Network Configuration
variable "internal_cidr_ranges" {
  description = "CIDR ranges for internal VPC traffic"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

# Health Check Configuration
variable "health_check_target_tags" {
  description = "Network tags for health check targets"
  type        = list(string)
  default     = ["gke-node", "allow-health-check"]
}

# SSH Configuration
variable "authorized_ssh_ranges" {
  description = "Authorized IP ranges for SSH access (empty list = no SSH access)"
  type        = list(string)
  default     = []
}

variable "ssh_target_tags" {
  description = "Network tags for SSH access targets"
  type        = list(string)
  default     = ["allow-ssh"]
}

# HTTPS Ingress Configuration
variable "allow_internet_https" {
  description = "Allow HTTPS traffic from internet"
  type        = bool
  default     = true
}

variable "https_source_ranges" {
  description = "Source IP ranges for HTTPS traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_target_tags" {
  description = "Network tags for HTTPS ingress targets"
  type        = list(string)
  default     = ["allow-https"]
}

# HTTP Ingress Configuration
variable "allow_internet_http" {
  description = "Allow HTTP traffic from internet (for redirect to HTTPS)"
  type        = bool
  default     = false
}

variable "http_source_ranges" {
  description = "Source IP ranges for HTTP traffic"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_target_tags" {
  description = "Network tags for HTTP ingress targets"
  type        = list(string)
  default     = ["allow-http"]
}

# GKE-Specific Configuration
variable "enable_gke_master_firewall" {
  description = "Enable firewall rules for GKE master to nodes communication"
  type        = bool
  default     = true
}

variable "gke_master_cidr" {
  description = "CIDR range for GKE master"
  type        = string
  default     = "172.16.0.0/28"
}

variable "gke_node_tags" {
  description = "Network tags for GKE nodes"
  type        = list(string)
  default     = ["gke-node"]
}

# Default Deny Rule
variable "create_deny_all_rule" {
  description = "Create explicit deny all ingress rule (lowest priority)"
  type        = bool
  default     = true
}

# Egress Logging
variable "enable_egress_logging" {
  description = "Enable logging for egress traffic (can be expensive)"
  type        = bool
  default     = false
}
