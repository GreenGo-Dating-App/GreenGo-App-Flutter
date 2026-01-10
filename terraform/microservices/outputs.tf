output "functions_service_account" {
  description = "Service account email for Cloud Functions"
  value       = google_service_account.functions_sa.email
}

output "media_buckets" {
  description = "Cloud Storage buckets for media"
  value = {
    for k, v in google_storage_bucket.media_buckets : k => v.name
  }
}

output "bigquery_dataset" {
  description = "BigQuery dataset for analytics"
  value       = google_bigquery_dataset.analytics.dataset_id
}

output "pubsub_topics" {
  description = "Pub/Sub topics for scheduled functions"
  value = {
    for k, v in google_pubsub_topic.scheduled_topics : k => v.name
  }
}
