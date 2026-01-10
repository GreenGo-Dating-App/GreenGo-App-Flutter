# GreenGo Chat - Installation Guide

Complete step-by-step guide for setting up the GreenGo Chat application across Development, Test/Staging, and Production environments.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup (All Environments)](#initial-setup-all-environments)
3. [Development Environment Setup](#development-environment-setup)
4. [Test/Staging Environment Setup](#teststaging-environment-setup)
5. [Production Environment Setup](#production-environment-setup)
6. [Backend Setup (Django)](#backend-setup-django)
7. [Running the Application](#running-the-application)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Software

1. **Flutter SDK** (3.0.0 or higher)
   ```bash
   # Download from: https://flutter.dev/docs/get-started/install
   # Verify installation:
   flutter --version
   flutter doctor
   ```

2. **Dart SDK** (3.0.0 or higher)
   - Bundled with Flutter

3. **Git**
   ```bash
   git --version
   ```

4. **Node.js & npm** (16+ recommended)
   ```bash
   node --version
   npm --version
   ```

5. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

6. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire --version
   ```

7. **Python** (3.9+ for backend)
   ```bash
   python --version
   pip --version
   ```

8. **PostgreSQL** (14+ for backend database)
   ```bash
   psql --version
   ```

9. **Redis** (for caching and Celery)
   ```bash
   redis-cli --version
   ```

### Platform-Specific Prerequisites

#### For Android Development:
- **Android Studio** (latest version)
- **Android SDK** (API 21+)
- **Java JDK** (11 or 17)
  ```bash
  java --version
  keytool -version
  ```

#### For iOS Development (macOS only):
- **Xcode** (14.0+)
- **CocoaPods**
  ```bash
  sudo gem install cocoapods
  pod --version
  ```

#### For Web Development:
- Modern web browser (Chrome recommended)

### Account Requirements

- **Google Cloud Platform** account with billing enabled
- **Firebase** account (free tier or Blaze plan)
- **Stripe** account (for payments)
- **Agora.io** account (for video calling)
- **SendGrid** account (for emails)
- **Twilio** account (optional, for SMS)

---

## Initial Setup (All Environments)

### 1. Clone the Repository

```bash
cd "C:\Users\Software Engineering\GreenGo App"
git clone <your-repository-url> GreenGo-App-Flutter
cd GreenGo-App-Flutter
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Verify Flutter Setup

```bash
flutter doctor -v
```

Fix any issues reported by `flutter doctor` before proceeding.

### 4. Install Git Hooks (Optional)

```bash
# Install pre-commit hooks
pip install pre-commit
pre-commit install
```

---

## Development Environment Setup

### Step 1: Environment Configuration

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` file and set development values:**
   ```bash
   ENVIRONMENT=development

   # Firebase Configuration (from Firebase Console)
   GCP_PROJECT_ID=greengo-chat-dev
   FIREBASE_PROJECT_ID=greengo-chat-dev
   FIREBASE_API_KEY=<your-dev-api-key>
   FIREBASE_AUTH_DOMAIN=greengo-chat-dev.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=greengo-chat-dev.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=<your-sender-id>
   FIREBASE_APP_ID=<your-app-id>

   # Enable Firebase Emulators for local development
   USE_FIREBASE_EMULATORS=true
   FIRESTORE_EMULATOR_HOST=localhost:8080
   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099
   FIREBASE_STORAGE_EMULATOR_HOST=localhost:9199

   # Backend API (local Django server)
   BACKEND_API_URL=http://localhost:8000/api

   # Feature Flags (enable what you need)
   ENABLE_VIDEO_CALLING=false
   ENABLE_IN_APP_PURCHASES=false
   ENABLE_FIREBASE_ANALYTICS=false
   ```

### Step 2: Firebase Setup for Development

1. **Login to Firebase:**
   ```bash
   firebase login
   ```

2. **Create Firebase project (if not exists):**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project"
   - Project name: `greengo-chat-dev`
   - Enable Google Analytics: No (for dev)
   - Wait for project creation

3. **Configure Firebase for Flutter:**
   ```bash
   # This will create firebase_options.dart
   flutterfire configure --project=greengo-chat-dev
   ```

4. **Enable Firestore Database:**
   - Go to: https://console.firebase.google.com/project/greengo-chat-dev/firestore
   - Click "Create database"
   - Choose location: `us-central1`
   - Start in **Test mode** (for development)

5. **Enable Firebase Storage:**
   - Go to: https://console.firebase.google.com/project/greengo-chat-dev/storage
   - Click "Get Started"
   - Choose location: `us-central1`
   - Start in **Test mode**

6. **Enable Authentication:**
   - Go to: https://console.firebase.google.com/project/greengo-chat-dev/authentication
   - Click "Get started"
   - Enable **Email/Password** authentication

7. **Deploy Firestore Rules (dev rules):**
   ```bash
   firebase deploy --only firestore:rules --project greengo-chat-dev
   ```

8. **Deploy Storage Rules:**
   ```bash
   firebase deploy --only storage:rules --project greengo-chat-dev
   ```

### Step 3: Android Configuration for Development

1. **Get Debug Keystore SHA-1:**
   ```bash
   # Windows:
   keytool -keystore "%USERPROFILE%\.android\debug.keystore" -list -v -storepass android -keypass android

   # Linux/Mac:
   keytool -keystore ~/.android/debug.keystore -list -v -storepass android -keypass android
   ```

2. **Add SHA-1 to Firebase:**
   - Go to: https://console.firebase.google.com/project/greengo-chat-dev/settings/general
   - Scroll to "Your apps"
   - Click on Android app (or add if not exists)
   - Click "Add fingerprint"
   - Paste the SHA-1 from step 1
   - Click "Save"

3. **Download google-services.json:**
   - In Firebase Console, go to Project Settings → Your apps → Android app
   - Click "Download google-services.json"
   - Place it in: `android/app/google-services.json`

### Step 4: iOS Configuration for Development (macOS only)

1. **Download GoogleService-Info.plist:**
   - In Firebase Console, go to Project Settings → Your apps → iOS app
   - Click "Download GoogleService-Info.plist"
   - Place it in: `ios/Runner/GoogleService-Info.plist`

2. **Install CocoaPods dependencies:**
   ```bash
   cd ios
   pod install
   cd ..
   ```

### Step 5: Setup Firebase Emulators

1. **Initialize Firebase Emulators:**
   ```bash
   firebase init emulators
   ```
   - Select: Authentication, Firestore, Storage, Pub/Sub
   - Use default ports

2. **Configure emulator ports in `firebase.json`:**
   ```json
   {
     "emulators": {
       "auth": {
         "port": 9099
       },
       "firestore": {
         "port": 8080
       },
       "storage": {
         "port": 9199
       },
       "pubsub": {
         "port": 8085
       },
       "ui": {
         "enabled": true,
         "port": 4000
       }
     }
   }
   ```

3. **Start Firebase Emulators:**
   ```bash
   firebase emulators:start
   ```
   - Emulator UI: http://localhost:4000
   - Keep this terminal running

### Step 6: Backend Setup (Development)

See [Backend Setup (Django)](#backend-setup-django) section below.

### Step 7: Generate Required Files

```bash
# Generate localization files
flutter gen-l10n

# Run code generation for models and dependency injection
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 8: Verify Development Setup

```bash
# Run tests
flutter test

# Run app on emulator/simulator
flutter run
```

---

## Test/Staging Environment Setup

### Step 1: Environment Configuration

1. **Create separate `.env.test` file:**
   ```bash
   cp .env .env.test
   ```

2. **Update `.env.test` with staging values:**
   ```bash
   ENVIRONMENT=staging

   # Firebase Configuration (separate test project)
   GCP_PROJECT_ID=greengo-chat-test
   FIREBASE_PROJECT_ID=greengo-chat-test
   FIREBASE_API_KEY=<your-test-api-key>
   FIREBASE_AUTH_DOMAIN=greengo-chat-test.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=greengo-chat-test.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=<your-test-sender-id>
   FIREBASE_APP_ID=<your-test-app-id>

   # Disable emulators for test
   USE_FIREBASE_EMULATORS=false

   # Backend API (staging server)
   BACKEND_API_URL=https://api-test.greengochat.com/api

   # Enable analytics and crashlytics for testing
   ENABLE_FIREBASE_ANALYTICS=true
   ENABLE_CRASHLYTICS=true

   # Use test payment keys
   STRIPE_PUBLISHABLE_KEY=pk_test_<your-test-key>
   ```

### Step 2: Firebase Setup for Test/Staging

1. **Create separate Firebase project:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create new project: `greengo-chat-test`
   - Enable Google Analytics: Yes

2. **Configure Firebase for test environment:**
   ```bash
   flutterfire configure --project=greengo-chat-test
   ```

3. **Enable Firestore with production rules:**
   - Create database in `us-central1`
   - Start in **Production mode**
   - Deploy production-ready rules:
     ```bash
     firebase deploy --only firestore:rules --project greengo-chat-test
     ```

4. **Enable Firebase Storage with production rules:**
   ```bash
   firebase deploy --only storage:rules --project greengo-chat-test
   ```

5. **Enable Authentication:**
   - Enable Email/Password
   - Configure OAuth providers (Google, Apple, Facebook)

6. **Enable Firebase Crashlytics:**
   - Go to Crashlytics section
   - Click "Enable Crashlytics"

### Step 3: Android Configuration for Test

1. **Create upload keystore:**
   ```bash
   # Windows:
   keytool -genkey -v -keystore upload-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload

   # Save this file securely! Don't commit to Git!
   ```

2. **Create `android/key.properties`:**
   ```properties
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

3. **Get upload keystore SHA-1 and SHA-256:**
   ```bash
   keytool -keystore upload-keystore.jks -list -v
   ```

4. **Add both SHA fingerprints to Firebase test project**

5. **Download new `google-services.json` for test environment**

### Step 4: iOS Configuration for Test (macOS only)

1. **Download `GoogleService-Info.plist` for test project**

2. **Configure Xcode project:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select "Runner" target
   - Update Bundle Identifier: `com.greengochat.test`
   - Configure signing with your Apple Developer account

### Step 5: Build for Testing

```bash
# Build Android APK for testing
flutter build apk --release

# Build iOS for TestFlight (macOS only)
flutter build ios --release
```

### Step 6: Deploy to Firebase App Distribution

```bash
# Upload Android build
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app <your-firebase-app-id> \
  --groups testers \
  --release-notes "Test build $(date +%Y-%m-%d)"
```

---

## Production Environment Setup

### Step 1: Environment Configuration

1. **Create `.env.prod` file:**
   ```bash
   ENVIRONMENT=production

   # Firebase Configuration (production project)
   GCP_PROJECT_ID=greengo-chat-prod
   FIREBASE_PROJECT_ID=greengo-chat-prod
   FIREBASE_API_KEY=<your-prod-api-key>
   FIREBASE_AUTH_DOMAIN=greengo-chat-prod.firebaseapp.com
   FIREBASE_STORAGE_BUCKET=greengo-chat-prod.appspot.com
   FIREBASE_MESSAGING_SENDER_ID=<your-prod-sender-id>
   FIREBASE_APP_ID=<your-prod-app-id>
   FIREBASE_MEASUREMENT_ID=<your-measurement-id>

   # Backend API (production server)
   BACKEND_API_URL=https://api.greengochat.com/api

   # All monitoring enabled
   ENABLE_FIREBASE_ANALYTICS=true
   ENABLE_CRASHLYTICS=true
   ENABLE_PERFORMANCE_MONITORING=true

   # Production payment keys
   STRIPE_PUBLISHABLE_KEY=pk_live_<your-live-key>

   # Disable debug features
   DEBUG_MODE=false
   ENABLE_API_DOCS=false
   ```

### Step 2: Firebase Setup for Production

1. **Create production Firebase project:**
   - Project name: `greengo-chat-prod`
   - Enable Google Analytics: Yes
   - Upgrade to Blaze (pay-as-you-go) plan

2. **Configure Firebase:**
   ```bash
   flutterfire configure --project=greengo-chat-prod
   ```

3. **Setup Firestore:**
   - Create database in `us-central1`
   - **Production mode**
   - Deploy strict security rules:
     ```bash
     firebase deploy --only firestore:rules --project greengo-chat-prod
     ```

4. **Setup Firebase Storage:**
   ```bash
   firebase deploy --only storage:rules --project greengo-chat-prod
   ```

5. **Setup Firebase Functions (if applicable):**
   ```bash
   cd functions
   npm install
   cd ..
   firebase deploy --only functions --project greengo-chat-prod
   ```

6. **Enable all required services:**
   - Authentication (Email, Google, Apple, Facebook, Phone)
   - Firestore Database
   - Storage
   - Crashlytics
   - Performance Monitoring
   - Analytics
   - Cloud Messaging
   - Remote Config
   - App Check

### Step 3: Android Production Configuration

1. **Create production signing keystore:**
   ```bash
   keytool -genkey -v -keystore production-keystore.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias production

   # CRITICAL: Backup this file securely!
   # Store password in secure location (1Password, etc.)
   ```

2. **Update `android/key.properties` for production:**
   ```properties
   storePassword=<production-store-password>
   keyPassword=<production-key-password>
   keyAlias=production
   storeFile=../production-keystore.jks
   ```

3. **Get SHA fingerprints and add to Firebase**

4. **Download production `google-services.json`**

5. **Update `android/app/build.gradle`:**
   - Update `applicationId` to production bundle ID
   - Update `versionCode` and `versionName`

### Step 4: iOS Production Configuration (macOS only)

1. **Apple Developer Setup:**
   - Create App ID in Apple Developer Portal
   - Create Distribution certificate
   - Create Distribution provisioning profile

2. **Xcode Configuration:**
   - Bundle Identifier: `com.greengochat.app`
   - Configure push notifications capability
   - Configure App Groups (if needed)
   - Configure signing with Distribution profile

3. **Download production `GoogleService-Info.plist`**

### Step 5: Build for Production

#### Android (Google Play Store):

```bash
# Build Android App Bundle (recommended)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### iOS (App Store):

```bash
# Build iOS archive (macOS only)
flutter build ios --release

# Open Xcode to archive and upload:
open ios/Runner.xcworkspace
```

### Step 6: App Store Submission

#### Google Play Console:
1. Create app listing
2. Upload `app-release.aab`
3. Complete store listing
4. Submit for review

#### Apple App Store Connect:
1. Create app in App Store Connect
2. Archive in Xcode
3. Upload to App Store Connect
4. Complete app information
5. Submit for review

---

## Backend Setup (Django)

### Development Environment

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create virtual environment:**
   ```bash
   # Windows:
   python -m venv venv
   venv\Scripts\activate

   # Linux/Mac:
   python3 -m venv venv
   source venv/bin/activate
   ```

3. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

4. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

5. **Update `.env` with local settings:**
   ```bash
   DJANGO_SECRET_KEY=<generate-a-secret-key>
   DJANGO_DEBUG=True
   DATABASE_NAME=greengo_chat_dev
   DATABASE_USER=postgres
   DATABASE_PASSWORD=<your-db-password>
   DATABASE_HOST=localhost
   DATABASE_PORT=5432
   ```

6. **Setup PostgreSQL database:**
   ```sql
   -- Connect to PostgreSQL
   psql -U postgres

   -- Create database and user
   CREATE DATABASE greengo_chat_dev;
   CREATE USER greengo_user WITH PASSWORD 'your-password';
   ALTER ROLE greengo_user SET client_encoding TO 'utf8';
   ALTER ROLE greengo_user SET default_transaction_isolation TO 'read committed';
   ALTER ROLE greengo_user SET timezone TO 'UTC';
   GRANT ALL PRIVILEGES ON DATABASE greengo_chat_dev TO greengo_user;
   ```

7. **Run database migrations:**
   ```bash
   python manage.py migrate
   ```

8. **Create superuser:**
   ```bash
   python manage.py createsuperuser
   ```

9. **Start Redis (in separate terminal):**
   ```bash
   redis-server
   ```

10. **Start Celery worker (in separate terminal):**
    ```bash
    celery -A config worker -l info
    ```

11. **Run development server:**
    ```bash
    python manage.py runserver 0.0.0.0:8000
    ```
    - API will be available at: http://localhost:8000/api
    - Admin panel: http://localhost:8000/admin

### Test/Staging Backend

1. **Deploy to Google Cloud Run / App Engine / Compute Engine**

2. **Setup Cloud SQL PostgreSQL:**
   ```bash
   # Create Cloud SQL instance
   gcloud sql instances create greengo-db-test \
     --database-version=POSTGRES_14 \
     --tier=db-f1-micro \
     --region=us-central1
   ```

3. **Configure environment variables in cloud platform**

4. **Run migrations on cloud:**
   ```bash
   python manage.py migrate --settings=config.settings.staging
   ```

### Production Backend

1. **Use production-grade database:**
   - Cloud SQL PostgreSQL (Recommended)
   - Or managed PostgreSQL service

2. **Setup Redis:**
   - Cloud Memorystore (GCP)
   - Or managed Redis service

3. **Configure environment variables:**
   ```bash
   DJANGO_DEBUG=False
   DJANGO_ALLOWED_HOSTS=api.greengochat.com
   # Use production database credentials
   # Use production API keys
   ```

4. **Deploy with HTTPS enabled**

5. **Setup automated backups**

6. **Configure monitoring and alerting**

---

## Running the Application

### Development (with Firebase Emulators)

1. **Start Firebase Emulators (Terminal 1):**
   ```bash
   firebase emulators:start
   ```

2. **Start Backend (Terminal 2):**
   ```bash
   cd backend
   venv\Scripts\activate  # or source venv/bin/activate on Linux/Mac
   python manage.py runserver
   ```

3. **Start Redis (Terminal 3):**
   ```bash
   redis-server
   ```

4. **Start Celery (Terminal 4):**
   ```bash
   cd backend
   celery -A config worker -l info
   ```

5. **Run Flutter app (Terminal 5):**
   ```bash
   # Make sure to use development environment
   flutter run
   ```

### Test/Staging

```bash
# Use deploy script
./deploy.sh test android

# Or manually:
flutter run --release --dart-define=ENVIRONMENT=staging
```

### Production

```bash
# Use deploy script
./deploy.sh prod android

# Or manually build:
flutter build appbundle --release --dart-define=ENVIRONMENT=production
```

---

## Deployment

### Using the Deployment Script

The project includes a unified deployment script that handles all environments and platforms.

#### Deploy to Development:
```bash
./deploy.sh dev android
```

#### Deploy to Test:
```bash
./deploy.sh test android --clean
```

#### Deploy to Production:
```bash
./deploy.sh prod android --skip-tests
```

#### Deploy All Platforms:
```bash
./deploy.sh prod all
```

### Manual Deployment

#### Android:
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# App Bundle (for Play Store)
flutter build appbundle --release
```

#### iOS (macOS only):
```bash
# Build
flutter build ios --release

# Then open Xcode to archive and upload
open ios/Runner.xcworkspace
```

#### Web:
```bash
# Build
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting --project greengo-chat-prod
```

---

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues

**Problem:** `flutter doctor` shows errors

**Solutions:**
```bash
# Accept Android licenses
flutter doctor --android-licenses

# Update Flutter
flutter upgrade

# Clear cache
flutter clean
```

#### 2. Firebase Configuration Issues

**Problem:** "No Firebase App has been created"

**Solutions:**
```bash
# Re-run FlutterFire configuration
flutterfire configure --project=your-project-id

# Check if firebase_options.dart exists
ls lib/firebase_options.dart

# Verify Firebase initialization in main.dart
```

#### 3. Build Runner Errors

**Problem:** Code generation fails

**Solutions:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

#### 4. Android Build Failures

**Problem:** Build fails with "Execution failed for task ':app:mergeDebugResources'"

**Solutions:**
```bash
# Clean Android build
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

#### 5. iOS Build Failures (macOS)

**Problem:** CocoaPods errors

**Solutions:**
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

#### 6. Firebase Emulator Connection Issues

**Problem:** App can't connect to emulators

**Solutions:**
- Check `USE_FIREBASE_EMULATORS=true` in `.env`
- Verify emulators are running: `firebase emulators:start`
- Check emulator UI at http://localhost:4000
- Restart emulators

#### 7. Backend Connection Issues

**Problem:** Flutter app can't connect to Django backend

**Solutions:**
- Verify backend is running: `curl http://localhost:8000/api/health`
- Check `BACKEND_API_URL` in `.env`
- For Android emulator, use `http://10.0.2.2:8000/api` instead of `localhost`
- Check CORS settings in Django

#### 8. Database Migration Errors

**Problem:** Django migrations fail

**Solutions:**
```bash
# Reset database (DEVELOPMENT ONLY!)
python manage.py migrate --fake <app_name> zero
python manage.py migrate

# Or create new migration
python manage.py makemigrations
python manage.py migrate
```

#### 9. Permission Errors

**Problem:** Camera, location, or storage permission denied

**Solutions:**
- Check `AndroidManifest.xml` for required permissions
- Check `Info.plist` for iOS permissions
- Request permissions at runtime using `permission_handler` package

#### 10. Release Build Crashes

**Problem:** App crashes in release mode but works in debug

**Solutions:**
- Check ProGuard rules (Android)
- Enable crash reporting (Crashlytics)
- Test release build thoroughly:
  ```bash
  flutter run --release
  ```

### Getting Help

- **Documentation:** Check `/docs` folder
- **Firebase Setup:** See `FIREBASE_SETUP.md`
- **Feature Flags:** See `FEATURE_FLAGS.md`
- **Implementation Details:** See `IMPLEMENTATION_SUMMARY.md`
- **Agora Issues:** See `AGORA_FIX.md`

### Environment-Specific Checklist

#### Before Running Development:
- [ ] Firebase Emulators running
- [ ] Backend server running
- [ ] Redis running
- [ ] PostgreSQL running
- [ ] `.env` file configured
- [ ] `flutter pub get` completed
- [ ] Code generation completed

#### Before Deploying to Test:
- [ ] All tests passing
- [ ] Firebase test project configured
- [ ] Backend deployed to staging
- [ ] Environment variables updated
- [ ] Build keystore configured
- [ ] Version number updated

#### Before Deploying to Production:
- [ ] Full QA testing completed
- [ ] All critical bugs fixed
- [ ] Firebase production project configured
- [ ] Backend deployed to production
- [ ] Production API keys configured
- [ ] Release notes prepared
- [ ] App store assets ready
- [ ] Version number incremented
- [ ] Production keystore secured

---

## Next Steps

After completing installation:

1. **Review the codebase structure:**
   - `/lib/core` - Core utilities and configuration
   - `/lib/features` - Feature modules
   - `/lib/shared` - Shared widgets and utilities

2. **Read feature documentation:**
   - `FEATURE_FLAGS.md` - Feature flag configuration
   - `QUICK_START_FEATURE_FLAGS.md` - Quick reference

3. **Setup your IDE:**
   - Install Flutter and Dart plugins
   - Configure code formatters
   - Setup debugging configurations

4. **Join the development workflow:**
   - Create a feature branch
   - Make changes
   - Run tests
   - Submit pull request

---

**Last Updated:** 2024-11-17
**Version:** 1.0.0

For questions or issues, please contact the development team.
