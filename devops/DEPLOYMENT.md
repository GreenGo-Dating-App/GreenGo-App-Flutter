# GreenGoChat - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Firebase Setup](#firebase-setup)
3. [Google Cloud Platform Setup](#google-cloud-platform-setup)
4. [Flutter Project Configuration](#flutter-project-configuration)
5. [Building the Application](#building-the-application)
6. [Deployment to Production](#deployment-to-production)
7. [Testing](#testing)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)

---

## Prerequisites

### Required Tools
- **Flutter SDK**: Version 3.0.0 or higher
- **Dart SDK**: Version 3.0.0 or higher
- **Android Studio** or **VS Code** with Flutter extensions
- **Xcode** (for iOS deployment, macOS only)
- **Firebase CLI**: Install via `npm install -g firebase-tools`
- **Google Cloud SDK**: [Install here](https://cloud.google.com/sdk/docs/install)
- **Git**: For version control

### Required Accounts
- **Firebase** account with Blaze (Pay as you go) plan
- **Google Cloud Platform** account
- **Apple Developer** account (for iOS deployment)
- **Google Play** developer account (for Android deployment)

---

## Firebase Setup

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project**
3. Enter project name: `greengo-chat-prod` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Select or create Analytics account
6. Click **Create Project**

### 2. Enable Firebase Services

#### Authentication
```bash
# Enable Email/Password
1. Navigate to Authentication → Sign-in method
2. Enable Email/Password provider
3. Enable Google Sign-In (add your OAuth client IDs)
4. Enable Facebook Login (add Facebook App ID and secret)
```

#### Cloud Firestore
```bash
# Create Firestore database
1. Navigate to Firestore Database
2. Click "Create database"
3. Choose production mode
4. Select location (choose closest to your users)

# Set up security rules (update with your rules)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Profiles collection
    match /profiles/{profileId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == profileId;
    }

    // Matches collection
    match /matches/{matchId} {
      allow read, write: if request.auth != null &&
        (resource.data.user1Id == request.auth.uid ||
         resource.data.user2Id == request.auth.uid);
    }

    // Messages collection
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow write: if request.auth != null;
    }
  }
}
```

#### Firebase Storage
```bash
# Set up storage
1. Navigate to Storage
2. Click "Get started"
3. Use production mode security rules

# Storage rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/photos/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
        request.resource.size < 5 * 1024 * 1024 && // 5MB limit
        request.resource.contentType.matches('image/.*');
    }

    match /users/{userId}/voice/{fileName} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId &&
        request.resource.size < 10 * 1024 * 1024 && // 10MB limit
        request.resource.contentType.matches('audio/.*');
    }
  }
}
```

#### Firebase Cloud Messaging (FCM)
```bash
1. Navigate to Project Settings → Cloud Messaging
2. Note your Server Key and Sender ID
3. For iOS, upload your APNs certificate
```

#### Firebase Crashlytics
```bash
# Already configured in the app
# View crashes at: Crashlytics → Dashboard
```

#### Firebase Remote Config
```bash
1. Navigate to Remote Config
2. Add parameters:
   - feature_video_calls_enabled: true (Boolean)
   - feature_voice_messages_enabled: true (Boolean)
   - max_photos_per_profile: 6 (Number)
   - max_distance_km: 100 (Number)
   - subscription_prices_usd: {"basic": 0, "silver": 9.99, "gold": 19.99} (JSON)
3. Publish changes
```

### 3. Add Apps to Firebase Project

#### Android App
```bash
1. Click "Add app" → Android
2. Enter package name: com.greengochat.greengochatapp
3. Download google-services.json
4. Place in: android/app/google-services.json
```

#### iOS App
```bash
1. Click "Add app" → iOS
2. Enter bundle ID: com.greengochat.greengochatapp
3. Download GoogleService-Info.plist
4. Place in: ios/Runner/GoogleService-Info.plist
```

---

## Google Cloud Platform Setup

### 1. Enable Required APIs

```bash
# Login to GCP
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Enable APIs
gcloud services enable \
  firestore.googleapis.com \
  storage-api.googleapis.com \
  cloudmessaging.googleapis.com \
  identitytoolkit.googleapis.com \
  maps-backend.googleapis.com \
  places-backend.googleapis.com
```

### 2. Google Maps Setup

```bash
1. Go to Google Cloud Console → APIs & Services → Credentials
2. Click "Create Credentials" → API Key
3. Restrict key:
   - Application restrictions: Android/iOS apps
   - API restrictions: Maps SDK, Places API, Geocoding API
4. Add your package name and SHA-1 certificate fingerprint
```

**Get SHA-1 fingerprint:**
```bash
# Debug keystore
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release keystore
keytool -list -v -keystore /path/to/release.keystore -alias your-key-alias
```

### 3. Configure API Keys

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<manifest>
  <application>
    <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_ANDROID_API_KEY"/>
  </application>
</manifest>
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_IOS_API_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

---

## Flutter Project Configuration

### 1. Install Dependencies

```bash
cd "C:\Users\Software Engineering\GreenGo App"

# Get Flutter dependencies
flutter pub get

# Run code generation
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Environment Configuration

Create environment-specific configuration files:

**lib/core/config/env_config.dart**:
```dart
class EnvConfig {
  static const String environment = String.fromEnvironment('ENV', defaultValue: 'development');
  static const bool isProduction = environment == 'production';
  static const bool isDevelopment = environment == 'development';

  // API endpoints
  static const String apiBaseUrl = isProduction
    ? 'https://api.greengochat.com'
    : 'https://api-dev.greengochat.com';
}
```

### 3. Update App Version

**pubspec.yaml**:
```yaml
version: 1.0.0+1  # Increment before each release
```

---

## Building the Application

### Android Build

#### Debug Build
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

#### Release Build
```bash
# Generate upload keystore (first time only)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create key.properties file
# android/key.properties
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=<path-to-keystore>

# Build release APK
flutter build apk --release

# Build App Bundle (recommended for Play Store)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Update android/app/build.gradle.kts
```kotlin
android {
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### iOS Build

#### Prerequisites
```bash
# Install CocoaPods
sudo gem install cocoapods

# Install iOS dependencies
cd ios
pod install
cd ..
```

#### Debug Build
```bash
flutter build ios --debug
```

#### Release Build
```bash
# Build for release
flutter build ios --release

# Create archive in Xcode
1. Open ios/Runner.xcworkspace in Xcode
2. Select "Any iOS Device" as target
3. Product → Archive
4. Distribute App → App Store Connect
```

---

## Deployment to Production

### Google Play Store (Android)

#### 1. Prepare Store Listing
- App name, description, screenshots
- Privacy policy URL
- Content rating questionnaire
- Pricing and distribution settings

#### 2. Upload App Bundle
```bash
# Using Google Play Console
1. Go to Play Console → All apps → Create app
2. Fill in app details
3. Navigate to Production → Create new release
4. Upload app-release.aab
5. Fill in release notes
6. Review and roll out

# Or use fastlane (automated)
cd android
fastlane supply --aab ../build/app/outputs/bundle/release/app-release.aab
```

### Apple App Store (iOS)

#### 1. App Store Connect Setup
```bash
1. Go to App Store Connect
2. My Apps → + → New App
3. Fill in app information:
   - Platform: iOS
   - Name: GreenGoChat
   - Primary Language: English
   - Bundle ID: com.greengochat.greengochatapp
   - SKU: GREENGOCHAT001
```

#### 2. Upload Build
```bash
# Using Xcode
1. Archive the app (Product → Archive)
2. Distribute App → App Store Connect
3. Upload

# Or use Transporter app
1. Export IPA from Xcode
2. Open Transporter
3. Drag and drop IPA file
4. Deliver
```

#### 3. Submit for Review
```bash
1. Select build in App Store Connect
2. Add screenshots, description, keywords
3. Set pricing
4. Submit for review
```

---

## Testing

### Running Tests

#### Unit Tests
```bash
flutter test
```

#### Integration Tests
```bash
flutter test integration_test/
```

#### Widget Tests
```bash
flutter test test/widget_test/
```

### Using Mock Servers

See [TEST_MOCK_SETUP.sh](#test-script) for detailed mock server setup.

```bash
# Run with mock servers
chmod +x TEST_MOCK_SETUP.sh
./TEST_MOCK_SETUP.sh
```

---

## Monitoring and Maintenance

### Firebase Console Monitoring

#### Crashlytics
```bash
# View crash reports
https://console.firebase.google.com/project/YOUR_PROJECT/crashlytics

# Set up crash alerts
1. Navigate to Project Settings → Integrations
2. Enable Crashlytics email notifications
```

#### Performance Monitoring
```bash
# View performance metrics
https://console.firebase.google.com/project/YOUR_PROJECT/performance

# Monitor:
- App start time
- Screen rendering performance
- Network request latency
```

#### Analytics
```bash
# View user analytics
https://console.firebase.google.com/project/YOUR_PROJECT/analytics

# Track:
- Daily/Monthly active users
- User retention
- Event funnels (registration → match → message)
```

### Cloud Firestore Monitoring

```bash
# Monitor usage
1. Navigate to Firestore → Usage tab
2. Track:
   - Document reads/writes
   - Storage usage
   - Network egress

# Set up billing alerts
1. Go to GCP Console → Billing → Budgets & alerts
2. Create budget alert for Firestore costs
```

### Remote Config Updates

```bash
# Update app behavior without new release
1. Firebase Console → Remote Config
2. Update parameters
3. Publish changes
4. Changes propagate to users within fetch interval (1 hour default)
```

---

## Required Servers and Infrastructure

### Firebase Services (Managed by Google)
- **Firebase Authentication**: User authentication and management
- **Cloud Firestore**: NoSQL database for app data
- **Firebase Storage**: Media file storage (photos, audio)
- **Firebase Cloud Messaging**: Push notifications
- **Firebase Crashlytics**: Crash reporting
- **Firebase Analytics**: User behavior analytics
- **Firebase Performance**: App performance monitoring
- **Firebase Remote Config**: Dynamic app configuration

### Optional Backend Services

#### Custom API Server (if needed)
```bash
# For custom business logic, deploy backend API to:
- Google Cloud Run (serverless)
- Google Compute Engine (VMs)
- Google Kubernetes Engine (containers)

# Example Cloud Run deployment
gcloud run deploy greengo-api \
  --image gcr.io/YOUR_PROJECT/greengo-api \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated
```

#### Cloud Functions (Serverless)
```bash
# For background tasks and triggers
# Examples:
- Send notification on new match
- Process uploaded photos
- Generate thumbnails
- Clean up old data

# Deploy function
firebase deploy --only functions
```

---

## Security Considerations

### 1. Secure API Keys
```bash
# Never commit API keys to version control
# Use environment variables or secure key management

# Add to .gitignore:
android/key.properties
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
.env
```

### 2. Enable App Check
```bash
# Protect backend resources from abuse
1. Firebase Console → App Check
2. Register apps
3. Enable enforcement for:
   - Cloud Firestore
   - Cloud Storage
   - Cloud Functions
```

### 3. Implement Rate Limiting
```bash
# Use Firebase Security Rules with rate limiting
match /users/{userId} {
  allow write: if request.auth.uid == userId &&
    request.time > resource.data.lastUpdate + duration.value(1, 's');
}
```

---

## Troubleshooting

### Common Issues

#### Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --release
```

#### Firebase Initialization Issues
```bash
# Verify google-services.json placement
# Verify Firebase config in main.dart
# Check Firebase project settings match
```

#### iOS CocoaPods Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter build ios
```

---

## Support and Resources

- **Flutter Documentation**: https://docs.flutter.dev
- **Firebase Documentation**: https://firebase.google.com/docs
- **Google Cloud Documentation**: https://cloud.google.com/docs
- **Project Repository**: [Your Git Repository URL]

---

## Version History

- **v1.0.0** (2025-01-17): Initial production release
  - Email/password authentication
  - Social login (Google, Facebook)
  - Profile creation and management
  - Discovery and matching
  - Real-time messaging
  - Multi-language support (7 languages)

---

**Last Updated**: January 2025
