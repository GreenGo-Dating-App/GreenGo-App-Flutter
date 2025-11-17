# 🚀 GreenGoChat - Quick Start Guide

Get GreenGoChat up and running in **30 minutes**!

---

## 📋 Prerequisites Checklist

Before you begin, ensure you have:

- [ ] Flutter SDK 3.16+ installed
- [ ] Node.js 18+ installed
- [ ] Terraform 1.5+ installed
- [ ] Git installed
- [ ] Google Cloud Platform account created
- [ ] Firebase account created (linked to GCP)
- [ ] Code editor (VS Code or Android Studio)

---

## ⚡ 5-Minute Local Setup (Development Mode)

### Step 1: Install CLI Tools

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify installations
firebase --version
flutter --version
terraform --version
node --version
```

### Step 2: Clone and Install

```bash
# Navigate to project directory
cd "c:\Users\Software Engineering\GreenGo App"

# Install Flutter dependencies
flutter pub get

# Install Cloud Functions dependencies
cd functions
npm install
cd ..
```

### Step 3: Start Firebase Emulators

```bash
# Initialize Firebase (if not done)
firebase init

# Start emulators
firebase emulators:start
```

This starts:
- Firestore Emulator: `localhost:8080`
- Auth Emulator: `localhost:9099`
- Storage Emulator: `localhost:9199`
- Functions Emulator: `localhost:5001`

### Step 4: Configure Environment

```bash
# Create .env file
cp .env.example .env
```

Edit `.env` and set:
```env
USE_FIREBASE_EMULATORS=true
FIRESTORE_EMULATOR_HOST=localhost:8080
FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199
```

### Step 5: Run the App

```bash
# Run on Android emulator
flutter run -d android

# Or run on iOS simulator
flutter run -d ios

# Or run on web
flutter run -d chrome
```

**🎉 You're now running GreenGoChat locally with emulators!**

---

## 🌐 15-Minute Production Setup (GCP Deployment)

### Step 1: Create GCP Project

```bash
# Login to Google Cloud
gcloud auth login

# Create new project
gcloud projects create greengo-chat-prod --name="GreenGoChat Production"

# Set as active project
gcloud config set project greengo-chat-prod

# Enable billing
# Visit: https://console.cloud.google.com/billing
```

### Step 2: Configure Terraform

```bash
cd terraform

# Copy example config
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_name   = "greengo-chat"
environment    = "production"
gcp_project_id = "greengo-chat-prod"
region         = "us-central1"

alert_notification_email = "your-email@example.com"

use_test_environment = false
multi_region = true
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review deployment plan
terraform plan

# Deploy (confirm with 'yes')
terraform apply
```

This creates:
- ✅ Firestore database
- ✅ Cloud Storage buckets
- ✅ Cloud KMS encryption keys
- ✅ Service accounts
- ✅ VPC network
- ✅ Pub/Sub topics
- ✅ BigQuery dataset
- ✅ Monitoring & alerts

**Time: ~5-10 minutes**

### Step 4: Configure Firebase

```bash
# Login to Firebase
firebase login

# Link to GCP project
firebase use --add greengo-chat-prod

# Configure Flutter
flutterfire configure --project=greengo-chat-prod
```

This generates `lib/firebase_options.dart`

### Step 5: Setup Environment Variables

Download service account keys:

```bash
# Go to GCP Console
# IAM & Admin > Service Accounts
# Create key for each service account
# Download JSON files
```

Place files in `functions/certs/`:
- `service-account-key.json`
- `firebase-admin-sdk.json`

Edit `functions/.env`:
```env
GCP_PROJECT_ID=greengo-chat-prod
FIREBASE_PROJECT_ID=greengo-chat-prod
GOOGLE_APPLICATION_CREDENTIALS=./certs/service-account-key.json
```

### Step 6: Configure Third-Party Services

#### Twilio (SMS)
1. Sign up at [twilio.com](https://www.twilio.com)
2. Get Account SID and Auth Token
3. Add to `functions/.env`:
```env
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=your-auth-token
TWILIO_PHONE_NUMBER=+1234567890
```

#### SendGrid (Email)
1. Sign up at [sendgrid.com](https://sendgrid.com)
2. Create API key
3. Add to `functions/.env`:
```env
SENDGRID_API_KEY=SG.xxxxxxxxxxxxx
SENDGRID_FROM_EMAIL=noreply@greengochat.com
```

#### Stripe (Payments)
1. Sign up at [stripe.com](https://stripe.com)
2. Get API keys
3. Add to `functions/.env`:
```env
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

#### Agora.io (Video Calling)
1. Sign up at [agora.io](https://www.agora.io)
2. Create project and get App ID
3. Add to `functions/.env`:
```env
AGORA_APP_ID=your-app-id
AGORA_APP_CERTIFICATE=your-certificate
```

### Step 7: Deploy Backend

```bash
# Deploy security rules
firebase deploy --only firestore:rules,storage,firestore:indexes

# Build and deploy Cloud Functions
cd functions
npm run build
firebase deploy --only functions
cd ..
```

### Step 8: Configure OAuth Providers

#### Google Sign-In
1. Go to [GCP Console > APIs & Services > Credentials](https://console.cloud.google.com/apis/credentials)
2. Create OAuth 2.0 Client ID
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place in respective directories

#### Apple Sign-In
1. Go to [Apple Developer](https://developer.apple.com)
2. Create Service ID
3. Configure Sign In with Apple
4. Add to `.env`

#### Facebook Login
1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create app
3. Get App ID and Secret
4. Add to `.env`

### Step 9: Build and Deploy

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
firebase deploy --only hosting
```

**🎉 Your production environment is live!**

---

## 🧪 Testing Your Setup

### Test Local Development

```bash
# Start emulators
firebase emulators:start

# In another terminal, run app
flutter run -d chrome

# Try these actions:
# 1. Register with email
# 2. Login
# 3. Create profile
# 4. Upload photo
```

### Test Production

```bash
# Run in release mode
flutter run --release

# Test features:
# 1. Email authentication
# 2. Google Sign-In
# 3. Profile creation
# 4. Photo upload to Cloud Storage
# 5. Real-time messaging
```

---

## 🔧 Common Issues & Solutions

### Issue: "Firebase not initialized"

**Solution:**
```bash
# Make sure you ran
flutterfire configure

# Check that lib/firebase_options.dart exists
```

### Issue: "Permission denied" in Firestore

**Solution:**
```bash
# Deploy security rules
firebase deploy --only firestore:rules
```

### Issue: "Cloud Function timeout"

**Solution:**
Edit `functions/src/config/constants.ts`:
```typescript
export const FUNCTION_TIMEOUT = 300; // 5 minutes
```

### Issue: "Terraform state locked"

**Solution:**
```bash
cd terraform
terraform force-unlock <lock-id>
```

### Issue: "Emulators not starting"

**Solution:**
```bash
# Kill any existing processes
npx kill-port 8080 9099 9199 5001

# Clear Firebase cache
firebase setup:emulators:firestore
firebase setup:emulators:storage

# Restart
firebase emulators:start
```

---

## 📚 Next Steps

After completing the quick start:

1. **Read the Full Guide**: [MASTER_IMPLEMENTATION_GUIDE.md](MASTER_IMPLEMENTATION_GUIDE.md)

2. **Implement Features**:
   - [ ] Complete authentication Cloud Functions
   - [ ] Build UI screens
   - [ ] Implement matching algorithm
   - [ ] Add real-time messaging
   - [ ] Integrate video calling
   - [ ] Setup payment processing

3. **Customize Branding**:
   - Update colors in `lib/core/constants/app_colors.dart`
   - Replace logo in `assets/images/`
   - Update app name in `pubspec.yaml`

4. **Configure Monitoring**:
   - Setup Sentry for error tracking
   - Configure Firebase Analytics
   - Create custom dashboards

5. **Security Hardening**:
   - Review security rules
   - Enable App Check
   - Setup DDoS protection
   - Configure VPC Service Controls

6. **Performance Optimization**:
   - Enable CDN caching
   - Optimize images
   - Implement lazy loading
   - Add pagination

---

## 🆘 Getting Help

- **Documentation**: See [README.md](README.md)
- **Issues**: Create a GitHub issue
- **Support**: support@greengochat.com
- **Community**: Join our Discord

---

## ✅ Checklist for Go-Live

Before launching to production:

### Infrastructure
- [ ] Terraform infrastructure deployed
- [ ] All APIs enabled
- [ ] Service accounts configured
- [ ] Cloud KMS setup
- [ ] Backups configured
- [ ] Monitoring enabled
- [ ] Alerts configured

### Backend
- [ ] Cloud Functions deployed
- [ ] Security rules active
- [ ] Indexes created
- [ ] Environment variables set
- [ ] Third-party services configured

### Frontend
- [ ] App builds successfully
- [ ] All features tested
- [ ] Analytics integrated
- [ ] Crash reporting enabled
- [ ] App store assets ready

### Security
- [ ] OAuth providers configured
- [ ] SSL certificates active
- [ ] Data encryption enabled
- [ ] Security audit completed
- [ ] Privacy policy published
- [ ] Terms of service published

### Compliance
- [ ] GDPR compliance implemented
- [ ] Data export functionality
- [ ] Account deletion workflow
- [ ] Cookie consent (web)
- [ ] Age verification

### Testing
- [ ] Unit tests passing
- [ ] Integration tests passing
- [ ] E2E tests passing
- [ ] Load testing completed
- [ ] Security testing completed

### Operations
- [ ] Runbook created
- [ ] Incident response plan
- [ ] Support channels setup
- [ ] Monitoring dashboards
- [ ] Backup/restore tested

---

**Happy Coding! 💚**
