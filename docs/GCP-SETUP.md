# GCP Setup Guide

**CODITECT Infrastructure on Google Cloud Platform**

**Last Updated:** November 23, 2025

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [GCP Project Setup](#gcp-project-setup)
3. [Enable APIs](#enable-apis)
4. [Service Accounts](#service-accounts)
5. [Networking](#networking)
6. [GKE Cluster](#gke-cluster)
7. [Cloud SQL](#cloud-sql)
8. [Secrets Management](#secrets-management)
9. [Billing & Cost Management](#billing--cost-management)

---

## Prerequisites

### Required Tools

```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Initialize gcloud
gcloud init

# Install kubectl
gcloud components install kubectl

# Install Terraform
brew install terraform  # macOS
# OR
wget https://releases.hashicorp.com/opentofu/1.6.0/terraform_1.6.0_linux_amd64.zip
```

### GCP Account Requirements

- **Organization Account:** (recommended for production)
- **Billing Account:** Active billing account required
- **IAM Roles:** Project Owner or Editor
- **Quota:** Sufficient quota for GKE, Cloud SQL

---

## GCP Project Setup

### Create Projects

```bash
# Set organization ID (if applicable)
export ORG_ID=$(gcloud organizations list --format="value(name)")

# Create development project
gcloud projects create coditect-dev \
    --organization=$ORG_ID \
    --name="CODITECT Development" \
    --set-as-default

# Create staging project
gcloud projects create coditect-staging \
    --organization=$ORG_ID \
    --name="CODITECT Staging"

# Create production project
gcloud projects create coditect-production \
    --organization=$ORG_ID \
    --name="CODITECT Production"
```

### Link Billing Account

```bash
# List billing accounts
gcloud billing accounts list

# Set billing account ID
export BILLING_ACCOUNT_ID=XXXXXX-XXXXXX-XXXXXX

# Link projects to billing
gcloud billing projects link coditect-dev \
    --billing-account=$BILLING_ACCOUNT_ID

gcloud billing projects link coditect-staging \
    --billing-account=$BILLING_ACCOUNT_ID

gcloud billing projects link coditect-production \
    --billing-account=$BILLING_ACCOUNT_ID
```

---

## Enable APIs

### Required APIs

```bash
# Set project
gcloud config set project coditect-dev

# Enable all required APIs
gcloud services enable \
    compute.googleapis.com \
    container.googleapis.com \
    sqladmin.googleapis.com \
    storage.googleapis.com \
    secretmanager.googleapis.com \
    cloudresourcemanager.googleapis.com \
    iam.googleapis.com \
    iamcredentials.googleapis.com \
    cloudbuild.googleapis.com \
    artifactregistry.googleapis.com \
    monitoring.googleapis.com \
    logging.googleapis.com \
    cloudtrace.googleapis.com

# Verify APIs enabled
gcloud services list --enabled
```

---

## Service Accounts

### Create Service Accounts

```bash
# Terraform service account
gcloud iam service-accounts create terraform-sa \
    --description="Terraform infrastructure provisioning" \
    --display-name="Terraform SA"

# GKE service account
gcloud iam service-accounts create gke-sa \
    --description="GKE node service account" \
    --display-name="GKE SA"

# Cloud SQL service account
gcloud iam service-accounts create cloudsql-sa \
    --description="Cloud SQL client connections" \
    --display-name="Cloud SQL SA"

# Django application service account
gcloud iam service-accounts create django-app-sa \
    --description="Django application runtime" \
    --display-name="Django App SA"
```

### Assign IAM Roles

```bash
export PROJECT_ID=coditect-dev

# Terraform SA - broad permissions for infrastructure
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/iam.securityAdmin"

# GKE SA - minimal permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:gke-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"

# Cloud SQL SA
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:cloudsql-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client"

# Django App SA
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/storage.objectViewer"
```

### Download Service Account Keys

```bash
# Terraform SA key (for local development)
gcloud iam service-accounts keys create terraform-key.json \
    --iam-account=terraform-sa@${PROJECT_ID}.iam.gserviceaccount.com

# IMPORTANT: Store securely and never commit to git
mv terraform-key.json ~/.config/gcloud/terraform-key.json
chmod 600 ~/.config/gcloud/terraform-key.json

# Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/terraform-key.json
```

---

## Networking

### Create VPC Network

```bash
# Create VPC
gcloud compute networks create coditect-vpc \
    --subnet-mode=custom \
    --bgp-routing-mode=regional

# Create GKE subnet
gcloud compute networks subnets create gke-subnet \
    --network=coditect-vpc \
    --region=us-central1 \
    --range=10.0.0.0/20 \
    --enable-private-ip-google-access \
    --secondary-range pods=10.1.0.0/16 \
    --secondary-range services=10.2.0.0/16

# Create database subnet
gcloud compute networks subnets create db-subnet \
    --network=coditect-vpc \
    --region=us-central1 \
    --range=10.0.16.0/24 \
    --enable-private-ip-google-access

# Create Redis subnet
gcloud compute networks subnets create redis-subnet \
    --network=coditect-vpc \
    --region=us-central1 \
    --range=10.0.17.0/24 \
    --enable-private-ip-google-access
```

### Configure Firewall Rules

```bash
# Allow internal communication
gcloud compute firewall-rules create allow-internal \
    --network=coditect-vpc \
    --allow=tcp,udp,icmp \
    --source-ranges=10.0.0.0/16

# Allow HTTPS from internet
gcloud compute firewall-rules create allow-https \
    --network=coditect-vpc \
    --allow=tcp:443 \
    --source-ranges=0.0.0.0/0 \
    --target-tags=https-server

# Allow SSH from Cloud Identity-Aware Proxy
gcloud compute firewall-rules create allow-ssh-iap \
    --network=coditect-vpc \
    --allow=tcp:22 \
    --source-ranges=35.235.240.0/20
```

### Create NAT Gateway

```bash
# Create Cloud Router
gcloud compute routers create nat-router \
    --network=coditect-vpc \
    --region=us-central1

# Create NAT configuration
gcloud compute routers nats create nat-config \
    --router=nat-router \
    --region=us-central1 \
    --auto-allocate-nat-external-ips \
    --nat-all-subnet-ip-ranges
```

---

## GKE Cluster

### Create GKE Autopilot Cluster

```bash
# Create cluster
gcloud container clusters create-auto coditect-gke \
    --region=us-central1 \
    --network=coditect-vpc \
    --subnetwork=gke-subnet \
    --cluster-secondary-range-name=pods \
    --services-secondary-range-name=services \
    --enable-private-nodes \
    --enable-private-endpoint \
    --master-ipv4-cidr=172.16.0.0/28 \
    --no-enable-master-authorized-networks \
    --enable-ip-alias \
    --enable-autorepair \
    --enable-autoupgrade \
    --service-account=gke-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --workload-pool=${PROJECT_ID}.svc.id.goog \
    --release-channel=regular

# Get credentials
gcloud container clusters get-credentials coditect-gke \
    --region=us-central1

# Verify cluster
kubectl get nodes
```

### Configure Workload Identity

```bash
# Create Kubernetes service account
kubectl create serviceaccount django-ksa -n default

# Bind to GCP service account
gcloud iam service-accounts add-iam-policy-binding \
    django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com \
    --member="serviceAccount:${PROJECT_ID}.svc.id.goog[default/django-ksa]" \
    --role="roles/iam.workloadIdentityUser"

# Annotate Kubernetes service account
kubectl annotate serviceaccount django-ksa \
    iam.gke.io/gcp-service-account=django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

---

## Cloud SQL

### Create PostgreSQL Instance

```bash
# Create instance
gcloud sql instances create coditect-postgres \
    --database-version=POSTGRES_15 \
    --tier=db-custom-4-16384 \
    --region=us-central1 \
    --network=projects/${PROJECT_ID}/global/networks/coditect-vpc \
    --no-assign-ip \
    --enable-bin-log \
    --backup-start-time=03:00 \
    --maintenance-window-day=SUN \
    --maintenance-window-hour=04 \
    --storage-type=SSD \
    --storage-size=100GB \
    --storage-auto-increase \
    --availability-type=REGIONAL

# Create database
gcloud sql databases create coditect_dev \
    --instance=coditect-postgres

# Create user
gcloud sql users create django \
    --instance=coditect-postgres \
    --password=<SECURE_PASSWORD>
```

### Setup Cloud SQL Proxy

```bash
# Install Cloud SQL Proxy
curl -o cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.darwin.amd64
chmod +x cloud_sql_proxy

# Get instance connection name
gcloud sql instances describe coditect-postgres --format="value(connectionName)"

# Run proxy
./cloud_sql_proxy -instances=${PROJECT_ID}:us-central1:coditect-postgres=tcp:5432
```

---

## Secrets Management

### Create Secrets

```bash
# Django secret key
echo -n "$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" | \
gcloud secrets create django-secret-key --data-file=-

# Database password
echo -n "SECURE_DATABASE_PASSWORD" | \
gcloud secrets create db-password --data-file=-

# Stripe API key
echo -n "sk_live_YOUR_STRIPE_KEY" | \
gcloud secrets create stripe-api-key --data-file=-

# Grant access to Django app SA
for secret in django-secret-key db-password stripe-api-key; do
  gcloud secrets add-iam-policy-binding $secret \
      --member="serviceAccount:django-app-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
      --role="roles/secretmanager.secretAccessor"
done
```

---

## Billing & Cost Management

### Set Budget Alerts

```bash
# Create budget (example: $500/month for dev)
gcloud billing budgets create \
    --billing-account=$BILLING_ACCOUNT_ID \
    --display-name="CODITECT Dev Monthly Budget" \
    --budget-amount=500USD \
    --threshold-rule=percent=50 \
    --threshold-rule=percent=90 \
    --threshold-rule=percent=100
```

### Cost Optimization Tips

**Development Environment:**
- Use preemptible VMs where possible
- Scale down resources outside business hours
- Use GKE Autopilot (pay per pod)
- Enable auto-scaling with lower limits

**Monitoring:**
- Enable cost allocation labels
- Review cost breakdown weekly
- Set up alerts for unexpected spikes

---

## Verification Checklist

After completing setup, verify:

- [ ] All projects created (dev, staging, production)
- [ ] Billing accounts linked
- [ ] Required APIs enabled
- [ ] Service accounts created with proper permissions
- [ ] VPC network and subnets configured
- [ ] Firewall rules in place
- [ ] GKE cluster operational
- [ ] Cloud SQL instance running
- [ ] Secrets created and accessible
- [ ] Budget alerts configured
- [ ] kubectl configured and working
- [ ] Cloud SQL Proxy connection successful

---

## Next Steps

1. **Run Terraform:** Initialize infrastructure as code
   ```bash
   cd opentofu/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

2. **Deploy Application:** Deploy Django to GKE
   ```bash
   kubectl apply -k kubernetes/base
   kubectl apply -k kubernetes/services
   ```

3. **Configure Monitoring:** Setup Prometheus and Grafana
   ```bash
   kubectl apply -k kubernetes/monitoring
   ```

---

## Troubleshooting

### Issue: API not enabled

```bash
# List all services
gcloud services list --available

# Enable specific service
gcloud services enable SERVICE_NAME
```

### Issue: Insufficient quota

```bash
# Check quota
gcloud compute project-info describe --project=$PROJECT_ID

# Request quota increase via GCP Console
# Compute Engine → Quotas → Select quota → Request increase
```

### Issue: Permission denied

```bash
# Check current permissions
gcloud projects get-iam-policy $PROJECT_ID

# Add missing role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="user:your-email@example.com" \
    --role="roles/REQUIRED_ROLE"
```

---

## Additional Resources

- [GCP Documentation](https://cloud.google.com/docs)
- [GKE Best Practices](https://cloud.google.com/kubernetes-engine/docs/best-practices)
- [Cloud SQL Best Practices](https://cloud.google.com/sql/docs/postgres/best-practices)
- [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

---

**Document Owner:** CODITECT Infrastructure Team
**Review Cycle:** Quarterly
**Next Review:** February 2026
