/**
 * GreenGo App - Microservices Infrastructure
 * Terraform configuration for deploying 160+ Cloud Functions across 12 service domains
 */

terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }

  backend "gcs" {
    bucket = "greengo-terraform-state"
    prefix = "microservices"
  }
}

# Provider configuration
provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "firestore.googleapis.com",
    "storage.googleapis.com",
    "bigquery.googleapis.com",
    "vision.googleapis.com",
    "translate.googleapis.com",
    "speech.googleapis.com",
    "language.googleapis.com",
    "secretmanager.googleapis.com",
    "run.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}

# Cloud Storage bucket for function source code
resource "google_storage_bucket" "functions_source" {
  name     = "${var.project_id}-functions-source"
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 3
    }
    action {
      type = "Delete"
    }
  }
}

# Cloud Storage buckets for media
resource "google_storage_bucket" "media_buckets" {
  for_each = toset([
    "user-photos",
    "profile-media",
    "chat-attachments",
    "call-recordings",
    "conversation-backups",
    "pdf-exports",
  ])

  name     = "${var.project_id}-${each.key}"
  location = var.region

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }

  lifecycle_rule {
    condition {
      age = 90
      matches_prefix = ["temp/"]
    }
    action {
      type = "Delete"
    }
  }
}

# BigQuery dataset for analytics
resource "google_bigquery_dataset" "analytics" {
  dataset_id  = "greengo_analytics"
  location    = var.region
  description = "Analytics data warehouse"

  delete_contents_on_destroy = false

  access {
    role          = "OWNER"
    user_by_email = google_service_account.functions_sa.email
  }
}

# BigQuery tables
resource "google_bigquery_table" "analytics_tables" {
  for_each = {
    revenue_events      = "Revenue transactions"
    subscription_events = "Subscription lifecycle events"
    user_events         = "User behavior events"
    cohort_data         = "Cohort analysis data"
  }

  dataset_id = google_bigquery_dataset.analytics.dataset_id
  table_id   = each.key

  deletion_protection = true

  time_partitioning {
    type  = "DAY"
    field = "timestamp"
  }

  schema = file("${path.module}/schemas/${each.key}.json")
}

# Pub/Sub topics for scheduled functions
resource "google_pubsub_topic" "scheduled_topics" {
  for_each = toset([
    "cleanup-disappearing-media",
    "send-scheduled-messages",
    "check-expiring-subscriptions",
    "process-expired-coins",
    "grant-monthly-allowances",
    "update-leaderboards",
    "predict-churn-daily",
    "security-audit",
  ])

  name = each.key
}

# Service account for Cloud Functions
resource "google_service_account" "functions_sa" {
  account_id   = "greengo-functions"
  display_name = "GreenGo Cloud Functions Service Account"
}

# IAM roles for service account
resource "google_project_iam_member" "functions_permissions" {
  for_each = toset([
    "roles/datastore.user",
    "roles/storage.admin",
    "roles/bigquery.dataEditor",
    "roles/cloudscheduler.admin",
    "roles/pubsub.publisher",
    "roles/secretmanager.secretAccessor",
    "roles/cloudtranslate.user",
    "roles/cloudspeech.client",
    "roles/vision.user",
    "roles/language.user",
  ])

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.functions_sa.email}"
}

# Secret Manager secrets
resource "google_secret_manager_secret" "secrets" {
  for_each = toset([
    "sendgrid-api-key",
    "twilio-auth-token",
    "stripe-secret-key",
    "agora-app-id",
    "agora-app-certificate",
  ])

  secret_id = each.key

  replication {
    auto {}
  }
}

# Microservices modules
module "media_processing" {
  source = "./modules/media-processing"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  media_bucket       = google_storage_bucket.media_buckets["user-photos"].name
  depends_on_apis    = google_project_service.required_apis
}

module "messaging" {
  source = "./modules/messaging"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  scheduled_topic    = google_pubsub_topic.scheduled_topics["send-scheduled-messages"].name
  depends_on_apis    = google_project_service.required_apis
}

module "backup_export" {
  source = "./modules/backup-export"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  backup_bucket      = google_storage_bucket.media_buckets["conversation-backups"].name
  export_bucket      = google_storage_bucket.media_buckets["pdf-exports"].name
  depends_on_apis    = google_project_service.required_apis
}

module "subscription" {
  source = "./modules/subscription"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  expiring_topic     = google_pubsub_topic.scheduled_topics["check-expiring-subscriptions"].name
  depends_on_apis    = google_project_service.required_apis
}

module "coin_service" {
  source = "./modules/coin-service"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  allowance_topic    = google_pubsub_topic.scheduled_topics["grant-monthly-allowances"].name
  expiration_topic   = google_pubsub_topic.scheduled_topics["process-expired-coins"].name
  depends_on_apis    = google_project_service.required_apis
}

module "analytics" {
  source = "./modules/analytics"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  bigquery_dataset   = google_bigquery_dataset.analytics.dataset_id
  churn_topic        = google_pubsub_topic.scheduled_topics["predict-churn-daily"].name
  depends_on_apis    = google_project_service.required_apis
}

module "gamification" {
  source = "./modules/gamification"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  leaderboard_topic  = google_pubsub_topic.scheduled_topics["update-leaderboards"].name
  depends_on_apis    = google_project_service.required_apis
}

module "safety_moderation" {
  source = "./modules/safety-moderation"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  depends_on_apis    = google_project_service.required_apis
}

module "admin" {
  source = "./modules/admin"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  depends_on_apis    = google_project_service.required_apis
}

module "notification" {
  source = "./modules/notification"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  sendgrid_secret    = google_secret_manager_secret.secrets["sendgrid-api-key"].secret_id
  twilio_secret      = google_secret_manager_secret.secrets["twilio-auth-token"].secret_id
  depends_on_apis    = google_project_service.required_apis
}

module "video_calling" {
  source = "./modules/video-calling"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  recording_bucket   = google_storage_bucket.media_buckets["call-recordings"].name
  agora_app_id       = google_secret_manager_secret.secrets["agora-app-id"].secret_id
  agora_certificate  = google_secret_manager_secret.secrets["agora-app-certificate"].secret_id
  depends_on_apis    = google_project_service.required_apis
}

module "security" {
  source = "./modules/security"

  project_id         = var.project_id
  region             = var.region
  service_account    = google_service_account.functions_sa.email
  source_bucket      = google_storage_bucket.functions_source.name
  audit_topic        = google_pubsub_topic.scheduled_topics["security-audit"].name
  depends_on_apis    = google_project_service.required_apis
}

# Cloud Scheduler jobs
resource "google_cloud_scheduler_job" "scheduled_jobs" {
  for_each = {
    cleanup_media        = { schedule = "0 * * * *", topic = "cleanup-disappearing-media" }
    send_messages        = { schedule = "* * * * *", topic = "send-scheduled-messages" }
    check_subscriptions  = { schedule = "0 9 * * *", topic = "check-expiring-subscriptions" }
    process_coins        = { schedule = "0 2 * * *", topic = "process-expired-coins" }
    grant_allowances     = { schedule = "0 0 1 * *", topic = "grant-monthly-allowances" }
    update_leaderboards  = { schedule = "0 * * * *", topic = "update-leaderboards" }
    predict_churn        = { schedule = "0 3 * * *", topic = "predict-churn-daily" }
    security_audit       = { schedule = "0 4 * * *", topic = "security-audit" }
  }

  name             = each.key
  schedule         = each.value.schedule
  time_zone        = "UTC"
  attempt_deadline = "320s"

  pubsub_target {
    topic_name = google_pubsub_topic.scheduled_topics[each.value.topic].id
    data       = base64encode(jsonencode({ trigger = "scheduler" }))
  }
}
