# ============================================================
# Terraform Variables
# ============================================================

# Common Configuration
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

# API Gateway Configuration
variable "api_name" {
  description = "API Gateway API name"
  type        = string
  default     = "ecommerce-api"
}

variable "gateway_name" {
  description = "API Gateway name"
  type        = string
  default     = "ecommerce-gateway"
}

variable "new_api_config" {
  description = "New API Config ID"
  type        = string
  default     = "ecommerce-config-v3"
}

variable "neg_name" {
  description = "Network Endpoint Group name"
  type        = string
  default     = "api-gateway-neg"
}

variable "backend_service_name" {
  description = "Backend Service name"
  type        = string
  default     = "api-backend"
}

# Load Balancer Configuration
variable "url_map_name" {
  description = "URL Map name"
  type        = string
  default     = "ecommerce-lb"
}

variable "api_path_pattern" {
  description = "API path pattern for routing"
  type        = string
  default     = "/api/*"
}

variable "default_backend_service" {
  description = "Default backend service"
  type        = string
  default     = "frontend-backend"
}

# Cloud Armor Configuration
variable "security_policy_name" {
  description = "Cloud Armor security policy name"
  type        = string
  default     = "api-gateway-inject-key"
}

# Logging Configuration
variable "enable_backend_logs" {
  description = "Enable backend service logging"
  type        = bool
  default     = true
}

variable "log_sample_rate" {
  description = "Backend service log sample rate"
  type        = number
  default     = 1.0
}
