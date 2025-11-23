# Firewall Rules Module - Production-Ready Security Rules
# Least-privilege firewall rules for GKE and infrastructure

locals {
  network_name = var.network_name

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "firewall"
  }
}

# Allow internal traffic within VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.network_name}-allow-internal"
  network = var.network_name
  project = var.project_id

  description = "Allow internal traffic between all resources in VPC"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.internal_cidr_ranges

  priority = 65534

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow health checks from GCP load balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.network_name}-allow-health-checks"
  network = var.network_name
  project = var.project_id

  description = "Allow health checks from GCP load balancers"

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "130.211.0.0/22", # GCP Health Check ranges
    "35.191.0.0/16",
  ]

  target_tags = var.health_check_target_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow SSH from authorized IPs (bastion/admin access)
resource "google_compute_firewall" "allow_ssh" {
  count = length(var.authorized_ssh_ranges) > 0 ? 1 : 0

  name    = "${local.network_name}-allow-ssh"
  network = var.network_name
  project = var.project_id

  description = "Allow SSH from authorized IP ranges"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.authorized_ssh_ranges
  target_tags   = var.ssh_target_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow HTTPS ingress from internet (for load balancers)
resource "google_compute_firewall" "allow_https_ingress" {
  count = var.allow_internet_https ? 1 : 0

  name    = "${local.network_name}-allow-https-ingress"
  network = var.network_name
  project = var.project_id

  description = "Allow HTTPS traffic from internet to load balancers"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = var.https_source_ranges
  target_tags   = var.https_target_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow HTTP ingress (optional, for HTTP to HTTPS redirect)
resource "google_compute_firewall" "allow_http_ingress" {
  count = var.allow_internet_http ? 1 : 0

  name    = "${local.network_name}-allow-http-ingress"
  network = var.network_name
  project = var.project_id

  description = "Allow HTTP traffic from internet (for redirect to HTTPS)"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = var.http_source_ranges
  target_tags   = var.http_target_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# GKE-specific: Allow master to nodes communication
resource "google_compute_firewall" "allow_gke_master_to_nodes" {
  count = var.enable_gke_master_firewall ? 1 : 0

  name    = "${local.network_name}-allow-gke-master"
  network = var.network_name
  project = var.project_id

  description = "Allow GKE master to communicate with nodes"

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }

  source_ranges = [var.gke_master_cidr]
  target_tags   = var.gke_node_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# GKE-specific: Allow webhook admissions from master
resource "google_compute_firewall" "allow_gke_webhooks" {
  count = var.enable_gke_master_firewall ? 1 : 0

  name    = "${local.network_name}-allow-gke-webhooks"
  network = var.network_name
  project = var.project_id

  description = "Allow GKE master to call admission webhooks"

  allow {
    protocol = "tcp"
    ports    = ["8443", "9443", "15017"]
  }

  source_ranges = [var.gke_master_cidr]
  target_tags   = var.gke_node_tags

  priority = 1000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Deny all ingress by default (implicit, but explicit for clarity)
resource "google_compute_firewall" "deny_all_ingress" {
  count = var.create_deny_all_rule ? 1 : 0

  name    = "${local.network_name}-deny-all-ingress"
  network = var.network_name
  project = var.project_id

  description = "Deny all ingress traffic by default"

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]

  priority = 65535 # Lowest priority (evaluated last)

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow all egress (default behavior, explicit for management)
resource "google_compute_firewall" "allow_all_egress" {
  name    = "${local.network_name}-allow-all-egress"
  network = var.network_name
  project = var.project_id

  description = "Allow all egress traffic (controlled by Cloud NAT)"

  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]

  priority = 65534

  # Egress logging can be expensive, disabled by default
  log_config {
    metadata = var.enable_egress_logging ? "INCLUDE_ALL_METADATA" : "EXCLUDE_ALL_METADATA"
  }
}
