# Cloud SQL PostgreSQL Terraform Module

Production-ready Cloud SQL PostgreSQL module optimized for Citus distributed database deployment with high availability, automated backups, and point-in-time recovery.

## Features

- **PostgreSQL 16**: Latest stable version with Citus compatibility
- **High Availability**: Regional deployment with automatic failover
- **Automated Backups**: Daily backups with 7-day retention and PITR
- **Private Networking**: VPC-native deployment with optional public IP
- **SSL Required**: Encrypted connections enforced
- **Citus Configuration**: Pre-configured database flags for Citus extension
- **Read Replicas**: Optional read replicas for scaling read operations
- **Query Insights**: Performance monitoring and query analysis
- **Auto-Resize**: Automatic disk scaling up to configurable limit

## Usage

```hcl
module "cloudsql" {
  source = "../../modules/cloudsql"

  # Project Configuration
  project_id  = "coditect-citus-prod"
  environment = "production"

  # Instance Configuration
  tier              = "db-custom-4-16384" # 4 vCPUs, 16GB RAM
  availability_type = "REGIONAL"
  disk_size_gb      = 100

  # Network Configuration
  private_network = "projects/coditect-citus-prod/global/networks/coditect-vpc"
  enable_public_ip = false

  # Database Users
  app_user_name     = "coditect_app"
  app_user_password = data.google_secret_manager_secret_version.db_password.secret_data

  create_readonly_user    = true
  readonly_user_name      = "readonly"
  readonly_user_password  = data.google_secret_manager_secret_version.readonly_password.secret_data

  # Backup Configuration
  enable_point_in_time_recovery = true
  backup_retention_count        = 7

  # Read Replica (optional)
  create_read_replica = false

  # Citus Tuning
  max_connections      = "200"
  shared_buffers       = "4096MB"
  effective_cache_size = "12GB"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0, < 7.0 |

## Providers

| Name | Version |
|------|---------|
| google | >= 5.0, < 7.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | `string` | n/a | yes |
| environment | Environment name (dev, staging, production) | `string` | n/a | yes |
| private_network | VPC network for private IP | `string` | n/a | yes |
| app_user_password | Application database user password | `string` | n/a | yes |
| instance_name | Base name for Cloud SQL instance | `string` | `"coditect-citus"` | no |
| region | GCP region for Cloud SQL instance | `string` | `"us-central1"` | no |
| database_version | PostgreSQL version | `string` | `"POSTGRES_16"` | no |
| tier | Machine tier for Cloud SQL instance | `string` | `"db-custom-4-16384"` | no |
| availability_type | Availability type (ZONAL or REGIONAL) | `string` | `"REGIONAL"` | no |
| disk_size_gb | Initial disk size in GB | `number` | `100` | no |
| disk_autoresize_limit | Maximum disk size in GB for autoresize | `number` | `1000` | no |
| deletion_protection | Enable deletion protection | `bool` | `true` | no |
| enable_public_ip | Enable public IP address | `bool` | `false` | no |
| authorized_networks | List of authorized networks for public IP | `list(object)` | `[]` | no |
| database_name | Name of the default database | `string` | `"coditect"` | no |
| app_user_name | Application database user name | `string` | `"app_user"` | no |
| create_readonly_user | Create read-only user for analytics | `bool` | `true` | no |
| readonly_user_name | Read-only database user name | `string` | `"readonly_user"` | no |
| readonly_user_password | Read-only database user password | `string` | `""` | no |
| backup_start_time | Start time for automated backups (HH:MM UTC) | `string` | `"03:00"` | no |
| enable_point_in_time_recovery | Enable point-in-time recovery | `bool` | `true` | no |
| transaction_log_retention_days | Transaction log retention days for PITR | `number` | `7` | no |
| backup_retention_count | Number of automated backups to retain | `number` | `7` | no |
| maintenance_window_day | Day of week for maintenance (1-7) | `number` | `7` | no |
| maintenance_window_hour | Hour of day for maintenance window (0-23, UTC) | `number` | `3` | no |
| maintenance_update_track | Maintenance update track (stable or canary) | `string` | `"stable"` | no |
| max_connections | Maximum number of concurrent connections | `string` | `"200"` | no |
| shared_buffers | Shared buffer size | `string` | `"4096MB"` | no |
| effective_cache_size | Effective cache size | `string` | `"12GB"` | no |
| maintenance_work_mem | Maintenance work memory | `string` | `"1GB"` | no |
| work_mem | Work memory per operation | `string` | `"16MB"` | no |
| additional_database_flags | Additional database flags to set | `map(string)` | `{}` | no |
| enable_query_insights | Enable query insights | `bool` | `true` | no |
| create_read_replica | Create read replica | `bool` | `false` | no |
| replica_region | Region for read replica | `string` | `""` | no |
| replica_tier | Machine tier for read replica | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | Name of the Cloud SQL instance |
| instance_connection_name | Connection name for Cloud SQL Proxy |
| instance_self_link | Self link of the Cloud SQL instance |
| instance_service_account_email | Service account email for the instance |
| private_ip_address | Private IP address of the instance |
| public_ip_address | Public IP address (if enabled) |
| database_version | PostgreSQL version |
| database_name | Name of the default database |
| app_user_name | Application database user name |
| readonly_user_name | Read-only database user name |
| replica_instance_name | Read replica instance name |
| replica_connection_name | Read replica connection name |
| replica_private_ip_address | Read replica private IP |
| connection_string_private | Connection string using private IP (sensitive) |
| connection_string_proxy | Connection string using Cloud SQL Proxy (sensitive) |

## Resources Created

- `google_sql_database_instance.postgres` - Primary Cloud SQL instance
- `google_sql_database.default` - Default application database
- `google_sql_database.citus` - Citus extension database (if separate)
- `google_sql_user.app_user` - Application database user
- `google_sql_user.readonly_user` - Read-only user (optional)
- `google_sql_database_instance.replica` - Read replica (optional)

## Citus Configuration

The module pre-configures database flags for optimal Citus performance:

```hcl
shared_preload_libraries = "citus"
max_connections = "200"
shared_buffers = "4096MB"
effective_cache_size = "12GB"
```

### Enabling Citus Extension

After the instance is created, enable Citus:

```sql
-- Connect to the database
\c coditect

-- Enable Citus extension
CREATE EXTENSION IF NOT EXISTS citus;

-- Verify installation
SELECT * FROM citus_version();
```

## High Availability

**Regional Availability:**
- Automatic failover to standby instance in different zone
- Synchronous replication for zero data loss
- RPO (Recovery Point Objective): 0 seconds
- RTO (Recovery Time Objective): ~60 seconds

**Read Replicas:**
- Asynchronous replication
- Scale read operations horizontally
- Can be in different region for geographic distribution

## Backup and Recovery

**Automated Backups:**
- Daily backups at configured time (default: 03:00 UTC)
- Retention: 7 backups (configurable)
- Stored in multi-region GCS bucket

**Point-in-Time Recovery (PITR):**
- Restore to any point within retention window (default: 7 days)
- Transaction log retention configurable (1-35 days)

### Restore Example

```bash
# Create new instance from backup
gcloud sql backups restore <BACKUP_ID> \
  --backup-instance=<SOURCE_INSTANCE> \
  --target-instance=<NEW_INSTANCE>

# Or restore to point in time
gcloud sql backups restore <BACKUP_ID> \
  --backup-instance=<SOURCE_INSTANCE> \
  --target-instance=<NEW_INSTANCE> \
  --point-in-time='2025-01-15T10:30:00.000Z'
```

## Connection Methods

### 1. Private IP (Recommended for GKE)

```python
# Django settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': '<PRIVATE_IP>',
        'PORT': '5432',
        'NAME': 'coditect',
        'USER': 'coditect_app',
        'PASSWORD': os.environ['DB_PASSWORD'],
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}
```

### 2. Cloud SQL Proxy (Recommended for local development)

```bash
# Start Cloud SQL Proxy
cloud_sql_proxy -instances=<CONNECTION_NAME>=tcp:5432

# Django settings.py
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'HOST': 'localhost',
        'PORT': '5432',
        'NAME': 'coditect',
        'USER': 'coditect_app',
        'PASSWORD': os.environ['DB_PASSWORD'],
    }
}
```

### 3. Unix Socket (For GKE with Cloud SQL Proxy sidecar)

```yaml
# Kubernetes deployment
containers:
- name: app
  env:
  - name: DB_HOST
    value: "/cloudsql/<CONNECTION_NAME>"
- name: cloud-sql-proxy
  image: gcr.io/cloud-sql-connectors/cloud-sql-proxy:latest
  args:
  - "--structured-logs"
  - "--port=5432"
  - "<CONNECTION_NAME>"
```

## Security Considerations

1. **SSL Required**: All connections must use SSL/TLS
2. **Private IP**: Deploy in VPC without public IP for production
3. **IAM Authentication**: Consider using Cloud SQL IAM authentication
4. **Password Management**: Store passwords in Secret Manager
5. **Least Privilege**: Grant minimal permissions to database users
6. **Query Insights**: Monitor for suspicious queries

## Performance Tuning

### Machine Tier Recommendations

| Environment | Tier | vCPUs | RAM | Concurrent Users |
|-------------|------|-------|-----|------------------|
| Development | db-custom-2-8192 | 2 | 8GB | <100 |
| Staging | db-custom-4-16384 | 4 | 16GB | 100-1000 |
| Production | db-custom-8-32768 | 8 | 32GB | 1000-10000 |
| Production (High) | db-custom-16-65536 | 16 | 64GB | >10000 |

### Database Flag Tuning

Based on machine tier, adjust:

```hcl
# For db-custom-8-32768 (8 vCPUs, 32GB RAM)
shared_buffers = "8192MB"  # 25% of RAM
effective_cache_size = "24GB"  # 75% of RAM
work_mem = "32MB"
maintenance_work_mem = "2GB"
max_connections = "300"
```

## Monitoring

Access performance metrics in Cloud Console:
- CPU utilization
- Memory utilization
- Disk I/O
- Connection count
- Query performance (Query Insights)

Set up alerts for:
- CPU > 80%
- Memory > 85%
- Disk > 80%
- Connection count approaching max

## Cost Optimization

For non-production environments:
- Use `ZONAL` availability (cheaper than `REGIONAL`)
- Reduce `tier` (smaller machine type)
- Reduce `disk_size_gb` (minimum 10GB)
- Reduce `backup_retention_count` to 3
- Disable read replicas

## Migration

### From Existing PostgreSQL

1. Export schema and data using `pg_dump`
2. Create Cloud SQL instance using this module
3. Import schema and data using `pg_restore` or `psql`
4. Enable Citus extension
5. Migrate to distributed tables (if using Citus)

### From Cloud SQL (Different Instance)

```bash
# Create replica of source instance
gcloud sql instances create-replica <REPLICA_NAME> \
  --master-instance=<SOURCE_INSTANCE>

# Promote replica to standalone instance
gcloud sql instances promote-replica <REPLICA_NAME>
```

## Examples

See `examples/` directory for:
- Development instance configuration
- Staging instance configuration
- Production instance with read replica
- Multi-region deployment

## Related Modules

- [networking](../networking/) - VPC configuration for private IP
- [secrets](../secrets/) - Secret Manager for passwords
- [gke](../gke/) - GKE cluster for application deployment

## Support

For issues or questions, contact the infrastructure team or see [CONTRIBUTING.md](../../../CONTRIBUTING.md).

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
