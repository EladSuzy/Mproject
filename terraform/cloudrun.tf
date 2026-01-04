resource "google_service_account" "run_sa" {
  account_id   = "${var.environment}-sa"
  display_name = "Cloud Run SA ${var.environment}"
}

resource "google_cloud_run_v2_service" "default" {
  name     = "${var.service_name}-${var.environment}"
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.run_sa.email
    
    containers {
      image = var.container_image
      
      resources {
        limits = {
          cpu    = "2"
          memory = "1Gi" // High memory for potential Java/Node apps
        }
      }
      
      env {
        name  = "DB_HOST"
        value = google_sql_database_instance.main.private_ip_address
      }
      env {
        name = "DB_NAME"
        value = google_sql_database.database.name
      }
      env {
        name = "DB_USER"
        value = google_sql_user.users.name
      }
      env {
        name = "DB_PASSWORD"
        value_source {
          secret_key_ref {
            secret = google_secret_manager_secret.db_password.secret_id
            version = "latest"
          }
        }
      }
    }

    vpc_access{
      connector = google_vpc_access_connector.connector.id
      egress    = "ALL_TRAFFIC"
    }

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }
  }
}

# Allow unauthenticated invocations (handled by LB/Authentication layer usually, 
# but for internal LB setup we often need to allow the LB SA to invoke)
# For strictly internal, we might restrict this further.
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_v2_service.default.name
  location = google_cloud_run_v2_service.default.location
  role     = "roles/run.invoker"
  member   = "allUsers" # WARNING: In production, restrict to Load Balancer Service Account
}
