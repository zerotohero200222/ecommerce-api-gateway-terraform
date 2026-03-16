# ============================================================
# Variable Definitions
# ============================================================

# ============================================================
# Required Variables - Project Configuration
# ============================================================

variable "project_id" {
  description = "GCP Project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

# ============================================================
# Required Variables - API Gateway
# ============================================================

variable "api_name" {
  description = "Name of the existing API in API Gateway"
  type        = string
}

variable "gateway_name" {
  description = "Name of the existing API Gateway"
  type        = string
}

variable "new_api_config" {
  description = "Name for the new API Gateway configuration with security"
  type        = string
}

# ============================================================
# Required Variables - Load Balancer
# ============================================================

variable "url_map_name" {
  description = "Name of the existing Load Balancer URL Map"
  type        = string
}

variable "path_matcher_name" {
  description = "Name for the new path matcher"
  type        = string
  default     = "api-matcher"
}

variable "api_path_pattern" {
  description = "Path pattern for API Gateway routing"
  type        = string
  default     = "/api/*"
}

# ============================================================
# Required Variables - Backend Service
# ============================================================

variable "backend_service_name" {
  description = "Name for the API Gateway backend service"
  type        = string
  default     = "api-backend"
}

variable "neg_name" {
  description = "Name for the serverless NEG"
  type        = string
  default     = "api-gateway-neg"
}

# ============================================================
# Required Variables - Security
# ============================================================

variable "security_policy_name" {
  description = "Name for the Cloud Armor security policy"
  type        = string
  default     = "api-gateway-inject-key"
}

variable "api_key_name" {
  description = "Resource name for the API key"
  type        = string
  default     = "load-balancer-api-key"
}

variable "api_key_display_name" {
  description = "Display name for the API key"
  type        = string
  default     = "LoadBalancer-API-Key"
}

# ============================================================
# Optional Variables - Logging
# ============================================================

variable "enable_backend_logs" {
  description = "Enable logging for backend service"
  type        = bool
  default     = true
}

variable "log_sample_rate" {
  description = "Sample rate for backend logs (0.0 to 1.0)"
  type        = number
  default     = 1.0

  validation {
    condition     = var.log_sample_rate >= 0.0 && var.log_sample_rate <= 1.0
    error_message = "Log sample rate must be between 0.0 and 1.0"
  }
}

# ============================================================
# Optional Variables - Environment
# ============================================================

variable "environment" {
  description = "Environment name (dev, uat, prod)"
  type        = string
  default     = "dev"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
