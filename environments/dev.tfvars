# ============================================================
# Development Environment Configuration
# ============================================================

# Project Configuration
project_id = "project-1c4daaee-c7bb-486d-970"
region     = "us-central1"

# API Gateway Configuration
api_name       = "ecommerce-api"
gateway_name   = "ecommerce-gateway"
new_api_config = "ecommerce-config-v3"

# Load Balancer Configuration
url_map_name      = "ecommerce-lb"
path_matcher_name = "api-matcher"
api_path_pattern  = "/api/*"

# Backend Service Configuration
backend_service_name = "api-backend"
neg_name             = "api-gateway-neg"

# Security Configuration
security_policy_name = "api-gateway-inject-key"
api_key_name         = "load-balancer-api-key"
api_key_display_name = "LoadBalancer-API-Key"

# Logging Configuration
enable_backend_logs = true
log_sample_rate     = 1.0

# Environment
environment = "dev"

# Labels
labels = {
  environment = "dev"
  managed_by  = "terraform"
  component   = "api-gateway-backend"
  team        = "platform"
}
