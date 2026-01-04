# VPC Network
resource "google_compute_network" "main" {
  name                    = "${var.service_name}-${var.environment}-vpc"
  auto_create_subnetworks = false
}

# Subnet for the connector and general resources
resource "google_compute_subnetwork" "main" {
  name          = "${var.service_name}-${var.environment}-subnet"
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region
  network       = google_compute_network.main.id
}

# Serverless VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  name          = "${var.environment}-con" # Shortened to fit 25 char limit often
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.main.name
}

# Private Service Access for Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.main.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
