output "api_key" {
  value     = google_apikeys_key.api_key.key_string
  sensitive = true
}

output "backend_service" {
  value = google_compute_backend_service.api_backend.name
}
