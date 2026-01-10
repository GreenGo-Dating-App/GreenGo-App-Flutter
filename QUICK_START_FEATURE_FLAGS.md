# Quick Start: Feature Flags System

## Current Status: MVP Mode ✅

Your app is configured for MVP with **email/password authentication only**.

---

## How to Enable Google Sign-In (Example)

### 1. Update Feature Flag
**File:** `lib/core/config/app_config.dart`

```dart
static const bool enableGoogleAuth = true;  // Change false → true
```

### 2. Uncomment Dependencies
**File:** `pubspec.yaml`

```yaml
# Uncomment these lines:
google_sign_in: ^6.1.6
font_awesome_flutter: ^10.6.0
```

### 3. Uncomment Import
**File:** `lib/features/authentication/presentation/screens/login_screen.dart`

```dart
// Uncomment this line:
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
```

### 4. Setup Firebase
1. Add SHA-1 fingerprint to Firebase Console
2. Enable Google Sign-In in Firebase Authentication
3. Download updated `google-services.json`

### 5. Rebuild App
```bash
flutter clean
flutter pub get
flutter run
```

### ✅ Done!
Google Sign-In button will now appear on the login screen.

---

## Feature Flags Reference

**Location:** `lib/core/config/app_config.dart`

| Feature | Flag Variable | Default |
|---------|--------------|---------|
| Google Sign-In | `enableGoogleAuth` | `false` |
| Facebook Login | `enableFacebookAuth` | `false` |
| Biometric Auth | `enableBiometricAuth` | `false` |
| Apple Sign-In | `enableAppleAuth` | `false` |

---

## What Happens Automatically

✅ **When all flags are `false`:**
- No social login section shows
- Only email/password login visible
- Clean, simple MVP interface

✅ **When you enable ANY flag:**
- Social login section appears automatically
- Only enabled buttons show
- Divider and "Or continue with" text appears

✅ **Dynamic UI:**
- UI updates based on flags
- No manual code changes needed
- Just flip the flag and rebuild!

---

## See Full Documentation

For detailed instructions, requirements, and troubleshooting:
📖 **Read:** `FEATURE_FLAGS.md`

---

## Quick Test

Run your app and check the console output:

```
=================================
App Configuration (MVP)
=================================
Auth Methods: Email/Password
Social Login UI: false
...
=================================
```

This confirms your current configuration!

---

**Need help?** Check `FEATURE_FLAGS.md` for complete guide.
