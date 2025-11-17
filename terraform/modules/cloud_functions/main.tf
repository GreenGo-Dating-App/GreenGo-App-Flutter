/**
 * Cloud Functions Module for GreenGoChat
 * Deploys all messaging-related Cloud Functions
 */

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Local variables
locals {
  functions_bucket_name = "${var.project_id}-cloud-functions-${var.environment}"
  runtime              = var.runtime
  region               = var.region

  common_env_vars = {
    ENVIRONMENT           = var.environment
    PROJECT_ID            = var.project_id
    FIRESTORE_DATABASE    = var.firestore_database_name
    STORAGE_BUCKET        = var.storage_bucket_name
    MAX_IMAGE_SIZE_MB     = var.max_image_size_mb
    MAX_VIDEO_DURATION    = var.max_video_duration_seconds
    DISAPPEARING_TTL_HOURS = var.disappearing_media_ttl_hours
  }
}

# Cloud Storage bucket for Cloud Functions source code
resource "google_storage_bucket" "functions_bucket" {
  name     = local.functions_bucket_name
  location = var.region
  project  = var.project_id

  uniform_bucket_level_access = true

  labels = var.common_labels

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30  # Delete old function versions after 30 days
    }
  }
}

# Archive Cloud Functions source code
data "archive_file" "functions_source" {
  type        = "zip"
  source_dir  = var.functions_source_dir
  output_path = "${path.module}/.tmp/functions.zip"
  excludes    = ["node_modules", ".git", "*.log"]
}

# Upload Cloud Functions source to bucket
resource "google_storage_bucket_object" "functions_archive" {
  name   = "functions-${data.archive_file.functions_source.output_md5}.zip"
  bucket = google_storage_bucket.functions_bucket.name
  source = data.archive_file.functions_source.output_path
}

# Cloud Function: Image Compression (Point 102)
resource "google_cloudfunctions2_function" "compress_image" {
  name     = "compressUploadedImage"
  location = local.region
  project  = var.project_id

  description = "Automatically compresses uploaded images to max 2MB and generates thumbnails"

  build_config {
    runtime     = local.runtime
    entry_point = "compressUploadedImage"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 100
    min_instance_count = 0
    available_memory   = "512Mi"
    timeout_seconds    = 300

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "compressUploadedImage"
    })

    service_account_email = var.functions_service_account_email
  }

  event_trigger {
    trigger_region = local.region
    event_type     = "google.cloud.storage.object.v1.finalized"

    event_filters {
      attribute = "bucket"
      value     = var.storage_bucket_name
    }

    retry_policy = "RETRY_POLICY_RETRY"
  }

  labels = var.common_labels
}

# Cloud Function: Video Processing (Point 105)
resource "google_cloudfunctions2_function" "process_video" {
  name     = "processUploadedVideo"
  location = local.region
  project  = var.project_id

  description = "Generates video thumbnails and validates duration limits"

  build_config {
    runtime     = local.runtime
    entry_point = "processUploadedVideo"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 50
    min_instance_count = 0
    available_memory   = "2Gi"
    timeout_seconds    = 540

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "processUploadedVideo"
    })

    service_account_email = var.functions_service_account_email
  }

  event_trigger {
    trigger_region = local.region
    event_type     = "google.cloud.storage.object.v1.finalized"

    event_filters {
      attribute = "bucket"
      value     = var.storage_bucket_name
    }

    event_filters {
      attribute = "name"
      value     = "videos/*"
      operator  = "match-path-pattern"
    }

    retry_policy = "RETRY_POLICY_RETRY"
  }

  labels = var.common_labels
}

# Cloud Function: Voice Transcription (Point 107)
resource "google_cloudfunctions2_function" "transcribe_voice" {
  name     = "transcribeVoiceMessage"
  location = local.region
  project  = var.project_id

  description = "Transcribes voice messages using Cloud Speech-to-Text"

  build_config {
    runtime     = local.runtime
    entry_point = "transcribeVoiceMessage"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 50
    min_instance_count = 0
    available_memory   = "1Gi"
    timeout_seconds    = 300

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME      = "transcribeVoiceMessage"
      SUPPORTED_LANGUAGES = join(",", var.supported_languages)
    })

    service_account_email = var.functions_service_account_email
  }

  event_trigger {
    trigger_region = local.region
    event_type     = "google.cloud.storage.object.v1.finalized"

    event_filters {
      attribute = "bucket"
      value     = var.storage_bucket_name
    }

    event_filters {
      attribute = "name"
      value     = "voice/*"
      operator  = "match-path-pattern"
    }

    retry_policy = "RETRY_POLICY_RETRY"
  }

  labels = var.common_labels
}

# Cloud Function: Translate Message (Points 111-113)
resource "google_cloudfunctions2_function" "translate_message" {
  name     = "translateMessage"
  location = local.region
  project  = var.project_id

  description = "Translates messages using Cloud Translation API"

  build_config {
    runtime     = local.runtime
    entry_point = "translateMessage"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 100
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 60

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME      = "translateMessage"
      SUPPORTED_LANGUAGES = join(",", var.supported_languages)
    })

    service_account_email = var.functions_service_account_email
  }

  labels = var.common_labels
}

# Pub/Sub Topic: Scheduled Messages
resource "google_pubsub_topic" "scheduled_messages" {
  name    = "scheduled-messages-trigger"
  project = var.project_id

  labels = var.common_labels
}

# Cloud Scheduler: Send Scheduled Messages (Point 116)
resource "google_cloud_scheduler_job" "send_scheduled_messages" {
  name     = "send-scheduled-messages"
  project  = var.project_id
  region   = local.region

  description = "Triggers sending of scheduled messages every minute"
  schedule    = var.scheduled_messages_schedule
  time_zone   = "UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.scheduled_messages.id
    data       = base64encode("{\"trigger\": \"scheduled_messages\"}")
  }
}

# Cloud Function: Send Scheduled Messages
resource "google_cloudfunctions2_function" "send_scheduled_messages" {
  name     = "sendScheduledMessages"
  location = local.region
  project  = var.project_id

  description = "Sends scheduled messages at their scheduled time"

  build_config {
    runtime     = local.runtime
    entry_point = "sendScheduledMessages"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 300

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "sendScheduledMessages"
    })

    service_account_email = var.functions_service_account_email
  }

  event_trigger {
    trigger_region = local.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.scheduled_messages.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  labels = var.common_labels
}

# Pub/Sub Topic: Disappearing Media Cleanup
resource "google_pubsub_topic" "disappearing_media_cleanup" {
  name    = "disappearing-media-cleanup-trigger"
  project = var.project_id

  labels = var.common_labels
}

# Cloud Scheduler: Cleanup Disappearing Media (Point 108)
resource "google_cloud_scheduler_job" "cleanup_disappearing_media" {
  name     = "cleanup-disappearing-media"
  project  = var.project_id
  region   = local.region

  description = "Triggers cleanup of expired disappearing media hourly"
  schedule    = var.disappearing_media_schedule
  time_zone   = "UTC"

  pubsub_target {
    topic_name = google_pubsub_topic.disappearing_media_cleanup.id
    data       = base64encode("{\"trigger\": \"disappearing_media_cleanup\"}")
  }
}

# Cloud Function: Cleanup Disappearing Media
resource "google_cloudfunctions2_function" "cleanup_disappearing_media" {
  name     = "cleanupDisappearingMedia"
  location = local.region
  project  = var.project_id

  description = "Deletes media files that have expired (24 hour TTL)"

  build_config {
    runtime     = local.runtime
    entry_point = "cleanupDisappearingMedia"

    source {
      storage_source {
        bucket = google_storage_bucket.functions_bucket.name
        object = google_storage_bucket_object.functions_archive.name
      }
    }
  }

  service_config {
    max_instance_count = 5
    min_instance_count = 0
    available_memory   = "256Mi"
    timeout_seconds    = 300

    environment_variables = merge(local.common_env_vars, {
      FUNCTION_NAME = "cleanupDisappearingMedia"
    })

    service_account_email = var.functions_service_account_email
  }

  event_trigger {
    trigger_region = local.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.disappearing_media_cleanup.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }

  labels = var.common_labels
}

# IAM Policy: Allow Cloud Functions to invoke other functions
resource "google_cloudfunctions2_function_iam_member" "translate_invoker" {
  project        = var.project_id
  location       = local.region
  cloud_function = google_cloudfunctions2_function.translate_message.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${var.functions_service_account_email}"
}

# Grant Cloud Functions access to Cloud Translation API
resource "google_project_iam_member" "functions_translation_user" {
  project = var.project_id
  role    = "roles/cloudtranslate.user"
  member  = "serviceAccount:${var.functions_service_account_email}"
}

# Grant Cloud Functions access to Cloud Speech-to-Text API
resource "google_project_iam_member" "functions_speech_user" {
  project = var.project_id
  role    = "roles/speech.client"
  member  = "serviceAccount:${var.functions_service_account_email}"
}

# Grant Cloud Functions access to Cloud Storage
resource "google_project_iam_member" "functions_storage_admin" {
  project = var.project_id
  role    = "roles/storage.objectAdmin"
  member  = "serviceAccount:${var.functions_service_account_email}"
}

# Grant Cloud Functions access to Firestore
resource "google_project_iam_member" "functions_firestore_user" {
  project = var.project_id
  role    = "roles/datastore.user"
  member  = "serviceAccount:${var.functions_service_account_email}"
}
