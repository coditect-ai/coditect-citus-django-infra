# Cloud SQL PostgreSQL Module - Outputs

output "instance_name" {
  description = "Name of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.name
}

output "instance_connection_name" {
  description = "Connection name for Cloud SQL Proxy (project:region:instance)"
  value       = google_sql_database_instance.postgres.connection_name
}

output "instance_self_link" {
  description = "Self link of the Cloud SQL instance"
  value       = google_sql_database_instance.postgres.self_link
}

output "instance_service_account_email" {
  description = "Service account email address assigned to the instance"
  value       = google_sql_database_instance.postgres.service_account_email_address
}

output "private_ip_address" {
  description = "Private IP address of the Cloud SQL instance"
  value       = try(google_sql_database_instance.postgres.private_ip_address, null)
}

output "public_ip_address" {
  description = "Public IP address of the Cloud SQL instance (if enabled)"
  value       = try(google_sql_database_instance.postgres.public_ip_address, null)
}

output "database_version" {
  description = "PostgreSQL version of the instance"
  value       = google_sql_database_instance.postgres.database_version
}

output "database_name" {
  description = "Name of the default database"
  value       = google_sql_database.default.name
}

output "app_user_name" {
  description = "Application database user name"
  value       = google_sql_user.app_user.name
}

output "readonly_user_name" {
  description = "Read-only database user name (if created)"
  value       = try(google_sql_user.readonly_user[0].name, null)
}

output "replica_instance_name" {
  description = "Name of the read replica instance (if created)"
  value       = try(google_sql_database_instance.replica[0].name, null)
}

output "replica_connection_name" {
  description = "Connection name for read replica (if created)"
  value       = try(google_sql_database_instance.replica[0].connection_name, null)
}

output "replica_private_ip_address" {
  description = "Private IP address of read replica (if created)"
  value       = try(google_sql_database_instance.replica[0].private_ip_address, null)
}

# Connection strings for application configuration
output "connection_string_private" {
  description = "PostgreSQL connection string using private IP"
  value       = "postgresql://${google_sql_user.app_user.name}@${try(google_sql_database_instance.postgres.private_ip_address, "PENDING")}:5432/${google_sql_database.default.name}?sslmode=require"
  sensitive   = true
}

output "connection_string_proxy" {
  description = "PostgreSQL connection string using Cloud SQL Proxy"
  value       = "postgresql://${google_sql_user.app_user.name}@localhost:5432/${google_sql_database.default.name}?host=/cloudsql/${google_sql_database_instance.postgres.connection_name}"
  sensitive   = true
}
