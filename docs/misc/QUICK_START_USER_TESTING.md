# Quick Start: User Testing on Firebase Test Lab

**Goal**: Get your GreenGo app running on virtual devices in Google Cloud within 30 minutes.

---

## Step 1: Verify Prerequisites (5 minutes)

### Windows
```cmd
check_environment.bat
```

### macOS/Linux
```bash
chmod +x check_environment.sh
./check_environment.sh
```

**What it checks**:
- ✅ Node.js installed
- ✅ Flutter installed
- ✅ Google Cloud SDK installed (REQUIRED)
- ✅ Firebase CLI installed
- ✅ Project files exist

### If Google Cloud SDK is Missing

**Critical Requirement**: You MUST install Google Cloud SDK manually.

**Windows**:
1. Download: https://cloud.google.com/sdk/docs/install
2. Run installer
3. Restart terminal

**macOS**:
```bash
brew install --cask google-cloud-sdk
```

**Linux**:
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

After installation:
```bash
gcloud init
```

---

## Step 2: Complete Setup (10-15 minutes)

### Windows
```cmd
setup_and_test.bat
```

### macOS/Linux
```bash
./setup_and_test.sh
```

**What it does**:
1. Installs all npm dependencies (~2 min)
2. Builds TypeScript Cloud Functions (~1 min)
3. Installs Flutter dependencies (~2 min)
4. Authenticates with Firebase/Google Cloud (interactive)
5. Builds Android APK for testing (~5 min)

**Total time**: 10-15 minutes (including downloads)

**Prompts you'll see**:
- Firebase login (opens browser)
- Google Cloud login (opens browser)
- Select Firebase project (if multiple)

---

## Step 3: Run Tests (10-15 minutes)

### Windows
```cmd
firebase_test_lab.bat
```

### macOS/Linux
```bash
./firebase_test_lab.sh
```

**Choose test configuration**:

```
[1] Quick Test - 1 device, 5 minutes
    Best for: Fast validation

[2] Standard Test - 3 devices, 10 minutes (RECOMMENDED)
    Best for: Comprehensive testing

[3] Comprehensive Test - 6 devices, 15 minutes
    Best for: Pre-release validation

[4] Custom Test - Configure manually
    Best for: Specific device testing
```

**Recommendation**: Start with option [2] Standard Test

---

## Step 4: View Results (Immediately after test completes)

### Firebase Console (Recommended)
1. Go to: https://console.firebase.google.com/
2. Select your project
3. Click "Test Lab" in sidebar
4. View results with videos, screenshots, logs

### What You'll See:
- ✅ Video recording of test session
- ✅ Screenshots at key moments
- ✅ Performance metrics (CPU, memory)
- ✅ Crash logs (if any)
- ✅ Code coverage report

---

## Quick Reference

### All Commands

| Task | Windows | macOS/Linux |
|------|---------|-------------|
| Check environment | `check_environment.bat` | `./check_environment.sh` |
| Setup & build | `setup_and_test.bat` | `./setup_and_test.sh` |
| Run tests | `firebase_test_lab.bat` | `./firebase_test_lab.sh` |

### Test Devices (Standard Configuration)

1. **Google Pixel 4** - Android 11 (API 30)
2. **Samsung Galaxy S21** - Android 12 (API 31)
3. **Nexus 6P** - Android 10 (API 29)

### Cost

- **First 10 tests/day**: FREE
- **After free tier**: $1-5 per test
- **Recommendation**: Run 1-2 tests per day during development

---

## Troubleshooting

### "APK not found"
```bash
flutter clean
flutter pub get
flutter build apk --debug
```

### "Not authenticated"
```bash
firebase login
gcloud auth login
```

### "Billing not enabled"
1. Go to Firebase Console
2. Upgrade to Blaze (pay-as-you-go) plan
3. Add billing info
4. Set budget alert at $10/month

### "Google Cloud SDK not found"
This is REQUIRED and cannot be auto-installed.
Download from: https://cloud.google.com/sdk/docs/install

---

## First Time Setup Checklist

Before running tests, ensure:

- [ ] Google Cloud SDK installed
- [ ] Node.js installed (v18+)
- [ ] Flutter installed
- [ ] Firebase project created
- [ ] Billing enabled (Blaze plan)
- [ ] Ran `check_environment.bat/.sh` successfully
- [ ] Ran `setup_and_test.bat/.sh` successfully

---

## Expected Timeline

| Step | Time | Details |
|------|------|---------|
| Check environment | 1 min | Verify prerequisites |
| Install dependencies | 2-3 min | npm install |
| Build TypeScript | 1 min | Compile functions |
| Build Flutter APK | 3-5 min | Create test APK |
| Run test (Standard) | 10 min | 3 devices |
| Review results | 5-10 min | Watch videos, check logs |
| **Total** | **25-30 min** | **End-to-end** |

---

## What Gets Tested

Firebase Test Lab will automatically:

1. **Install** the app on virtual devices
2. **Launch** the app
3. **Explore** the UI automatically (Robo test)
4. **Record** video of all interactions
5. **Capture** screenshots
6. **Monitor** performance metrics
7. **Detect** crashes and ANRs
8. **Generate** comprehensive report

---

## After Testing

### If Tests Pass ✅
1. Review video recordings for UX issues
2. Check performance metrics
3. Plan next testing iteration
4. Deploy Cloud Functions: `firebase deploy --only functions`

### If Tests Fail ❌
1. Check crash logs in Firebase Console
2. Review stack traces
3. Fix issues in code
4. Rebuild and retest

---

## Next Steps

After successful testing:

1. **Deploy Cloud Functions**
   ```bash
   cd functions
   npm run build
   firebase deploy --only functions
   ```

2. **Set Up Production**
   - Configure environment variables
   - Enable security rules
   - Set up monitoring

3. **App Store Submission**
   - Build release APK/IPA
   - Run comprehensive tests
   - Submit to Google Play/App Store

---

## Getting Help

### Documentation
- **Complete Guide**: [FIREBASE_TEST_LAB_GUIDE.md](FIREBASE_TEST_LAB_GUIDE.md)
- **Project Index**: [INDEX.md](INDEX.md)
- **Test Execution**: [TEST_EXECUTION_README.md](TEST_EXECUTION_README.md)

### Support
- Firebase Console: https://console.firebase.google.com/
- Firebase Docs: https://firebase.google.com/docs/test-lab
- Stack Overflow: Tag `firebase-test-lab`

---

## Success Indicators

You're ready for user testing when:

✅ All environment checks pass
✅ APK builds successfully
✅ Tests run on Firebase Test Lab
✅ Video recordings show app working
✅ No critical crashes detected
✅ Performance metrics acceptable

---

**Status**: Ready for User Testing
**Last Updated**: January 15, 2025
**Estimated Setup Time**: 25-30 minutes

**Next Command**: `check_environment.bat` or `./check_environment.sh`
