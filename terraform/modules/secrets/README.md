# Secret Manager Terraform Module

Production-ready Secret Manager module for centralized secrets storage with automatic replication, rotation policies, and IAM-based access control.

## Features

- **Automatic Replication**: Secrets replicated across all GCP regions
- **Rotation Policies**: Configurable rotation periods (90-365 days)
- **IAM Integration**: Fine-grained access control per secret
- **Version History**: Keeps last 10 versions automatically
- **Audit Logging**: All access logged for compliance
- **Lifecycle Management**: Prevents accidental deletion

## Default Secrets

The module creates these secrets by default:

| Secret | Description | Rotation Period |
|--------|-------------|-----------------|
| `database-password` | PostgreSQL application user password | 90 days |
| `database-readonly-password` | PostgreSQL read-only user password | 90 days |
| `redis-auth-string` | Redis AUTH authentication string | 90 days |
| `django-secret-key` | Django SECRET_KEY for signing | 180 days |
| `stripe-api-key` | Stripe API key for payments | 90 days |
| `stripe-webhook-secret` | Stripe webhook signature secret | 90 days |
| `sendgrid-api-key` | SendGrid API key for email | 90 days |
| `jwt-private-key` | JWT signing private key (RSA) | 365 days |
| `jwt-public-key` | JWT verification public key (RSA) | 365 days |

## Usage

```hcl
module "secrets" {
  source = "../../modules/secrets"

  # Project Configuration
  project_id  = "coditect-citus-prod"
  environment = "production"

  # Service Account Access
  app_runtime_service_account = "app-runtime@coditect-citus-prod.iam.gserviceaccount.com"
  deployment_service_account  = "deployment@coditect-citus-prod.iam.gserviceaccount.com"

  # Admin Access
  admin_members = [
    "user:admin@example.com",
    "group:security-team@example.com"
  ]

  # Additional Secrets (beyond defaults)
  additional_secrets = {
    "github-webhook-secret" = {
      description     = "GitHub webhook secret for CI/CD"
      rotation_period = "7776000s" # 90 days
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0, < 7.0 |

## Populating Secrets

Secrets are created empty. Populate them after creation:

### Using gcloud

```bash
# Generate and store database password
echo -n "$(openssl rand -base64 32)" | \
  gcloud secrets versions add production-database-password \
    --data-file=-

# Store existing value
echo -n "sk_live_ABC123..." | \
  gcloud secrets versions add production-stripe-api-key \
    --data-file=-

# Generate Django secret key
echo -n "$(python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')" | \
  gcloud secrets versions add production-django-secret-key \
    --data-file=-
```

### Using Terraform (from file)

```hcl
# Not recommended for production - use gcloud instead
resource "google_secret_manager_secret_version" "db_password" {
  secret      = module.secrets.database_password_secret
  secret_data = file("${path.module}/secrets/db-password.txt")
}
```

## Accessing Secrets

### From GKE with Workload Identity

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  serviceAccountName: app-runtime
  containers:
  - name: app
    image: gcr.io/project/app:latest
    env:
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secrets
          key: database-password
---
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: app-secrets
spec:
  provider: gcp
  parameters:
    secrets: |
      - resourceName: "projects/PROJECT_ID/secrets/production-database-password/versions/latest"
        path: "database-password"
```

### From Python Application

```python
from google.cloud import secretmanager

def get_secret(project_id, secret_id, version="latest"):
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/{version}"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

# Usage
db_password = get_secret("coditect-citus-prod", "production-database-password")
```

### From Django Settings

```python
# settings.py
import os
from google.cloud import secretmanager

def get_secret(secret_id):
    if os.environ.get("LOCAL_DEV"):
        # Use local .env file in development
        return os.environ[secret_id]

    client = secretmanager.SecretManagerServiceClient()
    project_id = os.environ["GCP_PROJECT_ID"]
    name = f"projects/{project_id}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")

# Use secrets
SECRET_KEY = get_secret("production-django-secret-key")
DATABASES = {
    'default': {
        'PASSWORD': get_secret("production-database-password"),
    }
}
```

## IAM Roles

| Role | Permission | Use Case |
|------|------------|----------|
| `secretAccessor` | Read secret values | Application runtime |
| `secretVersionAdder` | Add new versions | Deployment automation |
| `secretViewer` | View metadata only (not values) | Human administrators |
| `secretVersionManager` | Manage versions | Secret rotation automation |

## Secret Rotation

Secrets have automatic rotation reminders but require manual rotation:

### Rotation Workflow

1. **Reminder Triggered**: After rotation period expires
2. **Generate New Value**: Create new password/key
3. **Add New Version**: `gcloud secrets versions add <SECRET> --data-file=-`
4. **Update Applications**: Deploy with new secret
5. **Disable Old Version**: After grace period

### Rotation Script

```bash
#!/bin/bash
# rotate-database-password.sh

NEW_PASSWORD=$(openssl rand -base64 32)

# Add new version to Secret Manager
echo -n "$NEW_PASSWORD" | \
  gcloud secrets versions add production-database-password --data-file=-

# Update Cloud SQL user
gcloud sql users set-password app_user \
  --instance=coditect-citus-production \
  --password="$NEW_PASSWORD"

# Trigger rolling restart of application pods
kubectl rollout restart deployment/app -n production
```

## Security Best Practices

1. **Never Commit Secrets**: Don't store secrets in Git
2. **Use Secret Manager**: Always use Secret Manager in GCP
3. **Least Privilege**: Grant only required IAM roles
4. **Regular Rotation**: Rotate critical secrets every 90 days
5. **Audit Access**: Review Secret Manager audit logs
6. **Separate Environments**: Use different secrets per environment
7. **Version Control**: Keep 10 versions for rollback

## Monitoring

Set up alerts for:
- Secret access failures (potential unauthorized access)
- Secret rotation due (manual intervention required)
- Unusual access patterns (security incident)

## Examples

See `examples/` directory for:
- Basic secret configuration
- Integration with GKE Workload Identity
- Secret rotation automation
- Multi-environment setup

## Related Modules

- [gke](../gke/) - GKE cluster with Workload Identity
- [cloudsql](../cloudsql/) - Database using secrets
- [redis](../redis/) - Redis using AUTH secret

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
