# Fix for Agora RTC Engine Build Error

## Problem
You're getting C++ linker errors when building with `agora_rtc_engine` package due to NDK 27 compatibility issues.

## Quick Fix (Option 1): Downgrade NDK ⭐ RECOMMENDED

### Step 1: Install NDK 25 or 26
```bash
# Open Android Studio
# Tools > SDK Manager > SDK Tools tab
# Check "Show Package Details"
# Under "NDK (Side by side)", install version 25.1.8937393 or 26.1.10909125
# Uncheck version 27.0.12077973
# Click Apply
```

### Step 2: Force Flutter to use NDK 25
Edit `android/local.properties` and add:
```properties
ndk.dir=C:\\Users\\Software Engineering\\AppData\\Local\\Android\\Sdk\\ndk\\25.1.8937393
```

### Step 3: Clean and rebuild
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

---

## Alternative Fix (Option 2): Temporarily Remove Agora

If you want to test other features without video calling first:

### Step 1: Comment out Agora in pubspec.yaml
```yaml
# Video Calling
# agora_rtc_engine: ^6.3.0  # Temporarily disabled
```

### Step 2: Update dependencies
```bash
flutter pub get
```

### Step 3: Comment out Agora imports in code
You'll need to comment out any Agora-related code in your Flutter app temporarily.

---

## Permanent Fix (Option 3): Wait for Agora Update

The Agora team is working on NDK 27 compatibility. Check for updates:
```bash
flutter pub upgrade agora_rtc_engine
```

---

## Solution I Recommend: Use NDK 25

**Why**: NDK 25 is stable and compatible with all your packages.

**Steps**:

1. **Install NDK 25 via Android Studio**:
   - Open Android Studio
   - File > Settings (or Preferences on Mac)
   - Appearance & Behavior > System Settings > Android SDK
   - SDK Tools tab
   - Check "Show Package Details"
   - Find "NDK (Side by side)"
   - Check version `25.1.8937393`
   - Click OK to install

2. **Configure Flutter to use NDK 25**:

   Edit `android/local.properties`:
   ```properties
   sdk.dir=C:\\Users\\Software Engineering\\AppData\\Local\\Android\\Sdk
   flutter.sdk=C:\\flutter
   ndk.dir=C:\\Users\\Software Engineering\\AppData\\Local\\Android\\Sdk\\ndk\\25.1.8937393
   ```

3. **Clean everything**:
   ```bash
   cd "c:\\Users\\Software Engineering\\GreenGo App"
   flutter clean
   cd android
   ./gradlew clean
   cd ..
   flutter pub get
   ```

4. **Build again**:
   ```bash
   flutter run
   ```

---

## Quick Test Without Video Calling

If you want to run the app immediately without fixing Agora:

1. **Edit pubspec.yaml** - Comment out agora:
   ```yaml
   # agora_rtc_engine: ^6.3.0
   ```

2. **Run**:
   ```bash
   flutter pub get
   flutter run
   ```

This will let you test all other features (authentication, chat, profiles, matching, etc.) while you set up NDK 25 for video calling.

---

## Why This Happens

- **NDK 27** changed how C++ standard library linking works
- **Agora RTC Engine 6.5.3** hasn't updated their native code for NDK 27 yet
- **NDK 25/26** work fine with current Agora versions

---

## Verification After Fix

Run this to check which NDK is being used:
```bash
cat android/local.properties
```

Should show:
```
ndk.dir=C:\\Users\\Software Engineering\\AppData\\Local\\Android\\Sdk\\ndk\\25.1.8937393
```

---

## Next Steps After Fix

1. Build should complete successfully
2. App will launch on emulator/device
3. All features except video calling will work immediately
4. Video calling requires Agora App ID configuration (see FIRST_RUN_GUIDE.md)

---

**Recommended Action**: Install NDK 25 and configure `local.properties`. This takes 5 minutes and solves the issue permanently.
