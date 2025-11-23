# Cloud SQL PostgreSQL Module - Production-Ready HA Configuration
# Designed for Citus distributed PostgreSQL deployment

locals {
  instance_name = "${var.instance_name}-${var.environment}"

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "cloudsql-postgresql"
    database    = "citus"
  }

  # Database flags for Citus configuration
  citus_database_flags = {
    "shared_preload_libraries"         = "citus"
    "max_connections"                  = var.max_connections
    "shared_buffers"                   = var.shared_buffers
    "effective_cache_size"             = var.effective_cache_size
    "maintenance_work_mem"             = var.maintenance_work_mem
    "checkpoint_completion_target"     = "0.9"
    "wal_buffers"                      = "16MB"
    "default_statistics_target"        = "100"
    "random_page_cost"                 = "1.1" # For SSD
    "effective_io_concurrency"         = "200" # For SSD
    "work_mem"                         = var.work_mem
    "min_wal_size"                     = "1GB"
    "max_wal_size"                     = "4GB"
    "max_worker_processes"             = "8"
    "max_parallel_workers_per_gather"  = "4"
    "max_parallel_workers"             = "8"
    "max_parallel_maintenance_workers" = "4"
  }
}

# Cloud SQL PostgreSQL Instance
resource "google_sql_database_instance" "postgres" {
  name                = local.instance_name
  database_version    = var.database_version
  region              = var.region
  deletion_protection = var.deletion_protection

  settings {
    tier                  = var.tier
    availability_type     = var.availability_type
    disk_type             = "PD_SSD"
    disk_size             = var.disk_size_gb
    disk_autoresize       = true
    disk_autoresize_limit = var.disk_autoresize_limit

    # IP configuration
    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      require_ssl     = true

      # Authorized networks for public IP access (if enabled)
      dynamic "authorized_networks" {
        for_each = var.authorized_networks

        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    # Backup configuration
    backup_configuration {
      enabled                        = true
      start_time                     = var.backup_start_time
      point_in_time_recovery_enabled = var.enable_point_in_time_recovery
      transaction_log_retention_days = var.transaction_log_retention_days

      backup_retention_settings {
        retained_backups = var.backup_retention_count
        retention_unit   = "COUNT"
      }
    }

    # Maintenance window
    maintenance_window {
      day          = var.maintenance_window_day
      hour         = var.maintenance_window_hour
      update_track = var.maintenance_update_track
    }

    # Database flags for Citus
    dynamic "database_flags" {
      for_each = merge(local.citus_database_flags, var.additional_database_flags)

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    # Insights configuration
    insights_config {
      query_insights_enabled  = var.enable_query_insights
      query_string_length     = 1024
      record_application_tags = true
      record_client_address   = true
    }

    # User labels
    user_labels = local.common_labels
  }

  # Lifecycle management
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      settings[0].disk_size, # Managed by autoresize
    ]
  }
}

# Default PostgreSQL database
resource "google_sql_database" "default" {
  name      = var.database_name
  instance  = google_sql_database_instance.postgres.name
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# Citus extension database (if different from default)
resource "google_sql_database" "citus" {
  count = var.database_name != "citus" ? 1 : 0

  name      = "citus"
  instance  = google_sql_database_instance.postgres.name
  charset   = "UTF8"
  collation = "en_US.UTF8"
}

# Root user (managed by Cloud SQL)
# Password stored in Secret Manager

# Application user
resource "google_sql_user" "app_user" {
  name     = var.app_user_name
  instance = google_sql_database_instance.postgres.name
  password = var.app_user_password # Should come from Secret Manager
}

# Read-only user for analytics/reporting
resource "google_sql_user" "readonly_user" {
  count = var.create_readonly_user ? 1 : 0

  name     = var.readonly_user_name
  instance = google_sql_database_instance.postgres.name
  password = var.readonly_user_password # Should come from Secret Manager
}

# High Availability Replica (for production)
resource "google_sql_database_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  name                 = "${local.instance_name}-replica"
  master_instance_name = google_sql_database_instance.postgres.name
  database_version     = var.database_version
  region               = var.replica_region != "" ? var.replica_region : var.region
  deletion_protection  = var.deletion_protection

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.replica_tier != "" ? var.replica_tier : var.tier
    availability_type = "ZONAL" # Replicas are always zonal
    disk_type         = "PD_SSD"
    disk_size         = var.disk_size_gb
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = var.enable_public_ip
      private_network = var.private_network
      require_ssl     = true
    }

    # Same database flags as primary
    dynamic "database_flags" {
      for_each = merge(local.citus_database_flags, var.additional_database_flags)

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }

    user_labels = merge(
      local.common_labels,
      {
        replica = "true"
      }
    )
  }

  lifecycle {
    prevent_destroy = true
  }
}
