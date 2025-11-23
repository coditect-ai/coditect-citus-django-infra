# Firewall Rules Terraform Module

Production-ready firewall rules module implementing least-privilege network security for GKE clusters and infrastructure components.

## Features

- **Least-Privilege Access**: Deny by default, allow only required traffic
- **Internal VPC Traffic**: Allow communication within VPC
- **Health Check Support**: Allow GCP load balancer health checks
- **GKE Master Communication**: Allow GKE control plane to node communication
- **Optional SSH Access**: Configurable SSH access from authorized IPs
- **Ingress Control**: HTTPS/HTTP ingress with configurable source ranges
- **Comprehensive Logging**: All rules log connections for security auditing

## Usage

```hcl
module "firewall" {
  source = "../../modules/firewall"

  # Project Configuration
  project_id   = "coditect-citus-prod"
  environment  = "production"
  network_name = module.networking.network_name

  # Internal Network
  internal_cidr_ranges = ["10.0.0.0/8"]

  # GKE Configuration
  enable_gke_master_firewall = true
  gke_master_cidr            = "172.16.0.0/28"
  gke_node_tags              = ["gke-node"]

  # SSH Access (optional, production typically disabled)
  authorized_ssh_ranges = []  # No SSH access

  # HTTPS Ingress
  allow_internet_https = true
  https_source_ranges  = ["0.0.0.0/0"]

  # HTTP Ingress (for HTTPS redirect only)
  allow_internet_http = false
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| google | >= 5.0, < 7.0 |

## Security Model

### Default Behavior
- **Deny all ingress** (explicit rule with lowest priority)
- **Allow all egress** (controlled by Cloud NAT)
- **Log all connections** (for security auditing)

### Allowed Traffic
1. **Internal VPC**: All protocols between VPC resources
2. **Health Checks**: TCP from GCP load balancer ranges
3. **GKE Master**: TCP 443, 10250 from master CIDR
4. **GKE Webhooks**: TCP 8443, 9443, 15017 from master CIDR
5. **HTTPS**: TCP 443 from internet (optional)
6. **HTTP**: TCP 80 from internet (optional, redirect only)
7. **SSH**: TCP 22 from authorized IPs (optional)

## Firewall Rules Priority

| Priority | Rule | Description |
|----------|------|-------------|
| 1000 | Allow specific traffic | Health checks, SSH, HTTPS, GKE master |
| 65534 | Allow internal | All VPC internal communication |
| 65534 | Allow egress | All outbound traffic |
| 65535 | Deny all ingress | Explicit deny (lowest priority) |

## Network Tags

Firewall rules use network tags for targeting:

| Tag | Purpose |
|-----|---------|
| `gke-node` | GKE cluster nodes |
| `allow-health-check` | Resources behind load balancers |
| `allow-ssh` | SSH access allowed |
| `allow-https` | HTTPS ingress allowed |
| `allow-http` | HTTP ingress allowed |

Assign tags in your resource configurations:

```hcl
# GKE node pool
node_config {
  tags = ["gke-node", "allow-health-check"]
}
```

## Examples

### Production Configuration

```hcl
module "firewall" {
  source = "../../modules/firewall"

  project_id   = "coditect-citus-prod"
  environment  = "production"
  network_name = module.networking.network_name

  # No SSH access in production
  authorized_ssh_ranges = []

  # HTTPS only (no HTTP)
  allow_internet_https = true
  allow_internet_http  = false

  # GKE firewall rules
  enable_gke_master_firewall = true
  gke_master_cidr            = "172.16.0.0/28"

  # Explicit deny all rule
  create_deny_all_rule = true

  # Disable expensive egress logging
  enable_egress_logging = false
}
```

### Development Configuration

```hcl
module "firewall" {
  source = "../../modules/firewall"

  project_id   = "coditect-citus-dev"
  environment  = "dev"
  network_name = module.networking.network_name

  # Allow SSH from office IP
  authorized_ssh_ranges = ["203.0.113.0/24"]

  # Allow both HTTP and HTTPS
  allow_internet_https = true
  allow_internet_http  = true

  # Enable egress logging for debugging
  enable_egress_logging = true
}
```

## Monitoring

Monitor firewall rules in Cloud Console:
- Firewall Insights: Analyze rule usage
- Firewall Rules Logging: View allowed/denied connections
- VPC Flow Logs: Detailed traffic analysis

Set up alerts for:
- High denied connection rate (potential attack)
- Unexpected allowed connections
- Changes to firewall rules

## Best Practices

1. **Principle of Least Privilege**: Only allow required traffic
2. **Use Network Tags**: Target rules precisely with tags
3. **Enable Logging**: Log all rules for security auditing
4. **Regular Review**: Review and remove unused rules
5. **Source IP Restrictions**: Limit SSH/admin access to known IPs
6. **No Public SSH**: Disable SSH in production, use bastion hosts
7. **HTTPS Only**: Disable HTTP except for redirect purposes

## Troubleshooting

### Connection Refused

Check firewall rules allow traffic:
```bash
gcloud compute firewall-rules list \
  --filter="network:coditect-vpc-production" \
  --format="table(name,sourceRanges,allowed[].ports)"
```

### GKE Pods Can't Communicate

Ensure internal traffic is allowed:
```bash
# Verify allow-internal rule exists
gcloud compute firewall-rules describe coditect-vpc-production-allow-internal
```

### Load Balancer Health Checks Fail

Verify health check firewall rule and node tags:
```bash
gcloud compute firewall-rules describe coditect-vpc-production-allow-health-checks
```

## Related Modules

- [networking](../networking/) - VPC and subnet configuration
- [gke](../gke/) - GKE cluster (uses network tags)

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
