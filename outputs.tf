# ============================================================
# Output Definitions
# ============================================================

output "api_key" {
  description = "API key for Load Balancer authentication (sensitive)"
  value       = google_apikeys_key.load_balancer_key.key_string
  sensitive   = true
}

output "api_key_id" {
  description = "API key resource ID"
  value       = google_apikeys_key.load_balancer_key.id
}

output "api_gateway_config_id" {
  description = "ID of the new API Gateway configuration"
  value       = google_api_gateway_api_config.secured_config.id
}

output "api_gateway_config_name" {
  description = "Name of the new API Gateway configuration"
  value       = google_api_gateway_api_config.secured_config.api_config_id
}

output "api_gateway_neg_id" {
  description = "ID of the API Gateway Network Endpoint Group"
  value       = google_compute_region_network_endpoint_group.api_gateway_neg.id
}

output "api_gateway_neg_name" {
  description = "Name of the API Gateway Network Endpoint Group"
  value       = google_compute_region_network_endpoint_group.api_gateway_neg.name
}

output "api_gateway_backend_id" {
  description = "ID of the API Gateway backend service"
  value       = google_compute_backend_service.api_gateway_backend.id
}

output "api_gateway_backend_name" {
  description = "Name of the API Gateway backend service"
  value       = google_compute_backend_service.api_gateway_backend.name
}

output "cloud_armor_policy_id" {
  description = "ID of the Cloud Armor security policy"
  value       = google_compute_security_policy.api_key_injection.id
}

output "cloud_armor_policy_name" {
  description = "Name of the Cloud Armor security policy"
  value       = google_compute_security_policy.api_key_injection.name
}

output "url_map_id" {
  description = "ID of the updated URL Map"
  value       = google_compute_url_map.updated_lb.id
}

output "url_map_self_link" {
  description = "Self link of the updated URL Map"
  value       = google_compute_url_map.updated_lb.self_link
}

# ============================================================
# Configuration Summary
# ============================================================

output "configuration_summary" {
  description = "Summary of the deployed configuration"
  value = {
    project_id            = var.project_id
    region                = var.region
    api_gateway_name      = var.gateway_name
    api_config_name       = google_api_gateway_api_config.secured_config.api_config_id
    backend_service_name  = google_compute_backend_service.api_gateway_backend.name
    neg_name              = google_compute_region_network_endpoint_group.api_gateway_neg.name
    url_map_name          = var.url_map_name
    security_policy_name  = google_compute_security_policy.api_key_injection.name
    path_pattern          = var.api_path_pattern
    environment           = var.environment
  }
}

output "backend_service_details" {
  description = "Details of the API Gateway backend service"
  value = {
    name                  = google_compute_backend_service.api_gateway_backend.name
    protocol              = google_compute_backend_service.api_gateway_backend.protocol
    timeout_sec           = google_compute_backend_service.api_gateway_backend.timeout_sec
    security_policy       = google_compute_backend_service.api_gateway_backend.security_policy
    load_balancing_scheme = google_compute_backend_service.api_gateway_backend.load_balancing_scheme
  }
}

output "deployment_commands" {
  description = "Commands to verify the deployment"
  value = {
    get_api_key           = "terraform output -raw api_key"
    check_backend_health  = "gcloud compute backend-services get-health ${google_compute_backend_service.api_gateway_backend.name} --global"
    check_url_map         = "gcloud compute url-maps describe ${var.url_map_name} --global"
    check_security_policy = "gcloud compute security-policies describe ${google_compute_security_policy.api_key_injection.name}"
  }
}
