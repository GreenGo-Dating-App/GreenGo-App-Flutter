/**
 * Cloud Functions Module Variables
 */

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Functions"
  type        = string
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string
}

variable "runtime" {
  description = "Node.js runtime version"
  type        = string
  default     = "nodejs18"
}

variable "functions_source_dir" {
  description = "Path to Cloud Functions source code directory"
  type        = string
}

variable "firestore_database_name" {
  description = "Firestore database name"
  type        = string
}

variable "storage_bucket_name" {
  description = "Cloud Storage bucket name for media uploads"
  type        = string
}

variable "functions_service_account_email" {
  description = "Service account email for Cloud Functions"
  type        = string
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "max_image_size_mb" {
  description = "Maximum image size in MB after compression"
  type        = number
  default     = 2
}

variable "max_video_duration_seconds" {
  description = "Maximum video duration in seconds"
  type        = number
  default     = 60
}

variable "disappearing_media_ttl_hours" {
  description = "Time to live for disappearing media in hours"
  type        = number
  default     = 24
}

variable "scheduled_messages_schedule" {
  description = "Cron schedule for sending scheduled messages"
  type        = string
  default     = "every 1 minutes"
}

variable "disappearing_media_schedule" {
  description = "Cron schedule for cleaning up disappearing media"
  type        = string
  default     = "every 1 hours"
}

variable "supported_languages" {
  description = "List of supported translation languages"
  type        = list(string)
  default     = ["en", "es", "fr", "de", "pt", "it", "ja", "ko", "zh"]
}
