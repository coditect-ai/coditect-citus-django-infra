# Terraform Infrastructure as Code

Comprehensive Infrastructure-as-Code (IaC) for CODITECT Citus Django platform on Google Cloud Platform (GCP).

## Overview

This directory contains all Terraform configurations for provisioning and managing cloud infrastructure across three environments: development, staging, and production. The infrastructure supports a hyperscale, multi-tenant SaaS platform capable of serving 1 million+ tenant organizations.

## Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── gke/                   # Google Kubernetes Engine cluster
│   ├── cloudsql/              # Cloud SQL PostgreSQL with Citus
│   ├── redis/                 # Redis cache cluster
│   ├── networking/            # VPC, subnets, Cloud NAT
│   ├── firewall/              # Firewall rules
│   ├── secrets/               # Secret Manager integration
│   ├── citus/                 # Citus-specific configuration
│   └── monitoring/            # Prometheus, Grafana, Jaeger
├── environments/              # Environment-specific configurations
│   ├── dev/                   # Development environment
│   │   ├── main.tf            # Root module configuration
│   │   ├── variables.tf       # Variable definitions
│   │   ├── outputs.tf         # Output values
│   │   ├── backend.tf         # Remote state backend
│   │   ├── providers.tf       # Provider configuration
│   │   ├── terraform.tfvars.example # Example variables
│   │   └── README.md          # Environment documentation
│   ├── staging/               # Staging environment (same structure)
│   └── production/            # Production environment (same structure)
├── backend/                   # Backend setup scripts
│   ├── create-backends.sh     # GCS bucket creation script
│   └── README.md              # Backend documentation
└── README.md                  # This file
```

## Technology Stack

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **IaC Tool** | Terraform 1.5+ | Infrastructure provisioning |
| **Cloud Provider** | Google Cloud Platform | Cloud services |
| **Orchestration** | Google Kubernetes Engine (GKE) | Container management |
| **Database** | Cloud SQL PostgreSQL 16 + Citus | Distributed database |
| **Caching** | Cloud Memorystore (Redis 7.0) | Distributed cache |
| **Networking** | VPC, Cloud NAT, Cloud Firewall | Network infrastructure |
| **Secrets** | Secret Manager | Credential management |
| **State Storage** | Google Cloud Storage | Terraform state backend |

## Prerequisites

### Required Tools

Install the following tools before working with this infrastructure:

```bash
# Terraform
brew install terraform
terraform version  # Should be >= 1.5.0

# Google Cloud SDK
brew install --cask google-cloud-sdk
gcloud version

# kubectl (for GKE access)
brew install kubectl
kubectl version --client
```

### GCP Authentication

```bash
# Login with your Google account
gcloud auth login

# Set application-default credentials (for Terraform)
gcloud auth application-default login

# Set active project
gcloud config set project coditect-citus-prod

# Verify authentication
gcloud auth list
```

### Service Account

Terraform requires a service account with appropriate permissions:

```bash
# Create service account
gcloud iam service-accounts create terraform \
    --display-name="Terraform Service Account" \
    --description="Service account for Terraform infrastructure management"

# Grant required roles
for role in \
    roles/compute.admin \
    roles/container.admin \
    roles/iam.serviceAccountAdmin \
    roles/resourcemanager.projectIamAdmin \
    roles/storage.admin \
    roles/servicenetworking.networksAdmin \
    roles/redis.admin \
    roles/cloudsql.admin \
    roles/secretmanager.admin
do
    gcloud projects add-iam-policy-binding coditect-citus-prod \
        --member="serviceAccount:terraform@coditect-citus-prod.iam.gserviceaccount.com" \
        --role="$role"
done

# Create and download key (store securely!)
gcloud iam service-accounts keys create ~/terraform-key.json \
    --iam-account=terraform@coditect-citus-prod.iam.gserviceaccount.com

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
```

## Quick Start

### 1. Setup Backend Storage

Before initializing Terraform, create GCS buckets for state storage:

```bash
cd backend
./create-backends.sh all
cd ..
```

This creates three buckets:
- `coditect-terraform-state-dev`
- `coditect-terraform-state-staging`
- `coditect-terraform-state-prod`

### 2. Configure Environment

Choose an environment (dev, staging, or production):

```bash
cd environments/dev

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Critical variables to set:**
- `project_id` - Your GCP project ID
- `db_app_user_password` - Secure database password
- `db_readonly_user_password` - Read-only user password

**Security Best Practice:** Use environment variables instead of tfvars:
```bash
export TF_VAR_db_app_user_password="$(openssl rand -base64 32)"
export TF_VAR_db_readonly_user_password="$(openssl rand -base64 32)"
```

### 3. Initialize Terraform

```bash
# Initialize backend and download providers
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt
```

### 4. Plan Infrastructure

```bash
# Create execution plan
terraform plan -out=tfplan

# Review plan carefully before applying
```

**What to look for:**
- Number of resources to create (should match expectations)
- No unexpected deletions (unless intentional)
- Correct naming conventions
- Appropriate resource sizes

### 5. Apply Changes

```bash
# Apply planned changes
terraform apply tfplan

# Monitor progress (first run takes 15-20 minutes)
```

### 6. Access Resources

```bash
# Configure kubectl for GKE cluster
gcloud container clusters get-credentials coditect-citus-dev \
    --region us-central1 \
    --project coditect-citus-prod

# Verify cluster access
kubectl get nodes

# View Terraform outputs
terraform output
```

## Environment Configurations

### Development

**Purpose:** Development and testing
**Cost:** ~$300/month

| Resource | Configuration |
|----------|---------------|
| GKE | 1-5 nodes, n1-standard-2, preemptible |
| Cloud SQL | db-custom-2-8192 (2 vCPU, 8GB RAM), ZONAL |
| Redis | 1GB, BASIC tier |
| Network | VPC, Cloud NAT, Firewall |

**Characteristics:**
- Preemptible nodes for cost savings
- Single-zone Cloud SQL (no HA)
- Basic Redis (no HA)
- Public GKE endpoint (easy access)
- Aggressive auto-scaling (scale down quickly)

**Access:**
```bash
cd environments/dev
terraform workspace select dev  # If using workspaces
```

### Staging

**Purpose:** Pre-production testing and validation
**Cost:** ~$1,200/month

| Resource | Configuration |
|----------|---------------|
| GKE | 2-8 nodes, n1-standard-4, standard |
| Cloud SQL | db-custom-4-16384 (4 vCPU, 16GB RAM), REGIONAL |
| Redis | 5GB, STANDARD_HA tier |
| Network | VPC, Cloud NAT, Firewall |

**Characteristics:**
- Standard (non-preemptible) nodes
- Regional Cloud SQL (HA across zones)
- Redis with HA (multi-zone)
- Private GKE endpoint
- Binary Authorization enabled
- Stricter auto-scaling

**Access:**
```bash
cd environments/staging
terraform workspace select staging  # If using workspaces
```

### Production

**Purpose:** Production workloads (1M+ tenants)
**Cost:** ~$5,000/month

| Resource | Configuration |
|----------|---------------|
| GKE | 3-20 nodes, n1-standard-8, standard |
| Cloud SQL | db-custom-8-32768 (8 vCPU, 32GB RAM), REGIONAL, 2 read replicas |
| Redis | 20GB, STANDARD_HA tier, 3 read replicas |
| Network | VPC, Cloud NAT, Firewall |

**Characteristics:**
- High-performance nodes (n1-standard-8)
- Regional Cloud SQL with read replicas
- Redis with read replicas
- Private GKE endpoint (no public access)
- Binary Authorization enforced
- Deletion protection enabled
- Extended backup retention (7 days)
- RDB persistence for Redis

**Access:**
```bash
cd environments/production
terraform workspace select production  # If using workspaces
```

## Module Dependency Graph

```
┌─────────────┐
│  Networking │ (VPC, Subnet, NAT)
└──────┬──────┘
       │
       ├─────────┬─────────┬─────────┐
       │         │         │         │
       ▼         ▼         ▼         ▼
  ┌─────────┐ ┌────────┐ ┌──────┐ ┌─────┐
  │Firewall │ │Cloud   │ │Redis │ │GKE  │
  └─────────┘ │SQL     │ └──────┘ └──┬──┘
              └────────┘              │
                  │                   │
                  └─────────┬─────────┘
                            │
                            ▼
                      ┌─────────┐
                      │Secrets  │
                      └─────────┘
```

**Execution Order:**
1. **Networking** - VPC, subnets, Cloud NAT
2. **Firewall** - Depends on VPC
3. **Cloud SQL, Redis, GKE** - Depend on VPC (parallel execution)
4. **Secrets** - Depends on Cloud SQL and Redis outputs

## Terraform Best Practices

### Code Organization

- **Modules:** Reusable components in `modules/`
- **Environments:** Environment-specific values in `environments/*/`
- **No Duplication:** DRY principle - reuse modules
- **Version Control:** All `.tf` files committed to git

### State Management

- **Remote State:** GCS backend (never local state)
- **State Locking:** Automatic with GCS
- **Versioning:** Enabled on all state buckets
- **Security:** State files contain secrets - protect access

### Security

- ✅ Never commit `terraform.tfvars` or `*.tfstate`
- ✅ Use Secret Manager for passwords
- ✅ Rotate credentials quarterly
- ✅ Enable deletion protection for production
- ✅ Use private GKE clusters in production

### Workflow

```bash
# 1. Create feature branch
git checkout -b feature/add-monitoring

# 2. Make changes
vim environments/dev/main.tf

# 3. Format code
terraform fmt -recursive

# 4. Validate
terraform validate

# 5. Plan
terraform plan -out=tfplan

# 6. Apply (after review)
terraform apply tfplan

# 7. Commit changes
git add .
git commit -m "feat(terraform): Add monitoring module"
git push

# 8. Create pull request
```

## Troubleshooting

### Common Issues

**Issue 1: "Error creating Network: googleapi: Error 409: Already Exists"**

**Cause:** Resource already exists in GCP.

**Solution:** Import existing resource:
```bash
terraform import module.networking.google_compute_network.vpc \
    projects/coditect-citus-prod/global/networks/coditect-vpc-dev
```

**Issue 2: "insufficient regional quota"**

**Cause:** GCP quota limits exceeded.

**Solution:** Request quota increase:
```bash
# Check current quotas
gcloud compute project-info describe --project=coditect-citus-prod

# Request increase via Cloud Console
# https://console.cloud.google.com/iam-admin/quotas
```

**Issue 3: "Backend initialization failed"**

**Cause:** GCS bucket doesn't exist or no access.

**Solution:**
```bash
# Verify bucket exists
gsutil ls gs://coditect-terraform-state-dev

# If not, create it
cd ../../backend
./create-backends.sh dev

# Retry init
cd ../environments/dev
terraform init
```

**Issue 4: "State lock timeout"**

**Cause:** Another Terraform process is holding the lock.

**Solution:**
```bash
# Force unlock (DANGER: only if you're sure no other process is running)
terraform force-unlock LOCK_ID

# Or wait for lock to expire (automatic after 20 minutes)
```

### Debug Mode

```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run Terraform command
terraform plan

# Review logs
tail -f terraform.log
```

## Cost Management

### Monthly Cost Breakdown

| Environment | GKE | Cloud SQL | Redis | Network | Total |
|-------------|-----|-----------|-------|---------|-------|
| Development | $100 | $150 | $30 | $20 | **$300** |
| Staging | $600 | $500 | $80 | $20 | **$1,200** |
| Production | $3,000 | $1,500 | $400 | $100 | **$5,000** |
| **TOTAL** | | | | | **$6,500/month** |

### Cost Optimization Tips

**Development:**
- Use preemptible nodes (60% cheaper)
- Scale down to 0 nodes after hours
- Use ZONAL Cloud SQL (no HA)
- BASIC Redis tier

**Staging:**
- Use committed use discounts (37% off)
- Scale down during low-traffic periods

**Production:**
- Use committed use discounts (57% off for 3-year)
- Right-size machine types (monitor usage)
- Use persistent disk snapshots (cheaper than backups)
- Archive old data to Cloud Storage

**Tools:**
```bash
# Estimate costs before apply
terraform plan | grep "+" | wc -l  # Resources to create

# View actual costs
gcloud beta billing accounts list
gcloud beta billing projects describe coditect-citus-prod
```

## Monitoring & Alerts

### Terraform-Managed Resources

```bash
# List all managed resources
terraform state list

# Show specific resource details
terraform state show module.gke.google_container_cluster.primary

# View resource dependencies
terraform graph | dot -Tpng > graph.png
```

### GCP Monitoring

Access monitoring in Cloud Console:
- **GKE:** https://console.cloud.google.com/kubernetes/list
- **Cloud SQL:** https://console.cloud.google.com/sql/instances
- **Redis:** https://console.cloud.google.com/memorystore/redis/instances
- **Billing:** https://console.cloud.google.com/billing

## Maintenance

### Terraform Updates

```bash
# Check current version
terraform version

# Upgrade Terraform
brew upgrade terraform

# Update provider versions in providers.tf
# Then re-initialize
terraform init -upgrade
```

### Resource Updates

```bash
# Refresh state from GCP
terraform refresh

# Show changes
terraform plan

# Apply updates
terraform apply
```

### Disaster Recovery

**Backup State:**
```bash
# Automated backups (GCS versioning enabled)
gsutil ls -la gs://coditect-terraform-state-prod/production/state/

# Manual backup
terraform state pull > backup-$(date +%Y%m%d).tfstate
```

**Restore State:**
```bash
# Rollback to previous version
gsutil cp gs://coditect-terraform-state-prod/production/state/default.tfstate#GENERATION \
    ./terraform.tfstate

terraform state push terraform.tfstate
```

**Rebuild Infrastructure:**
```bash
# Destroy all resources (DANGER!)
terraform destroy

# Recreate from scratch
terraform apply tfplan
```

## Migration Guide

### From Local State to Remote

```bash
# 1. Backup local state
cp terraform.tfstate terraform.tfstate.backup

# 2. Add backend configuration to backend.tf
# (already configured in this project)

# 3. Initialize with backend
terraform init

# 4. Terraform will prompt to migrate state
# Answer 'yes'

# 5. Verify migration
terraform state list
```

### Between Environments

```bash
# Export state from dev
cd environments/dev
terraform state pull > dev-state.json

# Import into staging (use with caution!)
cd ../staging
# Manually recreate resources or use terraformer
```

## Testing

### Pre-Apply Validation

```bash
# Format check
terraform fmt -check -recursive

# Validation
terraform validate

# Security scan (if using tfsec)
tfsec .

# Cost estimation (if using Infracost)
infracost breakdown --path .
```

### Post-Apply Verification

```bash
# Verify GKE cluster
kubectl get nodes
kubectl get pods -A

# Verify Cloud SQL
gcloud sql instances describe coditect-citus-dev

# Verify Redis
gcloud redis instances describe coditect-redis-dev --region=us-central1

# Run smoke tests
cd ../../../../tests
./smoke-test.sh dev
```

## Contributing

### Making Changes

1. Create feature branch
2. Make Terraform changes
3. Run `terraform fmt`
4. Run `terraform validate`
5. Create pull request with plan output

### Code Review Checklist

- [ ] Code formatted (`terraform fmt`)
- [ ] Validation passes (`terraform validate`)
- [ ] Plan output included in PR
- [ ] No hardcoded secrets
- [ ] Proper resource naming
- [ ] Appropriate tags/labels
- [ ] Documentation updated
- [ ] Cost impact noted

## Support

### Documentation

- **Terraform:** https://www.terraform.io/docs
- **GCP Provider:** https://registry.terraform.io/providers/hashicorp/google/latest/docs
- **GKE:** https://cloud.google.com/kubernetes-engine/docs
- **Cloud SQL:** https://cloud.google.com/sql/docs
- **Redis:** https://cloud.google.com/memorystore/docs/redis

### Internal Resources

- **Main README:** `../README.md`
- **PROJECT-PLAN:** `../PROJECT-PLAN.md`
- **TASKLIST:** `../TASKLIST.md`

### Getting Help

- **Slack:** #coditect-infrastructure
- **Email:** devops@az1.ai
- **Issues:** GitHub Issues

---

**Last Updated:** November 23, 2025
**Terraform Version:** >= 1.5.0
**GCP Provider Version:** ~> 5.0
**Managed By:** DevOps Team
