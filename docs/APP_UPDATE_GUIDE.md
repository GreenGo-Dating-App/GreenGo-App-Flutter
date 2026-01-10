# GreenGo App Update Guide

Complete guide for building, deploying, and managing app updates for Android and iOS.

---

## Table of Contents

1. [Overview](#overview)
2. [Version Numbering](#version-numbering)
3. [Android Updates](#android-updates)
4. [iOS Updates](#ios-updates)
5. [Triggering In-App Updates](#triggering-in-app-updates)
6. [Update Scenarios](#update-scenarios)
7. [Rollback Procedures](#rollback-procedures)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The GreenGo app uses a **Firestore-based version control system** that allows you to:

- **Force Update (Hard)**: Block app usage until user updates (for critical/security fixes)
- **Soft Update**: Prompt user to update but allow skipping (for new features)
- **Maintenance Mode**: Block all users during server maintenance

### How It Works

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   App Starts    │────▶│  Check Firestore │────▶│  Compare Versions│
└─────────────────┘     │  app_config/ver  │     └────────┬────────┘
                        └──────────────────┘              │
                                                          ▼
                        ┌─────────────────────────────────────────────┐
                        │                                             │
              ┌─────────┴─────────┐  ┌──────────┴──────────┐  ┌──────┴──────┐
              │  installed <      │  │  installed <        │  │   Up to     │
              │  minVersion       │  │  recommendedVersion │  │   Date      │
              └────────┬──────────┘  └──────────┬──────────┘  └──────┬──────┘
                       │                        │                    │
                       ▼                        ▼                    ▼
              ┌────────────────┐     ┌─────────────────┐     ┌─────────────┐
              │  FORCE UPDATE  │     │   SOFT UPDATE   │     │  Continue   │
              │  (Blocking)    │     │   (Dismissible) │     │  to App     │
              └────────────────┘     └─────────────────┘     └─────────────┘
```

---

## Version Numbering

### Semantic Versioning Format

```
MAJOR.MINOR.PATCH+BUILD
  │     │     │     │
  │     │     │     └── Build number (auto-increment for each build)
  │     │     └──────── Patch: Bug fixes (no new features)
  │     └────────────── Minor: New features (backward compatible)
  └──────────────────── Major: Breaking changes (force update)
```

### Examples

| Version | Meaning |
|---------|---------|
| `1.0.0+1` | Initial release |
| `1.0.1+5` | Bug fix release |
| `1.1.0+10` | New feature release |
| `2.0.0+25` | Major update with breaking changes |

### Update Version in pubspec.yaml

```yaml
# File: pubspec.yaml
name: greengo_chat
version: 1.2.0+15  # <-- Update this
```

The format is `MAJOR.MINOR.PATCH+BUILD_NUMBER`

---

## Android Updates

### Prerequisites

1. **Android Studio** installed
2. **Java JDK 17+** installed
3. **Release Keystore** created and secured
4. **Google Play Console** account with app created

### Step 1: Update Version Number

Edit `pubspec.yaml`:

```yaml
version: 1.2.0+15  # Increment appropriately
```

**Important**: The build number (`+15`) must always increase for Play Store uploads.

### Step 2: Update Release Notes

Edit `android/fastlane/metadata/android/en-US/changelogs/15.txt`:

```
- New chat features
- Performance improvements
- Bug fixes
```

The filename should match your build number.

### Step 3: Build Release APK/AAB

#### Option A: Build App Bundle (Recommended for Play Store)

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release App Bundle
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

#### Option B: Build APK (For direct distribution)

```bash
flutter build apk --release --split-per-abi

# Outputs:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
# build/app/outputs/flutter-apk/app-x86_64-release.apk
```

### Step 4: Sign the Release

The app should auto-sign if `android/key.properties` is configured:

```properties
# File: android/key.properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=greengo_release
storeFile=../keystore/greengo-release.jks
```

**Never commit this file to git!**

### Step 5: Upload to Google Play Console

#### Manual Upload:

1. Go to [Google Play Console](https://play.google.com/console)
2. Select **GreenGo** app
3. Navigate to **Release** > **Production** (or Testing track)
4. Click **Create new release**
5. Upload `app-release.aab`
6. Add release notes
7. Click **Review release**
8. Click **Start rollout to Production**

#### Using Fastlane (Automated):

```bash
cd android

# Upload to internal testing
fastlane supply --track internal --aab ../build/app/outputs/bundle/release/app-release.aab

# Upload to production
fastlane supply --track production --aab ../build/app/outputs/bundle/release/app-release.aab
```

### Step 6: Configure Staged Rollout (Recommended)

In Play Console, set rollout percentage:

| Stage | Percentage | Duration | Purpose |
|-------|------------|----------|---------|
| 1 | 1% | 24 hours | Catch critical bugs |
| 2 | 5% | 24 hours | Monitor crash rates |
| 3 | 20% | 24 hours | Broader testing |
| 4 | 50% | 24 hours | Half user base |
| 5 | 100% | - | Full release |

### Step 7: Trigger In-App Update

After the update is live on Play Store, update Firestore to notify users:

```javascript
// Firebase Console > Firestore > app_config/version

// For SOFT update (recommended for most releases):
{
  "android": {
    "minVersion": "1.0.0",           // Keep existing
    "recommendedVersion": "1.2.0",   // Set to new version
    "currentVersion": "1.2.0",       // Set to new version
    "storeUrl": "https://play.google.com/store/apps/details?id=com.greengo.chat",
    "releaseNotes": "New chat features and performance improvements"
  }
}

// For FORCE update (critical security fixes only):
{
  "android": {
    "minVersion": "1.2.0",           // Set to new version - FORCES all users
    "recommendedVersion": "1.2.0",
    "currentVersion": "1.2.0",
    "storeUrl": "https://play.google.com/store/apps/details?id=com.greengo.chat",
    "releaseNotes": "Critical security update. Please update immediately."
  }
}
```

---

## iOS Updates

### Prerequisites

1. **macOS** with **Xcode 15+** installed
2. **Apple Developer Account** ($99/year)
3. **App Store Connect** app created
4. **Distribution Certificate** and **Provisioning Profile**

### Step 1: Update Version Number

Edit `pubspec.yaml`:

```yaml
version: 1.2.0+15  # Increment appropriately
```

Also verify `ios/Runner/Info.plist` (usually auto-synced):

```xml
<key>CFBundleShortVersionString</key>
<string>1.2.0</string>
<key>CFBundleVersion</key>
<string>15</string>
```

### Step 2: Build iOS Release

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build iOS release
flutter build ios --release

# This creates: build/ios/iphoneos/Runner.app
```

### Step 3: Open in Xcode and Archive

```bash
# Open Xcode workspace
open ios/Runner.xcworkspace
```

In Xcode:

1. Select **Any iOS Device (arm64)** as build target
2. Go to **Product** > **Archive**
3. Wait for archive to complete
4. **Organizer** window opens automatically

### Step 4: Upload to App Store Connect

In Xcode Organizer:

1. Select the archive
2. Click **Distribute App**
3. Select **App Store Connect**
4. Select **Upload**
5. Choose signing options (automatic recommended)
6. Click **Upload**

#### Using Fastlane (Automated):

```bash
cd ios

# Build and upload to TestFlight
fastlane beta

# Build and upload to App Store
fastlane release
```

### Step 5: Submit for App Review

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select **GreenGo** app
3. Click **+ Version or Platform** > **iOS**
4. Enter version number: `1.2.0`
5. Select the build you uploaded
6. Fill in **What's New** (release notes)
7. Complete all required metadata
8. Click **Submit for Review**

### Step 6: App Review Timeline

| Review Type | Typical Duration |
|-------------|------------------|
| Standard | 24-48 hours |
| Expedited (request) | 12-24 hours |
| Rejection + Resubmit | Add 24-48 hours |

### Step 7: Release After Approval

Options after approval:

| Option | Description |
|--------|-------------|
| **Manual Release** | You control when it goes live |
| **Automatic Release** | Goes live immediately after approval |
| **Phased Release** | Gradual rollout over 7 days |

Recommended: Use **Phased Release** for major updates.

### Step 8: Trigger In-App Update

After the update is live on App Store, update Firestore:

```javascript
// Firebase Console > Firestore > app_config/version

{
  "ios": {
    "minVersion": "1.0.0",           // Keep for soft update
    "recommendedVersion": "1.2.0",   // Set to new version
    "currentVersion": "1.2.0",
    "storeUrl": "https://apps.apple.com/app/greengo/id123456789",
    "releaseNotes": "New chat features and performance improvements"
  }
}
```

---

## Triggering In-App Updates

### Using Firebase Console (Manual)

1. Go to **Firebase Console** > **Firestore Database**
2. Navigate to `app_config` > `version`
3. Edit the appropriate platform fields

### Using Admin Script (Recommended)

Create file `scripts/release_update.js`:

```javascript
const admin = require('firebase-admin');

// Initialize with service account
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function releaseUpdate(options) {
  const {
    platform,           // 'android' or 'ios'
    version,            // '1.2.0'
    releaseNotes,       // 'What's new...'
    isForceUpdate       // true = force, false = soft
  } = options;

  const updates = {
    [`${platform}.currentVersion`]: version,
    [`${platform}.recommendedVersion`]: version,
    [`${platform}.releaseNotes`]: releaseNotes,
    [`${platform}.releaseDate`]: new Date().toISOString(),
    'updatedAt': admin.firestore.FieldValue.serverTimestamp(),
  };

  // Force update: set minVersion
  if (isForceUpdate) {
    updates[`${platform}.minVersion`] = version;
  }

  await db.doc('app_config/version').update(updates);

  console.log(`✅ ${platform} update released: v${version}`);
  console.log(`   Type: ${isForceUpdate ? 'FORCE' : 'SOFT'} update`);
}

// Example usage:
releaseUpdate({
  platform: 'android',
  version: '1.2.0',
  releaseNotes: '• New chat features\n• Performance improvements\n• Bug fixes',
  isForceUpdate: false
});
```

Run with:

```bash
node scripts/release_update.js
```

### Using Flutter Code (For Admin Panel)

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> releaseUpdate({
  required String platform,
  required String version,
  required String releaseNotes,
  bool isForceUpdate = false,
}) async {
  final docRef = FirebaseFirestore.instance.doc('app_config/version');

  final updates = <String, dynamic>{
    '$platform.currentVersion': version,
    '$platform.recommendedVersion': version,
    '$platform.releaseNotes': releaseNotes,
    '$platform.releaseDate': DateTime.now().toIso8601String(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  if (isForceUpdate) {
    updates['$platform.minVersion'] = version;
  }

  await docRef.update(updates);
}
```

---

## Update Scenarios

### Scenario 1: Regular Feature Release (Soft Update)

**Situation**: New features, non-critical bug fixes

```
User has: 1.1.0
Store has: 1.2.0

Firestore config:
  minVersion: 1.0.0        (unchanged)
  recommendedVersion: 1.2.0 (updated)

Result: User sees dismissible "Update Available" dialog
```

**Steps**:
1. Build and upload to stores
2. Wait for store approval
3. Update Firestore `recommendedVersion` to new version
4. Users see soft update prompt on next app launch

### Scenario 2: Critical Security Fix (Force Update)

**Situation**: Security vulnerability, critical bug, breaking API change

```
User has: 1.1.0
Store has: 1.2.0

Firestore config:
  minVersion: 1.2.0        (updated - FORCES update)
  recommendedVersion: 1.2.0

Result: User sees blocking "Update Required" dialog - cannot use app
```

**Steps**:
1. Build and upload to stores (request expedited review if critical)
2. Wait for store approval
3. Update Firestore `minVersion` to new version
4. ALL users below this version are blocked until they update

### Scenario 3: Phased Rollout

**Situation**: Major update, want to monitor stability

```
Day 1: Release to stores with 1% rollout
Day 2: Update Firestore for soft update (early adopters)
Day 3: Increase store rollout to 20%
Day 5: Increase to 50%
Day 7: Full 100% rollout
Day 8: Update Firestore minVersion (now everyone should update)
```

### Scenario 4: Platform-Specific Update

**Situation**: Android-only or iOS-only update

```javascript
// Only update Android, leave iOS unchanged
{
  "android": {
    "minVersion": "1.0.0",
    "recommendedVersion": "1.3.0",  // New Android version
    "currentVersion": "1.3.0"
  },
  "ios": {
    "minVersion": "1.0.0",
    "recommendedVersion": "1.2.0",  // iOS still on old version
    "currentVersion": "1.2.0"
  }
}
```

### Scenario 5: Emergency Maintenance

**Situation**: Server down, critical backend issue

```javascript
// Enable maintenance mode
{
  "maintenanceMode": true,
  "maintenanceMessage": "We are performing emergency maintenance. Expected duration: 30 minutes."
}

// After maintenance complete
{
  "maintenanceMode": false
}
```

---

## Rollback Procedures

### If Bad Update Released

#### Step 1: Immediate Mitigation

```javascript
// Lower the recommendedVersion to allow users to skip
// Or if force update was set, lower minVersion

// Firestore update:
{
  "android": {
    "minVersion": "1.1.0",         // Rollback to previous stable
    "recommendedVersion": "1.1.0"
  }
}
```

#### Step 2: Store Actions

**Google Play**:
1. Go to Play Console > Release > Production
2. Click **Halt rollout** (stops new installs)
3. Create new release with fixed version

**App Store**:
1. Go to App Store Connect
2. Click **Remove from Sale** (emergency only)
3. Or submit expedited review for fix

#### Step 3: Hotfix Release

1. Fix the issue
2. Increment version (e.g., 1.2.1)
3. Upload to stores
4. Request expedited review (App Store)
5. Once approved, update Firestore

---

## Troubleshooting

### Common Issues

#### "App not detecting new version"

1. Check Firestore document exists: `app_config/version`
2. Verify field names match exactly (case-sensitive)
3. Check platform field: `android` or `ios`
4. Ensure app has internet connection
5. Check Firebase console for any errors

#### "Force update not showing"

1. Compare versions correctly (semantic versioning)
2. Ensure `minVersion` > installed version
3. Check `storeUrl` is correct for the platform
4. Test with a lower installed version

#### "Update dialog shows but store link fails"

1. Verify store URL format:
   - Android: `https://play.google.com/store/apps/details?id=com.greengo.chat`
   - iOS: `https://apps.apple.com/app/greengo/id123456789`
2. Ensure app is published (not in draft)
3. Test URL in browser first

#### "Build number rejected by store"

- Build number must always increase
- Check current build number in store console
- Use next available number

### Debug Mode

Add this to check version status:

```dart
import 'core/services/version_check_service.dart';

// In your debug screen or console
final result = versionCheck.checkVersion();
print('Update type: ${result.updateType}');
print('Installed: ${result.installedVersion}');
print('Required: ${result.requiredVersion}');
```

---

## Quick Reference

### Version Update Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update changelog/release notes
- [ ] Run `flutter clean && flutter pub get`
- [ ] Build release (`flutter build appbundle` / `flutter build ios`)
- [ ] Upload to store (Play Console / App Store Connect)
- [ ] Wait for approval
- [ ] Update Firestore `app_config/version`
- [ ] Monitor crash reports and user feedback
- [ ] Gradually increase rollout percentage

### Firestore Document Structure

```
app_config/version
├── maintenanceMode: boolean
├── maintenanceMessage: string
├── android
│   ├── minVersion: string
│   ├── recommendedVersion: string
│   ├── currentVersion: string
│   ├── storeUrl: string
│   ├── releaseNotes: string
│   └── releaseDate: string
└── ios
    ├── minVersion: string
    ├── recommendedVersion: string
    ├── currentVersion: string
    ├── storeUrl: string
    ├── releaseNotes: string
    └── releaseDate: string
```

### Update Type Decision Tree

```
Is there a security vulnerability?
  YES → FORCE UPDATE (set minVersion)
  NO  ↓

Is there a breaking API change?
  YES → FORCE UPDATE (set minVersion)
  NO  ↓

Is it a major version (X.0.0)?
  YES → Consider FORCE UPDATE
  NO  ↓

Is it a minor/patch version?
  YES → SOFT UPDATE (set recommendedVersion only)
```
