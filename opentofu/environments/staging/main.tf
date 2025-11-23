# Main Terraform Configuration - Staging Environment
# Orchestrates all infrastructure modules for CODITECT Citus Django platform

locals {
  full_cluster_name = "${var.cluster_name}-${var.environment}"
  full_db_name      = "${var.db_instance_name}-${var.environment}"
  full_redis_name   = "${var.redis_instance_name}-${var.environment}"
  full_network_name = "${var.network_name}-${var.environment}"
}

# Data sources for existing resources
data "google_project" "current" {
  project_id = var.project_id
}

# VPC Network
module "networking" {
  source = "../../modules/networking"

  project_id   = var.project_id
  environment  = var.environment
  network_name = var.network_name
  region       = var.region

  # Subnet configuration
  primary_subnet_cidr     = var.primary_subnet_cidr
  pods_secondary_cidr     = var.pods_secondary_cidr
  services_secondary_cidr = var.services_secondary_cidr

  # Cloud NAT configuration
  enable_nat_logging = true
  nat_log_filter     = "ALL" # More verbose for dev

  # Flow logs
  flow_logs_interval = "INTERVAL_5_SEC"
  flow_logs_sampling = 1.0 # 100% sampling for dev

  # Private service connection for Cloud SQL
  private_service_cidr_prefix = 16
}

# Firewall Rules
module "firewall" {
  source = "../../modules/firewall"

  project_id   = var.project_id
  environment  = var.environment
  network_name = module.networking.network_name

  # Disable SSH access in staging (use IAP instead)
  authorized_ssh_ranges = []

  depends_on = [module.networking]
}

# Cloud SQL PostgreSQL with Citus
module "cloudsql" {
  source = "../../modules/cloudsql"

  project_id    = var.project_id
  environment   = var.environment
  instance_name = var.db_instance_name
  region        = var.region

  # Instance configuration
  tier                  = var.db_tier
  availability_type     = var.db_availability_type
  disk_size_gb          = var.db_disk_size_gb
  disk_autoresize_limit = 200  # Max 200GB for dev
  deletion_protection   = true # Allow deletion in dev

  # Network configuration
  private_network  = module.networking.network_self_link
  enable_public_ip = false

  # Database and users
  database_name          = "coditect"
  app_user_name          = "app_user"
  app_user_password      = var.db_app_user_password
  create_readonly_user   = true
  readonly_user_name     = "readonly_user"
  readonly_user_password = var.db_readonly_user_password

  # Backup configuration
  backup_start_time              = "03:00"
  enable_point_in_time_recovery  = true
  transaction_log_retention_days = 3 # Shorter retention for dev
  backup_retention_count         = 3

  # Maintenance window
  maintenance_window_day  = 7 # Sunday
  maintenance_window_hour = 3

  # Database flags (optimized for 8GB RAM)
  max_connections      = "100"
  shared_buffers       = "2048MB"
  effective_cache_size = "6GB"
  maintenance_work_mem = "512MB"
  work_mem             = "8MB"

  # Query insights
  enable_query_insights = true

  # No read replicas in dev
  create_read_replica = false

  depends_on = [
    module.networking,
    module.firewall
  ]
}

# Redis Cache
module "redis" {
  source = "../../modules/redis"

  project_id    = var.project_id
  environment   = var.environment
  instance_name = var.redis_instance_name
  region        = var.region

  # Instance configuration
  memory_size_gb = var.redis_memory_size_gb
  tier           = var.redis_tier
  redis_version  = "REDIS_7_0"

  # Network
  authorized_network = module.networking.network_self_link

  # Maintenance
  maintenance_window_day  = "SUNDAY"
  maintenance_window_hour = 3

  # Auth
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  # Note: Cloud Memorystore persistence is automatically managed by Google
  # No manual configuration needed

  depends_on = [module.networking]
}

# GKE Cluster
module "gke" {
  source = "../../modules/gke"

  project_id   = var.project_id
  environment  = var.environment
  cluster_name = var.cluster_name
  region       = var.region
  node_zones   = var.node_zones

  # Network configuration
  network_name                  = module.networking.network_name
  subnet_name                   = module.networking.subnet_name
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  # Private cluster configuration
  enable_private_endpoint = true # Public endpoint for dev access
  master_ipv4_cidr_block  = "172.16.0.0/28"
  master_authorized_networks = [
    {
      cidr_block   = "10.20.0.0/20" # Staging subnet only
      display_name = "Staging subnet only"
    }
  ]

  # Node pool configuration
  initial_node_count    = 1
  min_node_count        = var.min_node_count
  max_node_count        = var.max_node_count
  machine_type          = var.machine_type
  disk_size_gb          = var.disk_size_gb
  use_preemptible_nodes = false # Use preemptible for cost savings

  # Service account
  node_service_account = var.gke_service_account_email

  # Network tags
  node_tags = ["gke-node", "allow-health-check"]

  # Upgrade configuration
  max_surge       = 1
  max_unavailable = 0

  # Release channel
  release_channel = "STABLE" # Faster updates for dev

  # Maintenance window
  maintenance_start_time = "03:00"

  # Security
  enable_binary_authorization = true # Disabled for dev

  # Monitoring
  enable_managed_prometheus = true

  depends_on = [
    module.networking,
    module.firewall
  ]
}

# Secret Manager Secrets
module "secrets" {
  source = "../../modules/secrets"

  project_id  = var.project_id
  environment = var.environment

  # No additional secrets beyond defaults (database, redis, django, stripe, jwt)
  # Default secrets are defined in modules/secrets/main.tf:14-52
  additional_secrets = {}

  # Note: Secret values must be populated separately after apply
  # Use: gcloud secrets versions add SECRET_NAME --data-file=VALUE_FILE
  # OR: Use secrets population script in scripts/populate-secrets.sh

  depends_on = [
    module.cloudsql,
    module.redis
  ]
}

# Lifecycle management
resource "null_resource" "prevent_destroy_warning" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "echo 'WARNING: This is the DEV environment. Resources can be destroyed for cost savings.'"
  }
}
