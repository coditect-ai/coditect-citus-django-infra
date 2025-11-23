# Terraform Backend Setup

This directory contains scripts and documentation for setting up GCS (Google Cloud Storage) backends for Terraform state management across all environments.

## Overview

Terraform state is stored remotely in GCS buckets to enable:
- **Team Collaboration:** Multiple engineers can work on infrastructure
- **State Locking:** Prevents concurrent modifications
- **State History:** Versioning enabled for rollback capability
- **Security:** State files contain sensitive data (encrypted at rest)

## Backend Architecture

```
GCS State Buckets (per environment)
├── coditect-terraform-state-dev
│   ├── dev/state/default.tfstate
│   └── Versioning: Last 10 versions
├── coditect-terraform-state-staging
│   ├── staging/state/default.tfstate
│   └── Versioning: Last 10 versions
└── coditect-terraform-state-prod
    ├── production/state/default.tfstate
    └── Versioning: Last 10 versions
```

### Bucket Configuration

| Feature | Configuration |
|---------|---------------|
| **Location** | US (multi-region) |
| **Storage Class** | STANDARD |
| **Versioning** | Enabled (keep last 10 versions) |
| **Access Control** | Uniform bucket-level access |
| **Encryption** | Google-managed (default) |
| **Lifecycle Policy** | Delete versions after 10 newer versions |

## Prerequisites

### Required Tools

- **gcloud CLI:** Latest version
- **gsutil:** Included with gcloud

### Authentication

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project coditect-citus-prod
```

### Service Account

Ensure the Terraform service account exists:
```bash
# Check if service account exists
gcloud iam service-accounts list | grep terraform

# If not, create it
gcloud iam service-accounts create terraform \
    --display-name="Terraform Service Account" \
    --description="Service account for Terraform infrastructure management"

# Grant necessary roles
gcloud projects add-iam-policy-binding coditect-citus-prod \
    --member="serviceAccount:terraform@coditect-citus-prod.iam.gserviceaccount.com" \
    --role="roles/storage.admin"
```

## Quick Start

### Create All Backends

```bash
# Make script executable
chmod +x create-backends.sh

# Create buckets for all environments
./create-backends.sh all
```

### Create Single Environment

```bash
# Create only dev bucket
./create-backends.sh dev

# Create only staging bucket
./create-backends.sh staging

# Create only production bucket
./create-backends.sh production
```

## Script Details

### create-backends.sh

**Purpose:** Automates GCS bucket creation and configuration for Terraform state storage.

**Actions:**
1. Creates GCS bucket with environment-specific name
2. Enables versioning (keep last 10 versions)
3. Sets lifecycle policy (automatic cleanup)
4. Adds metadata labels
5. Enables uniform bucket-level access
6. Grants storage.admin to Terraform service account
7. Verifies configuration

**Usage:**
```bash
./create-backends.sh [environment]
```

**Arguments:**
- `environment` - dev, staging, production, or all (default: all)

**Output:**
```
[INFO] === Terraform State Backend Setup ===
[INFO] Project: coditect-citus-prod
[INFO] Location: US
[INFO] Environment Filter: all

[INFO] Creating bucket: coditect-terraform-state-dev
[INFO] Bucket coditect-terraform-state-dev created successfully
[INFO] Enabling versioning on coditect-terraform-state-dev
[INFO] Setting lifecycle policy on coditect-terraform-state-dev
[INFO] Adding labels to coditect-terraform-state-dev
[INFO] Enabling uniform bucket-level access on coditect-terraform-state-dev
[INFO] Granting storage.admin to terraform@coditect-citus-prod.iam.gserviceaccount.com
[INFO] ✓ Bucket coditect-terraform-state-dev configured successfully

...
```

## Bucket Naming Convention

| Environment | Bucket Name |
|-------------|-------------|
| Development | `coditect-terraform-state-dev` |
| Staging | `coditect-terraform-state-staging` |
| Production | `coditect-terraform-state-prod` |

## State Management

### Initialize Backend

After creating buckets, initialize Terraform in each environment:

```bash
# Development
cd ../environments/dev
terraform init

# Staging
cd ../environments/staging
terraform init

# Production
cd ../environments/production
terraform init
```

### Migrate Existing State

If you have local state files:

```bash
# Backup local state
cp terraform.tfstate terraform.tfstate.backup

# Initialize with backend
terraform init

# Terraform will prompt to migrate state
# Answer 'yes' to copy local state to GCS
```

### View State

```bash
# List state resources
terraform state list

# Show specific resource
terraform state show module.gke.google_container_cluster.primary

# Download state (for inspection only)
gsutil cp gs://coditect-terraform-state-dev/dev/state/default.tfstate ./
```

### Rollback State

If you need to rollback to a previous version:

```bash
# List available versions
gsutil ls -la gs://coditect-terraform-state-dev/dev/state/

# Download specific version
gsutil cp gs://coditect-terraform-state-dev/dev/state/default.tfstate#<GENERATION> ./terraform.tfstate

# Force Terraform to use this state
terraform state push terraform.tfstate
```

## Security Best Practices

### Encryption

- **At Rest:** GCS default encryption (Google-managed keys)
- **In Transit:** TLS 1.2+ for all API calls
- **Recommendation:** Use customer-managed encryption keys (CMEK) for production

### Access Control

- **Principle of Least Privilege:** Only Terraform service account has write access
- **Audit Logging:** All state access is logged in Cloud Audit Logs
- **Uniform Bucket Access:** IAM policies applied at bucket level (no ACLs)

### Enable CMEK (Optional - Production)

```bash
# Create KMS keyring
gcloud kms keyrings create terraform-state \
    --location=us

# Create encryption key
gcloud kms keys create state-encryption \
    --location=us \
    --keyring=terraform-state \
    --purpose=encryption

# Grant encrypter/decrypter role to GCS service account
gcloud kms keys add-iam-policy-binding state-encryption \
    --location=us \
    --keyring=terraform-state \
    --member="serviceAccount:service-<PROJECT_NUMBER>@gs-project-accounts.iam.gserviceaccount.com" \
    --role="roles/cloudkms.cryptoKeyEncrypterDecrypter"

# Update bucket to use CMEK
gsutil kms encryption \
    -k projects/coditect-citus-prod/locations/us/keyRings/terraform-state/cryptoKeys/state-encryption \
    gs://coditect-terraform-state-prod
```

## Troubleshooting

### Issue: "Permission denied" when creating bucket

**Solution:**
```bash
# Check current account
gcloud auth list

# Ensure you have storage.admin role
gcloud projects get-iam-policy coditect-citus-prod \
    --flatten="bindings[].members" \
    --filter="bindings.members:user:YOUR_EMAIL"
```

### Issue: "Bucket name already taken"

**Solution:** Bucket names are globally unique. If the name is taken, either:
1. The bucket exists in your project (check `gsutil ls`)
2. Someone else owns the name (choose a different prefix)

### Issue: "State locking not working"

**Symptoms:** Multiple users can apply simultaneously

**Solution:** GCS backend supports native state locking. Ensure:
```bash
# Backend configuration includes bucket (locking is automatic)
terraform {
  backend "gcs" {
    bucket = "coditect-terraform-state-dev"
    prefix = "dev/state"
  }
}
```

### Issue: "Failed to get existing workspaces"

**Solution:** This is harmless on first init. Ignore or:
```bash
terraform init -reconfigure
```

## Monitoring

### View Bucket Metrics

```bash
# View bucket size
gsutil du -s gs://coditect-terraform-state-dev

# View object count
gsutil ls -r gs://coditect-terraform-state-dev | wc -l

# View versioning status
gsutil versioning get gs://coditect-terraform-state-dev
```

### Cloud Console

Access GCS buckets in Cloud Console:
https://console.cloud.google.com/storage/browser?project=coditect-citus-prod

## Maintenance

### Cleanup Old Versions

Lifecycle policy automatically deletes versions after 10 newer versions exist. Manual cleanup:

```bash
# List all versions
gsutil ls -la gs://coditect-terraform-state-dev/dev/state/

# Delete specific version
gsutil rm gs://coditect-terraform-state-dev/dev/state/default.tfstate#<GENERATION>
```

### Backup State

```bash
# Backup all state files
gsutil -m cp -r \
    gs://coditect-terraform-state-dev \
    gs://coditect-backups/terraform-state/$(date +%Y-%m-%d)/
```

## Cost Estimates

| Environment | Storage | Requests/Month | Cost/Month |
|-------------|---------|----------------|------------|
| Development | ~10MB | ~1,000 | $0.01 |
| Staging | ~20MB | ~5,000 | $0.02 |
| Production | ~50MB | ~10,000 | $0.05 |
| **Total** | | | **~$0.08/month** |

*Costs are negligible compared to infrastructure costs*

## Next Steps

1. ✅ Create GCS buckets (`./create-backends.sh all`)
2. ✅ Verify bucket configuration
3. Initialize Terraform in each environment
4. Migrate existing state (if applicable)
5. Test state locking with team
6. Enable CMEK for production (optional)

## Support

- **GCS Documentation:** https://cloud.google.com/storage/docs
- **Terraform Backend Docs:** https://www.terraform.io/docs/language/settings/backends/gcs.html
- **Internal Docs:** See main repository README

---

**Last Updated:** November 23, 2025
**Managed By:** DevOps Team
