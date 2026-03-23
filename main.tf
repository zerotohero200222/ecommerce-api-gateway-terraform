# ============================================================
# API KEY
# ============================================================

resource "google_apikeys_key" "api_key" {
  display_name = "LoadBalancer API Key"
  project      = var.project_id

  restrictions {
    api_targets {
      service = "apigateway.googleapis.com"
    }
  }
}

# ============================================================
# API GATEWAY NEG
# ============================================================

resource "google_compute_region_network_endpoint_group" "api_gateway_neg" {
  provider              = google-beta
  name                  = var.neg_name
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  serverless_deployment {
    platform = "apigateway.googleapis.com"
    resource = var.gateway_name
  }
}

# ============================================================
# CLOUD ARMOR POLICY
# ============================================================

resource "google_compute_security_policy" "api_policy" {
  name = var.security_policy_name

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
}

# ============================================================
# BACKEND SERVICE (API GATEWAY)
# ============================================================

resource "google_compute_backend_service" "api_backend" {
  name                  = var.backend_service_name
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  security_policy = google_compute_security_policy.api_policy.id

  backend {
    group = google_compute_region_network_endpoint_group.api_gateway_neg.id
  }
}

# ============================================================
# URL MAP UPDATE (ADD /api/* ROUTE)
# ============================================================

resource "google_compute_url_map" "updated_lb" {
  name            = var.url_map_name
  default_service = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/backendServices/${var.default_backend_service}"

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/backendServices/${var.default_backend_service}"

    path_rule {
      paths   = [var.api_path_pattern]
      service = google_compute_backend_service.api_backend.id
    }
  }
}
