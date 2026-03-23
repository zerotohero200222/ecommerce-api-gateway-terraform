# ============================================================
# Terraform Outputs
# ============================================================

# Backend Service
output "backend_service" {
  description = "Backend service name"
  value       = google_compute_backend_service.api_gateway_backend.name
}

output "backend_service_id" {
  description = "Backend service ID"
  value       = google_compute_backend_service.api_gateway_backend.id
}

# API Key
output "api_key" {
  description = "API Key for Load Balancer"
  value       = google_apikeys_key.api_key.key_string
  sensitive   = true
}

output "api_key_name" {
  description = "API Key name"
  value       = google_apikeys_key.api_key.name
}

# NEG
output "neg_id" {
  description = "Network Endpoint Group ID"
  value       = google_compute_region_network_endpoint_group.api_gateway_neg.id
}

# Cloud Armor
output "security_policy_id" {
  description = "Cloud Armor security policy ID"
  value       = google_compute_security_policy.api_policy.id
}

# API Config
output "api_config_id" {
  description = "API Gateway config ID"
  value       = google_api_gateway_api_config.secured_config.id
}

# URL Map
output "url_map_id" {
  description = "URL Map ID"
  value       = google_compute_url_map.updated_lb.id
}

# Configuration Summary
output "configuration_summary" {
  description = "Deployment configuration summary"
  value = {
    project_id         = var.project_id
    region             = var.region
    api_gateway_name   = var.gateway_name
    api_config_name    = var.new_api_config
    backend_service    = var.backend_service_name
    neg_name           = var.neg_name
    security_policy    = var.security_policy_name
    url_map_name       = var.url_map_name
    path_pattern       = var.api_path_pattern
  }
}
