# GreenGoChat Deployment Guide

This guide covers deploying the complete GreenGoChat backend infrastructure using Terraform and Firebase Cloud Functions.

## Prerequisites

### Required Tools
- [Node.js](https://nodejs.org/) v18 or higher
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`
- [Terraform](https://www.terraform.io/downloads) v1.5.0 or higher
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install): `gcloud` CLI
- Git

### Required Accounts
- Google Cloud Platform account
- Firebase project created
- Billing enabled on GCP project

## Step 1: Initial Setup

### 1.1 Clone Repository
```bash
git clone <your-repo-url>
cd "GreenGo App"
```

### 1.2 Install Cloud Functions Dependencies
```bash
cd functions
npm install
```

Required packages will be installed:
- `firebase-functions`
- `firebase-admin`
- `@google-cloud/storage`
- `@google-cloud/speech`
- `@google-cloud/translate`
- `sharp` (image processing)
- `fluent-ffmpeg` (video processing)
- `pdfkit` (PDF generation)

### 1.3 Authenticate with Google Cloud
```bash
# Login to Google Cloud
gcloud auth login

# Set your project ID
gcloud config set project YOUR_PROJECT_ID

# Login to Firebase
firebase login
```

## Step 2: Configure Terraform

### 2.1 Create terraform.tfvars
```bash
cd ../terraform
cp terraform.tfvars.example terraform.tfvars
```

### 2.2 Edit terraform.tfvars
```hcl
# Project Configuration
project_name   = "greengo-chat"
environment    = "production"  # Options: development, staging, production
gcp_project_id = "your-actual-gcp-project-id"

# Region Configuration
region       = "us-central1"
zone         = "us-central1-a"
multi_region = false  # Set to true for production multi-region deployment

# Alerts and Monitoring
alert_notification_email = "your-email@example.com"

# Backup Configuration
enable_automated_backups = true
backup_retention_days    = 30

# Cost Management
enable_cost_alerts    = true
monthly_budget_amount = 2000  # USD
```

### 2.3 Initialize Terraform
```bash
terraform init
```

This will:
- Download required providers (Google Cloud)
- Initialize backend
- Set up modules

## Step 3: Deploy Infrastructure with Terraform

### 3.1 Review Deployment Plan
```bash
terraform plan
```

This shows what will be created:
- Firestore database
- Cloud Storage buckets (4 buckets)
- Cloud Functions (6 functions)
- Cloud Scheduler jobs (2 jobs)
- Pub/Sub topics (2 topics)
- Service accounts (3 accounts)
- IAM permissions
- KMS encryption keys

### 3.2 Apply Terraform Configuration
```bash
terraform apply
```

Type `yes` when prompted to confirm.

**Expected Duration:** 5-10 minutes

### 3.3 Verify Deployment
```bash
terraform output
```

You should see:
```
project_id = "your-project-id"
firestore_database_name = "(default)"
storage_buckets = {
  "chat_attachments" = "greengo-chat-chat-attachments-production"
  "backups" = "greengo-chat-backups-production"
  ...
}
cloud_functions = {
  "compress_image_url" = "https://..."
  ...
}
```

## Step 4: Deploy Cloud Functions

### 4.1 Build TypeScript Functions
```bash
cd ../functions
npm run build
```

### 4.2 Deploy All Functions
```bash
firebase deploy --only functions
```

This deploys:
1. `compressUploadedImage` - Image compression
2. `processUploadedVideo` - Video thumbnail generation
3. `transcribeVoiceMessage` - Voice transcription
4. `translateMessage` - Message translation
5. `sendScheduledMessages` - Scheduled message delivery
6. `cleanupDisappearingMedia` - Media cleanup
7. `backupConversation` - Conversation backup
8. `restoreConversation` - Backup restoration
9. `exportConversationToPDF` - PDF export
10. Auto-translate and batch functions

**Expected Duration:** 3-5 minutes per function

### 4.3 Verify Functions
```bash
firebase functions:list
```

## Step 5: Configure Firestore Security Rules

### 5.1 Deploy Firestore Rules
```bash
firebase deploy --only firestore:rules
```

### 5.2 Deploy Firestore Indexes
```bash
firebase deploy --only firestore:indexes
```

This creates indexes for:
- Notifications (userId + isRead + createdAt)
- Messages (conversationId + sentAt)
- Scheduled messages (isScheduled + scheduledFor)
- And 10 more indexes

## Step 6: Set Up Cloud Scheduler

Cloud Scheduler jobs are automatically created by Terraform:

### 6.1 Verify Scheduler Jobs
```bash
gcloud scheduler jobs list --location=us-central1
```

You should see:
- `send-scheduled-messages` - Runs every 1 minute
- `cleanup-disappearing-media` - Runs every 1 hour

### 6.2 Test Scheduler Jobs (Optional)
```bash
# Manually trigger scheduled messages job
gcloud scheduler jobs run send-scheduled-messages --location=us-central1

# Manually trigger cleanup job
gcloud scheduler jobs run cleanup-disappearing-media --location=us-central1
```

## Step 7: Enable Required APIs

Terraform enables these automatically, but verify:

```bash
gcloud services list --enabled
```

Required APIs:
- `firestore.googleapis.com`
- `storage-api.googleapis.com`
- `cloudfunctions.googleapis.com`
- `translate.googleapis.com`
- `speech.googleapis.com`
- `cloudscheduler.googleapis.com`
- `pubsub.googleapis.com`

## Step 8: Configure Environment Variables

### 8.1 Set Cloud Functions Environment Variables
```bash
firebase functions:config:set \
  storage.bucket="greengo-chat-chat-attachments-production" \
  backup.bucket="greengo-chat-backups-production" \
  max.image_size_mb=2 \
  max.video_duration=60 \
  disappearing.ttl_hours=24
```

### 8.2 Redeploy Functions with New Config
```bash
firebase deploy --only functions
```

## Step 9: Test Deployment

### 9.1 Test Image Compression
Upload an image to the chat attachments bucket:
```bash
gsutil cp test-image.jpg gs://greengo-chat-chat-attachments-production/images/
```

Check logs:
```bash
gcloud functions logs read compressUploadedImage --limit 10
```

### 9.2 Test Scheduled Messages
Create a test scheduled message in Firestore, then check logs after 1 minute:
```bash
gcloud functions logs read sendScheduledMessages --limit 10
```

### 9.3 Test Translation
Use Firebase emulator or production to call:
```javascript
const translateMessage = firebase.functions().httpsCallable('translateMessage');
const result = await translateMessage({
  messageId: 'test-id',
  conversationId: 'test-conv',
  targetLanguage: 'es',
  sourceText: 'Hello, how are you?'
});
```

## Step 10: Monitoring and Logs

### 10.1 View Cloud Functions Logs
```bash
# All functions
firebase functions:log

# Specific function
gcloud functions logs read compressUploadedImage --limit 50
```

### 10.2 Set Up Monitoring Alerts
Already configured by Terraform if `enable_cost_alerts = true`.

Check in GCP Console:
- **Monitoring > Alerting** for cost alerts
- **Cloud Functions > Metrics** for function performance

### 10.3 View Metrics
```bash
# Function invocations
gcloud monitoring time-series list \
  --filter='metric.type="cloudfunctions.googleapis.com/function/execution_count"' \
  --interval-start-time=2024-01-01T00:00:00Z

# Function errors
gcloud monitoring time-series list \
  --filter='metric.type="cloudfunctions.googleapis.com/function/user_error_count"' \
  --interval-start-time=2024-01-01T00:00:00Z
```

## Step 11: Flutter App Configuration

### 11.1 Update Firebase Configuration
Ensure `lib/firebase_options.dart` is generated:
```bash
flutterfire configure
```

### 11.2 Update Function URLs
If using HTTP callable functions, the URLs are automatically configured via Firebase SDK.

### 11.3 Test from Flutter App
```dart
// Test translation
final translateMessage = FirebaseFunctions.instance.httpsCallable('translateMessage');
final result = await translateMessage.call({
  'messageId': messageId,
  'conversationId': conversationId,
  'targetLanguage': 'es',
});

// Test backup
final backupConversation = FirebaseFunctions.instance.httpsCallable('backupConversation');
final backupResult = await backupConversation.call({
  'conversationId': conversationId,
  'encryptionKey': 'optional-encryption-key',
});

// Test PDF export
final exportPDF = FirebaseFunctions.instance.httpsCallable('exportConversationToPDF');
final pdfResult = await exportPDF.call({
  'conversationId': conversationId,
  'options': {
    'includeTimestamps': true,
    'includeMedia': true,
    'includeReactions': true,
  },
});
```

## Troubleshooting

### Issue: Terraform apply fails
**Solution:**
```bash
# Check API enablement
gcloud services list --enabled

# Verify permissions
gcloud projects get-iam-policy YOUR_PROJECT_ID

# Re-initialize
terraform init -upgrade
```

### Issue: Cloud Functions timeout
**Solution:**
Increase timeout in `terraform/modules/cloud_functions/main.tf`:
```hcl
service_config {
  timeout_seconds = 540  # Increase from 300
  available_memory = "2Gi"  # Increase if needed
}
```

### Issue: FFmpeg not found
**Solution:**
FFmpeg is included in Cloud Functions Node.js 18 runtime. Verify:
```bash
gcloud functions describe processUploadedVideo --region=us-central1
```

### Issue: Translation API quota exceeded
**Solution:**
Increase quota in GCP Console:
- **APIs & Services > Cloud Translation API > Quotas**
- Request quota increase

## Maintenance

### Daily Backups
Automated backups run every Sunday at 02:00 UTC.

Verify:
```bash
gsutil ls gs://greengo-chat-backups-production/backups/auto/
```

### Clean Up Old Exports
PDF exports auto-delete after 7 days via `cleanupExpiredExports` function (runs daily at 03:00 UTC).

### Update Functions
```bash
cd functions
npm install  # Update dependencies
npm run build
firebase deploy --only functions
```

### Update Infrastructure
```bash
cd terraform
terraform plan
terraform apply
```

## Cost Estimation

**Monthly costs (estimated):**
- Cloud Functions: $20-100 (based on invocations)
- Cloud Storage: $5-30 (based on storage used)
- Cloud Translation API: $20 per 1M characters
- Cloud Speech-to-Text API: $1.44 per hour
- Cloud Scheduler: $0.10 per job per month
- Firestore: Free tier up to 1GB, then $0.18/GB

**Total estimated:** $50-200/month for moderate usage

## Security Checklist

- [ ] Firestore security rules deployed
- [ ] Service accounts have minimum required permissions
- [ ] Cloud KMS encryption enabled for sensitive data
- [ ] Backup encryption keys stored securely
- [ ] Cost alerts configured
- [ ] Function authentication enforced
- [ ] CORS configured correctly
- [ ] API keys restricted (if used)

## Next Steps

1. Set up CI/CD pipeline for automatic deployments
2. Configure staging environment
3. Set up error reporting (Sentry/Crashlytics)
4. Implement A/B testing for features
5. Add analytics tracking
6. Set up CDN for media delivery
7. Configure backup restoration procedures

## Support

For issues or questions:
- Check logs: `firebase functions:log`
- Review Terraform state: `terraform show`
- GCP Console: https://console.cloud.google.com
- Firebase Console: https://console.firebase.google.com

---

**Deployment Complete!** All 39 features are now live in production.
