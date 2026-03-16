# ============================================================
# E-Commerce API Gateway with Cloud Armor Security
# ============================================================
# This configuration creates:
#   1. Serverless NEG for API Gateway
#   2. Backend Service for API Gateway
#   3. URL Map path matcher for /api/*
#   4. API Key for authentication
#   5. Cloud Armor security policy with API key injection
#   6. Updated API Gateway configuration with security
# ============================================================

locals {
  # Common configuration
  common_config = {
    project_id = var.project_id
    region     = var.region
  }

  # API Gateway configuration
  api_gateway_config = {
    api_name        = var.api_name
    gateway_name    = var.gateway_name
    new_config      = var.new_api_config
    neg_name        = var.neg_name
    backend_service = var.backend_service_name
  }

  # Load Balancer configuration
  load_balancer_config = {
    url_map_name      = var.url_map_name
    path_matcher_name = var.path_matcher_name
    path_pattern      = var.api_path_pattern
  }

  # Cloud Armor configuration
  cloud_armor_config = {
    policy_name = var.security_policy_name
  }
}

# ============================================================
# Data Sources - Fetch Existing Resources
# ============================================================

# Get existing URL Map
data "google_compute_url_map" "existing_lb" {
  name    = local.load_balancer_config.url_map_name
  project = local.common_config.project_id
}

# ============================================================
# API Key Creation
# ============================================================

resource "google_apikeys_key" "load_balancer_key" {
  name         = var.api_key_name
  display_name = var.api_key_display_name
  project      = local.common_config.project_id

  restrictions {
    api_targets {
      service = "apigateway.googleapis.com"
    }
  }
}

# ============================================================
# API Gateway Configuration
# ============================================================

# Create new API config with security
resource "google_api_gateway_api_config" "secured_config" {
  provider      = google-beta
  api           = local.api_gateway_config.api_name
  api_config_id = local.api_gateway_config.new_config
  project       = local.common_config.project_id

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = filebase64("${path.module}/files/openapi.yaml")
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Update API Gateway to use new config
resource "google_api_gateway_gateway" "gateway_update" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.secured_config.id
  gateway_id = local.api_gateway_config.gateway_name
  region     = local.common_config.region
  project    = local.common_config.project_id

  depends_on = [google_api_gateway_api_config.secured_config]
}

# ============================================================
# Serverless Network Endpoint Group (NEG)
# ============================================================

resource "google_compute_region_network_endpoint_group" "api_gateway_neg" {
  name    = local.api_gateway_config.neg_name
  project = local.common_config.project_id
  region  = local.common_config.region

  network_endpoint_type = "SERVERLESS"

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = local.api_gateway_config.gateway_name
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [google_api_gateway_gateway.gateway_update]
}

# ============================================================
# Backend Service
# ============================================================

resource "google_compute_backend_service" "api_gateway_backend" {
  name        = local.api_gateway_config.backend_service
  project     = local.common_config.project_id
  protocol    = "HTTP"
  timeout_sec = 60

  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway_neg.id
  }

  # Attach Cloud Armor security policy
  security_policy = google_compute_security_policy.api_key_injection.id

  log_config {
    enable      = var.enable_backend_logs
    sample_rate = var.log_sample_rate
  }

  depends_on = [
    google_compute_region_network_endpoint_group.api_gateway_neg,
    google_compute_security_policy.api_key_injection
  ]
}

# ============================================================
# Cloud Armor Security Policy
# ============================================================

resource "google_compute_security_policy" "api_key_injection" {
  name        = local.cloud_armor_config.policy_name
  project     = local.common_config.project_id
  description = "Inject x-api-key header for API Gateway authentication"

  # Default rule - allow all
  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule - allow all traffic"
  }

  # Custom rule - inject API key header
  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Inject x-api-key header for API Gateway authentication"

    header_action {
      request_headers_to_adds {
        header_name  = "x-api-key"
        header_value = google_apikeys_key.load_balancer_key.key_string
      }
    }
  }
}

# ============================================================
# URL Map Update - Add Path Matcher
# ============================================================

resource "google_compute_url_map" "updated_lb" {
  name            = local.load_balancer_config.url_map_name
  project         = local.common_config.project_id
  default_service = data.google_compute_url_map.existing_lb.default_service

  # Preserve existing host rules if any
  dynamic "host_rule" {
    for_each = data.google_compute_url_map.existing_lb.host_rule
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.value.path_matcher
    }
  }

  # Preserve existing path matchers
  dynamic "path_matcher" {
    for_each = data.google_compute_url_map.existing_lb.path_matcher
    content {
      name            = path_matcher.value.name
      default_service = path_matcher.value.default_service

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rule
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.service
        }
      }
    }
  }

  # Add new path matcher for API Gateway
  path_matcher {
    name            = local.load_balancer_config.path_matcher_name
    default_service = data.google_compute_url_map.existing_lb.default_service

    path_rule {
      paths   = [local.load_balancer_config.path_pattern]
      service = google_compute_backend_service.api_gateway_backend.id
    }
  }

  depends_on = [google_compute_backend_service.api_gateway_backend]
}
