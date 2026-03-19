########################################
# RANDOM SUFFIX
########################################
resource "random_id" "suffix" {
  byte_length = 2
}

########################################
# API KEY (FIXED)
########################################
resource "google_apikeys_key" "api_key" {
  name         = "lb-api-key-${random_id.suffix.hex}"
  display_name = "LoadBalancer API Key"

  restrictions {
    api_targets {
      service = "apigateway.googleapis.com"
    }
  }
}

########################################
# SERVERLESS NEG (FIXED)
########################################
resource "google_compute_region_network_endpoint_group" "api_gateway_neg" {
  provider              = google-beta
  name                  = "api-gateway-neg"
  region                = "us-central1"
  network_endpoint_type = "SERVERLESS"

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = "ecommerce-gateway"
  }
}

########################################
# BACKEND SERVICE
########################################
resource "google_compute_backend_service" "api_backend" {
  name                  = "api-backend"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 60

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway_neg.id
  }
}

########################################
# CLOUD ARMOR POLICY (FIXED)
########################################
resource "google_compute_security_policy" "api_policy" {
  name = "api-gateway-inject-key"

  rule {
    priority = 1000
    action   = "allow"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }

    header_action {
      request_headers_to_adds {
        header_name  = "x-api-key"
        header_value = google_apikeys_key.api_key.key_string
      }
    }
  }

  rule {
    priority = 2147483647
    action   = "deny(403)"

    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
  }
}

########################################
# ATTACH CLOUD ARMOR
########################################
resource "google_compute_backend_service" "secured_backend" {
  name                  = google_compute_backend_service.api_backend.name
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  security_policy = google_compute_security_policy.api_policy.id
}
