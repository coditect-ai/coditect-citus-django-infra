# GKE Cluster Terraform Module

Production-ready Google Kubernetes Engine (GKE) cluster module for CODITECT Citus Django infrastructure, designed for hyperscale multi-tenant applications.

## Features

- **Multi-Zone High Availability**: Cluster nodes distributed across 3 zones in a region
- **Auto-Scaling**: Node pool auto-scales between configurable min/max nodes per zone
- **Private Cluster**: No public IPs on nodes, master API optionally private
- **Workload Identity**: Secure GCP API access without service account keys
- **Network Policy**: Calico-based network segmentation for pod-to-pod traffic
- **Binary Authorization**: Optional deployment validation for enhanced security
- **Managed Prometheus**: Built-in monitoring with GCP Managed Prometheus
- **Automatic Updates**: Rolling updates via GKE release channels
- **Security Hardening**: Shielded nodes, secure boot, integrity monitoring

## Usage

```hcl
module "gke_cluster" {
  source = "../../modules/gke"

  # Project Configuration
  project_id  = "coditect-citus-prod"
  environment = "production"

  # Network Configuration
  network_name                  = module.networking.vpc_name
  subnet_name                   = module.networking.subnet_name
  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"

  # Node Pool Configuration
  machine_type       = "n1-standard-4"
  disk_size_gb       = 100
  min_node_count     = 3
  max_node_count     = 20
  initial_node_count = 3

  # Service Account
  node_service_account = "gke-node@coditect-citus-prod.iam.gserviceaccount.com"

  # Security
  enable_binary_authorization = true
  enable_private_endpoint     = false # Set to true for fully private cluster

  master_authorized_networks = [
    {
      cidr_block   = "10.0.0.0/8"
      display_name = "internal"
    }
  ]

  # Monitoring
  enable_managed_prometheus = true

  # Release Channel
  release_channel = "STABLE"
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
| network_name | Name of the VPC network | `string` | n/a | yes |
| subnet_name | Name of the subnet for GKE nodes | `string` | n/a | yes |
| node_service_account | Service account email for GKE nodes | `string` | n/a | yes |
| cluster_name | Base name for the GKE cluster | `string` | `"coditect-citus"` | no |
| region | GCP region for the cluster | `string` | `"us-central1"` | no |
| node_zones | List of zones for multi-zone deployment | `list(string)` | `["us-central1-a", "us-central1-b", "us-central1-c"]` | no |
| pods_secondary_range_name | Name of the secondary IP range for pods | `string` | `"pods"` | no |
| services_secondary_range_name | Name of the secondary IP range for services | `string` | `"services"` | no |
| enable_private_endpoint | Enable private endpoint for master API | `bool` | `false` | no |
| master_ipv4_cidr_block | CIDR block for the GKE master | `string` | `"172.16.0.0/28"` | no |
| master_authorized_networks | List of CIDR blocks authorized to access master | `list(object)` | `null` | no |
| initial_node_count | Initial number of nodes per zone | `number` | `1` | no |
| min_node_count | Minimum number of nodes per zone | `number` | `3` | no |
| max_node_count | Maximum number of nodes per zone | `number` | `20` | no |
| machine_type | Machine type for GKE nodes | `string` | `"n1-standard-4"` | no |
| disk_size_gb | Disk size in GB for each node | `number` | `100` | no |
| use_preemptible_nodes | Use preemptible nodes for cost savings | `bool` | `false` | no |
| node_tags | Network tags for GKE nodes | `list(string)` | `["gke-node", "allow-health-check"]` | no |
| node_taints | Node taints for workload isolation | `list(object)` | `[]` | no |
| max_surge | Max nodes beyond current size during upgrade | `number` | `1` | no |
| max_unavailable | Max unavailable nodes during upgrade | `number` | `0` | no |
| release_channel | GKE release channel (RAPID, REGULAR, STABLE) | `string` | `"STABLE"` | no |
| maintenance_start_time | Start time for daily maintenance window (HH:MM UTC) | `string` | `"03:00"` | no |
| enable_binary_authorization | Enable Binary Authorization | `bool` | `true` | no |
| enable_managed_prometheus | Enable managed Prometheus | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_name | Name of the GKE cluster |
| cluster_id | Full resource ID of the GKE cluster |
| cluster_endpoint | Endpoint for accessing the GKE cluster (sensitive) |
| cluster_ca_certificate | Base64 encoded CA certificate (sensitive) |
| cluster_location | Location (region) of the GKE cluster |
| cluster_zones | Zones where cluster nodes are deployed |
| node_pool_name | Name of the primary node pool |
| node_pool_instance_group_urls | Instance group URLs for the node pool |
| workload_identity_pool | Workload Identity pool for service account binding |
| master_version | Current master Kubernetes version |
| node_version | Current node Kubernetes version |
| network | VPC network name used by the cluster |
| subnetwork | Subnet name used by the cluster |
| services_ipv4_cidr | IPv4 CIDR block for services |
| cluster_ipv4_cidr | IPv4 CIDR block for pods |

## Resources Created

- `google_container_cluster.primary` - GKE cluster with multi-zone configuration
- `google_container_node_pool.primary_nodes` - Managed node pool with auto-scaling

## Architecture Decisions

### Private Cluster

The cluster is configured as a private cluster by default:
- Node IPs are private (RFC 1918)
- Master API can be accessed from authorized networks only
- Cloud NAT provides egress connectivity for private nodes

### Workload Identity

Workload Identity is enabled to allow pods to authenticate to GCP services securely without service account keys. Bind Kubernetes service accounts to Google service accounts using:

```bash
kubectl annotate serviceaccount <KSA_NAME> \
  iam.gke.io/gcp-service-account=<GSA_NAME>@<PROJECT_ID>.iam.gserviceaccount.com
```

### Node Pool Auto-Scaling

Auto-scaling is configured per zone:
- **Development**: min=1, max=5 per zone (total 3-15 nodes)
- **Staging**: min=2, max=10 per zone (total 6-30 nodes)
- **Production**: min=3, max=20 per zone (total 9-60 nodes)

### Release Channels

- **STABLE**: Production workloads (recommended)
- **REGULAR**: Feature testing before production
- **RAPID**: Early access to new features

## Security Considerations

1. **Network Policy**: Enabled by default using Calico
2. **Binary Authorization**: Enable for production to validate container images
3. **Shielded Nodes**: Secure boot and integrity monitoring enabled
4. **Service Account**: Use least-privilege custom service account
5. **Master Authorized Networks**: Restrict API access to trusted networks
6. **Private Nodes**: No public IPs exposed

## Monitoring

The cluster is configured with:
- System component logging and monitoring
- Workload logging and monitoring
- GCP Managed Prometheus (optional)

Access metrics in Cloud Console or via Prometheus-compatible clients.

## Maintenance

- **Daily Maintenance Window**: Default 03:00 UTC (configurable)
- **Auto-Repair**: Automatically repairs unhealthy nodes
- **Auto-Upgrade**: Automatically upgrades nodes per release channel

## Cost Optimization

For development environments:
- Reduce `machine_type` to `n1-standard-2`
- Set `use_preemptible_nodes = true`
- Lower `min_node_count` to 1
- Reduce `max_node_count` to 5

## Examples

See `examples/` directory for:
- Development cluster configuration
- Staging cluster configuration
- Production cluster configuration
- Multi-cluster setup

## Lifecycle Management

- **prevent_destroy**: Enabled on cluster resource to prevent accidental deletion
- **create_before_destroy**: Enabled on node pool for zero-downtime updates
- **ignore_changes**: Configured for node count (managed by auto-scaler)

## Related Modules

- [networking](../networking/) - VPC and subnet configuration
- [firewall](../firewall/) - Firewall rules for GKE
- [secrets](../secrets/) - Secret Manager integration

## Support

For issues or questions, contact the infrastructure team or see [CONTRIBUTING.md](../../../CONTRIBUTING.md).

## License

Copyright (c) 2025 AZ1.AI INC. See [LICENSE](../../../LICENSE).
