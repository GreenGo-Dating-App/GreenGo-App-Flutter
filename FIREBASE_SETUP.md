# Firebase Setup Guide - GreenGo Chat App

Complete guide for setting up Firebase for Development, Test/Staging, and Production environments.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Development Environment Setup](#development-environment-setup)
3. [Test/Staging Environment Setup](#teststaging-environment-setup)
4. [Production Environment Setup](#production-environment-setup)
5. [Common Configuration Steps](#common-configuration-steps)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Tools

1. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Google Cloud SDK (Optional but recommended)**
   - Download from: https://cloud.google.com/sdk/install
   - After installation, authenticate:
     ```bash
     gcloud auth login
     ```

3. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. **Java Keytool** (comes with JDK)
   - Verify: `keytool -version`

---

## Development Environment Setup

### 1. Get Debug Keystore SHA-1 Fingerprint

```bash
keytool -keystore "%USERPROFILE%\.android\debug.keystore" -list -v -storepass android -keypass android
```

**Save these values:**
- **SHA-1:** `DA:A5:2F:5A:ED:69:10:83:65:B6:97:02:AE:82:B7:0E:4B:62:BA:0D`
- **SHA-256:** `E8:A8:F3:CB:1D:9F:3D:C2:3F:77:65:CF:97:EE:30:F3:0A:56:29:CC:A4:1C:C7:C2:21:4C:5F:5B:BC:2E:AA:84`

### 2. Run Firebase Setup Script

```bash
cd devops/scripts/firebase
./setup_firebase_dev.sh
```

**What this script does:**
- Creates Firebase project: `greengo-chat-dev`
- Configures Firestore with development rules
- Configures Storage with development rules
- Generates configuration files

### 3. Manual Steps After Script

#### A. Create Firestore Database

1. Go to: https://console.firebase.google.com/project/greengo-chat-dev/firestore
2. Click **"Create database"**
3. Choose location: **us-central1**
4. Start in **production mode** (rules will be deployed by script)
5. Wait for creation to complete

#### B. Initialize Firebase Storage

1. Go to: https://console.firebase.google.com/project/greengo-chat-dev/storage
2. Click **"Get Started"**
3. Choose location: **us-central1**
4. Start in **production mode**
5. Wait for creation to complete

#### C. Deploy Storage Rules

```bash
cd GreenGo-App-Flutter
firebase deploy --only storage:rules --project greengo-chat-dev
```

#### D. Configure Authentication

1. Go to: https://console.firebase.google.com/project/greengo-chat-dev/authentication/providers

2. **Enable Email/Password:**
   - Click on "Email/Password"
   - Enable the first toggle
   - Save

3. **Enable Google Sign-In:**
   - Click on "Google"
   - Enable
   - Add support email
   - Save

4. **Add SHA-1 Fingerprint:**
   - Go to Project Settings → Your apps → Android app
   - Scroll to "SHA certificate fingerprints"
   - Click "Add fingerprint"
   - Add debug SHA-1: `DA:A5:2F:5A:ED:69:10:83:65:B6:97:02:AE:82:B7:0E:4B:62:BA:0D`

5. **Download google-services.json:**
   - In Project Settings → Your apps → Android app
   - Click "Download google-services.json"
   - Save to: `android/app/google-services.json`

6. **Enable Facebook Login (Optional):**
   - Click on "Facebook"
   - Add App ID and App Secret from Facebook Developer Console
   - Save

#### E. Configure FlutterFire

```bash
flutterfire configure --project=greengo-chat-dev
```

### 4. Verify Setup

```bash
flutter clean
flutter pub get
flutter run
```

---

## Test/Staging Environment Setup

### 1. Get Release Keystore (Create if needed)

#### Create Release Keystore

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Save these details securely:**
- Keystore password
- Key password
- Key alias: `upload`

#### Get SHA-1 Fingerprint

```bash
keytool -keystore android/app/upload-keystore.jks -list -v
```

**Save the SHA-1 and SHA-256 values**

### 2. Configure Signing

Create/update `android/key.properties`:

```properties
storePassword=your-keystore-password
keyPassword=your-key-password
keyAlias=upload
storeFile=upload-keystore.jks
```

**IMPORTANT:** Add to `.gitignore`:
```
android/app/upload-keystore.jks
android/key.properties
```

### 3. Run Firebase Setup Script

```bash
cd devops/scripts/firebase
./setup_firebase_test.sh
```

**Project created:** `greengo-chat-staging`

### 4. Manual Steps

Follow the same manual steps as Development:
- Create Firestore Database
- Initialize Firebase Storage
- Deploy Storage Rules
- Configure Authentication (use staging SHA-1)
- Download `google-services.json` for staging
- Configure FlutterFire

```bash
flutterfire configure --project=greengo-chat-staging --out=lib/firebase_options_staging.dart
```

### 5. Environment-Specific Configuration

Create environment flavor configurations in `android/app/build.gradle`:

```gradle
android {
    flavorDimensions "environment"
    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
        }
        prod {
            dimension "environment"
        }
    }
}
```

---

## Production Environment Setup

### 1. Production Keystore

**CRITICAL:** Use a separate, highly secure keystore for production.

```bash
keytool -genkey -v -keystore android/app/greengo-prod-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias greengo-prod
```

**Security Requirements:**
- Use a very strong password
- Store keystore in secure location
- Backup keystore securely (loss means you can't update your app)
- Never commit to version control

#### Get Production SHA-1

```bash
keytool -keystore android/app/greengo-prod-keystore.jks -list -v
```

### 2. Run Production Setup Script

```bash
cd devops/scripts/firebase
./setup_firebase_prod.sh
```

**IMPORTANT:** Type `PRODUCTION` when prompted to confirm.

**Project created:** `greengo-chat-prod`

### 3. Manual Steps

#### A. Enable Billing

1. Go to: https://console.firebase.google.com/project/greengo-chat-prod/settings/billing
2. Enable billing (required for production)

#### B. Create Firestore Database

Same as dev, but for production project.

#### C. Initialize Firebase Storage

Same as dev, but for production project.

#### D. Deploy Storage Rules

```bash
firebase deploy --only storage:rules --project greengo-chat-prod
```

#### E. Configure Authentication

1. Enable Email/Password with **email verification required**
2. Enable Google Sign-In
3. Add production SHA-1 fingerprint
4. Configure OAuth consent screen in Google Cloud Console
5. Set up email templates for verification/password reset

#### F. Enable App Check

1. Go to: https://console.firebase.google.com/project/greengo-chat-prod/appcheck
2. Register your app
3. Enable enforcement for Firestore, Storage, and Authentication

#### G. Enable Crashlytics

1. Go to: https://console.firebase.google.com/project/greengo-chat-prod/crashlytics
2. Enable Crashlytics
3. Configure symbolication for release builds

#### H. Enable Performance Monitoring

1. Go to: https://console.firebase.google.com/project/greengo-chat-prod/performance
2. Enable Performance Monitoring

#### I. Set Up Analytics

1. Go to: https://console.firebase.google.com/project/greengo-chat-prod/analytics
2. Link to Google Analytics property
3. Configure data retention settings

#### J. Configure Automated Backups

1. Go to: https://console.cloud.google.com/firestore/databases/-default-/import-export?project=greengo-chat-prod
2. Set up automated Firestore exports
3. Configure Cloud Storage bucket lifecycle policies

#### K. Set Up Billing Alerts

1. Go to Google Cloud Console → Billing → Budgets & alerts
2. Create budget alerts to monitor costs

### 4. Production FlutterFire Configuration

```bash
flutterfire configure --project=greengo-chat-prod --out=lib/firebase_options_production.dart
```

---

## Common Configuration Steps

### Firebase Configuration Files

After running setup scripts, these files are created:

**Development:**
- `devops/scripts/firebase/firebase.json`
- `devops/scripts/firebase/firestore.rules`
- `devops/scripts/firebase/storage.rules`
- `devops/scripts/firebase/firestore.indexes.json`

**These are copied to project root for deployment.**

### Security Rules Overview

#### Development Rules (`firestore.rules`)
- **Permissive** - allows all access for testing
- Authentication required but minimal validation
- Useful for rapid development

#### Staging Rules (`firestore.staging.rules`)
- **Moderate** - requires authentication and basic validation
- User existence checks
- Immutable messages
- No deletion allowed

#### Production Rules (`firestore.prod.rules`)
- **Strict** - comprehensive security
- Email verification required
- Rate limiting
- Field validation
- Immutable critical fields
- Time-based constraints

### Environment Variables

Create `.env` files for each environment:

**.env.dev:**
```
ENVIRONMENT=dev
FIREBASE_PROJECT_ID=greengo-chat-dev
```

**.env.staging:**
```
ENVIRONMENT=staging
FIREBASE_PROJECT_ID=greengo-chat-staging
```

**.env.production:**
```
ENVIRONMENT=production
FIREBASE_PROJECT_ID=greengo-chat-prod
```

### Building for Different Environments

**Development:**
```bash
flutter run --flavor dev -t lib/main_dev.dart
```

**Staging:**
```bash
flutter run --flavor staging -t lib/main_staging.dart
```

**Production:**
```bash
flutter build apk --flavor prod -t lib/main_production.dart --release
```

---

## Troubleshooting

### Common Issues

#### 1. "Firebase API not enabled"

**Solution:**
```bash
gcloud auth login
gcloud services enable firestore.googleapis.com --project=PROJECT_ID
gcloud services enable firebaserules.googleapis.com --project=PROJECT_ID
gcloud services enable storage.googleapis.com --project=PROJECT_ID
gcloud services enable firebasestorage.googleapis.com --project=PROJECT_ID
```

#### 2. "Database does not exist"

**Solution:**
- Go to Firebase Console → Firestore
- Click "Create database"
- Follow wizard to create database

#### 3. "Storage has not been set up"

**Solution:**
- Go to Firebase Console → Storage
- Click "Get Started"
- Follow wizard to initialize storage

#### 4. "Index not necessary" error

**Solution:**
Firebase can handle simple queries automatically. Either:
- Deploy without indexes: `firebase deploy --only firestore:rules`
- Or use `--force` flag: `firebase deploy --only firestore --force`

#### 5. "SHA-1 fingerprint not found"

**Solution:**
- Verify keystore path is correct
- For debug: `%USERPROFILE%\.android\debug.keystore`
- Password for debug keystore: `android`

#### 6. "App Check token error"

**Normal for development.** In production:
- Enable App Check in Firebase Console
- Configure attestation providers (Play Integrity, reCAPTCHA)

#### 7. "CONFIGURATION_NOT_FOUND" reCAPTCHA error

**Solution:**
- Enable Email/Password authentication in Firebase Console
- Ensure `google-services.json` is in `android/app/`
- Rebuild the app after adding configuration

#### 8. "Permission denied" on deployment

**Solution:**
- Authenticate Firebase CLI: `firebase login --reauth`
- Verify you have Owner/Editor role on project
- Check billing is enabled (for production)

### Verify Configuration

#### Check Firebase Connection

```bash
firebase projects:list
firebase use greengo-chat-dev
firebase deploy --only firestore:rules --project greengo-chat-dev
```

#### Check Android Configuration

Verify `android/app/google-services.json` exists:
```bash
ls -la android/app/google-services.json
```

#### Check FlutterFire Configuration

Verify Firebase options file exists:
```bash
ls -la lib/firebase_options.dart
```

### Clean Rebuild

If experiencing issues:

```bash
flutter clean
rm -rf android/.gradle
rm -rf android/app/build
flutter pub get
flutter pub upgrade
flutter run
```

---

## Security Checklist

### Development
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] Authentication enabled
- [ ] Debug SHA-1 added

### Staging
- [ ] Firestore rules deployed (stricter)
- [ ] Storage rules deployed (stricter)
- [ ] Authentication enabled with validation
- [ ] Release SHA-1 added
- [ ] Test data isolation

### Production
- [ ] **Billing enabled**
- [ ] **Firestore rules deployed (strictest)**
- [ ] **Storage rules deployed (strictest)**
- [ ] **Email verification required**
- [ ] **App Check enabled**
- [ ] **Crashlytics enabled**
- [ ] **Performance Monitoring enabled**
- [ ] **Analytics configured**
- [ ] **Automated backups configured**
- [ ] **Billing alerts set up**
- [ ] **OAuth consent screen configured**
- [ ] **Production SHA-1 added**
- [ ] **Keystore backed up securely**
- [ ] **Remove development TODOs from rules**

---

## Important Files & Locations

### Firebase Configuration
```
devops/scripts/firebase/
├── setup_firebase_dev.sh          # Dev setup script
├── setup_firebase_test.sh         # Staging setup script
├── setup_firebase_prod.sh         # Production setup script
├── firebase.json                  # Dev config
├── firestore.rules                # Dev Firestore rules
├── firestore.staging.rules        # Staging Firestore rules
├── firestore.prod.rules           # Production Firestore rules
├── storage.rules                  # Dev Storage rules
├── storage.staging.rules          # Staging Storage rules
├── storage.prod.rules             # Production Storage rules
└── firestore.indexes.json         # Firestore indexes
```

### Android Configuration
```
android/app/
├── google-services.json           # Firebase config for Android
├── upload-keystore.jks            # Staging/Release keystore
└── greengo-prod-keystore.jks      # Production keystore

android/
└── key.properties                 # Keystore credentials (DO NOT COMMIT)
```

### Flutter Configuration
```
lib/
├── firebase_options.dart          # Dev Firebase options
├── firebase_options_staging.dart  # Staging Firebase options
├── firebase_options_production.dart # Production Firebase options
├── main_dev.dart                  # Dev entry point
├── main_staging.dart              # Staging entry point
└── main_production.dart           # Production entry point
```

---

## Quick Reference

### Firebase Projects

| Environment | Project ID | Region |
|------------|------------|--------|
| Development | greengo-chat-dev | us-central1 |
| Staging | greengo-chat-staging | us-central1 |
| Production | greengo-chat-prod | us-central1 |

### Console Links

**Development:**
- Firebase: https://console.firebase.google.com/project/greengo-chat-dev
- Firestore: https://console.firebase.google.com/project/greengo-chat-dev/firestore
- Storage: https://console.firebase.google.com/project/greengo-chat-dev/storage
- Auth: https://console.firebase.google.com/project/greengo-chat-dev/authentication

**Staging:**
- Firebase: https://console.firebase.google.com/project/greengo-chat-staging
- Firestore: https://console.firebase.google.com/project/greengo-chat-staging/firestore
- Storage: https://console.firebase.google.com/project/greengo-chat-staging/storage
- Auth: https://console.firebase.google.com/project/greengo-chat-staging/authentication

**Production:**
- Firebase: https://console.firebase.google.com/project/greengo-chat-prod
- Firestore: https://console.firebase.google.com/project/greengo-chat-prod/firestore
- Storage: https://console.firebase.google.com/project/greengo-chat-prod/storage
- Auth: https://console.firebase.google.com/project/greengo-chat-prod/authentication

### Useful Commands

```bash
# List Firebase projects
firebase projects:list

# Switch project
firebase use greengo-chat-dev

# Deploy Firestore rules only
firebase deploy --only firestore:rules --project PROJECT_ID

# Deploy Storage rules only
firebase deploy --only storage:rules --project PROJECT_ID

# Deploy everything
firebase deploy --project PROJECT_ID

# Start Firebase emulators
firebase emulators:start --project greengo-chat-dev

# Get keystore SHA-1
keytool -keystore PATH_TO_KEYSTORE -list -v

# FlutterFire configuration
flutterfire configure --project=PROJECT_ID
```

---

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review Firebase documentation: https://firebase.google.com/docs
3. Check script logs in `devops/scripts/firebase/*.log`

---

**Last Updated:** November 2025
**Version:** 1.0.0
