# Secret Manager Module - Production-Ready Secrets Management
# Centralized secrets storage with IAM bindings and rotation policies

locals {
  secret_prefix = var.environment

  common_labels = {
    environment = var.environment
    project     = var.project_id
    managed_by  = "terraform"
    component   = "secrets"
  }

  # Default secrets to create
  default_secrets = {
    "database-password" = {
      description     = "PostgreSQL database password for application user"
      rotation_period = "7776000s" # 90 days
    }
    "database-readonly-password" = {
      description     = "PostgreSQL read-only user password"
      rotation_period = "7776000s" # 90 days
    }
    "redis-auth-string" = {
      description     = "Redis AUTH string for authentication"
      rotation_period = "7776000s" # 90 days
    }
    "django-secret-key" = {
      description     = "Django SECRET_KEY for cryptographic signing"
      rotation_period = "15552000s" # 180 days
    }
    "stripe-api-key" = {
      description     = "Stripe API key for payment processing"
      rotation_period = "7776000s" # 90 days
    }
    "stripe-webhook-secret" = {
      description     = "Stripe webhook signing secret"
      rotation_period = "7776000s" # 90 days
    }
    "sendgrid-api-key" = {
      description     = "SendGrid API key for email delivery"
      rotation_period = "7776000s" # 90 days
    }
    "jwt-private-key" = {
      description     = "JWT signing private key (RSA)"
      rotation_period = "31536000s" # 365 days
    }
    "jwt-public-key" = {
      description     = "JWT verification public key (RSA)"
      rotation_period = "31536000s" # 365 days
    }
  }

  # Merge default and additional secrets
  all_secrets = merge(local.default_secrets, var.additional_secrets)
}

# Create Secret Manager secrets
resource "google_secret_manager_secret" "secrets" {
  for_each = local.all_secrets

  secret_id = "${local.secret_prefix}-${each.key}"
  project   = var.project_id

  replication {
    auto {
      # Automatic replication across all regions
    }
  }

  rotation {
    rotation_period = each.value.rotation_period

    # Next rotation time calculated automatically
    # Manual rotation can be triggered via gcloud or Console
  }

  topics {
    name = var.notification_topic != "" ? var.notification_topic : null
  }

  labels = merge(
    local.common_labels,
    {
      secret_type = each.key
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# IAM binding for application runtime service account
resource "google_secret_manager_secret_iam_member" "app_runtime_accessor" {
  for_each = var.app_runtime_service_account != "" ? local.all_secrets : {}

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.app_runtime_service_account}"
}

# IAM binding for deployment service account (for initial secret population)
resource "google_secret_manager_secret_iam_member" "deployment_admin" {
  for_each = var.deployment_service_account != "" ? local.all_secrets : {}

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[each.key].id
  role      = "roles/secretmanager.secretVersionAdder"
  member    = "serviceAccount:${var.deployment_service_account}"
}

# IAM binding for human administrators (view only)
resource "google_secret_manager_secret_iam_member" "admin_viewers" {
  for_each = length(var.admin_members) > 0 ? toset(flatten([
    for s in keys(local.all_secrets) : [
      for m in var.admin_members : "${s}:${m}"
    ]
  ])) : toset([])

  project   = var.project_id
  secret_id = google_secret_manager_secret.secrets[split(":", each.value)[0]].id
  role      = "roles/secretmanager.secretViewer"
  member    = split(":", each.value)[1]
}
