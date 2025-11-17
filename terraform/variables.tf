# Terraform Variables for GreenGoChat Infrastructure

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "greengo-chat"
}

variable "environment" {
  description = "Environment name (development, staging, production)"
  type        = string

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

variable "gcp_project_id" {
  description = "GCP Project ID for production environment"
  type        = string
}

variable "test_project_id" {
  description = "GCP Project ID for test/emulated environment"
  type        = string
  default     = "test-greengo-chat"
}

variable "use_test_environment" {
  description = "Whether to use test/emulated environment instead of real GCP"
  type        = bool
  default     = false
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "multi_region" {
  description = "Whether to use multi-region configuration for Firestore"
  type        = bool
  default     = false
}

# Emulator Configuration
variable "firestore_emulator_host" {
  description = "Firestore emulator host (e.g., localhost:8080)"
  type        = string
  default     = null
}

variable "storage_emulator_host" {
  description = "Cloud Storage emulator host (e.g., localhost:9023)"
  type        = string
  default     = null
}

variable "pubsub_emulator_host" {
  description = "Pub/Sub emulator host (e.g., localhost:8085)"
  type        = string
  default     = null
}

# Alert Configuration
variable "alert_notification_email" {
  description = "Email address for alert notifications"
  type        = string
}

# Backup Configuration
variable "enable_automated_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 30
}

# Cost Management
variable "enable_cost_alerts" {
  description = "Enable cost alerts"
  type        = bool
  default     = true
}

variable "monthly_budget_amount" {
  description = "Monthly budget amount in USD"
  type        = number
  default     = 2000
}

# Security
variable "enable_vpc_service_controls" {
  description = "Enable VPC Service Controls"
  type        = bool
  default     = false
}

variable "enable_binary_authorization" {
  description = "Enable Binary Authorization for container images"
  type        = bool
  default     = false
}
