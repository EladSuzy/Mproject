# Production-Ready Stateless Backend Service on GCP

This repository contains the Infrastructure as Code (Terraform) and CI/CD configuration (Cloud Build) for deploying a scalable, secure, and production-grade stateless backend service on Google Cloud Platform.

## 1. Architecture Overview

See the full [Architecture Diagram](ARCHITECTURE.md).

The architecture is designed around **Google Cloud Run**, providing a serverless, consistently reliable, and cost-effective compute layer.

### Key Components
*   **Compute**: Cloud Run (v2) for running stateless containers.
*   **ingress**: Global External Application Load Balancer (HTTPS) with Cloud Armor WAF.
*   **Data Persistence**: Cloud SQL (PostgreSQL) for relational data, accessed via Private IP.
*   **Networking**: VPC with Private Service Access and Serverless Connector for secure egress.
*   **Security**: Secret Manager for sensitive config, IAM for access control.
*   **Observability**: Cloud Monitoring Dashboards and Alerting Policies.
*   **CI/CD**: Cloud Build pipeline for automated testing and deployment.

## 2. Design Choices & Rationale

### Why Cloud Run?
We chose Cloud Run over GKE or Compute Engine because:
*   **No Ops Overhead**: No cluster management, patching, or node provisioning.
*   **Fast Autoscaling**: Scales from 0 to N instance in seconds based on request concurrency.
*   **Cost Efficiency**: Pay only for CPU/Memory allocated during request processing (or provisioned instances).

### Why Global Load Balancer?
Even though Cloud Run has a default domain, we place a Global LB in front to:
*   **Edge Termination**: Terminate SSL at the Google edge (closest to user).
*   **Security**: Integrate **Cloud Armor** (WAF) to block DDoS and attacks before they reach the app.
*   **Custom Domain**: Easier management of custom SSL certificates and domains.

### Why Direct VPC Egress?
The service uses a **Serverless VPC Access Connector** (or Direct VPC Egress) to ensure that traffic destined for private services (like a potential Cloud SQL DB or Redis) travels over Google's private network, not the public internet.

## 3. Assumptions Made

*   **Statelessness**: The application does not store local state (files/memory) that needs to persist between requests. State is offloaded to external databases/storage.
*   **Containerization**: The application is packaged as a Docker container listening on a configurable `PORT`.
*   **Single Region**: The current Terraform deploys to a single region (`us-central1´ default).
*   **Managed Services**: Preference for fully managed Google services (Cloud SQL, Secret Manager) over self-hosted alternatives.

## 4. How to Use

### Prerequisites
*   Google Cloud Project (with Billing enabled)
*   `gcloud` CLI installed
*   Terraform >= 1.0

### Deployment
1.  **Initialize Terraform**:
    ```bash
    cd terraform
    terraform init
    ```
2.  **Plan & Apply**:
    ```bash
    terraform plan -var="project_id=YOUR_PROJECT_ID"
    terraform apply -var="project_id=YOUR_PROJECT_ID"
    ```
3.  **CI/CD**:
    Connect your repository to Cloud Build triggers pointing to `cloudbuild.yaml`.

## 5. Potential Improvements

1.  **DNS & Certificate Management**:
    *   Integrate Terraform with Cloud DNS to automatically manage A-records.
    *   Use Google-managed SSL certificates on the Load Balancer.

2.  **Multi-Region Deployment**:
    *   Deploy Cloud Run services to multiple regions (e.g., US, EU, Asia).
    *   Update the Global LB to route users to the nearest healthy region (Geo-routing).