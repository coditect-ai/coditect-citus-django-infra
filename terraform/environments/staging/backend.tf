# Terraform Backend Configuration - Development Environment
# GCS backend for remote state storage with state locking

terraform {
  backend "gcs" {
    bucket = "coditect-terraform-state-staging"
    prefix = "staging/state"

    # State locking is automatically enabled for GCS backend
    # Versioning should be enabled on the bucket for state history
  }
}
