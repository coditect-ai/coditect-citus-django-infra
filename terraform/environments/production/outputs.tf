# Terraform Outputs - Development Environment
# Important resource details for accessing and monitoring infrastructure

# Network Outputs
output "network_name" {
  description = "VPC network name"
  value       = module.networking.network_name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = module.networking.network_self_link
}

output "subnet_name" {
  description = "Primary subnet name"
  value       = module.networking.subnet_name
}

output "subnet_cidr" {
  description = "Primary subnet CIDR range"
  value       = module.networking.subnet_cidr
}

output "nat_ip_addresses" {
  description = "Cloud NAT external IP addresses"
  value       = module.networking.nat_ip_addresses
}

# GKE Cluster Outputs
output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = module.gke.cluster_endpoint
  sensitive   = true
}

output "gke_cluster_ca_certificate" {
  description = "GKE cluster CA certificate"
  value       = module.gke.cluster_ca_certificate
  sensitive   = true
}

output "gke_cluster_location" {
  description = "GKE cluster location (region)"
  value       = module.gke.cluster_location
}

output "gke_service_account_email" {
  description = "Service account email for GKE nodes"
  value       = module.gke.service_account_email
}

# Cloud SQL Outputs
output "cloudsql_instance_name" {
  description = "Cloud SQL instance name"
  value       = module.cloudsql.instance_name
}

output "cloudsql_connection_name" {
  description = "Cloud SQL connection name (for Cloud SQL Proxy)"
  value       = module.cloudsql.connection_name
}

output "cloudsql_private_ip" {
  description = "Cloud SQL private IP address"
  value       = module.cloudsql.private_ip_address
  sensitive   = true
}

output "cloudsql_database_name" {
  description = "Main database name"
  value       = module.cloudsql.database_name
}

output "cloudsql_app_user" {
  description = "Application database user"
  value       = module.cloudsql.app_user_name
}

# Redis Outputs
output "redis_instance_id" {
  description = "Redis instance ID"
  value       = module.redis.instance_id
}

output "redis_host" {
  description = "Redis host address"
  value       = module.redis.host
  sensitive   = true
}

output "redis_port" {
  description = "Redis port"
  value       = module.redis.port
}

output "redis_current_location" {
  description = "Redis instance location"
  value       = module.redis.current_location_id
}

# Secret Manager Outputs
output "secret_ids" {
  description = "Secret Manager secret IDs"
  value       = module.secrets.secret_ids
}

# Connection Instructions
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --region ${var.region} --project ${var.project_id}"
}

output "cloudsql_proxy_command" {
  description = "Command to start Cloud SQL Proxy"
  value       = "cloud_sql_proxy -instances=${module.cloudsql.connection_name}=tcp:5432"
}

output "redis_connection_string" {
  description = "Redis connection string format"
  value       = "redis://:AUTH_STRING@${module.redis.host}:${module.redis.port}"
  sensitive   = true
}

# Cost Estimate
output "estimated_monthly_cost" {
  description = "Estimated monthly cost (USD)"
  value       = "~$300 (GKE: $100, Cloud SQL: $150, Redis: $30, Network: $20)"
}

# Environment Info
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}
