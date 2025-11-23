# Redis Cluster Module - Outputs

output "instance_name" {
  description = "Name of the Redis instance"
  value       = google_redis_instance.cache.name
}

output "instance_id" {
  description = "Full resource ID of the Redis instance"
  value       = google_redis_instance.cache.id
}

output "host" {
  description = "IP address of the Redis instance"
  value       = google_redis_instance.cache.host
}

output "port" {
  description = "Port number of the Redis instance"
  value       = google_redis_instance.cache.port
}

output "current_location_id" {
  description = "Current zone where the Redis instance is provisioned"
  value       = google_redis_instance.cache.current_location_id
}

output "persistence_iam_identity" {
  description = "IAM identity for persistence operations"
  value       = google_redis_instance.cache.persistence_iam_identity
}

output "read_endpoint" {
  description = "Read endpoint for read replicas (if enabled)"
  value       = try(google_redis_instance.cache.read_endpoint, null)
}

output "read_endpoint_port" {
  description = "Port for read endpoint"
  value       = try(google_redis_instance.cache.read_endpoint_port, null)
}

output "auth_string" {
  description = "AUTH string for Redis authentication (if enabled)"
  value       = try(google_redis_instance.cache.auth_string, null)
  sensitive   = true
}

output "server_ca_certs" {
  description = "Server CA certificates for TLS (if transit encryption enabled)"
  value       = try(google_redis_instance.cache.server_ca_certs, null)
  sensitive   = true
}

output "connection_string" {
  description = "Redis connection string for applications"
  value       = var.auth_enabled ? "rediss://:${google_redis_instance.cache.auth_string}@${google_redis_instance.cache.host}:${google_redis_instance.cache.port}" : "redis://${google_redis_instance.cache.host}:${google_redis_instance.cache.port}"
  sensitive   = true
}

output "connection_string_readonly" {
  description = "Redis connection string for read-only operations (if read replicas enabled)"
  value = var.replica_count > 0 && var.read_replicas_mode == "READ_REPLICAS_ENABLED" ? (
    var.auth_enabled ?
    "rediss://:${google_redis_instance.cache.auth_string}@${google_redis_instance.cache.read_endpoint}:${google_redis_instance.cache.read_endpoint_port}" :
    "redis://${google_redis_instance.cache.read_endpoint}:${google_redis_instance.cache.read_endpoint_port}"
  ) : null
  sensitive = true
}

output "region" {
  description = "Region where Redis instance is deployed"
  value       = google_redis_instance.cache.region
}

output "tier" {
  description = "Service tier of the Redis instance"
  value       = google_redis_instance.cache.tier
}

output "memory_size_gb" {
  description = "Memory size in GB"
  value       = google_redis_instance.cache.memory_size_gb
}

output "redis_version" {
  description = "Redis version"
  value       = google_redis_instance.cache.redis_version
}
