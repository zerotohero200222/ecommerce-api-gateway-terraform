# E-Commerce API Gateway with Cloud Armor Security - FIXED
# ============================================================

locals {
  common_config = {
    project_id = var.project_id
    region     = var.region
  }

  api_gateway_config = {
    api_name        = var.api_name
    gateway_name    = var.gateway_name
    new_config      = var.new_api_config
    neg_name        = var.neg_name
    backend_service = var.backend_service_name
  }

  load_balancer_config = {
    url_map_name      = var.url_map_name
    path_pattern      = var.api_path_pattern
    default_backend   = var.default_backend_service
  }

  cloud_armor_config = {
    policy_name = var.security_policy_name
  }
}

# ============================================================
# Random Suffix for Unique API Key Name
# ============================================================

resource "random_id" "suffix" {
  byte_length = 2
}

# ============================================================
# API Key Creation with Unique Name
# ============================================================

resource "google_apikeys_key" "api_key" {
  name         = "lb-api-key-${random_id.suffix.hex}"
  display_name = "LoadBalancer-API-Key"
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

# ============================================================
# Update Gateway via null_resource
# ============================================================

resource "null_resource" "update_gateway" {
  triggers = {
    api_config_id = google_api_gateway_api_config.secured_config.id
    gateway_id    = local.api_gateway_config.gateway_name
    timestamp     = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Updating API Gateway..."
      gcloud api-gateway gateways update ${local.api_gateway_config.gateway_name} \
        --api=${local.api_gateway_config.api_name} \
        --api-config=${local.api_gateway_config.new_config} \
        --location=${local.common_config.region} \
        --project=${local.common_config.project_id} \
        --quiet || echo "Gateway update may have failed - continuing..."
      
      echo "Waiting 60 seconds for gateway update to propagate..."
      sleep 60
    EOT
  }

  depends_on = [google_api_gateway_api_config.secured_config]
}

# ============================================================
# Serverless Network Endpoint Group (NEG)
# ============================================================

resource "google_compute_region_network_endpoint_group" "api_gateway_neg" {
  provider = google-beta
  
  name    = local.api_gateway_config.neg_name
  project = local.common_config.project_id
  region  = local.common_config.region

  network_endpoint_type = "SERVERLESS"

  # Use serverless_deployment for API Gateway
  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = local.api_gateway_config.gateway_name
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [null_resource.update_gateway]
}

# ============================================================
# Cloud Armor Security Policy
# ============================================================

resource "google_compute_security_policy" "api_policy" {
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
        header_value = google_apikeys_key.api_key.key_string
      }
    }
  }
}

# ============================================================
# Backend Service - FIXED (removed timeout_sec)
# ============================================================

resource "google_compute_backend_service" "api_backend" {
  name    = local.api_gateway_config.backend_service
  project = local.common_config.project_id
  
  # IMPORTANT: Do NOT set timeout_sec for serverless NEGs
  # It's not supported and will cause an error
  protocol = "HTTP"
  
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway_neg.id
  }

  # Attach Cloud Armor security policy
  security_policy = google_compute_security_policy.api_policy.id

  # Enable logging
  log_config {
    enable      = var.enable_backend_logs
    sample_rate = var.log_sample_rate
  }

  depends_on = [
    google_compute_region_network_endpoint_group.api_gateway_neg,
    google_compute_security_policy.api_policy
  ]
}

# ============================================================
# URL Map Update
# ============================================================

resource "google_compute_url_map" "updated_lb" {
  name    = local.load_balancer_config.url_map_name
  project = local.common_config.project_id

  default_service = "https://www.googleapis.com/compute/v1/projects/${local.common_config.project_id}/global/backendServices/${local.load_balancer_config.default_backend}"

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "https://www.googleapis.com/compute/v1/projects/${local.common_config.project_id}/global/backendServices/${local.load_balancer_config.default_backend}"

    path_rule {
      paths   = [local.load_balancer_config.path_pattern]
      service = google_compute_backend_service.api_backend.id
    }
  }

  depends_on = [google_compute_backend_service.api_backend]
}
