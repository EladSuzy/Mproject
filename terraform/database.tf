# Random Password for the DB structure
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Secret Manager resource to store the password
resource "google_secret_manager_secret" "db_password" {
  secret_id = "${var.service_name}-db-pass"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_val" {
  secret = google_secret_manager_secret.db_password.id
  secret_data = random_password.db_password.result
}

# Cloud SQL Instance
resource "google_sql_database_instance" "main" {
  name             = "${var.service_name}-db-instance"
  database_version = "POSTGRES_15"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro" # Use appropriate tier for production (e.g., db-custom-2-4096)
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.main.id
    }
  }
  deletion_protection  = false # Set to true for production
}

# Database
resource "google_sql_database" "database" {
  name     = "${var.service_name}-db"
  instance = google_sql_database_instance.main.name
}

# User
resource "google_sql_user" "users" {
  name     = "appuser"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
}

# Grant Cloud Run Service Account access to define secrets
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_cloud_run_v2_service.default.service_account}" # Implicit default SA
  # Ideally, create a dedicated SA for Cloud Run in cloudrun.tf and use it here
}
