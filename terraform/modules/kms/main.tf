# Cloud KMS Module for Encryption Key Management

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
  description = "Common labels"
  type        = map(string)
}

variable "key_ring_name" {
  description = "Name of the KMS key ring"
  type        = string
}

variable "crypto_keys" {
  description = "Map of crypto keys to create"
  type = map(object({
    name            = string
    rotation_period = string
  }))
}

# Create KMS Key Ring
resource "google_kms_key_ring" "key_ring" {
  name     = var.key_ring_name
  project  = var.project_id
  location = var.region

  count = var.use_test_environment ? 0 : 1
}

# Create Crypto Keys
resource "google_kms_crypto_key" "keys" {
  for_each = var.use_test_environment ? {} : var.crypto_keys

  name            = each.value.name
  key_ring        = google_kms_key_ring.key_ring[0].id
  rotation_period = each.value.rotation_period

  lifecycle {
    prevent_destroy = true
  }

  labels = var.common_labels
}

# Outputs
output "key_ring_id" {
  description = "KMS Key Ring ID"
  value       = var.use_test_environment ? null : google_kms_key_ring.key_ring[0].id
}

output "crypto_key_ids" {
  description = "Map of crypto key IDs"
  value = var.use_test_environment ? {} : {
    for k, v in google_kms_crypto_key.keys : k => v.id
  }
}
