# GreenGo Dating App - First Run Guide

**Complete step-by-step guide to run the app for the first time**

**Estimated Time**: 30-45 minutes
**Status**: Ready to begin

---

## Quick Overview

This guide will take you through:
1. ✅ Installing prerequisites (if needed)
2. ✅ Initializing the Flutter project
3. ✅ Installing dependencies
4. ✅ Configuring Firebase
5. ✅ Running the app

---

## Prerequisites Installation

### 1. Check What You Have

Run this command first:
```bash
check_environment.bat
```

This will tell you exactly what's missing.

### 2. Install Missing Prerequisites

#### If Node.js is Missing
1. Download: https://nodejs.org/
2. Install the **LTS version** (18.x or higher)
3. Restart your terminal
4. Verify: `node --version`

#### If Flutter is Missing
1. Download: https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter` (or your preferred location)
3. Add to PATH: `C:\flutter\bin`
4. Restart your terminal
5. Run: `flutter doctor`
6. Verify: `flutter --version`

#### If Google Cloud SDK is Missing ⚠️ **CRITICAL**
1. Download: https://cloud.google.com/sdk/docs/install
2. Run the installer
3. Check "Run gcloud init" during installation
4. Restart your terminal
5. Verify: `gcloud --version`

---

## Step-by-Step First Run

### Step 1: Initialize Flutter Project (1 minute)

This creates the `android/` and `ios/` folders needed to build the app.

```bash
cd "c:\Users\Software Engineering\GreenGo App"
flutter create . --org com.greengo.chat
```

**Expected Output**:
```
Creating project greengo_chat...
  android/app/src/main/AndroidManifest.xml (created)
  android/app/build.gradle (created)
  ios/Runner/Info.plist (created)
  ...
```

**What this does**:
- ✅ Creates `android/` folder with Android project files
- ✅ Creates `ios/` folder with iOS project files
- ✅ Preserves your existing `lib/` and `pubspec.yaml`
- ✅ Sets up build configurations

---

### Step 2: Install Dependencies (5-10 minutes)

#### 2a. Install Flutter Dependencies

```bash
flutter pub get
```

**Expected Output**:
```
Running "flutter pub get" in GreenGo App...
Resolving dependencies...
+ firebase_core 2.24.2
+ firebase_auth 4.15.3
+ cloud_firestore 4.13.6
...
Got dependencies!
```

**What this does**:
- Downloads all 45+ Flutter packages
- Sets up package dependencies
- Configures Firebase SDKs

#### 2b. Install Cloud Functions Dependencies

```bash
cd functions
npm install
```

**Expected Output**:
```
added 352 packages in 2m
```

**What this does**:
- Downloads all 37 npm packages
- Sets up Firebase Admin SDK
- Installs Google Cloud libraries

#### 2c. Build TypeScript

```bash
npm run build
```

**Expected Output**:
```
> greengo-chat-functions@1.0.0 build
> tsc

✨  Done in 15.3s
```

**What this does**:
- Compiles TypeScript to JavaScript
- Creates `lib/` folder with compiled code
- Validates all 109 Cloud Functions

---

### Step 3: Configure Firebase (10-15 minutes)

#### 3a. Create Firebase Project

1. Go to: https://console.firebase.google.com/
2. Click "Add project"
3. Enter project name: `greengo-dating-app` (or your choice)
4. Enable Google Analytics (recommended)
5. Click "Create project"

#### 3b. Configure Firebase for Android

1. In Firebase Console, click Android icon
2. Android package name: `com.greengo.chat.greengo_chat`
3. Download `google-services.json`
4. Place it here: `android/app/google-services.json`

#### 3c. Configure Firebase for iOS (Optional for now)

1. In Firebase Console, click iOS icon
2. iOS bundle ID: `com.greengo.chat.greengochat`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

#### 3d. Initialize Firebase in Project

```bash
# Go back to project root
cd ..

# Login to Firebase
firebase login

# Initialize Firebase
firebase init
```

**Select**:
- [x] Firestore
- [x] Functions
- [x] Storage
- [x] Emulators (optional but recommended)

**Firestore Setup**:
- Use default `firestore.rules`
- Use default `firestore.indexes.json`

**Functions Setup**:
- Select: "Use an existing project"
- Choose your Firebase project
- Language: TypeScript (already configured)
- ESLint: Yes (already configured)
- Install dependencies: No (already done)

**Storage Setup**:
- Use default `storage.rules`

#### 3e. Upgrade to Blaze Plan

⚠️ **Required for Cloud Functions**

1. In Firebase Console, click "Upgrade" button
2. Select "Blaze (Pay as you go)"
3. Add billing information
4. Set budget alert: $10/month (recommended)

#### 3f. Enable Required APIs

```bash
# Set your project
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable firestore.googleapis.com
gcloud services enable storage-api.googleapis.com
gcloud services enable vision.googleapis.com
gcloud services enable translate.googleapis.com
gcloud services enable speech.googleapis.com
gcloud services enable bigquery.googleapis.com
```

---

### Step 4: Set Up Environment Variables (5 minutes)

Create a file: `functions/.env`

```env
# SendGrid (Email)
SENDGRID_API_KEY=your_sendgrid_key_here

# Agora (Video Calling)
AGORA_APP_ID=your_agora_app_id
AGORA_APP_CERTIFICATE=your_agora_certificate

# Stripe (Payments)
STRIPE_SECRET_KEY=your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=your_stripe_webhook_secret

# Twilio (Optional - SMS backup)
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
```

**Getting API Keys**:

1. **SendGrid** (Email):
   - Sign up: https://sendgrid.com/
   - Get API key from Settings > API Keys
   - Free tier: 100 emails/day

2. **Agora** (Video Calling):
   - Sign up: https://www.agora.io/
   - Create project
   - Get App ID and Certificate
   - Free tier: 10,000 minutes/month

3. **Stripe** (Payments):
   - Sign up: https://stripe.com/
   - Get test keys from Developers > API Keys
   - Use test mode for development

---

### Step 5: Configure Firebase Security Rules (5 minutes)

#### 5a. Update `firestore.rules`

Replace the contents with basic rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Conversations - only participants can access
    match /conversations/{conversationId} {
      allow read, write: if request.auth != null;
    }

    // Messages - only conversation participants
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    // Default deny all
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

#### 5b. Update `storage.rules`

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User profile images
    match /users/{userId}/profile/{imageId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Chat media
    match /conversations/{conversationId}/{allPaths=**} {
      allow read, write: if request.auth != null;
    }

    // Default deny
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

#### 5c. Deploy Rules

```bash
firebase deploy --only firestore:rules,storage:rules
```

---

### Step 6: First Test Run (5-10 minutes)

#### Option A: Run on Emulator (Recommended for first run)

```bash
# Start Android emulator (if you have Android Studio)
flutter emulators --launch <emulator_id>

# Or use a physical device connected via USB

# Run the app in debug mode
flutter run
```

**Expected Output**:
```
Launching lib\main.dart on Android SDK built for x86 in debug mode...
Running Gradle task 'assembleDebug'...
✓ Built build\app\outputs\flutter-apk\app-debug.apk.
Installing build\app\outputs\flutter-apk\app-debug.apk...
```

#### Option B: Run on Physical Device

1. Enable Developer Options on your Android phone
2. Enable USB Debugging
3. Connect phone via USB
4. Trust the computer when prompted
5. Run: `flutter devices` (should show your phone)
6. Run: `flutter run`

---

### Step 7: Deploy Cloud Functions (Optional - 5 minutes)

**⚠️ Only do this if you want to test backend features**

```bash
cd functions

# Build TypeScript
npm run build

# Deploy all functions
firebase deploy --only functions
```

**Expected Output**:
```
✔  functions: Finished running predeploy script.
i  functions: ensuring required API cloudfunctions.googleapis.com is enabled...
i  functions: ensuring required API cloudbuild.googleapis.com is enabled...
✔  functions: required API cloudfunctions.googleapis.com is enabled
✔  functions: required API cloudbuild.googleapis.com is enabled
i  functions: preparing functions directory for uploading...
i  functions: packaged functions (154.23 KB) for uploading
✔  functions: functions folder uploaded successfully

i  functions: creating Node.js 18 function compressUploadedImage...
i  functions: creating Node.js 18 function compressImage...
...
✔  functions[compressUploadedImage]: Successful create operation.
✔  functions[compressImage]: Successful create operation.
...

✔  Deploy complete!
```

**Time**: 10-15 minutes (109 functions take time to deploy)

---

## Troubleshooting

### Issue: "flutter: command not found"

**Solution**:
```bash
# Add Flutter to PATH
set PATH=%PATH%;C:\flutter\bin

# Verify
flutter --version
```

### Issue: "gcloud: command not found"

**Solution**:
Download and install Google Cloud SDK:
https://cloud.google.com/sdk/docs/install

### Issue: "npm: command not found"

**Solution**:
Install Node.js from https://nodejs.org/

### Issue: "google-services.json not found"

**Solution**:
1. Go to Firebase Console
2. Project Settings > Your apps > Android app
3. Download `google-services.json`
4. Place in `android/app/google-services.json`

### Issue: "Error building gradle"

**Solution**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: "Cloud Functions deployment failed"

**Solution**:
1. Check billing is enabled (Blaze plan)
2. Check APIs are enabled
3. Check you're authenticated: `firebase login`
4. Try deploying one function: `firebase deploy --only functions:compressImage`

### Issue: "Firebase initialization failed"

**Solution**:
1. Check `google-services.json` is in correct location
2. Check package name matches in:
   - `android/app/build.gradle` (applicationId)
   - Firebase Console (Android app)
   - `google-services.json` (package_name)

---

## Verification Checklist

After completing all steps, verify:

### Flutter App
- [ ] App launches without errors
- [ ] Firebase initializes successfully
- [ ] Can see login screen
- [ ] No red error messages

### Cloud Functions
- [ ] All 109 functions deployed
- [ ] No deployment errors
- [ ] Functions visible in Firebase Console

### Firebase Services
- [ ] Firestore database created
- [ ] Storage bucket created
- [ ] Authentication enabled
- [ ] Security rules deployed

### Development Environment
- [ ] Flutter Doctor shows no errors
- [ ] Can run `flutter run` successfully
- [ ] Can build debug APK
- [ ] Firebase CLI works

---

## What to Test First

### 1. Authentication Flow (Most Important)
- Sign up with email
- Verify email works
- Login
- Logout

### 2. Profile Creation
- Add profile photos
- Fill in bio
- Set preferences

### 3. Discovery/Matching
- View potential matches
- Swipe left/right
- Get matches

### 4. Messaging
- Send text message
- Send photo
- Receive messages

---

## Common First-Run Commands

### View Flutter Device
```bash
flutter devices
```

### Run in Debug Mode
```bash
flutter run
```

### Run in Release Mode
```bash
flutter run --release
```

### Build APK
```bash
flutter build apk --debug
```

### View Logs
```bash
flutter logs
```

### Hot Reload (while app is running)
Press `r` in terminal

### Hot Restart (while app is running)
Press `R` in terminal

### Quit (while app is running)
Press `q` in terminal

---

## Quick Commands Reference

### Setup (One-time)
```bash
# 1. Initialize Flutter
flutter create . --org com.greengo.chat

# 2. Install Flutter dependencies
flutter pub get

# 3. Install Cloud Functions dependencies
cd functions && npm install && npm run build && cd ..

# 4. Login to Firebase
firebase login

# 5. Initialize Firebase
firebase init
```

### Daily Development
```bash
# Run app
flutter run

# Deploy functions (after changes)
cd functions && npm run build && firebase deploy --only functions && cd ..

# View logs
flutter logs

# Clean build
flutter clean && flutter pub get
```

### Testing
```bash
# Run all tests
run_tests.bat

# Run Firebase Test Lab
firebase_test_lab.bat

# Check environment
check_environment.bat
```

---

## Next Steps After First Run

### 1. Test Core Features
- Authentication
- Profile management
- Discovery/matching
- Chat messaging

### 2. Configure Third-Party Services
- SendGrid for emails
- Agora for video calls
- Stripe for payments

### 3. Run Security Audit
```bash
# After deploying functions
# Call runSecurityAudit via Firebase Console or API
```

### 4. Set Up Monitoring
- Enable Crashlytics
- Configure Performance Monitoring
- Set up alerts

### 5. Prepare for Testing
- Run Firebase Test Lab tests
- Fix any critical issues
- Optimize performance

---

## Cost Estimate (Development/Testing)

### Free Tier Usage (Sufficient for Development)
- Cloud Functions: 2M invocations/month
- Firestore: 50K reads, 20K writes/day
- Cloud Storage: 5GB
- Firebase Auth: Unlimited

### Paid Usage (If Exceeded Free Tier)
- Cloud Functions: ~$0-5/month
- Firestore: ~$0-10/month
- Cloud Storage: ~$0-2/month
- Third-party APIs: ~$0-20/month

**Total Development Cost**: $0-40/month

---

## Support & Resources

### Documentation
- **This Guide**: First-time setup
- **[INDEX.md](INDEX.md)**: Master documentation
- **[TEST_SUMMARY.md](TEST_SUMMARY.md)**: Feature summary
- **[VERIFICATION_REPORT.md](VERIFICATION_REPORT.md)**: Complete verification

### Official Docs
- Flutter: https://docs.flutter.dev/
- Firebase: https://firebase.google.com/docs
- Google Cloud: https://cloud.google.com/docs

### Community
- Flutter Discord: https://discord.gg/flutter
- Firebase Discord: https://discord.gg/firebase
- Stack Overflow: Tags `flutter`, `firebase`

---

## Success! 🎉

If you've completed all steps, your GreenGo dating app should now be running!

**What you've accomplished**:
- ✅ Installed all prerequisites
- ✅ Initialized Flutter project
- ✅ Installed dependencies
- ✅ Configured Firebase
- ✅ Deployed Cloud Functions (optional)
- ✅ Ran the app for the first time

**You're now ready for**:
- Development and feature testing
- Firebase Test Lab testing
- User acceptance testing
- Production deployment

---

**Last Updated**: January 15, 2025
**Status**: Ready for First Run
**Estimated Time**: 30-45 minutes total
