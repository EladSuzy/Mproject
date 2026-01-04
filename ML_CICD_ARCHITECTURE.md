# ML Inference CI/CD Architecture: Cloud vs. Edge

This document outlines the CI/CD processes for web services that perform ML inference. This design assumes the model is already trained and focuses solely on the delivery and orchestration of the inference service.

---

## 1. Case 1: Inference at the Edge
In this scenario, a pre-trained model is bundled or deployed alongside a web service to edge devices for local, low-latency execution.

### Architecture Diagram (Edge Inference)

```mermaid
graph TD
    subgraph "Cloud / Central Environment"
        Code[Web Service Code] -->|Push| CI[CI Pipeline - Cloud Build]
        Model[(Pre-trained Model Pool)] --> CI
        CI -->|Build & Package| Container[Service + Model Container]
        Container -->|Store| AR[Artifact Registry]
    end

    subgraph "Edge Fleet Management"
        AR -->|Sync| Manager[Edge Orchestrator - e.g. Anthos]
        Manager -->|OTA Update| Devices
    end

    subgraph "Edge Devices"
        Devices[Edge Gateway / Device]
        Devices -->|Run| App[Web Service - Flask/FastAPI]
        App -->|Inference Query| ModelFile[Local Model File]
    end

    User([Local Sensors/Users]) --> App
```

---

## 2. Case 2: Inference in the Cloud (GCP)
A centralized cloud environment where the web service runs in a managed environment and queries a model stored in a registry or hosted on a managed endpoint.

### Architecture Diagram (Cloud Inference)

```mermaid
graph TD
    subgraph "CI/CD Pipeline"
        Code[Web Service Code] -->|Push| CI[Cloud Build]
        CI -->|Test & Build| AR[Artifact Registry]
    end

    subgraph "GCP Serving Environment"
        AR -->|Deploy| CD[Google Cloud Deploy]
        CD -->|Blue-Green| CR[Cloud Run / GKE]
        
        CR -->|Ask Model| Vertex["Vertex AI Prediction Endpoint / Model Registry"]
        LB[Load Balancer] --> CR
    end

    subgraph "Observability"
        CR -->|Log Inferences| Log[Cloud Logging]
        CR -->|Monitor Latency| Mon[Cloud Monitoring]
    end

    User([External Users]) --> LB
```

---

## 3. Key Design Choices for Inference-Only

| Feature | Edge Inference | Cloud Inference (GCP) |
| :--- | :--- | :--- |
| **Model Delivery** | Pre-packaged in container or side-loaded. | Fetched at runtime or via managed endpoint. |
| **Network Dependency** | Zero requirement for inference. | Required for API calls/Model fetch. |
| **Updates** | Batch / Periodic sync. | Instant (Canary/Blue-Green). |
| **Scaling** | Limited by device hardware. | Highly elastic (Autoscaling). |

## 4. Operational Best Practices
1.  **Model Versioning**: Ensure the web service code is explicitly tied to a specific model version in the `config` or `environment variables`.
2.  **Health Checks**: Implement custom logic to ensure the model is loaded and "warm" before the service reports healthy.
3.  **Inference Logging**: Even without training, log the inputs/outputs to detect when the model might need a manual trigger for re-evaluation.
