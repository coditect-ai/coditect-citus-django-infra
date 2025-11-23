# Firewall Rules Module - Outputs

output "allow_internal_rule_name" {
  description = "Name of the allow internal traffic rule"
  value       = google_compute_firewall.allow_internal.name
}

output "allow_health_checks_rule_name" {
  description = "Name of the allow health checks rule"
  value       = google_compute_firewall.allow_health_checks.name
}

output "allow_ssh_rule_name" {
  description = "Name of the allow SSH rule (if created)"
  value       = try(google_compute_firewall.allow_ssh[0].name, null)
}

output "allow_https_rule_name" {
  description = "Name of the allow HTTPS ingress rule (if created)"
  value       = try(google_compute_firewall.allow_https_ingress[0].name, null)
}

output "allow_http_rule_name" {
  description = "Name of the allow HTTP ingress rule (if created)"
  value       = try(google_compute_firewall.allow_http_ingress[0].name, null)
}

output "allow_gke_master_rule_name" {
  description = "Name of the allow GKE master to nodes rule (if created)"
  value       = try(google_compute_firewall.allow_gke_master_to_nodes[0].name, null)
}

output "allow_gke_webhooks_rule_name" {
  description = "Name of the allow GKE webhooks rule (if created)"
  value       = try(google_compute_firewall.allow_gke_webhooks[0].name, null)
}

output "deny_all_ingress_rule_name" {
  description = "Name of the deny all ingress rule (if created)"
  value       = try(google_compute_firewall.deny_all_ingress[0].name, null)
}

output "allow_all_egress_rule_name" {
  description = "Name of the allow all egress rule"
  value       = google_compute_firewall.allow_all_egress.name
}

output "firewall_rules" {
  description = "List of all created firewall rule names"
  value = compact([
    google_compute_firewall.allow_internal.name,
    google_compute_firewall.allow_health_checks.name,
    try(google_compute_firewall.allow_ssh[0].name, ""),
    try(google_compute_firewall.allow_https_ingress[0].name, ""),
    try(google_compute_firewall.allow_http_ingress[0].name, ""),
    try(google_compute_firewall.allow_gke_master_to_nodes[0].name, ""),
    try(google_compute_firewall.allow_gke_webhooks[0].name, ""),
    try(google_compute_firewall.deny_all_ingress[0].name, ""),
    google_compute_firewall.allow_all_egress.name,
  ])
}
