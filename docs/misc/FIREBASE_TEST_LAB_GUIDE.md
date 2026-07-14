# Firebase Test Lab - Complete User Testing Guide

**Last Updated**: January 15, 2025
**Status**: Ready for User Testing

---

## Overview

Firebase Test Lab allows you to run your GreenGo dating app on real Android devices hosted in Google's data centers. This guide covers the complete setup and testing process.

---

## Prerequisites

### Required Software

1. **Node.js v18+**
   - Download: https://nodejs.org/
   - Verify: `node --version`

2. **Flutter SDK**
   - Download: https://flutter.dev/docs/get-started/install
   - Verify: `flutter --version`

3. **Firebase CLI**
   - Auto-installed by setup script
   - Manual install: `npm install -g firebase-tools`
   - Verify: `firebase --version`

4. **Google Cloud SDK**
   - Download: https://cloud.google.com/sdk/docs/install
   - **IMPORTANT**: Must be installed manually
   - Verify: `gcloud --version`

### Required Accounts

1. **Firebase Account**
   - Sign up: https://firebase.google.com/
   - Create project for GreenGo app

2. **Google Cloud Account**
   - Same account as Firebase
   - Billing must be enabled (Firebase Blaze plan)

---

## Quick Start (Windows)

### Step 1: Initial Setup

```cmd
# Run the setup script
setup_and_test.bat
```

This will:
- ✅ Check all dependencies
- ✅ Install npm packages
- ✅ Build TypeScript Cloud Functions
- ✅ Install Flutter dependencies
- ✅ Authenticate with Firebase/Google Cloud
- ✅ Build APK for testing

**Time Required**: 5-10 minutes

### Step 2: Run Tests

```cmd
# Run Firebase Test Lab
firebase_test_lab.bat
```

Choose your test configuration:
- **Quick Test** (1 device, 5 min) - Fast validation
- **Standard Test** (3 devices, 10 min) - Recommended
- **Comprehensive Test** (6 devices, 15 min) - Full coverage
- **Custom Test** - Manual configuration

---

## Quick Start (macOS/Linux)

### Step 1: Make Scripts Executable

```bash
chmod +x setup_and_test.sh
chmod +x firebase_test_lab.sh
```

### Step 2: Initial Setup

```bash
# Run the setup script
./setup_and_test.sh
```

### Step 3: Run Tests

```bash
# Run Firebase Test Lab
./firebase_test_lab.sh
```

---

## Detailed Setup Instructions

### 1. Install Google Cloud SDK

**Windows:**
1. Download installer: https://cloud.google.com/sdk/docs/install
2. Run GoogleCloudSDKInstaller.exe
3. Follow installation wizard
4. Open new command prompt
5. Run: `gcloud init`

**macOS:**
```bash
# Using Homebrew
brew install --cask google-cloud-sdk

# Initialize
gcloud init
```

**Linux:**
```bash
# Download and extract
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh

# Initialize
gcloud init
```

### 2. Configure Google Cloud Project

```bash
# Login to Google Cloud
gcloud auth login

# Set project (use your Firebase project ID)
gcloud config set project YOUR_PROJECT_ID

# Enable required APIs
gcloud services enable testing.googleapis.com
gcloud services enable toolresults.googleapis.com
gcloud services enable storage-api.googleapis.com
```

### 3. Enable Firebase Test Lab

1. Go to Firebase Console: https://console.firebase.google.com/
2. Select your project
3. Navigate to Test Lab in left sidebar
4. Click "Get Started" if prompted
5. Ensure Blaze (pay-as-you-go) plan is enabled

**Pricing**:
- First 10 tests/day on physical devices: FREE
- First 5 tests/day on virtual devices: FREE
- After free quota: $1-5 per device hour

### 4. Configure Firebase Storage Bucket

```bash
# Create storage bucket for test results
gsutil mb -p YOUR_PROJECT_ID gs://YOUR_PROJECT_ID-test-results

# Set bucket permissions
gsutil iam ch allUsers:objectViewer gs://YOUR_PROJECT_ID-test-results
```

---

## Test Configuration Options

### Quick Test (5 minutes)

**Devices**:
- Nexus 6P (Android API 29)

**Use Case**:
- Quick smoke test
- Verify app launches
- Check critical functionality

**Command**:
```bash
gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --device model=Nexus6P,version=29 \
  --timeout 5m
```

### Standard Test (10 minutes) - RECOMMENDED

**Devices**:
- Google Pixel 4 (Android API 30)
- Samsung Galaxy S21 (Android API 31)
- Nexus 6P (Android API 29)

**Use Case**:
- Comprehensive testing
- Multiple device types
- Different Android versions
- Best balance of coverage and cost

**Command**:
```bash
gcloud firebase test android run \
  --app build/app/outputs/flutter-apk/app-debug.apk \
  --device model=Pixel4,version=30 \
  --device model=a51,version=31 \
  --device model=Nexus6P,version=29 \
  --timeout 10m
```

### Comprehensive Test (15 minutes)

**Devices**:
- Google Pixel 5 (Android API 33) - Latest
- Google Pixel 4 (Android API 30)
- Samsung Galaxy S21 (Android API 31)
- Samsung Galaxy Tab S8 Ultra (Android API 32) - Tablet
- OnePlus 7 Pro (Android API 28) - Older device
- Nexus 6P (Android API 29)

**Use Case**:
- Pre-release validation
- Maximum device coverage
- Tablet testing
- Backward compatibility

---

## Available Test Devices

### Popular Flagship Devices

| Device | Model ID | Android API | Screen | RAM |
|--------|----------|-------------|--------|-----|
| Google Pixel 5 | Pixel5 | 33 | 6.0" FHD+ | 8GB |
| Google Pixel 4 | Pixel4 | 30 | 5.7" FHD+ | 6GB |
| Samsung Galaxy S21 | a51 | 31 | 6.5" FHD+ | 8GB |
| Samsung Tab S8 Ultra | gts8ultra | 32 | 14.6" WQXGA+ | 12GB |
| OnePlus 7 Pro | OnePlus7Pro | 28-29 | 6.67" QHD+ | 8GB |
| Nexus 6P | Nexus6P | 27-29 | 5.7" QHD | 3GB |

### View All Devices

```bash
# List all available Android devices
gcloud firebase test android models list

# Filter by API level
gcloud firebase test android models list --filter="supportedVersionIds:30"

# Filter by form factor
gcloud firebase test android models list --filter="form:VIRTUAL"
```

---

## Test Results & Reports

### Viewing Test Results

**Firebase Console** (Recommended):
1. Go to https://console.firebase.google.com/
2. Select your project
3. Click "Test Lab" in left sidebar
4. View test history and results

**Google Cloud Console**:
1. Go to https://console.cloud.google.com/
2. Navigate to Storage Browser
3. Open `YOUR_PROJECT_ID-test-results` bucket
4. Browse test result folders

### What's Included in Results

✅ **Video Recordings**
- Full test session recording
- Playback at 1x or 2x speed
- Timestamp annotations

✅ **Screenshots**
- Automatic screenshots at key points
- Error state captures
- UI state verification

✅ **Performance Metrics**
- CPU usage
- Memory consumption
- Network activity
- Battery drain

✅ **Crash Logs**
- Stack traces
- ANR (Application Not Responding) reports
- Native crash dumps

✅ **Code Coverage**
- Line coverage percentage
- Branch coverage
- Method coverage

✅ **Test Logs**
- Logcat output
- Firebase logs
- Custom instrumentation logs

---

## Testing User Flows

### Manual Testing Scenarios

Test Lab supports robo testing (automated UI exploration) and instrumentation tests. For GreenGo app, focus on:

#### Critical User Flows

1. **Authentication Flow**
   - Sign up with email
   - Phone verification
   - Profile creation
   - Photo upload

2. **Matching Flow**
   - Browse profiles
   - Swipe left/right
   - Match notification
   - Start chat

3. **Messaging Flow**
   - Send text message
   - Send photo
   - Voice message
   - Video call initiation

4. **Profile Flow**
   - Edit profile
   - Update photos
   - Change preferences
   - Privacy settings

5. **Subscription Flow**
   - View premium features
   - Select subscription tier
   - Payment (test mode)
   - Unlock features

### Automated Test Scenarios

Create instrumentation tests for automated validation:

```dart
// Example: integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete user flow test', (WidgetTester tester) async {
    // 1. Launch app
    await tester.pumpWidget(MyApp());

    // 2. Sign up flow
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // 3. Enter credentials
    await tester.enterText(find.byKey(Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(Key('password')), 'TestPass123!');

    // 4. Submit
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // 5. Verify profile screen
    expect(find.text('Create Your Profile'), findsOneWidget);
  });
}
```

Build test APK:
```bash
flutter build apk --debug
flutter build apk --debug integration_test/app_test.dart
```

---

## Cost Optimization

### Free Tier Limits

- **Virtual Devices**: 5 tests/day FREE
- **Physical Devices**: 10 tests/day FREE
- **Test Duration**: Up to 15 minutes per test

### Cost After Free Tier

| Device Type | Price per Hour |
|-------------|----------------|
| Virtual Device | $1 |
| Physical Device | $5 |

### Money-Saving Tips

1. **Use Virtual Devices First**
   - Virtual devices are cheaper
   - Good for initial testing
   - Physical devices for final validation

2. **Batch Your Tests**
   - Run comprehensive tests weekly
   - Quick tests for critical changes
   - Avoid redundant testing

3. **Set Appropriate Timeouts**
   - Quick Test: 5 minutes
   - Standard: 10 minutes
   - Comprehensive: 15 minutes max

4. **Use Targeted Device Sets**
   - Focus on popular devices
   - Cover different Android versions
   - Skip redundant configurations

5. **Schedule Tests Strategically**
   - Run overnight to avoid interruptions
   - Batch multiple features together
   - Use CI/CD for automated testing

---

## Troubleshooting

### Common Issues

#### 1. "APK not found" Error

**Problem**: Build APK doesn't exist

**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug
```

#### 2. "Authentication failed" Error

**Problem**: Not logged in to Firebase/Google Cloud

**Solution**:
```bash
# Login to Firebase
firebase login

# Login to Google Cloud
gcloud auth login

# Set project
gcloud config set project YOUR_PROJECT_ID
```

#### 3. "Permission denied" Error

**Problem**: Missing API permissions

**Solution**:
```bash
# Enable required APIs
gcloud services enable testing.googleapis.com
gcloud services enable toolresults.googleapis.com
gcloud services enable storage-api.googleapis.com
```

#### 4. "Billing not enabled" Error

**Problem**: Firebase project on Spark (free) plan

**Solution**:
1. Go to Firebase Console
2. Click "Upgrade" to Blaze plan
3. Add billing information
4. Set budget alerts (optional but recommended)

#### 5. "Device not available" Error

**Problem**: Requested device is offline or unavailable

**Solution**:
```bash
# Check device availability
gcloud firebase test android models list

# Use alternative device
# Instead of Pixel5, try Pixel4
```

#### 6. Tests Timing Out

**Problem**: App takes too long to load or crashes

**Solution**:
- Increase timeout: `--timeout 15m`
- Check app crashes in Firebase Crashlytics
- Review logcat in test results
- Optimize app startup time

---

## CI/CD Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: Firebase Test Lab

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.16.0'

    - name: Install dependencies
      run: flutter pub get

    - name: Build APK
      run: flutter build apk --debug

    - name: Authenticate to Google Cloud
      uses: google-github-actions/auth@v1
      with:
        credentials_json: ${{ secrets.GOOGLE_CLOUD_CREDENTIALS }}

    - name: Set up Cloud SDK
      uses: google-github-actions/setup-gcloud@v1

    - name: Run tests on Firebase Test Lab
      run: |
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=Pixel4,version=30 \
          --timeout 10m \
          --results-bucket=gs://${{ secrets.FIREBASE_PROJECT_ID }}-test-results
```

---

## Best Practices

### 1. Test Regularly

- **Daily**: Quick test on commits to main branch
- **Weekly**: Standard test for comprehensive coverage
- **Pre-Release**: Comprehensive test before app store submission

### 2. Monitor Test Results

- Review video recordings for UX issues
- Check performance metrics for bottlenecks
- Analyze crash logs immediately
- Track trends over time

### 3. Test Real User Scenarios

- Don't just test happy paths
- Test error handling
- Test edge cases (poor network, low storage)
- Test accessibility features

### 4. Use Test Matrix

Test on different:
- Android versions (API 28-33)
- Screen sizes (phone, tablet)
- Network conditions (WiFi, 4G, 3G)
- Languages (English, Spanish, etc.)

### 5. Automate Where Possible

- Write integration tests for critical flows
- Run tests automatically on code changes
- Set up alerts for test failures
- Generate reports automatically

---

## Environment Variables for Testing

Set these in `firebase_test_lab.bat` or `firebase_test_lab.sh`:

```bash
# Test mode flags
--environment-variables \
  coverage=true,\
  coverageFile=/sdcard/coverage.ec,\
  testMode=true,\
  clearState=true,\
  numShards=1
```

**Available Variables**:
- `coverage`: Enable code coverage
- `coverageFile`: Coverage output path
- `testMode`: Enable test mode features
- `clearState`: Clear app data before test
- `numShards`: Number of test shards (parallel execution)

---

## Next Steps

### After Setup Complete

1. **Run Your First Test**
   ```bash
   # Windows
   firebase_test_lab.bat

   # macOS/Linux
   ./firebase_test_lab.sh
   ```

2. **Review Results**
   - Check Firebase Console for test results
   - Watch video recordings
   - Review performance metrics
   - Fix any critical issues

3. **Set Up Monitoring**
   - Configure Firebase Crashlytics
   - Set up Performance Monitoring
   - Enable Analytics
   - Create custom dashboards

4. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

5. **Configure Production Environment**
   - Set up production Firebase project
   - Configure environment variables
   - Enable security rules
   - Set up backup systems

---

## Support & Resources

### Documentation
- Firebase Test Lab: https://firebase.google.com/docs/test-lab
- Google Cloud SDK: https://cloud.google.com/sdk/docs
- Flutter Testing: https://flutter.dev/docs/testing

### Pricing Calculator
https://firebase.google.com/pricing

### Community
- Firebase Discord: https://discord.gg/firebase
- Stack Overflow: Tag `firebase-test-lab`
- GitHub Issues: Project repository

---

## Checklist: Ready for User Testing

Before running your first test, verify:

- [ ] Node.js installed (v18+)
- [ ] Flutter installed and configured
- [ ] Firebase CLI installed
- [ ] Google Cloud SDK installed
- [ ] Firebase project created
- [ ] Billing enabled (Blaze plan)
- [ ] Authenticated with Firebase (`firebase login`)
- [ ] Authenticated with Google Cloud (`gcloud auth login`)
- [ ] Cloud Functions dependencies installed
- [ ] TypeScript compiled successfully
- [ ] Flutter dependencies installed
- [ ] APK built successfully
- [ ] Test Lab enabled in Firebase Console
- [ ] Storage bucket configured for results

**Run Verification**:
```bash
# Windows
setup_and_test.bat

# macOS/Linux
./setup_and_test.sh
```

If all steps pass, you're ready to run tests!

---

**Status**: ✅ READY FOR USER TESTING
**Last Updated**: January 15, 2025
**Version**: 1.0.0
