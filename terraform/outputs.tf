output "load_balancer_ip" {
  description = "The global IP address of the load balancer"
  value       = google_compute_global_address.default.address
}

output "cloud_run_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.default.uri
}
