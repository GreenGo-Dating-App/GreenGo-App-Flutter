/**
 * Media Processing Service Terraform Module
 * Deploys 10 Cloud Functions for media processing
 */

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "service_account" {
  description = "Service account email for functions"
  type        = string
}

variable "source_bucket" {
  description = "Bucket for function source code"
  type        = string
}

variable "media_bucket" {
  description = "Bucket for media files"
  type        = string
}

variable "depends_on_apis" {
  description = "API dependencies"
  type        = any
}

# Storage bucket for compressed images
resource "google_storage_bucket" "compressed_images" {
  name     = "${var.project_id}-compressed-images"
  location = var.region

  uniform_bucket_level_access = true
}

# 1. Compress Uploaded Image (Storage Trigger)
resource "google_cloudfunctions2_function" "compress_uploaded_image" {
  name     = "compressUploadedImage"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "compressUploadedImage"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 100
    available_memory      = "512Mi"
    timeout_seconds       = 300
    service_account_email = var.service_account

    environment_variables = {
      PROJECT_ID    = var.project_id
      MEDIA_BUCKET  = var.media_bucket
    }
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY"

    event_filters {
      attribute = "bucket"
      value     = var.media_bucket
    }
  }

  depends_on = [var.depends_on_apis]
}

# 2. Compress Image (HTTP Callable)
resource "google_cloudfunctions2_function" "compress_image" {
  name     = "compressImage"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "compressImage"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 50
    available_memory      = "512Mi"
    timeout_seconds       = 300
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

# 3. Process Uploaded Video (Storage Trigger)
resource "google_cloudfunctions2_function" "process_uploaded_video" {
  name     = "processUploadedVideo"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "processUploadedVideo"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 50
    available_memory      = "2Gi"
    timeout_seconds       = 540
    service_account_email = var.service_account
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY"

    event_filters {
      attribute = "bucket"
      value     = "${var.project_id}-profile-media"
    }
  }

  depends_on = [var.depends_on_apis]
}

# 4. Generate Video Thumbnail (HTTP Callable)
resource "google_cloudfunctions2_function" "generate_video_thumbnail" {
  name     = "generateVideoThumbnail"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "generateVideoThumbnail"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 25
    available_memory      = "2Gi"
    timeout_seconds       = 540
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

# 5. Transcribe Voice Message (Storage Trigger)
resource "google_cloudfunctions2_function" "transcribe_voice_message" {
  name     = "transcribeVoiceMessage"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "transcribeVoiceMessage"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 50
    available_memory      = "1Gi"
    timeout_seconds       = 300
    service_account_email = var.service_account
  }

  event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.storage.object.v1.finalized"
    retry_policy   = "RETRY_POLICY_RETRY"

    event_filters {
      attribute = "bucket"
      value     = "${var.project_id}-chat-attachments"
    }
  }

  depends_on = [var.depends_on_apis]
}

# 6-7. Transcribe Audio Functions (HTTP Callable)
resource "google_cloudfunctions2_function" "transcribe_audio" {
  name     = "transcribeAudio"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "transcribeAudio"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 25
    available_memory      = "1Gi"
    timeout_seconds       = 300
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

resource "google_cloudfunctions2_function" "batch_transcribe" {
  name     = "batchTranscribe"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "batchTranscribe"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 10
    available_memory      = "1Gi"
    timeout_seconds       = 540
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

# 8. Cleanup Disappearing Media (Scheduled)
resource "google_cloudfunctions2_function" "cleanup_disappearing_media" {
  name     = "cleanupDisappearingMedia"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "cleanupDisappearingMedia"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "256Mi"
    timeout_seconds       = 300
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

# 9. Mark Media as Disappearing (HTTP Callable)
resource "google_cloudfunctions2_function" "mark_media_as_disappearing" {
  name     = "markMediaAsDisappearing"
  location = var.region

  build_config {
    runtime     = "nodejs18"
    entry_point = "markMediaAsDisappearing"

    source {
      storage_source {
        bucket = var.source_bucket
        object = "media-processing-${filemd5("${path.module}/../../../functions/src/media/index.ts")}.zip"
      }
    }
  }

  service_config {
    max_instance_count    = 50
    available_memory      = "256Mi"
    timeout_seconds       = 60
    service_account_email = var.service_account
  }

  depends_on = [var.depends_on_apis]
}

# Outputs
output "function_names" {
  description = "Deployed function names"
  value = [
    google_cloudfunctions2_function.compress_uploaded_image.name,
    google_cloudfunctions2_function.compress_image.name,
    google_cloudfunctions2_function.process_uploaded_video.name,
    google_cloudfunctions2_function.generate_video_thumbnail.name,
    google_cloudfunctions2_function.transcribe_voice_message.name,
    google_cloudfunctions2_function.transcribe_audio.name,
    google_cloudfunctions2_function.batch_transcribe.name,
    google_cloudfunctions2_function.cleanup_disappearing_media.name,
    google_cloudfunctions2_function.mark_media_as_disappearing.name,
  ]
}
