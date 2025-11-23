# Development Environment - Terraform Configuration

## Overview

This directory contains Terraform configuration for the **development environment** of the CODITECT Citus Django platform. The development environment is optimized for cost savings while providing a functional testing environment.

## Environment Specifications

| Resource | Configuration | Cost/Month |
|----------|--------------|------------|
| **GKE Cluster** | 1-5 nodes (n1-standard-2, preemptible) | ~$100 |
| **Cloud SQL** | db-custom-2-8192, ZONAL, 50GB | ~$150 |
| **Redis** | 1GB, BASIC tier | ~$30 |
| **Networking** | VPC, Cloud NAT, Firewall | ~$20 |
| **Total** | | **~$300/month** |

## Architecture

```
Development Environment
├── VPC Network (10.10.0.0/20)
│   ├── Primary Subnet (GKE nodes)
│   ├── Secondary Range (Pods: 10.14.0.0/14)
│   └── Secondary Range (Services: 10.18.0.0/20)
├── GKE Cluster (coditect-citus-dev)
│   ├── Node Pool: 1-5 nodes (auto-scaling)
│   ├── Machine Type: n1-standard-2 (preemptible)
│   └── Disk: 50GB per node
├── Cloud SQL PostgreSQL (coditect-citus-dev)
│   ├── Tier: db-custom-2-8192 (2 vCPU, 8GB RAM)
│   ├── HA: ZONAL (single-zone)
│   ├── Disk: 50GB
│   └── Backups: Daily (3-day retention)
└── Redis (coditect-redis-dev)
    ├── Memory: 1GB
    ├── Tier: BASIC (no HA)
    └── Persistence: Disabled
```

## Prerequisites

### Required Tools

- **Terraform:** >= 1.5.0
- **gcloud CLI:** Latest version
- **kubectl:** Latest version

### GCP Authentication

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project coditect-citus-prod
```

### Service Account

Ensure the Terraform service account has these roles:
- `roles/compute.admin`
- `roles/container.admin`
- `roles/iam.serviceAccountAdmin`
- `roles/resourcemanager.projectIamAdmin`
- `roles/storage.admin`

## Quick Start

### 1. Setup Backend Bucket

```bash
# Create GCS bucket for Terraform state
cd ../../backend
./create-backends.sh dev

# Verify bucket creation
gsutil ls gs://coditect-terraform-state-dev
```

### 2. Configure Variables

```bash
# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars
```

**Required variables:**
- `project_id` - Your GCP project ID
- `db_app_user_password` - Database password (use Secret Manager!)
- `db_readonly_user_password` - Read-only user password

**Recommended:** Use environment variables instead of tfvars for secrets:
```bash
export TF_VAR_db_app_user_password="your-secure-password"
export TF_VAR_db_readonly_user_password="your-secure-password"
```

### 3. Initialize Terraform

```bash
# Initialize backend and download providers
terraform init

# Verify configuration
terraform validate
```

### 4. Plan Infrastructure

```bash
# Create execution plan
terraform plan -out=tfplan

# Review the plan carefully
```

### 5. Apply Configuration

```bash
# Apply infrastructure changes
terraform apply tfplan

# Confirm when prompted
```

**First-time deployment:** Expect 15-20 minutes for full infrastructure creation.

### 6. Access Resources

```bash
# Configure kubectl for GKE cluster
gcloud container clusters get-credentials coditect-citus-dev \
  --region us-central1 \
  --project coditect-citus-prod

# Verify cluster access
kubectl get nodes

# Start Cloud SQL Proxy (optional, for direct database access)
cloud_sql_proxy -instances=INSTANCE_CONNECTION_NAME=tcp:5432
```

## Resource Details

### GKE Cluster

- **Name:** `coditect-citus-dev`
- **Region:** `us-central1`
- **Zones:** `us-central1-a`, `us-central1-b`, `us-central1-c`
- **Nodes:** 1-5 (auto-scaling)
- **Machine Type:** `n1-standard-2` (2 vCPU, 7.5GB RAM)
- **Preemptible:** Yes (for cost savings)
- **Master Endpoint:** Public (accessible from anywhere)

**Access:**
```bash
kubectl get all -A
```

### Cloud SQL

- **Name:** `coditect-citus-dev`
- **Version:** PostgreSQL 16
- **Tier:** `db-custom-2-8192`
- **HA:** ZONAL (single-zone)
- **Private IP:** Yes (VPC peering)
- **Public IP:** No

**Connection:**
```bash
# Via Cloud SQL Proxy
cloud_sql_proxy -instances=coditect-citus-prod:us-central1:coditect-citus-dev=tcp:5432

# From GKE pod
psql -h <PRIVATE_IP> -U app_user -d coditect
```

### Redis

- **Name:** `coditect-redis-dev`
- **Version:** Redis 7.0
- **Memory:** 1GB
- **Tier:** BASIC (no HA)
- **Auth:** Enabled
- **TLS:** Server authentication

**Connection:**
```bash
# From GKE pod
redis-cli -h <REDIS_HOST> -p 6379 -a <AUTH_STRING>
```

## Development Workflow

### Making Changes

1. **Edit Terraform files**
2. **Validate changes:** `terraform validate`
3. **Plan changes:** `terraform plan`
4. **Review plan carefully**
5. **Apply changes:** `terraform apply`

### Adding Resources

```bash
# Add to main.tf
# Example: Add another node pool

# Plan and apply
terraform plan -out=tfplan
terraform apply tfplan
```

### Destroying Resources

⚠️ **WARNING:** This will delete all resources!

```bash
# Destroy specific resource
terraform destroy -target=module.redis

# Destroy entire environment
terraform destroy
```

**Cost Savings:** Destroy dev environment when not in use (evenings/weekends).

## Troubleshooting

### Common Issues

**Issue:** `Error creating Network: googleapi: Error 409: Already Exists`
- **Solution:** Resource already exists. Import it:
  ```bash
  terraform import module.networking.google_compute_network.vpc projects/PROJECT_ID/global/networks/NETWORK_NAME
  ```

**Issue:** `Error creating Cluster: insufficient regional quota`
- **Solution:** Request quota increase:
  ```bash
  gcloud compute project-info describe --project=PROJECT_ID
  ```

**Issue:** `Database user password is required`
- **Solution:** Set via environment variable:
  ```bash
  export TF_VAR_db_app_user_password="your-password"
  ```

### Debug Mode

```bash
# Enable debug logging
export TF_LOG=DEBUG
terraform plan

# Write logs to file
export TF_LOG_PATH=./terraform.log
terraform apply
```

### State Management

```bash
# View current state
terraform show

# List all resources
terraform state list

# Refresh state from GCP
terraform refresh
```

## Maintenance

### Backups

- **Automated:** Daily at 03:00 UTC
- **Retention:** 3 backups
- **PITR:** 3-day retention

### Updates

- **GKE:** REGULAR release channel (auto-updates)
- **Cloud SQL:** Maintenance window Sunday 03:00 UTC
- **Redis:** Maintenance window Sunday 03:00 UTC

### Monitoring

Access GCP Console:
- **GKE:** https://console.cloud.google.com/kubernetes/clusters
- **Cloud SQL:** https://console.cloud.google.com/sql/instances
- **Redis:** https://console.cloud.google.com/memorystore/redis/instances

## Security Notes

### Secrets

- ✅ Use Secret Manager for database passwords
- ✅ Never commit `terraform.tfvars` to git
- ✅ Rotate credentials quarterly

### Network

- ✅ Private GKE cluster (master endpoint public for dev)
- ✅ Cloud SQL private IP only
- ✅ Firewall rules restrict access

### Access Control

- ✅ GKE RBAC enabled
- ✅ Service accounts with least privilege
- ✅ Audit logging enabled

## Outputs

After successful apply, you'll see:

```hcl
gke_cluster_endpoint = "https://XX.XX.XX.XX"
gke_cluster_name = "coditect-citus-dev"
cloudsql_connection_name = "coditect-citus-prod:us-central1:coditect-citus-dev"
cloudsql_private_ip = "10.XX.XX.XX"
redis_host = "10.XX.XX.XX"
kubectl_config_command = "gcloud container clusters get-credentials ..."
estimated_monthly_cost = "~$300"
```

## Next Steps

1. **Deploy Kubernetes resources:** `cd ../../../kubernetes`
2. **Configure Citus cluster:** `cd ../../../citus`
3. **Deploy Django application:** See backend repository

## Support

- **Documentation:** `/docs/DEPLOYMENT.md`
- **Issues:** GitHub Issues
- **Contact:** DevOps Team

---

**Environment:** Development
**Last Updated:** November 23, 2025
**Managed By:** Terraform
