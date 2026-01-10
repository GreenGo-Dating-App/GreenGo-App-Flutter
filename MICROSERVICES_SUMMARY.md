# GreenGo App - Backend Microservices Summary

## Overview

The GreenGo dating app implements a **hybrid microservices architecture** combining serverless cloud functions, a Django REST backend, and containerized services.

---

## 🏗️ Architecture Components

### 1. Firebase Cloud Functions (160+ Serverless Functions)

**Platform:** Node.js/TypeScript
**Deployment:** Google Cloud Platform
**Purpose:** Serverless event-driven microservices

#### Service Domains (12 Categories)

| Service | Functions | Purpose |
|---------|-----------|---------|
| **Media Processing** | 10 | Image/video compression, transcription |
| **Messaging** | 8 | Translation, scheduled messages |
| **Backup & Export** | 8 | Conversation backup, PDF export |
| **Subscription** | 4 | Payment webhooks, lifecycle management |
| **Coin Service** | 6 | Virtual currency system |
| **Analytics** | 20+ | Revenue, cohort, churn prediction |
| **Gamification** | 8 | XP, achievements, leaderboards |
| **Safety & Moderation** | 11 | Content moderation, reporting |
| **Admin Panel** | 25+ | Dashboard, user management |
| **Notifications** | 8 | Push, email, SMS |
| **Video Calling** | 21 | WebRTC, Agora, group calls |
| **Security** | 5 | Security audits |

---

### 2. Django REST Backend

**Platform:** Python 3.11 + Django 4.2.7
**Purpose:** Complex business logic, real-time messaging, relational data

#### Django Services

1. **Authentication Service** - JWT, OAuth (Google, Facebook)
2. **User Service** - CRUD operations, profile management
3. **Matching Service** - Matching algorithm, swipe management
4. **Messaging Service** - Real-time chat (WebSockets via Django Channels)
5. **Payment Service** - Stripe integration, invoice generation

#### Background Jobs
- **Celery Workers** - Async task processing
- **Celery Beat** - Scheduled tasks
- **Redis** - Message broker

---

### 3. Containerized Infrastructure (Docker)

**Development Stack:**

```yaml
Services:
  - firebase: Firebase Emulator Suite
  - postgres: PostgreSQL 15 database
  - redis: Redis 7 cache
  - nginx: API Gateway & reverse proxy
  - adminer: Database UI
  - redis-commander: Redis UI
```

---

## 📊 Data Stores

### Primary Databases

1. **Cloud Firestore** (NoSQL)
   - User profiles and metadata
   - Real-time messaging
   - Video call signaling
   - Moderation results
   - ~30 collections

2. **PostgreSQL 15** (Relational)
   - User authentication
   - Matching algorithm data
   - Payment transactions
   - Analytics events

3. **Redis 7** (Cache)
   - User sessions
   - Rate limiting
   - Typing indicators
   - Real-time messaging queues

4. **BigQuery** (Data Warehouse)
   - Revenue analytics
   - User behavior events
   - Cohort analysis
   - Churn prediction data

5. **Cloud Storage** (Object Storage)
   - User photos
   - Profile media
   - Chat attachments
   - Call recordings
   - Backups

---

## 🔧 Function Trigger Types

### HTTP Callable Functions (~120)
- User-facing API functions
- Require Firebase Authentication
- Input validation and error handling
- Examples: `compressImage()`, `translateMessage()`, `verifyPurchase()`

### Storage Triggered Functions (~10)
- Auto-triggered on Cloud Storage uploads
- Media processing pipeline
- Examples: `compressUploadedImage`, `processUploadedVideo`, `transcribeVoiceMessage`

### Firestore Triggered Functions (~15)
- React to document create/update/delete
- Auto-translation
- Real-time notifications
- Examples: `autoTranslateMessage`, `onNewMatch`, `onMessageSent`

### Scheduled Functions (~15)
- Cron-based execution (Pub/Sub)
- Background maintenance
- Batch processing
- Examples:
  - `cleanupDisappearingMedia` (hourly)
  - `checkExpiringSubscriptions` (daily 9am UTC)
  - `grantMonthlyAllowances` (monthly 1st)

### Webhook Functions (~5)
- External service callbacks
- Payment processing
- Examples: `handlePlayStoreWebhook`, `handleAppStoreWebhook`

---

## 🌐 External Service Integrations

### Google Cloud Platform
- **Cloud Vision API** - Photo content moderation
- **Cloud Translation API** - Message translation (20+ languages)
- **Cloud Speech-to-Text** - Voice message transcription (6 languages)
- **Cloud Natural Language API** - Sentiment analysis, toxicity detection
- **BigQuery** - Analytics data warehouse

### Communication Services
- **Firebase Cloud Messaging (FCM)** - Push notifications
- **SendGrid** - Transactional and marketing emails
- **Twilio** - SMS notifications and fallback

### Payment Providers
- **Stripe** - Payment processing
- **Google Play Billing** - Android subscriptions and IAP
- **Apple App Store** - iOS subscriptions and IAP

### Video Infrastructure
- **Agora.io SDK** - Enterprise video calling
- **WebRTC** - Peer-to-peer video (fallback)

---

## 🔄 Inter-Service Communication

### Communication Patterns

1. **Client → Firebase Functions (Direct)**
   - HTTPS callable functions
   - JWT authentication via Firebase Auth

2. **Client → Django REST API (via Nginx)**
   - RESTful endpoints
   - JWT authentication
   - WebSocket connections for real-time chat

3. **Firebase Functions → Firestore**
   - Read/write operations
   - Real-time listeners
   - Batch writes

4. **Firebase Functions → Cloud Storage**
   - File uploads/downloads
   - Signed URLs
   - Storage triggers

5. **Firebase Functions → BigQuery**
   - Analytics data ingestion
   - SQL queries for dashboards

6. **Django → Firestore (via Firebase Admin SDK)**
   - Sync user data
   - Write notifications

7. **Django → PostgreSQL**
   - Complex relational queries
   - Transaction management

8. **Django → Redis**
   - Session caching
   - Rate limiting
   - Real-time data

9. **Celery → Background Tasks**
   - Email sending
   - Image processing
   - Report generation

10. **WebSockets (Django Channels)**
    - Real-time messaging
    - Typing indicators
    - Online status

---

## 📈 Key Features by Service

### Media Processing Service
- **Image Compression:** Auto-compress to <2MB using Sharp
- **Video Processing:** Generate thumbnails, validate 60s max duration
- **Voice Transcription:** Speech-to-Text for 6 languages
- **Disappearing Media:** Auto-delete after 24 hours

### Messaging Service
- **Auto-Translation:** Translate messages based on user preferences
- **Scheduled Messages:** Send messages at future date/time
- **20+ Languages:** Comprehensive language support

### Subscription Service
- **3 Tiers:** Basic (free), Silver ($9.99/mo), Gold ($19.99/mo)
- **Webhook Integration:** Google Play & App Store
- **Grace Period:** 7-day grace period for failed payments
- **Renewal Reminders:** 3 days before expiration

### Coin Service
- **Virtual Currency:** In-app coin system
- **365-Day Expiration:** FIFO spending model
- **Monthly Allowances:** Silver (100 coins), Gold (250 coins)
- **Reward System:** Achievements, milestones, daily login

### Analytics Service
- **Revenue Dashboard:** Daily/weekly/monthly revenue tracking
- **MRR Metrics:** Monthly Recurring Revenue analysis
- **Cohort Analysis:** User cohorts and retention
- **Churn Prediction:** ML-powered churn forecasting
- **A/B Testing:** Experiment framework with statistical significance

### Video Calling Service
- **1-on-1 Calls:** WebRTC and Agora SDK
- **Group Calls:** Up to 8 participants
- **Quality Tiers:** Auto-adjust based on bandwidth (1080p → 360p)
- **Features:** Virtual backgrounds, AR filters, beauty mode, screen sharing
- **Recording:** Call recording with mutual consent

### Safety & Moderation Service
- **AI Moderation:** Cloud Vision API for photos
- **Text Analysis:** Toxicity, profanity, spam detection
- **Fake Profile Detection:** Behavioral analysis
- **Scam Detection:** Pattern matching in conversations
- **Identity Verification:** Selfie and ID verification
- **Trust Score:** User trust scoring system

---

## 🚀 Deployment Architecture

### Development Environment
```
Docker Compose Stack:
├── Firebase Emulator (all services)
├── PostgreSQL 15
├── Redis 7
├── Nginx (reverse proxy)
├── Adminer (DB UI)
└── Redis Commander (Redis UI)
```

### Production Environment
```
Google Cloud Platform:
├── Firebase (Production project)
├── Cloud Functions (160+ functions)
├── Cloud Run (Django containers)
├── Cloud SQL (PostgreSQL)
├── Memorystore (Redis)
├── Cloud Storage (Media files)
└── BigQuery (Analytics)
```

---

## 📊 Performance Characteristics

### Scalability
- **Serverless Functions:** Auto-scale based on demand
- **Horizontal Scaling:** Django can scale horizontally
- **Database:** Read replicas for PostgreSQL
- **Caching:** Redis reduces database load

### Reliability
- **Retry Logic:** Failed function executions auto-retry
- **Circuit Breakers:** Prevent cascade failures
- **Graceful Degradation:** Fallback to reduced functionality
- **Health Checks:** Continuous monitoring

### Security
- **Authentication:** Firebase Auth + JWT
- **Authorization:** Role-based access control (RBAC)
- **Encryption:** AES-256-GCM for backups
- **Data Privacy:** GDPR compliance, user data export/deletion
- **Security Audits:** Daily automated security scans

---

## 📚 Technology Stack Summary

### Languages
- **TypeScript/Node.js** - Cloud Functions
- **Python 3.11** - Django backend
- **Dart** - Flutter frontend

### Frameworks
- **Firebase** - Backend infrastructure
- **Django 4.2.7** - REST API framework
- **Django REST Framework 3.14.0** - API serialization
- **Django Channels 4.0** - WebSocket support
- **Celery 5.3.4** - Task queue

### Databases
- **Cloud Firestore** - NoSQL document database
- **PostgreSQL 15** - Relational database
- **Redis 7** - In-memory cache
- **BigQuery** - Data warehouse

### Infrastructure
- **Docker** - Containerization
- **Nginx** - API Gateway
- **Google Cloud Platform** - Cloud infrastructure
- **Terraform** - Infrastructure as Code

### Third-Party Services
- **Agora.io** - Video calling
- **SendGrid** - Email delivery
- **Twilio** - SMS notifications
- **Stripe** - Payment processing

---

## 📖 Documentation Files

1. **ARCHITECTURE_DIAGRAMS_README.md** - Complete diagram documentation
2. **MICROSERVICES_SUMMARY.md** - This file
3. **greengo_microservices_architecture.png** - Visual microservices diagram
4. **greengo_functions_detailed.png** - Detailed functions breakdown

---

## 🔗 Related Diagrams

- `greengo_mvp_architecture.png` - Frontend Clean Architecture
- `greengo_detailed_architecture.png` - Feature module breakdown
- `greengo_simple_flow.png` - Data flow sequence
- `greengo_microservices_architecture.png` - Backend microservices
- `greengo_functions_detailed.png` - Cloud functions by trigger type

---

**Last Updated:** November 23, 2025
**Total Cloud Functions:** 160+
**Total Microservices:** 12 domains
**Backend Services:** 5 Django services
**External Integrations:** 10+ services
