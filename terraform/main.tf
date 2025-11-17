# GreenGoChat Infrastructure as Code
# Supports Google Cloud Platform and Test/Emulated environments

terraform {
  required_version = ">= 1.5.0"

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
    # This will be configured per environment
    # bucket  = "greengo-chat-terraform-state"
    # prefix  = "terraform/state"
  }
}

# Local variables
locals {
  project_name = var.project_name
  environment  = var.environment
  region       = var.region
  zone         = var.zone

  # Common labels
  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
    application = "greengo-chat"
  }

  # Service account names
  app_service_account      = "${local.project_name}-app-sa"
  functions_service_account = "${local.project_name}-functions-sa"
  storage_service_account  = "${local.project_name}-storage-sa"

  # Storage bucket names
  user_photos_bucket      = "${local.project_name}-user-photos-${local.environment}"
  profile_media_bucket    = "${local.project_name}-profile-media-${local.environment}"
  chat_attachments_bucket = "${local.project_name}-chat-attachments-${local.environment}"
  backups_bucket          = "${local.project_name}-backups-${local.environment}"
  terraform_state_bucket  = "${local.project_name}-terraform-state-${local.environment}"

  # Firestore settings
  firestore_location = var.use_test_environment ? "us-central" : var.multi_region ? "nam5" : "us-central1"
}

# Provider configuration
provider "google" {
  project = var.use_test_environment ? var.test_project_id : var.gcp_project_id
  region  = local.region

  # Use emulator URLs when in test mode
  firestore_custom_endpoint = var.use_test_environment ? var.firestore_emulator_host : null
  storage_custom_endpoint   = var.use_test_environment ? var.storage_emulator_host : null
}

provider "google-beta" {
  project = var.use_test_environment ? var.test_project_id : var.gcp_project_id
  region  = local.region

  # Use emulator URLs when in test mode
  firestore_custom_endpoint = var.use_test_environment ? var.firestore_emulator_host : null
  storage_custom_endpoint   = var.use_test_environment ? var.storage_emulator_host : null
}

# Data source for project
data "google_project" "project" {
  project_id = var.use_test_environment ? var.test_project_id : var.gcp_project_id
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "firestore.googleapis.com",
    "storage-api.googleapis.com",
    "cloudfunctions.googleapis.com",
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "pubsub.googleapis.com",
    "vision.googleapis.com",
    "translate.googleapis.com",
    "speech.googleapis.com",
    "texttospeech.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "aiplatform.googleapis.com",
    "bigquery.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "clouderrorreporting.googleapis.com",
  ])

  project = data.google_project.project.project_id
  service = each.value

  disable_on_destroy = false

  # Skip API enablement in test environment
  count = var.use_test_environment ? 0 : 1
}

# Firestore Database
resource "google_firestore_database" "database" {
  provider = google-beta

  project     = data.google_project.project.project_id
  name        = var.use_test_environment ? "test-database" : "(default)"
  location_id = local.firestore_location
  type        = var.use_test_environment ? "DATASTORE_MODE" : "FIRESTORE_NATIVE"

  # Concurrency mode
  concurrency_mode = "OPTIMISTIC"

  # App Engine integration
  app_engine_integration_mode = "DISABLED"

  # Point in time recovery
  point_in_time_recovery_enablement = var.use_test_environment ? "POINT_IN_TIME_RECOVERY_DISABLED" : "POINT_IN_TIME_RECOVERY_ENABLED"

  # Delete protection
  delete_protection_state = var.environment == "production" && !var.use_test_environment ? "DELETE_PROTECTION_ENABLED" : "DELETE_PROTECTION_DISABLED"

  depends_on = [google_project_service.required_apis]
}

# Cloud Storage Buckets
module "storage_buckets" {
  source = "./modules/storage"

  project_id          = data.google_project.project.project_id
  region              = local.region
  environment         = local.environment
  use_test_environment = var.use_test_environment
  common_labels       = local.common_labels

  # Bucket configurations
  buckets = {
    user_photos = {
      name                     = local.user_photos_bucket
      location                 = local.region
      storage_class            = "STANDARD"
      versioning_enabled       = true
      lifecycle_age_days       = 30  # Delete unverified photos after 30 days
      cors_enabled             = true
      uniform_bucket_level_access = true
    }
    profile_media = {
      name                     = local.profile_media_bucket
      location                 = local.region
      storage_class            = "STANDARD"
      versioning_enabled       = true
      lifecycle_age_days       = null  # Persistent storage
      cors_enabled             = true
      uniform_bucket_level_access = true
    }
    chat_attachments = {
      name                     = local.chat_attachments_bucket
      location                 = local.region
      storage_class            = "STANDARD"
      versioning_enabled       = true
      lifecycle_age_days       = 90  # Delete after 90 days
      cors_enabled             = true
      uniform_bucket_level_access = true
    }
    backups = {
      name                     = local.backups_bucket
      location                 = local.region
      storage_class            = "NEARLINE"
      versioning_enabled       = true
      lifecycle_age_days       = 365  # Keep backups for 1 year
      cors_enabled             = false
      uniform_bucket_level_access = true
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Cloud KMS for encryption
module "kms" {
  source = "./modules/kms"

  project_id        = data.google_project.project.project_id
  region            = local.region
  environment       = local.environment
  use_test_environment = var.use_test_environment
  common_labels     = local.common_labels

  # Key ring name
  key_ring_name = "${local.project_name}-keyring-${local.environment}"

  # Crypto keys
  crypto_keys = {
    user_data = {
      name            = "user-data-key"
      rotation_period = "7776000s"  # 90 days
    }
    photos = {
      name            = "photos-key"
      rotation_period = "7776000s"
    }
    messages = {
      name            = "messages-key"
      rotation_period = "2592000s"  # 30 days
    }
  }

  depends_on = [google_project_service.required_apis]
}

# Service Accounts
resource "google_service_account" "app_service_account" {
  account_id   = local.app_service_account
  display_name = "GreenGoChat App Service Account"
  description  = "Service account for GreenGoChat application"
  project      = data.google_project.project.project_id

  count = var.use_test_environment ? 0 : 1
}

resource "google_service_account" "functions_service_account" {
  account_id   = local.functions_service_account
  display_name = "GreenGoChat Cloud Functions Service Account"
  description  = "Service account for Cloud Functions"
  project      = data.google_project.project.project_id

  count = var.use_test_environment ? 0 : 1
}

resource "google_service_account" "storage_service_account" {
  account_id   = local.storage_service_account
  display_name = "GreenGoChat Storage Service Account"
  description  = "Service account for Cloud Storage operations"
  project      = data.google_project.project.project_id

  count = var.use_test_environment ? 0 : 1
}

# IAM Role Bindings
resource "google_project_iam_member" "app_firestore_user" {
  project = data.google_project.project.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${google_service_account.app_service_account[0].email}"

  count = var.use_test_environment ? 0 : 1
}

resource "google_project_iam_member" "app_storage_object_admin" {
  project = data.google_project.project.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${google_service_account.app_service_account[0].email}"

  count = var.use_test_environment ? 0 : 1
}

resource "google_project_iam_member" "functions_cloudkms_user" {
  project = data.google_project.project.project_id
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${google_service_account.functions_service_account[0].email}"

  count = var.use_test_environment ? 0 : 1
}

# Cloud CDN
module "cdn" {
  source = "./modules/cdn"

  project_id          = data.google_project.project.project_id
  region              = local.region
  environment         = local.environment
  use_test_environment = var.use_test_environment

  # Backend bucket for CDN
  backend_bucket_name = local.profile_media_bucket

  depends_on = [
    module.storage_buckets,
    google_project_service.required_apis
  ]
}

# VPC Network
module "network" {
  source = "./modules/network"

  project_id          = data.google_project.project.project_id
  region              = local.region
  environment         = local.environment
  use_test_environment = var.use_test_environment
  common_labels       = local.common_labels

  # Network configuration
  network_name = "${local.project_name}-network-${local.environment}"
  subnet_name  = "${local.project_name}-subnet-${local.environment}"
  subnet_cidr  = "10.0.0.0/24"

  depends_on = [google_project_service.required_apis]
}

# Pub/Sub Topics for Event-Driven Architecture
module "pubsub" {
  source = "./modules/pubsub"

  project_id          = data.google_project.project.project_id
  environment         = local.environment
  use_test_environment = var.use_test_environment
  common_labels       = local.common_labels

  topics = {
    user_registered = {
      name = "user-registered"
    }
    profile_created = {
      name = "profile-created"
    }
    photo_uploaded = {
      name = "photo-uploaded"
    }
    match_created = {
      name = "match-created"
    }
    message_sent = {
      name = "message-sent"
    }
    payment_completed = {
      name = "payment-completed"
    }
  }

  depends_on = [google_project_service.required_apis]
}

# BigQuery for Analytics
module "bigquery" {
  source = "./modules/bigquery"

  project_id          = data.google_project.project.project_id
  region              = local.region
  environment         = local.environment
  use_test_environment = var.use_test_environment
  common_labels       = local.common_labels

  # Dataset configuration
  dataset_id          = "greengo_analytics"
  dataset_description = "Analytics data for GreenGoChat"

  depends_on = [google_project_service.required_apis]
}

# Monitoring and Alerting
module "monitoring" {
  source = "./modules/monitoring"

  project_id          = data.google_project.project.project_id
  environment         = local.environment
  use_test_environment = var.use_test_environment

  # Alert notification channels
  notification_email = var.alert_notification_email

  depends_on = [google_project_service.required_apis]
}

# Cloud Functions for Messaging Features
module "cloud_functions" {
  source = "./modules/cloud_functions"

  project_id          = data.google_project.project.project_id
  region              = local.region
  environment         = local.environment
  runtime             = "nodejs18"

  # Source code directory
  functions_source_dir = "${path.root}/../functions"

  # Configuration
  firestore_database_name          = google_firestore_database.database.name
  storage_bucket_name              = local.chat_attachments_bucket
  functions_service_account_email  = google_service_account.functions_service_account[0].email

  # Settings
  max_image_size_mb            = 2
  max_video_duration_seconds   = 60
  disappearing_media_ttl_hours = 24
  scheduled_messages_schedule  = "every 1 minutes"
  disappearing_media_schedule  = "every 1 hours"
  supported_languages          = ["en", "es", "fr", "de", "pt", "it", "ja", "ko", "zh"]

  common_labels = local.common_labels

  depends_on = [
    google_project_service.required_apis,
    google_service_account.functions_service_account,
    module.storage_buckets
  ]

  count = var.use_test_environment ? 0 : 1
}

# Outputs
output "project_id" {
  description = "The project ID"
  value       = data.google_project.project.project_id
}

output "firestore_database_name" {
  description = "Firestore database name"
  value       = google_firestore_database.database.name
}

output "storage_buckets" {
  description = "Cloud Storage bucket names"
  value       = module.storage_buckets.bucket_names
}

output "service_accounts" {
  description = "Service account emails"
  value = var.use_test_environment ? {} : {
    app      = google_service_account.app_service_account[0].email
    functions = google_service_account.functions_service_account[0].email
    storage  = google_service_account.storage_service_account[0].email
  }
}

output "cdn_ip_address" {
  description = "CDN IP address"
  value       = module.cdn.ip_address
}

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value       = module.pubsub.topic_names
}

output "cloud_functions" {
  description = "Cloud Functions information"
  value = var.use_test_environment ? {} : {
    compress_image_url      = module.cloud_functions[0].compress_image_function_url
    process_video_url       = module.cloud_functions[0].process_video_function_url
    transcribe_voice_url    = module.cloud_functions[0].transcribe_voice_function_url
    translate_message_url   = module.cloud_functions[0].translate_message_function_url
    scheduler_jobs          = module.cloud_functions[0].scheduler_jobs
    messaging_pubsub_topics = module.cloud_functions[0].pubsub_topics
  }
}
