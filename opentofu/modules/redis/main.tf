# Redis Cluster Module - Production-Ready HA Configuration
# Cloud Memorystore for Redis

locals {
  instance_name = "${var.instance_name}-${var.environment}"

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "redis-cache"
  }
}

# Cloud Memorystore Redis Instance
resource "google_redis_instance" "cache" {
  name                    = local.instance_name
  tier                    = var.tier
  memory_size_gb          = var.memory_size_gb
  region                  = var.region
  location_id             = var.location_id
  alternative_location_id = var.alternative_location_id

  # Redis version
  redis_version = var.redis_version

  # Network configuration
  authorized_network = var.authorized_network
  connect_mode       = var.connect_mode

  # High availability configuration (for STANDARD_HA tier)
  replica_count      = var.tier == "STANDARD_HA" ? var.replica_count : null
  read_replicas_mode = var.tier == "STANDARD_HA" && var.replica_count > 0 ? var.read_replicas_mode : null

  # Security
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.transit_encryption_mode

  # Redis configuration
  redis_configs = merge(
    {
      # Memory management
      "maxmemory-policy" = var.maxmemory_policy

      # Persistence (for STANDARD_HA)
      "notify-keyspace-events" = var.notify_keyspace_events
    },
    var.additional_redis_configs
  )

  # Maintenance policy
  maintenance_policy {
    weekly_maintenance_window {
      day = var.maintenance_window_day
      start_time {
        hours   = var.maintenance_window_hour
        minutes = var.maintenance_window_minute
      }
    }
  }

  # Labels
  labels = local.common_labels

  # Lifecycle management
  lifecycle {
    prevent_destroy = true
  }
}
