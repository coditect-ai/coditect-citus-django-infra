# GKE Cluster Module - Production-Ready Multi-Zone Configuration
# Designed for hyperscale Django + Citus infrastructure

locals {
  cluster_name_full = "${var.cluster_name}-${var.environment}"
  node_pool_name    = "${local.cluster_name_full}-node-pool"

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "gke-cluster"
  }
}

# GKE Cluster with Multi-Zone HA Configuration
resource "google_container_cluster" "primary" {
  name     = local.cluster_name_full
  location = var.region

  # Multi-zone deployment for high availability
  node_locations = var.node_zones

  # We manage our own node pool
  remove_default_node_pool = true
  initial_node_count       = 1

  # Network configuration
  network    = var.network_name
  subnetwork = var.subnet_name

  # IP allocation policy for pods and services
  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # Private cluster configuration (no public node IPs)
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = var.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block

    master_global_access_config {
      enabled = true
    }
  }

  # Master authorized networks for API access
  dynamic "master_authorized_networks_config" {
    for_each = var.master_authorized_networks != null ? [1] : []

    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks

        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  # Workload Identity for secure GCP API access
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Network policy enforcement
  network_policy {
    enabled  = true
    provider = "PROVIDER_UNSPECIFIED" # Uses Calico
  }

  # Binary Authorization for deployment validation
  binary_authorization {
    evaluation_mode = var.enable_binary_authorization ? "PROJECT_SINGLETON_POLICY_ENFORCE" : "DISABLED"
  }

  # Addons configuration
  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    network_policy_config {
      disabled = false
    }

    gcp_filestore_csi_driver_config {
      enabled = true
    }

    gcs_fuse_csi_driver_config {
      enabled = true
    }
  }

  # Monitoring and logging configuration
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]

    managed_prometheus {
      enabled = var.enable_managed_prometheus
    }
  }

  # Release channel for automatic updates
  release_channel {
    channel = var.release_channel
  }

  # Maintenance policy
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.maintenance_start_time
    }
  }

  # Resource labels
  resource_labels = local.common_labels

  # Lifecycle management
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      node_pool,
      initial_node_count,
    ]
  }
}

# Managed Node Pool with Auto-scaling
resource "google_container_node_pool" "primary_nodes" {
  name       = local.node_pool_name
  location   = var.region
  cluster    = google_container_cluster.primary.name

  # Initial node count per zone
  initial_node_count = var.initial_node_count

  # Auto-scaling configuration
  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }

  # Node management
  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Upgrade settings for rolling updates
  upgrade_settings {
    max_surge       = var.max_surge
    max_unavailable = var.max_unavailable

    strategy = "SURGE"
  }

  # Node configuration
  node_config {
    preemptible  = var.use_preemptible_nodes
    machine_type = var.machine_type
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-ssd"

    # Service account with minimal permissions
    service_account = var.node_service_account

    # OAuth scopes for GCP API access
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]

    # Workload Identity metadata
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Security: Shielded instance features
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    # Node labels
    labels = merge(
      local.common_labels,
      {
        node_pool = local.node_pool_name
      }
    )

    # Node taints for workload isolation (optional)
    dynamic "taint" {
      for_each = var.node_taints

      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    # Metadata
    metadata = {
      disable-legacy-endpoints = "true"
    }

    # Tags for firewall rules
    tags = var.node_tags
  }

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      initial_node_count,
    ]
  }

  depends_on = [google_container_cluster.primary]
}
