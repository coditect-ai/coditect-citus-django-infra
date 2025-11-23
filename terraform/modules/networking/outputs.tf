# VPC Networking Module - Outputs

output "network_name" {
  description = "Name of the VPC network"
  value       = google_compute_network.vpc.name
}

output "network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.vpc.id
}

output "network_self_link" {
  description = "Self link of the VPC network"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Name of the primary subnet"
  value       = google_compute_subnetwork.primary.name
}

output "subnet_id" {
  description = "ID of the primary subnet"
  value       = google_compute_subnetwork.primary.id
}

output "subnet_self_link" {
  description = "Self link of the primary subnet"
  value       = google_compute_subnetwork.primary.self_link
}

output "subnet_cidr" {
  description = "CIDR range of the primary subnet"
  value       = google_compute_subnetwork.primary.ip_cidr_range
}

output "pods_secondary_range_name" {
  description = "Name of the secondary range for GKE pods"
  value       = var.pods_secondary_range_name
}

output "services_secondary_range_name" {
  description = "Name of the secondary range for GKE services"
  value       = var.services_secondary_range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "router_id" {
  description = "ID of the Cloud Router"
  value       = google_compute_router.router.id
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.nat.name
}

output "nat_ip_address" {
  description = "NAT IP address for egress traffic"
  value       = google_compute_router_nat.nat.nat_ip_allocate_option == "AUTO_ONLY" ? "AUTO-ALLOCATED" : null
}

output "private_vpc_connection" {
  description = "Private VPC connection for Cloud SQL"
  value       = google_service_networking_connection.private_vpc_connection.network
}

output "private_ip_address_name" {
  description = "Name of the private IP address range for VPC peering"
  value       = google_compute_global_address.private_ip_address.name
}

output "private_dns_zone_name" {
  description = "Name of the private DNS zone (if created)"
  value       = try(google_dns_managed_zone.private_zone[0].name, null)
}

output "private_dns_zone_domain" {
  description = "DNS domain of the private DNS zone (if created)"
  value       = try(google_dns_managed_zone.private_zone[0].dns_name, null)
}

output "vpc_name" {
  description = "Alias for network_name (backward compatibility)"
  value       = google_compute_network.vpc.name
}
