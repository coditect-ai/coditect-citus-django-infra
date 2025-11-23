# Terraform Quick Start Guide

5-minute guide to deploying CODITECT infrastructure to GCP.

## Prerequisites Checklist

- [ ] Terraform installed (`brew install terraform`)
- [ ] gcloud CLI installed (`brew install --cask google-cloud-sdk`)
- [ ] GCP project created (`coditect-citus-prod`)
- [ ] Authenticated with GCP (`gcloud auth login`)
- [ ] Terraform service account created
- [ ] Service account key downloaded

## Setup (One-Time)

### 1. Authenticate

```bash
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
gcloud config set project coditect-citus-prod
```

### 2. Create State Buckets

```bash
cd backend
./create-backends.sh all
cd ..
```

**Expected output:**
```
[INFO] === Terraform State Backend Setup ===
[INFO] Creating bucket: coditect-terraform-state-dev
[INFO] ✓ Bucket coditect-terraform-state-dev configured successfully
...
```

## Deploy Development Environment

### 1. Navigate to Dev Environment

```bash
cd environments/dev
```

### 2. Configure Variables

```bash
# Option A: Use environment variables (recommended)
export TF_VAR_project_id="coditect-citus-prod"
export TF_VAR_db_app_user_password="$(openssl rand -base64 32)"
export TF_VAR_db_readonly_user_password="$(openssl rand -base64 32)"

# Option B: Create terraform.tfvars (NOT recommended for secrets)
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # Edit values
```

### 3. Initialize Terraform

```bash
terraform init
```

**Expected output:**
```
Initializing the backend...
Successfully configured the backend "gcs"!

Initializing provider plugins...
- terraform.io/builtin/terraform
- hashicorp/google v5.x.x
...
Terraform has been successfully initialized!
```

### 4. Plan Infrastructure

```bash
terraform plan -out=tfplan
```

**Review plan output:**
- Should show ~30-40 resources to create
- Check naming (should include "-dev" suffix)
- Verify machine types (n1-standard-2 for dev)
- Confirm preemptible nodes enabled

### 5. Apply Configuration

```bash
terraform apply tfplan
```

**Wait time:** 15-20 minutes for first deployment

**Expected output:**
```
Apply complete! Resources: 38 added, 0 changed, 0 destroyed.

Outputs:

gke_cluster_endpoint = "https://XX.XX.XX.XX"
gke_cluster_name = "coditect-citus-dev"
cloudsql_connection_name = "coditect-citus-prod:us-central1:coditect-citus-dev"
...
```

### 6. Access Resources

```bash
# Configure kubectl
gcloud container clusters get-credentials coditect-citus-dev \
  --region us-central1 \
  --project coditect-citus-prod

# Verify cluster
kubectl get nodes

# Expected output:
# NAME                                   STATUS   ROLES    AGE   VERSION
# gke-coditect-citus-dev-pool-xxxx-xxxx   Ready    <none>   5m    v1.27.x
```

## Deploy Staging/Production

Same steps as development, but:

```bash
cd environments/staging  # or production

# Use stronger passwords for production!
export TF_VAR_db_app_user_password="$(openssl rand -base64 48)"
export TF_VAR_db_readonly_user_password="$(openssl rand -base64 48)"

terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## Verify Deployment

### Check GKE Cluster

```bash
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### Check Cloud SQL

```bash
gcloud sql instances describe coditect-citus-dev

# Expected: status: RUNNABLE
```

### Check Redis

```bash
gcloud redis instances describe coditect-redis-dev --region=us-central1

# Expected: state: READY
```

### Check Network

```bash
gcloud compute networks list
gcloud compute firewall-rules list
```

## Common Next Steps

### Deploy Application to GKE

```bash
cd ../../../kubernetes
kubectl apply -k base/
```

### Connect to Cloud SQL

```bash
# Option 1: Cloud SQL Proxy
cloud_sql_proxy -instances=coditect-citus-prod:us-central1:coditect-citus-dev=tcp:5432

# Option 2: From GKE pod (using private IP)
# See outputs for private_ip
```

### Access Redis

```bash
# Get auth string from Secret Manager
gcloud secrets versions access latest --secret="redis-auth-string-dev"

# Connect from GKE pod
redis-cli -h <REDIS_HOST> -p 6379 -a <AUTH_STRING>
```

## Troubleshooting

### "Backend initialization failed"

**Solution:**
```bash
cd ../../backend
./create-backends.sh dev
cd ../environments/dev
terraform init
```

### "insufficient regional quota"

**Solution:**
```bash
# Check quotas
gcloud compute project-info describe --project=coditect-citus-prod

# Request increase: https://console.cloud.google.com/iam-admin/quotas
```

### "Error 409: Already Exists"

**Solution:** Import existing resource
```bash
terraform import module.networking.google_compute_network.vpc \
  projects/coditect-citus-prod/global/networks/coditect-vpc-dev
```

### "database password required"

**Solution:**
```bash
export TF_VAR_db_app_user_password="your-secure-password"
terraform plan
```

## Cleanup

### Destroy Single Environment

```bash
terraform destroy
```

**WARNING:** This deletes all resources! Confirm you have backups.

### Destroy All Environments

```bash
# Dev
cd environments/dev
terraform destroy

# Staging
cd ../staging
terraform destroy

# Production (use extreme caution!)
cd ../production
terraform destroy
```

## Cost Monitoring

### Check Current Costs

```bash
gcloud billing accounts list
gcloud beta billing projects describe coditect-citus-prod
```

### Estimated Costs

| Environment | Monthly Cost |
|-------------|-------------|
| Development | $300 |
| Staging | $1,200 |
| Production | $5,000 |

### Save Money in Dev

```bash
# Scale GKE to 0 nodes after hours
kubectl scale deployment --all --replicas=0 -n default

# Or destroy dev environment when not in use
terraform destroy  # in environments/dev
```

## Next Steps

1. **Deploy Kubernetes resources:** See `../../../kubernetes/README.md`
2. **Setup Citus cluster:** See `../../../citus/README.md`
3. **Configure monitoring:** See `../../../monitoring/README.md`
4. **Deploy Django application:** See backend repository

## Getting Help

- **Full Documentation:** `README.md` (same directory)
- **Module Details:** `../modules/<module-name>/README.md`
- **Environment Details:** `environments/<env>/README.md`
- **Issues:** https://github.com/coditect-ai/coditect-citus-django-infra/issues

---

**Quick Reference:**
```bash
terraform init           # Initialize
terraform plan           # Preview changes
terraform apply tfplan   # Apply changes
terraform destroy        # Delete all resources
terraform output         # View outputs
terraform state list     # List resources
```
