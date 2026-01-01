# Monitoring Dashboard
resource "google_monitoring_dashboard" "cloud_run_dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "${var.service_name} Dashboard",
  "gridLayout": {
    "widgets": [
      {
        "title": "Cloud Run Request Count",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_count\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_RATE"
                }
              }
            }
          }]
        }
      },
      {
        "title": "Cloud Run Latency (p95)",
        "xyChart": {
          "dataSets": [{
            "timeSeriesQuery": {
              "timeSeriesFilter": {
                "filter": "resource.type=\"cloud_run_revision\" resource.label.\"service_name\"=\"${var.service_name}\" metric.type=\"run.googleapis.com/request_latencies\"",
                "aggregation": {
                  "perSeriesAligner": "ALIGN_PERCENTILE_95"
                }
              }
            }
          }]
        }
      }
    ]
  }
}
EOF
}

# Alert Policy: High Error Rate
resource "google_monitoring_alert_policy" "high_error_rate" {
  display_name = "${var.service_name} High Error Rate"
  combiner     = "OR"
  conditions {
    display_name = "Error Rate > 5%"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND resource.label.service_name = \"${var.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.label.response_code_class = \"5xx\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
      threshold_value = 0.05
    }
  }
}
