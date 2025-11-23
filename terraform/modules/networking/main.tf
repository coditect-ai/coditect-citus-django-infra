# VPC Networking Module - Production-Ready Network Infrastructure
# Custom VPC with subnets, Cloud Router, and Cloud NAT

locals {
  network_name = "${var.network_name}-${var.environment}"

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "networking"
  }
}

# Custom VPC Network
resource "google_compute_network" "vpc" {
  name                    = local.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  mtu                     = var.mtu

  # Delete default routes on destroy
  delete_default_routes_on_create = var.delete_default_routes_on_create

  project = var.project_id
}

# Primary Subnet for GKE Nodes
resource "google_compute_subnetwork" "primary" {
  name          = "${local.network_name}-${var.region}"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.primary_subnet_cidr

  # Enable Private Google Access for GKE nodes without public IPs
  private_ip_google_access = true

  # Secondary IP ranges for GKE pods and services
  secondary_ip_range {
    range_name    = var.pods_secondary_range_name
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_cidr
  }

  # Flow logs for security monitoring
  log_config {
    aggregation_interval = var.flow_logs_interval
    flow_sampling        = var.flow_logs_sampling
    metadata             = "INCLUDE_ALL_METADATA"
  }

  project = var.project_id
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  name    = "${local.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = var.bgp_asn
  }

  project = var.project_id
}

# Cloud NAT for Egress Traffic from Private Nodes
resource "google_compute_router_nat" "nat" {
  name   = "${local.network_name}-nat"
  router = google_compute_router.router.name
  region = var.region

  # NAT IP allocation
  nat_ip_allocate_option = var.nat_ip_allocate_option

  # Manual NAT IPs (if specified)
  dynamic "nat_ips" {
    for_each = var.nat_ips

    content {
      name = nat_ips.value
    }
  }

  # Source subnetwork configuration
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Logging configuration
  log_config {
    enable = var.enable_nat_logging
    filter = var.nat_log_filter
  }

  # Minimum ports per VM
  min_ports_per_vm = var.min_ports_per_vm

  # Enable Dynamic Port Allocation
  enable_dynamic_port_allocation = var.enable_dynamic_port_allocation

  # TCP timeouts
  tcp_established_idle_timeout_sec = var.tcp_established_idle_timeout_sec
  tcp_transitory_idle_timeout_sec  = var.tcp_transitory_idle_timeout_sec
  tcp_time_wait_timeout_sec        = var.tcp_time_wait_timeout_sec

  # UDP timeout
  udp_idle_timeout_sec = var.udp_idle_timeout_sec

  # ICMP timeout
  icmp_idle_timeout_sec = var.icmp_idle_timeout_sec

  project = var.project_id
}

# VPC Peering for Cloud SQL (Private Service Connection)
resource "google_compute_global_address" "private_ip_address" {
  name          = "${local.network_name}-private-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.private_service_cidr_prefix
  network       = google_compute_network.vpc.id

  project = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# DNS Configuration for VPC
resource "google_dns_managed_zone" "private_zone" {
  count = var.create_private_dns_zone ? 1 : 0

  name        = "${replace(local.network_name, "-", "")}-private-zone"
  dns_name    = var.private_dns_domain
  description = "Private DNS zone for ${local.network_name}"

  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }

  project = var.project_id
}
