#!/bin/bash
# IAM Setup Script - CODITECT Infrastructure
# This script creates service accounts and assigns IAM roles
# Usage: ./scripts/iam-setup.sh <environment>
# Example: ./scripts/iam-setup.sh dev

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment parameter provided
if [ $# -eq 0 ]; then
    log_error "Environment parameter required"
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, production"
    exit 1
fi

ENVIRONMENT=$1

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    log_error "Invalid environment: $ENVIRONMENT"
    echo "Valid environments: dev, staging, production"
    exit 1
fi

PROJECT_ID="coditect-$ENVIRONMENT"

log_info "Starting IAM setup for project: $PROJECT_ID"

# Check if project exists
if ! gcloud projects describe "$PROJECT_ID" &>/dev/null; then
    log_error "Project $PROJECT_ID not found. Run ./scripts/gcp-setup.sh $ENVIRONMENT first"
    exit 1
fi

# Set default project
gcloud config set project "$PROJECT_ID"

# Define service accounts
declare -A SERVICE_ACCOUNTS=(
    ["terraform-sa"]="Terraform infrastructure provisioning"
    ["gke-sa"]="GKE node service account"
    ["cloudsql-sa"]="Cloud SQL client connections"
    ["django-app-sa"]="Django application runtime"
    ["monitoring-sa"]="Monitoring and observability"
)

# Create service accounts
log_info "Creating service accounts..."
for sa_name in "${!SERVICE_ACCOUNTS[@]}"; do
    SA_EMAIL="${sa_name}@${PROJECT_ID}.iam.gserviceaccount.com"

    if gcloud iam service-accounts describe "$SA_EMAIL" &>/dev/null; then
        log_warn "Service account $sa_name already exists. Skipping creation."
    else
        log_info "Creating service account: $sa_name"
        gcloud iam service-accounts create "$sa_name" \
            --description="${SERVICE_ACCOUNTS[$sa_name]}" \
            --display-name="$sa_name"
        log_info "Created: $SA_EMAIL"
    fi
done

# Assign IAM roles
log_info "Assigning IAM roles..."

# Terraform SA - broad permissions for infrastructure management
log_info "Configuring terraform-sa roles..."
TERRAFORM_ROLES=(
    "roles/editor"
    "roles/iam.securityAdmin"
    "roles/compute.networkAdmin"
    "roles/container.admin"
)

for role in "${TERRAFORM_ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="$role" \
        --condition=None \
        2>/dev/null || log_warn "Role $role may already be assigned"
done

# GKE SA - minimal permissions for nodes
log_info "Configuring gke-sa roles..."
GKE_ROLES=(
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
    "roles/monitoring.viewer"
    "roles/stackdriver.resourceMetadata.writer"
)

for role in "${GKE_ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="$role" \
        --condition=None \
        2>/dev/null || log_warn "Role $role may already be assigned"
done

# Cloud SQL SA
log_info "Configuring cloudsql-sa roles..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:cloudsql-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client" \
    --condition=None \
    2>/dev/null || log_warn "Cloud SQL role may already be assigned"

# Django App SA
log_info "Configuring django-app-sa roles..."
DJANGO_ROLES=(
    "roles/secretmanager.secretAccessor"
    "roles/storage.objectViewer"
    "roles/cloudsql.client"
    "roles/cloudtrace.agent"
)

for role in "${DJANGO_ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="$role" \
        --condition=None \
        2>/dev/null || log_warn "Role $role may already be assigned"
done

# Monitoring SA
log_info "Configuring monitoring-sa roles..."
MONITORING_ROLES=(
    "roles/monitoring.metricWriter"
    "roles/logging.logWriter"
)

for role in "${MONITORING_ROLES[@]}"; do
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:monitoring-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
        --role="$role" \
        --condition=None \
        2>/dev/null || log_warn "Role $role may already be assigned"
done

# Download service account keys (for local development only)
KEYS_DIR="${HOME}/.config/gcloud/keys"
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

log_info "Downloading service account keys to $KEYS_DIR..."

# Only download Terraform SA key for local use
TERRAFORM_KEY="${KEYS_DIR}/${PROJECT_ID}-terraform-key.json"

if [ -f "$TERRAFORM_KEY" ]; then
    log_warn "Terraform key already exists at: $TERRAFORM_KEY"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping key download"
    else
        log_info "Creating new terraform service account key..."
        gcloud iam service-accounts keys create "$TERRAFORM_KEY" \
            --iam-account="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"
        chmod 600 "$TERRAFORM_KEY"
        log_info "Key saved to: $TERRAFORM_KEY"
    fi
else
    log_info "Creating terraform service account key..."
    gcloud iam service-accounts keys create "$TERRAFORM_KEY" \
        --iam-account="terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com"
    chmod 600 "$TERRAFORM_KEY"
    log_info "Key saved to: $TERRAFORM_KEY"
fi

# Create environment variables file
ENV_FILE="terraform/environments/$ENVIRONMENT/.env.iam"
log_info "Creating IAM environment file: $ENV_FILE"

cat > "$ENV_FILE" << EOF
# IAM Configuration - $ENVIRONMENT
# Generated: $(date)

# Service Account Emails
TERRAFORM_SA=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com
GKE_SA=gke-sa@${PROJECT_ID}.iam.gserviceaccount.com
CLOUDSQL_SA=cloudsql-sa@${PROJECT_ID}.iam.gserviceaccount.com
DJANGO_APP_SA=django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com
MONITORING_SA=monitoring-sa@${PROJECT_ID}.iam.gserviceaccount.com

# Terraform Key Path (for local development)
GOOGLE_APPLICATION_CREDENTIALS=$TERRAFORM_KEY

# Instructions
# 1. Export GOOGLE_APPLICATION_CREDENTIALS for Terraform:
#    export GOOGLE_APPLICATION_CREDENTIALS=$TERRAFORM_KEY
# 2. Use workload identity for GKE pods (recommended for production)
# 3. Never commit service account keys to git
EOF

log_info "IAM configuration saved to: $ENV_FILE"

# Summary
echo ""
log_info "================================"
log_info "IAM Setup Complete!"
log_info "================================"
echo ""
echo "Project:               $PROJECT_ID"
echo "Service Accounts:      ${#SERVICE_ACCOUNTS[@]}"
echo "Terraform Key:         $TERRAFORM_KEY"
echo ""
log_info "Service Accounts Created:"
for sa_name in "${!SERVICE_ACCOUNTS[@]}"; do
    echo "  - ${sa_name}@${PROJECT_ID}.iam.gserviceaccount.com"
done
echo ""
log_info "Next steps:"
echo "  1. Export credentials: export GOOGLE_APPLICATION_CREDENTIALS=$TERRAFORM_KEY"
echo "  2. Source IAM config: source $ENV_FILE"
echo "  3. Verify access: gcloud auth list"
echo "  4. Configure Terraform: cd terraform/environments/$ENVIRONMENT"
echo ""
log_warn "SECURITY NOTICE:"
echo "  - Service account keys are stored in: $KEYS_DIR"
echo "  - Keys are excluded from git via .gitignore"
echo "  - For production, use Workload Identity instead of keys"
echo "  - Rotate keys quarterly: gcloud iam service-accounts keys list"
echo ""
