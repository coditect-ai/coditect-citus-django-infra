#!/bin/bash
# Create GCS Buckets for Terraform State Storage
# Usage: ./create-backends.sh [environment]
#   environment: dev, staging, production, or all (default: all)

set -euo pipefail

# Configuration
PROJECT_ID="coditect-citus-prod"
LOCATION="US"  # Multi-region for redundancy
STORAGE_CLASS="STANDARD"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Environments
ENVIRONMENTS=("dev" "staging" "production")

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

create_bucket() {
    local env=$1
    local bucket_suffix
    
    if [ "$env" == "production" ]; then
        bucket_suffix="prod"
    else
        bucket_suffix="$env"
    fi
    
    local bucket_name="coditect-terraform-state-${bucket_suffix}"
    
    log_info "Creating bucket: ${bucket_name}"
    
    # Check if bucket already exists
    if gsutil ls -b "gs://${bucket_name}" &>/dev/null; then
        log_warn "Bucket ${bucket_name} already exists. Skipping creation."
        return 0
    fi
    
    # Create bucket
    gsutil mb \
        -p "${PROJECT_ID}" \
        -c "${STORAGE_CLASS}" \
        -l "${LOCATION}" \
        -b on \
        "gs://${bucket_name}"
    
    log_info "Bucket ${bucket_name} created successfully"
    
    # Enable versioning
    log_info "Enabling versioning on ${bucket_name}"
    gsutil versioning set on "gs://${bucket_name}"
    
    # Set lifecycle policy (keep last 10 versions)
    log_info "Setting lifecycle policy on ${bucket_name}"
    cat > /tmp/lifecycle.json <<LIFECYCLE
{
  "lifecycle": {
    "rule": [
      {
        "action": {
          "type": "Delete"
        },
        "condition": {
          "numNewerVersions": 10
        }
      }
    ]
  }
}
LIFECYCLE
    
    gsutil lifecycle set /tmp/lifecycle.json "gs://${bucket_name}"
    rm /tmp/lifecycle.json
    
    # Add labels
    log_info "Adding labels to ${bucket_name}"
    gsutil label ch \
        -l "environment:${env}" \
        -l "project:coditect-citus" \
        -l "managed_by:terraform" \
        -l "purpose:terraform-state" \
        "gs://${bucket_name}"
    
    # Enable uniform bucket-level access
    log_info "Enabling uniform bucket-level access on ${bucket_name}"
    gsutil uniformbucketlevelaccess set on "gs://${bucket_name}"
    
    # Grant storage.admin to Terraform service account
    local tf_sa="terraform@${PROJECT_ID}.iam.gserviceaccount.com"
    log_info "Granting storage.admin to ${tf_sa}"
    gsutil iam ch \
        "serviceAccount:${tf_sa}:roles/storage.admin" \
        "gs://${bucket_name}"
    
    log_info "✓ Bucket ${bucket_name} configured successfully"
    echo ""
}

verify_bucket() {
    local env=$1
    local bucket_suffix
    
    if [ "$env" == "production" ]; then
        bucket_suffix="prod"
    else
        bucket_suffix="$env"
    fi
    
    local bucket_name="coditect-terraform-state-${bucket_suffix}"
    
    log_info "Verifying bucket: ${bucket_name}"
    
    # Check bucket exists
    if ! gsutil ls -b "gs://${bucket_name}" &>/dev/null; then
        log_error "Bucket ${bucket_name} does not exist!"
        return 1
    fi
    
    # Check versioning
    if gsutil versioning get "gs://${bucket_name}" | grep -q "Enabled"; then
        log_info "✓ Versioning enabled"
    else
        log_warn "✗ Versioning NOT enabled"
    fi
    
    # Check lifecycle policy
    if gsutil lifecycle get "gs://${bucket_name}" &>/dev/null; then
        log_info "✓ Lifecycle policy configured"
    else
        log_warn "✗ Lifecycle policy NOT configured"
    fi
    
    # Check labels
    local labels=$(gsutil ls -L -b "gs://${bucket_name}" | grep -A 10 "Labels:")
    if echo "$labels" | grep -q "environment"; then
        log_info "✓ Labels configured"
    else
        log_warn "✗ Labels NOT configured"
    fi
    
    log_info "✓ Bucket ${bucket_name} verification complete"
    echo ""
}

# Main script
main() {
    local env_filter="${1:-all}"
    
    log_info "=== Terraform State Backend Setup ==="
    log_info "Project: ${PROJECT_ID}"
    log_info "Location: ${LOCATION}"
    log_info "Environment Filter: ${env_filter}"
    echo ""
    
    # Check if gcloud is installed
    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI not found. Please install it first."
        exit 1
    fi
    
    # Check if gsutil is installed
    if ! command -v gsutil &> /dev/null; then
        log_error "gsutil not found. Please install Google Cloud SDK."
        exit 1
    fi
    
    # Check authentication
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
        log_error "Not authenticated with gcloud. Run: gcloud auth login"
        exit 1
    fi
    
    # Set project
    log_info "Setting active project to ${PROJECT_ID}"
    gcloud config set project "${PROJECT_ID}"
    echo ""
    
    # Create buckets
    if [ "$env_filter" == "all" ]; then
        for env in "${ENVIRONMENTS[@]}"; do
            create_bucket "$env"
        done
    else
        if [[ " ${ENVIRONMENTS[@]} " =~ " ${env_filter} " ]]; then
            create_bucket "$env_filter"
        else
            log_error "Invalid environment: ${env_filter}"
            log_error "Valid options: dev, staging, production, all"
            exit 1
        fi
    fi
    
    # Verify buckets
    log_info "=== Verification ==="
    if [ "$env_filter" == "all" ]; then
        for env in "${ENVIRONMENTS[@]}"; do
            verify_bucket "$env"
        done
    else
        verify_bucket "$env_filter"
    fi
    
    log_info "=== Setup Complete ==="
    log_info "You can now run 'terraform init' in each environment directory."
    log_info ""
    log_info "Example:"
    log_info "  cd ../environments/dev"
    log_info "  terraform init"
}

# Run main function
main "$@"
