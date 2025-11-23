# GKE Cluster Module - Outputs

output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_id" {
  description = "Full resource ID of the GKE cluster"
  value       = google_container_cluster.primary.id
}

output "cluster_endpoint" {
  description = "Endpoint for accessing the GKE cluster (API server)"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64 encoded CA certificate for the GKE cluster"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Location (region) of the GKE cluster"
  value       = google_container_cluster.primary.location
}

output "cluster_zones" {
  description = "Zones where cluster nodes are deployed"
  value       = google_container_cluster.primary.node_locations
}

output "node_pool_name" {
  description = "Name of the primary node pool"
  value       = google_container_node_pool.primary_nodes.name
}

output "node_pool_instance_group_urls" {
  description = "Instance group URLs for the node pool"
  value       = google_container_node_pool.primary_nodes.instance_group_urls
}

output "workload_identity_pool" {
  description = "Workload Identity pool for service account binding"
  value       = "${var.project_id}.svc.id.goog"
}

output "master_version" {
  description = "Current master Kubernetes version"
  value       = google_container_cluster.primary.master_version
}

output "node_version" {
  description = "Current node Kubernetes version"
  value       = google_container_node_pool.primary_nodes.version
}

output "network" {
  description = "VPC network name used by the cluster"
  value       = google_container_cluster.primary.network
}

output "subnetwork" {
  description = "Subnet name used by the cluster"
  value       = google_container_cluster.primary.subnetwork
}

output "services_ipv4_cidr" {
  description = "IPv4 CIDR block for services"
  value       = google_container_cluster.primary.services_ipv4_cidr
}

output "cluster_ipv4_cidr" {
  description = "IPv4 CIDR block for pods"
  value       = google_container_cluster.primary.cluster_ipv4_cidr
}
