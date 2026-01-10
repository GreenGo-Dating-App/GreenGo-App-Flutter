# GreenGo App - Microservices Implementation Guide

## Overview

This document provides a complete implementation guide for all 160+ Cloud Functions organized into 12 microservice domains using TypeScript and Terraform.

---

## 📁 Project Structure

```
functions/
├── src/
│   ├── shared/
│   │   ├── types.ts              # Shared TypeScript types
│   │   ├── utils.ts              # Shared utility functions
│   │   └── constants.ts          # Shared constants
│   │
│   ├── media/                    # Media Processing Service (10 functions)
│   │   ├── index.ts             # Service exports
│   │   ├── compress.ts          # Image/video compression
│   │   ├── transcribe.ts        # Audio transcription
│   │   └── cleanup.ts           # Media cleanup
│   │
│   ├── messaging/                # Messaging Service (8 functions)
│   │   ├── index.ts
│   │   ├── translation.ts       # Message translation
│   │   └── scheduling.ts        # Scheduled messages
│   │
│   ├── backup/                   # Backup & Export Service (8 functions)
│   │   ├── index.ts
│   │   ├── conversation.ts      # Conversation backup
│   │   └── export-pdf.ts        # PDF export
│   │
│   ├── subscription/             # Subscription Service (4 functions)
│   │   ├── index.ts
│   │   ├── webhooks.ts          # Payment webhooks
│   │   └── lifecycle.ts         # Subscription lifecycle
│   │
│   ├── coins/                    # Coin Service (6 functions)
│   │   ├── index.ts
│   │   ├── purchase.ts          # Coin purchases
│   │   ├── rewards.ts           # Reward claiming
│   │   └── expiration.ts        # Coin expiration
│   │
│   ├── analytics/                # Analytics Service (20+ functions)
│   │   ├── index.ts
│   │   ├── revenue.ts           # Revenue analytics
│   │   ├── cohort.ts            # Cohort analysis
│   │   ├── churn.ts             # Churn prediction
│   │   └── ab-testing.ts        # A/B testing
│   │
│   ├── gamification/             # Gamification Service (8 functions)
│   │   ├── index.ts
│   │   ├── xp.ts                # XP system
│   │   ├── achievements.ts      # Achievements
│   │   └── leaderboard.ts       # Leaderboards
│   │
│   ├── safety/                   # Safety & Moderation Service (11 functions)
│   │   ├── index.ts
│   │   ├── moderation.ts        # AI moderation
│   │   ├── detection.ts         # Spam/scam detection
│   │   └── verification.ts      # Identity verification
│   │
│   ├── admin/                    # Admin Service (25+ functions)
│   │   ├── index.ts
│   │   ├── dashboard.ts         # Admin dashboard
│   │   ├── users.ts             # User management
│   │   └── moderation-queue.ts  # Moderation queue
│   │
│   ├── notification/             # Notification Service (8 functions)
│   │   ├── index.ts
│   │   ├── push.ts              # Push notifications
│   │   └── email.ts             # Email campaigns
│   │
│   ├── video/                    # Video Calling Service (21 functions)
│   │   ├── index.ts
│   │   ├── calls.ts             # Call management
│   │   ├── features.ts          # Video features
│   │   └── group.ts             # Group calls
│   │
│   ├── security/                 # Security Service (5 functions)
│   │   ├── index.ts
│   │   └── audit.ts             # Security audits
│   │
│   └── index.ts                  # Main exports
│
├── package.json
├── tsconfig.json
└── .eslintrc.js

terraform/
└── microservices/
    ├── main.tf                   # Main infrastructure
    ├── variables.tf              # Variables
    ├── outputs.tf                # Outputs
    └── modules/                  # Service modules
        ├── media-processing/
        ├── messaging/
        ├── backup-export/
        ├── subscription/
        ├── coin-service/
        ├── analytics/
        ├── gamification/
        ├── safety-moderation/
        ├── admin/
        ├── notification/
        ├── video-calling/
        └── security/
```

---

## 🎯 Implementation Status

### ✅ Completed

1. **Terraform Infrastructure** - Main configuration, variables, outputs
2. **Shared TypeScript Types** - All interface definitions
3. **Shared Utilities** - Common helper functions

### 📝 To Implement

For each service domain, create the following files:

1. **TypeScript Functions** - Complete function implementations
2. **Terraform Module** - Infrastructure for each service
3. **Tests** - Unit and integration tests
4. **Documentation** - API documentation

---

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Build TypeScript

```bash
npm run build
```

### 3. Deploy Infrastructure (Terraform)

```bash
cd terraform/microservices
terraform init
terraform plan -var="project_id=your-project-id"
terraform apply
```

### 4. Deploy Functions

```bash
# Deploy all functions
npm run deploy

# Deploy specific service
npm run deploy:media
npm run deploy:messaging
# ... etc
```

---

## 📋 Service Implementation Details

### 1. Media Processing Service (10 Functions)

**Functions:**
- `compressUploadedImage` (Storage Trigger)
- `compressImage` (HTTP Callable)
- `processUploadedVideo` (Storage Trigger)
- `generateVideoThumbnail` (HTTP Callable)
- `transcribeVoiceMessage` (Storage Trigger)
- `transcribeAudio` (HTTP Callable)
- `batchTranscribe` (HTTP Callable)
- `cleanupDisappearingMedia` (Scheduled - Hourly)
- `markMediaAsDisappearing` (HTTP Callable)

**Dependencies:**
- Sharp (image processing)
- FFmpeg (video processing)
- Google Cloud Vision API
- Google Cloud Speech-to-Text API

**Key Features:**
- Auto-compress images to <2MB
- Generate video thumbnails at 1s mark
- Transcribe voice messages in 6 languages
- Auto-delete disappearing media after 24 hours

---

### 2. Messaging Service (8 Functions)

**Functions:**
- `translateMessage` (HTTP Callable)
- `autoTranslateMessage` (Firestore Trigger)
- `batchTranslateMessages` (HTTP Callable)
- `getSupportedLanguages` (HTTP Callable)
- `scheduleMessage` (HTTP Callable)
- `sendScheduledMessages` (Scheduled - Every Minute)
- `cancelScheduledMessage` (HTTP Callable)
- `getScheduledMessages` (HTTP Callable)

**Dependencies:**
- Google Cloud Translation API
- Firestore
- Cloud Scheduler

**Key Features:**
- 20+ language support
- Auto-translation based on user preferences
- Message scheduling
- Batch translation

---

### 3. Backup & Export Service (8 Functions)

**Functions:**
- `backupConversation` (HTTP Callable)
- `restoreConversation` (HTTP Callable)
- `listBackups` (HTTP Callable)
- `deleteBackup` (HTTP Callable)
- `autoBackupConversations` (Scheduled - Weekly)
- `exportConversationToPDF` (HTTP Callable)
- `listPDFExports` (HTTP Callable)
- `cleanupExpiredExports` (Scheduled - Daily)

**Dependencies:**
- PDFKit
- Crypto (AES-256-GCM encryption)
- Cloud Storage

**Key Features:**
- Encrypted backups
- PDF export with custom themes
- Auto-backup active conversations
- 7-day retention for exports

---

### 4. Subscription Service (4 Functions)

**Functions:**
- `handlePlayStoreWebhook` (HTTP Request)
- `handleAppStoreWebhook` (HTTP Request)
- `checkExpiringSubscriptions` (Scheduled - Daily 9am UTC)
- `handleExpiredGracePeriods` (Scheduled - Hourly)

**Dependencies:**
- Google Play Billing API
- Apple App Store Server API
- Firestore

**Subscription Tiers:**
- Basic: Free (10 daily likes)
- Silver: $9.99/month (100 daily likes, advanced features)
- Gold: $19.99/month (Unlimited likes, all features)

**Key Features:**
- Webhook integration for both platforms
- 7-day grace period
- Renewal reminders
- Subscription analytics

---

### 5. Coin Service (6 Functions)

**Functions:**
- `verifyGooglePlayCoinPurchase` (HTTP Callable)
- `verifyAppStoreCoinPurchase` (HTTP Callable)
- `grantMonthlyAllowances` (Scheduled - Monthly 1st)
- `processExpiredCoins` (Scheduled - Daily 2am UTC)
- `sendExpirationWarnings` (Scheduled - Daily 10am UTC)
- `claimReward` (HTTP Callable)

**Dependencies:**
- Google Play Billing API
- Apple IAP
- Firestore

**Key Features:**
- 365-day coin expiration
- FIFO spending model
- Monthly allowances (Silver: 100, Gold: 250)
- Reward system integration

---

### 6. Analytics Service (20+ Functions)

**Functions:**
- Revenue: `getRevenueDashboard`, `exportRevenueData`
- Cohort: `getCohortAnalysis`, `calculateCohortRetention`
- Churn: `trainChurnModel`, `predictChurnDaily`, `getUserChurnPrediction`, `getAtRiskUsers`
- A/B Testing: `createABTest`, `assignUserToTest`, `recordConversion`, `getABTestResults`
- Metrics: `getARPU`, `forecastMRR`, `getRefundAnalytics`
- Segmentation: `calculateUserSegment`, `createUserCohort`

**Dependencies:**
- BigQuery
- Firestore
- Python ML libraries (via Cloud Run)

**Key Features:**
- Real-time revenue dashboard
- MRR tracking and forecasting
- ML-powered churn prediction
- A/B testing framework
- User segmentation

---

### 7. Gamification Service (8 Functions)

**Functions:**
- `grantXP` (HTTP Callable)
- `trackAchievementProgress` (HTTP Callable)
- `unlockAchievementReward` (HTTP Callable)
- `claimLevelRewards` (HTTP Callable)
- `trackChallengeProgress` (HTTP Callable)
- `claimChallengeReward` (HTTP Callable)
- `resetDailyChallenges` (Scheduled - Daily)
- `updateLeaderboardRankings` (Scheduled - Hourly)

**Dependencies:**
- Firestore
- Cloud Functions

**Key Features:**
- XP and leveling system
- Achievement unlocks with rewards
- Daily/weekly challenges
- Global and regional leaderboards

---

### 8. Safety & Moderation Service (11 Functions)

**Functions:**
- Moderation: `moderatePhoto`, `moderateText`, `detectSpam`, `detectFakeProfile`, `detectScam`
- Reporting: `submitReport`, `reviewReport`, `submitAppeal`, `blockUser`, `unblockUser`, `getBlockList`

**Dependencies:**
- Google Cloud Vision API
- Google Cloud Natural Language API
- Perspective API (toxicity)

**Key Features:**
- AI-powered photo moderation
- Text toxicity detection
- Spam/scam pattern detection
- Fake profile detection
- Reporting and appeals system

---

### 9. Admin Service (25+ Functions)

**Functions:**
- Dashboard: `getUserActivityMetrics`, `getRevenueMetrics`, `getSystemHealthMetrics`
- Roles: `createAdminUser`, `updateAdminRole`, `updateAdminPermissions`
- Users: `searchUsers`, `suspendUserAccount`, `deleteUserAccount`, `executeMassAction`
- Moderation: `getModerationQueue`, `takeModerationAction`, `executeBulkModeration`

**Dependencies:**
- Firestore
- BigQuery
- Cloud Functions

**Key Features:**
- Admin dashboard with real-time metrics
- Role-based access control
- Bulk user operations
- Moderation queue management

---

### 10. Notification Service (8 Functions)

**Functions:**
- Push: `sendPushNotification`, `sendBundledNotifications`, `trackNotificationOpened`
- Email: `sendTransactionalEmail`, `startWelcomeEmailSeries`, `sendWeeklyDigestEmails`, `sendReEngagementCampaign`

**Dependencies:**
- Firebase Cloud Messaging
- SendGrid
- Twilio

**Key Features:**
- Push notifications with FCM
- Transactional emails
- Email campaigns
- SMS notifications
- Notification analytics

---

### 11. Video Calling Service (21 Functions)

**Functions:**
- Core: `initiateVideoCall`, `answerVideoCall`, `endVideoCall`, `handleCallSignal`
- Features: `enableVirtualBackground`, `applyARFilter`, `startScreenSharing`
- Group: `createGroupVideoCall`, `joinGroupVideoCall`, `createBreakoutRoom`

**Dependencies:**
- Agora.io SDK
- WebRTC
- Firestore (signaling)
- Cloud Storage (recordings)

**Quality Tiers:**
- HD 1080p: ≥5 Mbps
- HD 720p: ≥2 Mbps
- SD 480p: ≥1 Mbps
- SD 360p: <1 Mbps

**Key Features:**
- 1-on-1 and group calls (up to 8 participants)
- Auto-quality adjustment
- Virtual backgrounds and AR filters
- Screen sharing
- Call recording with consent

---

### 12. Security Service (5 Functions)

**Functions:**
- `runSecurityAudit` (HTTP Callable)
- `scheduledSecurityAudit` (Scheduled - Daily)
- `getSecurityAuditReport` (HTTP Callable)
- `listSecurityAuditReports` (HTTP Callable)
- `cleanupOldAuditReports` (Scheduled - Monthly)

**Dependencies:**
- Firestore
- Cloud Functions

**Key Features:**
- Daily automated security scans
- Vulnerability detection
- Compliance monitoring
- Audit report generation

---

## 📊 Deployment Strategy

### Development

```bash
# Use Firebase emulators
firebase emulators:start

# Deploy to dev environment
terraform workspace select dev
terraform apply -var="environment=dev"
firebase deploy --only functions --project dev-project
```

### Staging

```bash
terraform workspace select staging
terraform apply -var="environment=staging"
firebase deploy --only functions --project staging-project
```

### Production

```bash
terraform workspace select prod
terraform apply -var="environment=prod"
firebase deploy --only functions --project prod-project
```

---

## 🔧 Configuration

### Environment Variables

Create `.env` files for each environment:

```bash
# .env.dev
PROJECT_ID=greengo-dev
REGION=us-central1
SENDGRID_API_KEY=xxx
TWILIO_AUTH_TOKEN=xxx
STRIPE_SECRET_KEY=xxx
AGORA_APP_ID=xxx
AGORA_APP_CERTIFICATE=xxx
```

### Terraform Variables

Create `terraform.tfvars`:

```hcl
project_id         = "greengo-prod"
region            = "us-central1"
environment       = "prod"
firebase_project_id = "greengo-prod"
```

---

## 🧪 Testing

### Unit Tests

```bash
npm test
```

### Integration Tests

```bash
npm run test:integration
```

### Load Testing

```bash
npm run test:load
```

---

## 📈 Monitoring

- **Cloud Functions Dashboard**: Monitor invocations, errors, latency
- **Firebase Console**: Real-time function logs
- **Cloud Monitoring**: Set up alerts and dashboards
- **BigQuery**: Analytics and usage tracking

---

## 🔐 Security Best Practices

1. **Authentication**: All callable functions verify Firebase Auth tokens
2. **Authorization**: Role-based access control for admin functions
3. **Input Validation**: All inputs validated before processing
4. **Rate Limiting**: Implement rate limiting for public endpoints
5. **Secrets Management**: Use Secret Manager for API keys
6. **HTTPS Only**: All functions served over HTTPS
7. **CORS**: Configure CORS for web clients

---

## 📚 Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Terraform Google Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)
- [GreenGo Architecture Diagrams](./ARCHITECTURE_DIAGRAMS_README.md)

---

## 🤝 Contributing

1. Create a feature branch
2. Implement the function
3. Write tests
4. Update documentation
5. Submit pull request

---

**Total Functions**: 160+
**Service Domains**: 12
**Languages**: TypeScript (Functions), HCL (Terraform)
**Cloud Provider**: Google Cloud Platform (Firebase)
