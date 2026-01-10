# Feature Flags Guide - GreenGo Chat App

This guide explains how to use the feature flag system to enable/disable authentication methods and other features in your app.

---

## Overview

The feature flag system allows you to:
- ✅ Enable/disable authentication methods (Google, Facebook, Biometric, Apple)
- ✅ Control which UI elements are shown
- ✅ Conditionally import libraries (reducing app size)
- ✅ Easy MVP → Full Product transition
- ✅ Environment-specific configurations

---

## Configuration File

**Location:** `lib/core/config/app_config.dart`

This file contains all feature flags as static constants.

---

## How to Enable/Disable Features

### Step 1: Update Feature Flags

Edit `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  static const String environment = 'MVP'; // or 'Production', 'Staging'

  // Set to true to enable, false to disable
  static const bool enableGoogleAuth = false;      // Google Sign-In
  static const bool enableFacebookAuth = false;    // Facebook Login
  static const bool enableBiometricAuth = false;   // Fingerprint/Face ID
  static const bool enableAppleAuth = false;       // Apple Sign-In
}
```

### Step 2: Update Dependencies in pubspec.yaml

When you enable a feature, uncomment the corresponding dependency:

#### For Google Authentication:
```yaml
# Uncomment when AppConfig.enableGoogleAuth = true
google_sign_in: ^6.1.6
```

#### For Facebook Authentication:
```yaml
# Uncomment when AppConfig.enableFacebookAuth = true
flutter_facebook_auth: ^6.0.3
```

#### For Biometric Authentication:
```yaml
# Uncomment when AppConfig.enableBiometricAuth = true
local_auth: ^2.1.8
```

#### For Apple Sign-In:
```yaml
# Uncomment when AppConfig.enableAppleAuth = true
sign_in_with_apple: ^5.0.0
```

#### For FontAwesome Icons (Google/Facebook):
```yaml
# Uncomment when enableGoogleAuth OR enableFacebookAuth = true
font_awesome_flutter: ^10.6.0
```

### Step 3: Update Imports

When social login is enabled, uncomment imports in these files:

#### A. `lib/features/authentication/presentation/screens/login_screen.dart`
```dart
// Uncomment when any social auth is enabled (for icons)
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
```

#### B. `lib/core/di/injection_container.dart`
```dart
// Uncomment when enableGoogleAuth = true
import 'package:google_sign_in/google_sign_in.dart';

// Uncomment when enableFacebookAuth = true
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

// Uncomment when enableBiometricAuth = true
import 'package:local_auth/local_auth.dart';

// Also uncomment the registration at the bottom:
if (AppConfig.enableGoogleAuth) {
  sl.registerLazySingleton(() => GoogleSignIn());
}

if (AppConfig.enableFacebookAuth) {
  sl.registerLazySingleton(() => FacebookAuth.instance);
}

if (AppConfig.enableBiometricAuth) {
  sl.registerLazySingleton(() => LocalAuthentication());
}
```

#### C. `lib/features/authentication/presentation/bloc/auth_bloc.dart`
```dart
// Uncomment when enableBiometricAuth = true
import 'package:local_auth/local_auth.dart';
```

#### D. `lib/features/authentication/data/datasources/auth_remote_data_source.dart`
```dart
// Uncomment when enableGoogleAuth = true
import 'package:google_sign_in/google_sign_in.dart';

// Uncomment when enableFacebookAuth = true
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
```

### Step 4: Run Flutter Commands

```bash
flutter clean
flutter pub get
flutter run
```

---

## Complete Examples

### Example 1: MVP with Only Email/Password (Current Setup)

**app_config.dart:**
```dart
static const bool enableGoogleAuth = false;
static const bool enableFacebookAuth = false;
static const bool enableBiometricAuth = false;
static const bool enableAppleAuth = false;
```

**pubspec.yaml:**
```yaml
# All social login dependencies commented out
# google_sign_in: ^6.1.6
# flutter_facebook_auth: ^6.0.3
# local_auth: ^2.1.8
# font_awesome_flutter: ^10.6.0
```

**Result:**
- Login screen shows only email/password fields
- No social login buttons
- Smaller app size
- Faster build times

---

### Example 2: Enable Google Sign-In

**Step 1 - app_config.dart:**
```dart
static const bool enableGoogleAuth = true;  // ← Changed to true
static const bool enableFacebookAuth = false;
static const bool enableBiometricAuth = false;
static const bool enableAppleAuth = false;
```

**Step 2 - pubspec.yaml:**
```yaml
# Uncomment these dependencies
google_sign_in: ^6.1.6              # ← Uncommented
font_awesome_flutter: ^10.6.0       # ← Uncommented (for Google icon)
```

**Step 3 - login_screen.dart:**
```dart
// Uncomment this import
import 'package:font_awesome_flutter/font_awesome_flutter.dart';  // ← Uncommented
```

**Step 4 - Firebase Console:**
1. Add SHA-1 fingerprint to Firebase project
2. Enable Google Sign-In in Authentication
3. Download updated `google-services.json`

**Step 5 - Run:**
```bash
flutter clean
flutter pub get
flutter run
```

**Result:**
- Login screen shows Google Sign-In button
- Google authentication works
- Email/password still available

---

### Example 3: Enable All Authentication Methods

**app_config.dart:**
```dart
static const bool enableGoogleAuth = true;
static const bool enableFacebookAuth = true;
static const bool enableBiometricAuth = true;
static const bool enableAppleAuth = true;  // iOS only
```

**pubspec.yaml:**
```yaml
# Uncomment all
google_sign_in: ^6.1.6
flutter_facebook_auth: ^6.0.3
local_auth: ^2.1.8
sign_in_with_apple: ^5.0.0
font_awesome_flutter: ^10.6.0
```

**login_screen.dart:**
```dart
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
```

**Result:**
- All authentication methods available
- Full-featured login screen
- Users can choose their preferred method

---

## Feature Requirements

When enabling each feature, ensure you've completed the requirements:

### Google Sign-In Requirements
- [ ] Uncomment `google_sign_in` in pubspec.yaml
- [ ] Uncomment `font_awesome_flutter` in pubspec.yaml
- [ ] Add SHA-1 fingerprint to Firebase Console
- [ ] Enable Google Sign-In in Firebase Authentication
- [ ] Download updated `google-services.json`
- [ ] Uncomment import in login_screen.dart

### Facebook Login Requirements
- [ ] Uncomment `flutter_facebook_auth` in pubspec.yaml
- [ ] Uncomment `font_awesome_flutter` in pubspec.yaml
- [ ] Create Facebook App in Facebook Developer Console
- [ ] Add App ID and App Secret to Firebase
- [ ] Enable Facebook in Firebase Authentication
- [ ] Configure `android/app/src/main/res/values/strings.xml`
- [ ] Uncomment import in login_screen.dart

### Biometric Authentication Requirements
- [ ] Uncomment `local_auth` in pubspec.yaml
- [ ] Add biometric permissions to `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  ```
- [ ] Add to `Info.plist` (iOS):
  ```xml
  <key>NSFaceIDUsageDescription</key>
  <string>We need Face ID for secure login</string>
  ```

### Apple Sign-In Requirements (iOS only)
- [ ] Uncomment `sign_in_with_apple` in pubspec.yaml
- [ ] Enable Apple Sign-In in Xcode Capabilities
- [ ] Configure Apple Sign-In in Firebase
- [ ] Apple Developer Account required

---

## How It Works

### 1. Configuration Layer
`lib/core/config/app_config.dart` contains compile-time constants that control features.

### 2. Conditional Rendering
The login screen uses Dart's `if` statements to conditionally render UI:

```dart
if (AppConfig.showSocialLoginSection) ...[
  // Social login UI
  if (AppConfig.enableGoogleAuth)
    _buildGoogleButton(),
  if (AppConfig.enableFacebookAuth)
    _buildFacebookButton(),
]
```

### 3. Auto-Hide/Show
- If **all** social auth flags are `false` → No social login section shows
- If **any** social auth flag is `true` → Social login section appears with enabled buttons only

---

## Benefits

### For MVP Development
- ✅ Start with minimal features (email/password only)
- ✅ Smaller APK size
- ✅ Faster build times
- ✅ Simpler testing
- ✅ No need for OAuth setup initially

### For Gradual Rollout
- ✅ Enable features one at a time
- ✅ Test each feature independently
- ✅ Easy rollback (just flip flag to false)
- ✅ Different configs for dev/staging/prod

### For Maintenance
- ✅ Single source of truth for features
- ✅ Clear documentation of what's enabled
- ✅ Easy to understand codebase
- ✅ No need to comment/uncomment multiple files

---

## Debugging

When you run the app, you'll see the configuration printed:

```
=================================
App Configuration (MVP)
=================================
Auth Methods: Email/Password
Social Login UI: false
In-App Purchases: true
Video Calls: false
Analytics: true
=================================
```

This helps you verify which features are enabled.

---

## Best Practices

### 1. Document Your Changes
When enabling a feature, update this document with any additional steps needed.

### 2. Use Environment-Specific Configs
Consider creating separate config files for different environments:
- `app_config_dev.dart` - Development (all features enabled for testing)
- `app_config_staging.dart` - Staging (beta features)
- `app_config_prod.dart` - Production (stable features only)

### 3. Test After Enabling Features
Always run a clean build and test thoroughly:
```bash
flutter clean
flutter pub get
flutter run
flutter test
```

### 4. Commit Dependencies
When enabling features for production, commit the uncommented dependencies.

### 5. Update Firebase Setup
Ensure Firebase Console settings match your enabled features.

---

## Troubleshooting

### Issue: Social login buttons not showing
**Solution:** Check that:
1. Feature flag is set to `true` in `app_config.dart`
2. App was rebuilt with `flutter clean && flutter pub get`
3. Dependencies are uncommented in `pubspec.yaml`

### Issue: Import errors after enabling feature
**Solution:**
1. Uncomment the import in `login_screen.dart`
2. Uncomment the dependency in `pubspec.yaml`
3. Run `flutter pub get`

### Issue: Google Sign-In not working
**Solution:**
1. Verify SHA-1 fingerprint is added to Firebase
2. Download updated `google-services.json`
3. Enable Google Sign-In in Firebase Console
4. Rebuild app completely

### Issue: Feature flag changes not reflecting
**Solution:**
1. Ensure you're editing the correct file (`lib/core/config/app_config.dart`)
2. Run hot restart (not just hot reload) - press `R` in terminal
3. If still not working, do a full rebuild: `flutter clean && flutter run`

---

## Migration Path: MVP → Full Product

### Phase 1: MVP (Current)
```dart
enableGoogleAuth = false
enableFacebookAuth = false
enableBiometricAuth = false
```

### Phase 2: Add Google Sign-In
```dart
enableGoogleAuth = true  // ← Enable
enableFacebookAuth = false
enableBiometricAuth = false
```

### Phase 3: Add All Social Login
```dart
enableGoogleAuth = true
enableFacebookAuth = true
enableBiometricAuth = true
```

### Phase 4: Full Features
```dart
// Authentication
enableGoogleAuth = true
enableFacebookAuth = true
enableBiometricAuth = true
enableAppleAuth = true

// Other features
enableVideoCalls = true
enableVoiceMessages = true
```

---

## Quick Reference

| Feature | Flag | Dependency | Import Needed |
|---------|------|------------|---------------|
| Google | `enableGoogleAuth` | `google_sign_in` | `font_awesome_flutter` |
| Facebook | `enableFacebookAuth` | `flutter_facebook_auth` | `font_awesome_flutter` |
| Biometric | `enableBiometricAuth` | `local_auth` | None |
| Apple | `enableAppleAuth` | `sign_in_with_apple` | None |

---

## Support

For questions or issues:
1. Check this documentation first
2. Review `FIREBASE_SETUP.md` for Firebase-specific setup
3. Check Flutter/Firebase documentation
4. Review app logs when debugging

---

**Last Updated:** November 2025
**Version:** 1.0.0
