# Reserve a global static IP
resource "google_compute_global_address" "default" {
  name = "${var.service_name}-${var.environment}-ip"
}

# Cloud Armor Security Policy
resource "google_compute_security_policy" "policy" {
  name = "${var.service_name}-${var.environment}-security-policy"

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "default rule"
  }

  # Example: Block specific IP or Geo
  # rule {
  #   action   = "deny(403)"
  #   priority = "1000"
  #   match {
  #      expr {
  #        expression = "origin.region_code == 'CN'"
  #      }
  #   }
  # }
}

# Serverless NEG for Cloud Run
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.service_name}-${var.environment}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.default.name
  }
}

# Backend Service for Cloud Run
resource "google_compute_backend_service" "default" {
  name                  = "${var.service_name}-${var.environment}-backend"
  protocol              = "HTTPS"
  enable_cdn            = true
  security_policy       = google_compute_security_policy.policy.id
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

# URL Map
resource "google_compute_url_map" "default" {
  name            = "${var.service_name}-${var.environment}-url-map"
  default_service = google_compute_backend_service.default.id
}

# Target HTTP Proxy (For demo purposes using HTTP. Prod should use HTTPS)
resource "google_compute_target_http_proxy" "default" {
  name    = "${var.service_name}-${var.environment}-http-proxy"
  url_map = google_compute_url_map.default.id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "default" {
  name       = "${var.service_name}-${var.environment}-lb"
  target     = google_compute_target_http_proxy.default.id
  port_range = "80"
  ip_address = google_compute_global_address.default.id
}
