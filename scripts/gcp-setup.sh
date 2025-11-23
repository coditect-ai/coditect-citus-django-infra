#!/bin/bash
# GCP Setup Script - CODITECT Infrastructure
# This script automates the creation of GCP projects and enables required APIs
# Usage: ./scripts/gcp-setup.sh <environment>
# Example: ./scripts/gcp-setup.sh dev

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

log_info "Starting GCP setup for environment: $ENVIRONMENT"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    log_error "gcloud CLI not found. Please install from https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    log_error "Not authenticated with gcloud. Run 'gcloud auth login' first"
    exit 1
fi

# Get organization ID (optional)
log_info "Checking for organization..."
ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1)

if [ -z "$ORG_ID" ]; then
    log_warn "No organization found. Project will be created without organization."
    ORG_FLAG=""
else
    log_info "Using organization: $ORG_ID"
    ORG_FLAG="--organization=$ORG_ID"
fi

# Set project ID
PROJECT_ID="coditect-$ENVIRONMENT"
PROJECT_NAME="CODITECT ${ENVIRONMENT^}"

# Create project
log_info "Creating project: $PROJECT_ID"
if gcloud projects describe "$PROJECT_ID" &>/dev/null; then
    log_warn "Project $PROJECT_ID already exists. Skipping creation."
else
    if [ -n "$ORG_FLAG" ]; then
        gcloud projects create "$PROJECT_ID" \
            $ORG_FLAG \
            --name="$PROJECT_NAME" \
            --set-as-default
    else
        gcloud projects create "$PROJECT_ID" \
            --name="$PROJECT_NAME" \
            --set-as-default
    fi
    log_info "Project created successfully"
fi

# Set default project
gcloud config set project "$PROJECT_ID"
log_info "Default project set to: $PROJECT_ID"

# Link billing account
log_info "Checking billing account..."
BILLING_ACCOUNTS=$(gcloud billing accounts list --format="value(name)" 2>/dev/null)

if [ -z "$BILLING_ACCOUNTS" ]; then
    log_error "No billing accounts found. Please create one at https://console.cloud.google.com/billing"
    exit 1
fi

BILLING_ACCOUNT_ID=$(echo "$BILLING_ACCOUNTS" | head -n 1)
log_info "Using billing account: $BILLING_ACCOUNT_ID"

# Check if billing is already linked
CURRENT_BILLING=$(gcloud billing projects describe "$PROJECT_ID" --format="value(billingAccountName)" 2>/dev/null || echo "")

if [ -z "$CURRENT_BILLING" ]; then
    log_info "Linking billing account to project..."
    gcloud billing projects link "$PROJECT_ID" \
        --billing-account="$BILLING_ACCOUNT_ID"
    log_info "Billing account linked successfully"
else
    log_warn "Billing already linked to: $CURRENT_BILLING"
fi

# Enable required APIs
log_info "Enabling required APIs..."

REQUIRED_APIS=(
    "compute.googleapis.com"
    "container.googleapis.com"
    "sqladmin.googleapis.com"
    "storage.googleapis.com"
    "secretmanager.googleapis.com"
    "cloudresourcemanager.googleapis.com"
    "iam.googleapis.com"
    "iamcredentials.googleapis.com"
    "cloudbuild.googleapis.com"
    "artifactregistry.googleapis.com"
    "monitoring.googleapis.com"
    "logging.googleapis.com"
    "cloudtrace.googleapis.com"
    "redis.googleapis.com"
    "servicenetworking.googleapis.com"
)

for api in "${REQUIRED_APIS[@]}"; do
    log_info "Enabling $api..."
    gcloud services enable "$api" --project="$PROJECT_ID" 2>/dev/null || true
done

log_info "Waiting for APIs to be fully enabled (this may take a minute)..."
sleep 30

# Verify APIs are enabled
log_info "Verifying enabled APIs..."
ENABLED_COUNT=0
for api in "${REQUIRED_APIS[@]}"; do
    if gcloud services list --enabled --project="$PROJECT_ID" --filter="name:$api" --format="value(name)" | grep -q "$api"; then
        ENABLED_COUNT=$((ENABLED_COUNT + 1))
    else
        log_warn "API not yet enabled: $api"
    fi
done

log_info "Enabled $ENABLED_COUNT/${#REQUIRED_APIS[@]} APIs"

# Create output file with project details
OUTPUT_FILE="terraform/environments/$ENVIRONMENT/.project-info"
log_info "Creating project info file: $OUTPUT_FILE"

cat > "$OUTPUT_FILE" << EOF
# GCP Project Information - $ENVIRONMENT
# Generated: $(date)

PROJECT_ID=$PROJECT_ID
PROJECT_NAME=$PROJECT_NAME
BILLING_ACCOUNT=$BILLING_ACCOUNT_ID
REGION=us-central1
ZONE=us-central1-a

# Organization (if applicable)
${ORG_ID:+ORGANIZATION_ID=$ORG_ID}

# APIs Enabled
APIS_ENABLED=$ENABLED_COUNT
TOTAL_APIS=${#REQUIRED_APIS[@]}

# Next Steps
# 1. Run: ./scripts/iam-setup.sh $ENVIRONMENT
# 2. Configure terraform/environments/$ENVIRONMENT/terraform.tfvars
# 3. Run: cd terraform/environments/$ENVIRONMENT && terraform init
EOF

log_info "Project info saved to: $OUTPUT_FILE"

# Summary
echo ""
log_info "================================"
log_info "GCP Setup Complete!"
log_info "================================"
echo ""
echo "Project ID:       $PROJECT_ID"
echo "Project Name:     $PROJECT_NAME"
echo "Billing Account:  $BILLING_ACCOUNT_ID"
echo "APIs Enabled:     $ENABLED_COUNT/${#REQUIRED_APIS[@]}"
echo ""
log_info "Next steps:"
echo "  1. Review project at: https://console.cloud.google.com/home/dashboard?project=$PROJECT_ID"
echo "  2. Run IAM setup: ./scripts/iam-setup.sh $ENVIRONMENT"
echo "  3. Configure Terraform variables in terraform/environments/$ENVIRONMENT/"
echo ""
