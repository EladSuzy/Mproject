variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
  default     = "backend-service"
}

variable "container_image" {
  description = "Container image to deploy (initial)"
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}
