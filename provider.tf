terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket  = "ecommerce-terraform-state-project-1c4daaee-c7bb-486d-970"
    prefix  = "api-gateway"
  }
}

provider "google" {
  project = "project-1c4daaee-c7bb-486d-970"
  region  = "us-central1"
}
