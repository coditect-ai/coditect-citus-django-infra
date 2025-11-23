# Redis Cluster Terraform Module

Production-ready Cloud Memorystore for Redis module with high availability, read replicas, and transit encryption for caching and session management.

## Features

- **Redis 7.2**: Latest stable version
- **High Availability**: STANDARD_HA tier with automatic failover
- **Read Replicas**: Optional read replicas (up to 5) for scaling read operations
- **Transit Encryption**: TLS encryption for data in transit
- **AUTH Enabled**: Password authentication for security
- **Private Network**: VPC-native deployment
- **Automated Maintenance**: Configurable maintenance windows
- **Memory Eviction Policies**: Configurable eviction strategies

## Usage

```hcl
module "redis" {
  source = "../../modules/redis"

  # Project Configuration
  project_id  = "coditect-citus-prod"
  environment = "production"

  # Instance Configuration
  tier           = "STANDARD_HA"
  memory_size_gb = 5
  redis_version  = "REDIS_7_2"

  # Network Configuration
  authorized_network = "projects/coditect-citus-prod/global/networks/coditect-vpc"
  connect_mode       = "DIRECT_PEERING"

  # High Availability
  location_id             = "us-central1-a"
  alternative_location_id = "us-central1-b"

  # Read Replicas (optional)
  replica_count      = 2
  read_replicas_mode = "READ_REPLICAS_ENABLED"

  # Security
  auth_enabled            = true
  transit_encryption_mode = "SERVER_AUTHENTICATION"

  # Redis Configuration
  maxmemory_policy = "allkeys-lru"
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
| environment | Environment name | `string` | n/a | yes |
| authorized_network | VPC network authorized to access Redis | `string` | n/a | yes |
| instance_name | Base name for Redis instance | `string` | `"coditect-cache"` | no |
| region | GCP region | `string` | `"us-central1"` | no |
| location_id | Zone for primary instance | `string` | `"us-central1-a"` | no |
| alternative_location_id | Zone for HA replica | `string` | `"us-central1-b"` | no |
| tier | Service tier (BASIC or STANDARD_HA) | `string` | `"STANDARD_HA"` | no |
| memory_size_gb | Memory size in GB | `number` | `5` | no |
| redis_version | Redis version | `string` | `"REDIS_7_2"` | no |
| connect_mode | Network connection mode | `string` | `"DIRECT_PEERING"` | no |
| replica_count | Number of read replicas | `number` | `0` | no |
| read_replicas_mode | Read replicas mode | `string` | `"READ_REPLICAS_DISABLED"` | no |
| auth_enabled | Enable Redis AUTH | `bool` | `true` | no |
| transit_encryption_mode | Transit encryption mode | `string` | `"SERVER_AUTHENTICATION"` | no |
| maxmemory_policy | Eviction policy | `string` | `"allkeys-lru"` | no |
| notify_keyspace_events | Keyspace notifications | `string` | `""` | no |
| additional_redis_configs | Additional Redis configs | `map(string)` | `{}` | no |
| maintenance_window_day | Maintenance day | `string` | `"SUNDAY"` | no |
| maintenance_window_hour | Maintenance hour (0-23 UTC) | `number` | `4` | no |
| maintenance_window_minute | Maintenance minute (0 or 30) | `number` | `0` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | Name of the Redis instance |
| instance_id | Full resource ID |
| host | IP address of the Redis instance |
| port | Port number |
| current_location_id | Current zone |
| persistence_iam_identity | IAM identity for persistence |
| read_endpoint | Read endpoint (if replicas enabled) |
| read_endpoint_port | Read endpoint port |
| auth_string | AUTH string (sensitive) |
| server_ca_certs | Server CA certificates (sensitive) |
| connection_string | Connection string for write operations (sensitive) |
| connection_string_readonly | Connection string for read operations (sensitive) |
| region | Region |
| tier | Service tier |
| memory_size_gb | Memory size |
| redis_version | Redis version |

## Resources Created

- `google_redis_instance.cache` - Cloud Memorystore Redis instance

## Service Tiers

### BASIC
- Single-zone deployment
- No automatic failover
- Lower cost
- Suitable for development/testing

### STANDARD_HA (Recommended for Production)
- Multi-zone deployment
- Automatic failover
- Higher availability (99.9% SLA)
- Optional read replicas

## Read Replicas

Read replicas allow scaling read operations:
- Up to 5 replicas per instance
- Asynchronous replication from primary
- Separate read endpoint
- Automatic load balancing across replicas

**Use cases:**
- High read throughput requirements
- Geographic distribution of read traffic
- Isolating analytics workloads

## Security

### Authentication
- **AUTH Enabled**: Requires password for all operations
- Store AUTH string in Secret Manager
- Rotate AUTH string regularly

### Transit Encryption
- **SERVER_AUTHENTICATION**: TLS encryption for all connections
- Provides server certificate for client validation
- Slightly higher latency (~1-2ms) vs unencrypted

### Network Security
- Private IP only (no public endpoint)
- VPC-native deployment
- Accessible only from authorized VPC

## Memory Eviction Policies

| Policy | Behavior |
|--------|----------|
| `noeviction` | Return errors when memory limit reached |
| `allkeys-lru` | Remove least recently used keys (recommended) |
| `volatile-lru` | Remove LRU keys with expiration set |
| `allkeys-random` | Remove random keys |
| `volatile-random` | Remove random keys with expiration |
| `volatile-ttl` | Remove keys with shortest TTL |
| `allkeys-lfu` | Remove least frequently used keys |
| `volatile-lfu` | Remove LFU keys with expiration |

**Recommendation:**
- **Caching**: `allkeys-lru` (removes old cached data automatically)
- **Session Store**: `volatile-lru` (only evicts expired sessions)
- **Queue**: `noeviction` (fail instead of losing queue items)

## Connection Examples

### Python (Django)

```python
# settings.py
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': f'rediss://:{os.environ["REDIS_AUTH"]}@{os.environ["REDIS_HOST"]}:{os.environ["REDIS_PORT"]}/0',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {
                'ssl_cert_reqs': 'required',
            },
        }
    }
}

# Session backend
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```

### Python (redis-py)

```python
import redis
import os

# Write client (primary)
client = redis.Redis(
    host=os.environ['REDIS_HOST'],
    port=int(os.environ['REDIS_PORT']),
    password=os.environ['REDIS_AUTH'],
    ssl=True,
    ssl_cert_reqs='required',
)

# Read client (replica endpoint)
if os.environ.get('REDIS_READ_ENDPOINT'):
    read_client = redis.Redis(
        host=os.environ['REDIS_READ_ENDPOINT'],
        port=int(os.environ['REDIS_READ_PORT']),
        password=os.environ['REDIS_AUTH'],
        ssl=True,
        ssl_cert_reqs='required',
    )
```

### Node.js (ioredis)

```javascript
const Redis = require('ioredis');

const client = new Redis({
  host: process.env.REDIS_HOST,
  port: process.env.REDIS_PORT,
  password: process.env.REDIS_AUTH,
  tls: {
    rejectUnauthorized: true,
  },
});
```

## Monitoring

Access metrics in Cloud Console:
- Memory usage
- CPU utilization
- Cache hit ratio
- Network throughput
- Connected clients

Set up alerts for:
- Memory usage > 80%
- Cache hit ratio < 80%
- CPU > 80%
- Connected clients approaching max

## Performance Tuning

### Memory Sizing

| Use Case | Memory Size | Notes |
|----------|-------------|-------|
| Session Store | 1-5 GB | Based on concurrent users |
| Caching Layer | 5-20 GB | Based on dataset size |
| Queue/Pub-Sub | 1-10 GB | Based on message volume |
| Full Dataset | 50-300 GB | Store entire dataset in memory |

**Calculation for Sessions:**
```
Memory = (Average Session Size) × (Peak Concurrent Users) × 1.3
Example: 10 KB × 50,000 users × 1.3 = 650 MB (~1 GB)
```

### Connection Pool Sizing

```python
# Django recommendation
'MAX_CONNECTIONS': min(50, (CPU_CORES * 2) + 1)

# Redis max_clients default: 10,000
# Set CONNECTION_POOL_KWARGS based on your application servers
```

## High Availability

**STANDARD_HA SLA:** 99.9% uptime
- **RPO**: ~60 seconds (asynchronous replication)
- **RTO**: ~2-3 minutes (automatic failover)

**Failover process:**
1. Primary instance becomes unhealthy
2. GCP promotes replica in alternative zone
3. DNS updates to new primary IP
4. Applications reconnect automatically (with retry logic)

## Cost Optimization

For non-production environments:
- Use `BASIC` tier (50% cheaper)
- Reduce `memory_size_gb` to minimum needed
- Disable read replicas
- Disable transit encryption (development only)

**Production cost example (STANDARD_HA, 5GB, us-central1):**
- Instance: ~$175/month
- Read Replicas (2x): +$175/month
- Total: ~$350/month

## Backup and Recovery

**Data Persistence:**
- Redis data is volatile (in-memory only)
- For critical data, use RDB snapshots or AOF persistence
- Or use Redis as cache with persistent storage (PostgreSQL) as source of truth

**Disaster Recovery:**
- For session data: Acceptable to lose on instance failure
- For cache data: Can be rebuilt from source database
- For critical data: Use persistent storage (Cloud SQL)

## Migration

### From Self-Managed Redis

1. Set up Cloud Memorystore instance
2. Use `redis-cli --rdb` to export data
3. Import using `redis-cli --pipe`
4. Update application configuration
5. Test thoroughly before switching traffic

### From Different Cloud Provider

1. Create Cloud Memorystore instance
2. Use Redis replication to sync data
3. Monitor replication lag
4. Switch application traffic
5. Decommission old instance

## Examples

See `examples/` directory for:
- Development instance (BASIC tier)
- Staging instance (STANDARD_HA)
- Production instance with read replicas
- Multi-region deployment

## Related Modules

- [networking](../networking/) - VPC configuration
- [secrets](../secrets/) - Secret Manager for AUTH string
- [gke](../gke/) - GKE cluster for application

## Support

For issues or questions, contact the infrastructure team or see [CONTRIBUTING.md](../../../CONTRIBUTING.md).

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
