# Secret Manager Module - Outputs

output "secret_ids" {
  description = "Map of secret names to Secret Manager secret IDs"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.id
  }
}

output "secret_names" {
  description = "Map of secret keys to full secret names"
  value = {
    for k, v in google_secret_manager_secret.secrets : k => v.name
  }
}

output "database_password_secret" {
  description = "Secret Manager resource name for database password"
  value       = google_secret_manager_secret.secrets["database-password"].name
}

output "redis_auth_secret" {
  description = "Secret Manager resource name for Redis AUTH string"
  value       = google_secret_manager_secret.secrets["redis-auth-string"].name
}

output "django_secret_key_secret" {
  description = "Secret Manager resource name for Django SECRET_KEY"
  value       = google_secret_manager_secret.secrets["django-secret-key"].name
}

output "stripe_api_key_secret" {
  description = "Secret Manager resource name for Stripe API key"
  value       = google_secret_manager_secret.secrets["stripe-api-key"].name
}

output "stripe_webhook_secret" {
  description = "Secret Manager resource name for Stripe webhook secret"
  value       = google_secret_manager_secret.secrets["stripe-webhook-secret"].name
}

output "jwt_private_key_secret" {
  description = "Secret Manager resource name for JWT private key"
  value       = google_secret_manager_secret.secrets["jwt-private-key"].name
}

output "jwt_public_key_secret" {
  description = "Secret Manager resource name for JWT public key"
  value       = google_secret_manager_secret.secrets["jwt-public-key"].name
}
