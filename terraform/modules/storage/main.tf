# Cloud Storage Buckets Module

variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "use_test_environment" {
  description = "Whether to use test environment"
  type        = bool
}

variable "common_labels" {
  description = "Common labels to apply to all resources"
  type        = map(string)
}

variable "buckets" {
  description = "Map of bucket configurations"
  type = map(object({
    name                     = string
    location                 = string
    storage_class            = string
    versioning_enabled       = bool
    lifecycle_age_days       = number
    cors_enabled             = bool
    uniform_bucket_level_access = bool
  }))
}

# Create Cloud Storage Buckets
resource "google_storage_bucket" "buckets" {
  for_each = var.buckets

  name          = each.value.name
  project       = var.project_id
  location      = each.value.location
  storage_class = each.value.storage_class
  labels        = var.common_labels

  uniform_bucket_level_access = each.value.uniform_bucket_level_access

  versioning {
    enabled = each.value.versioning_enabled
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = each.value.lifecycle_age_days != null ? [1] : []
    content {
      condition {
        age = each.value.lifecycle_age_days
      }
      action {
        type = "Delete"
      }
    }
  }

  # CORS configuration
  dynamic "cors" {
    for_each = each.value.cors_enabled ? [1] : []
    content {
      origin          = ["*"]
      method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      response_header = ["*"]
      max_age_seconds = 3600
    }
  }

  # Force destroy (only for non-production)
  force_destroy = var.environment != "production"

  count = var.use_test_environment ? 0 : 1
}

# Outputs
output "bucket_names" {
  description = "Map of bucket names"
  value = var.use_test_environment ? {} : {
    for k, v in google_storage_bucket.buckets : k => v.name
  }
}

output "bucket_urls" {
  description = "Map of bucket URLs"
  value = var.use_test_environment ? {} : {
    for k, v in google_storage_bucket.buckets : k => v.url
  }
}
