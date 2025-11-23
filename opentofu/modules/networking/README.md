# VPC Networking Terraform Module

Production-ready VPC networking module with custom subnets, Cloud Router, Cloud NAT, and VPC peering for private service connections.

## Features

- **Custom VPC**: Non-default network with regional routing
- **Private Google Access**: Nodes without public IPs can access Google APIs
- **Secondary IP Ranges**: Dedicated ranges for GKE pods and services
- **Cloud NAT**: Egress connectivity for private nodes
- **VPC Peering**: Private connection to Cloud SQL and other services
- **Flow Logs**: Network traffic monitoring and security analysis
- **Private DNS**: Optional private DNS zone for internal resolution

## Usage

```hcl
module "networking" {
  source = "../../modules/networking"

  # Project Configuration
  project_id  = "coditect-citus-prod"
  environment = "production"
  region      = "us-central1"

  # Network Configuration
  network_name = "coditect-vpc"

  # Subnet CIDR Ranges
  primary_subnet_cidr   = "10.0.0.0/20"    # 4,096 IPs for nodes
  pods_secondary_cidr   = "10.4.0.0/14"    # 262,144 IPs for pods
  services_secondary_cidr = "10.8.0.0/20"  # 4,096 IPs for services

  # Cloud NAT
  enable_nat_logging = true
  nat_log_filter     = "ERRORS_ONLY"

  # Private DNS
  create_private_dns_zone = true
  private_dns_domain      = "coditect.internal."
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0, < 7.0 |

## IP Address Planning

### Primary Subnet (10.0.0.0/20 - 4,096 IPs)
- GKE nodes: ~60 nodes max (with overhead)
- Load balancers: Internal LBs
- Cloud SQL: Private IP connections

### Pods Range (10.4.0.0/14 - 262,144 IPs)
- Calculation: 110 pods/node × 2,000 nodes = 220,000 pods
- Provides headroom for cluster growth

### Services Range (10.8.0.0/20 - 4,096 IPs)
- Kubernetes Services (ClusterIP, LoadBalancer)
- Each service consumes 1 IP
- 4,096 services is typically sufficient

## Cloud NAT

Cloud NAT provides egress connectivity for private GKE nodes:

**Benefits:**
- Nodes can pull container images from external registries
- Nodes can access external APIs (Stripe, SendGrid, etc.)
- No public IPs on nodes (enhanced security)
- Centralized egress IP for whitelisting

**Configuration:**
- Auto-allocated IP addresses (default)
- Dynamic port allocation enabled
- Logging for errors and troubleshooting

## VPC Peering

VPC peering for private services (Cloud SQL, Redis):

**Private Service Access:**
- Allocated range: /16 (65,536 IPs)
- Used by Cloud SQL, Redis, and other managed services
- No public IPs required
- Low latency, high throughput

## Flow Logs

Flow logs for security monitoring:

**Default Configuration:**
- Interval: 5 seconds
- Sampling: 50%
- Metadata: All metadata included

**Use Cases:**
- Network troubleshooting
- Security analysis
- Compliance auditing
- Cost attribution

## Examples

See [examples/](../../examples/) for complete usage examples.

## Related Modules

- [gke](../gke/) - GKE cluster deployment
- [cloudsql](../cloudsql/) - Cloud SQL with private IP
- [redis](../redis/) - Redis with VPC peering
- [firewall](../firewall/) - Firewall rules

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
