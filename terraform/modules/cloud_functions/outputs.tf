/**
 * Cloud Functions Module Outputs
 */

output "functions_bucket_name" {
  description = "Name of the Cloud Functions source bucket"
  value       = google_storage_bucket.functions_bucket.name
}

output "compress_image_function_name" {
  description = "Name of the image compression function"
  value       = google_cloudfunctions2_function.compress_image.name
}

output "compress_image_function_url" {
  description = "URL of the image compression function"
  value       = google_cloudfunctions2_function.compress_image.service_config[0].uri
}

output "process_video_function_name" {
  description = "Name of the video processing function"
  value       = google_cloudfunctions2_function.process_video.name
}

output "process_video_function_url" {
  description = "URL of the video processing function"
  value       = google_cloudfunctions2_function.process_video.service_config[0].uri
}

output "transcribe_voice_function_name" {
  description = "Name of the voice transcription function"
  value       = google_cloudfunctions2_function.transcribe_voice.name
}

output "transcribe_voice_function_url" {
  description = "URL of the voice transcription function"
  value       = google_cloudfunctions2_function.transcribe_voice.service_config[0].uri
}

output "translate_message_function_name" {
  description = "Name of the message translation function"
  value       = google_cloudfunctions2_function.translate_message.name
}

output "translate_message_function_url" {
  description = "URL of the message translation function"
  value       = google_cloudfunctions2_function.translate_message.service_config[0].uri
}

output "send_scheduled_messages_function_name" {
  description = "Name of the scheduled messages function"
  value       = google_cloudfunctions2_function.send_scheduled_messages.name
}

output "cleanup_disappearing_media_function_name" {
  description = "Name of the disappearing media cleanup function"
  value       = google_cloudfunctions2_function.cleanup_disappearing_media.name
}

output "scheduler_jobs" {
  description = "Cloud Scheduler job names"
  value = {
    scheduled_messages    = google_cloud_scheduler_job.send_scheduled_messages.name
    disappearing_media    = google_cloud_scheduler_job.cleanup_disappearing_media.name
  }
}

output "pubsub_topics" {
  description = "Pub/Sub topic names"
  value = {
    scheduled_messages    = google_pubsub_topic.scheduled_messages.name
    disappearing_media    = google_pubsub_topic.disappearing_media_cleanup.name
  }
}
