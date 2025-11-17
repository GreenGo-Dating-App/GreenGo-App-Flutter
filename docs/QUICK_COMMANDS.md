# Quick Commands Cheat Sheet

**One-page reference for all common commands**

---

## 🚀 First Time Setup (Run Once)

```bash
# 1. Initialize Flutter project
flutter create . --org com.greengo.chat

# 2. Install all dependencies
flutter pub get
cd functions && npm install && cd ..

# 3. Build Cloud Functions
cd functions && npm run build && cd ..

# 4. Login to Firebase
firebase login

# 5. Initialize Firebase
firebase init
```

---

## 📱 Run the App

### Quick Start
```bash
flutter run
```

### With Device Selection
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device_id>

# Run on Chrome (web)
flutter run -d chrome
```

### Build Modes
```bash
# Debug mode (default)
flutter run

# Release mode (optimized)
flutter run --release

# Profile mode (performance analysis)
flutter run --profile
```

---

## 🔨 Build APK/IPA

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK (unsigned)
flutter build apk --release

# Release APK (split by ABI - smaller size)
flutter build apk --split-per-abi

# App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS
```bash
# Build for iOS (macOS only)
flutter build ios --release

# Build IPA
flutter build ipa
```

---

## ☁️ Cloud Functions

### Build & Deploy
```bash
# Build TypeScript
cd functions && npm run build

# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:compressImage

# Deploy specific category
firebase deploy --only functions:videoCallFeatures

# View deployment
cd ..
```

### Test Locally
```bash
# Start Firebase emulators
firebase emulators:start

# Start only functions emulator
firebase emulators:start --only functions

# Import production data
firebase emulators:start --import=./firebase-data
```

---

## 🧪 Testing

### Development Tests
```bash
# Windows
run_tests.bat

# macOS/Linux
./run_tests.sh

# View latest report
cat test_reports/latest_test_report.md
```

### Firebase Test Lab
```bash
# Check prerequisites
check_environment.bat  # or ./check_environment.sh

# Complete setup
setup_and_test.bat  # or ./setup_and_test.sh

# Run tests
firebase_test_lab.bat  # or ./firebase_test_lab.sh
```

### Flutter Tests
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test
flutter test test/widget_test.dart
```

---

## 🔍 Debugging & Logs

### Flutter Logs
```bash
# View logs
flutter logs

# Clear logs
flutter logs --clear

# Logs from specific device
flutter logs -d <device_id>
```

### Firebase Logs
```bash
# View Cloud Functions logs
firebase functions:log

# Follow logs (live)
firebase functions:log --only functionName

# Last 100 entries
firebase functions:log --lines 100
```

### Android Logs
```bash
# View Android logs
adb logcat

# Filter Flutter logs
adb logcat | grep flutter

# Clear logs
adb logcat -c
```

---

## 🧹 Cleanup & Reset

### Flutter Clean
```bash
# Clean build artifacts
flutter clean

# Clean and reinstall
flutter clean && flutter pub get

# Deep clean (includes .dart_tool)
flutter clean && rm -rf .dart_tool && flutter pub get
```

### Android Clean
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Functions Clean
```bash
cd functions
rm -rf node_modules
rm -rf lib
npm install
npm run build
cd ..
```

---

## 📦 Dependency Management

### Flutter Dependencies
```bash
# Install dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Upgrade specific package
flutter pub upgrade firebase_core

# Show outdated packages
flutter pub outdated

# Run build_runner (for code generation)
flutter pub run build_runner build
```

### npm Dependencies
```bash
cd functions

# Install dependencies
npm install

# Update dependencies
npm update

# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix

cd ..
```

---

## 🔐 Firebase Commands

### Authentication
```bash
# Login
firebase login

# Logout
firebase logout

# List projects
firebase projects:list

# Use specific project
firebase use <project_id>
```

### Deployment
```bash
# Deploy everything
firebase deploy

# Deploy specific services
firebase deploy --only functions
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
firebase deploy --only hosting

# Deploy with force
firebase deploy --force
```

### Firestore
```bash
# Delete all data (dangerous!)
firebase firestore:delete --all-collections --recursive

# Import data
firebase firestore:import ./data

# Export data
firebase firestore:export ./data
```

---

## 🛠️ Development Workflow

### Hot Reload & Restart
While app is running:
- `r` - Hot reload (keep state)
- `R` - Hot restart (reset state)
- `p` - Show performance overlay
- `o` - Toggle platform (iOS/Android)
- `q` - Quit

### Code Analysis
```bash
# Analyze code
flutter analyze

# Fix formatting
dart format .

# Fix common issues
dart fix --apply
```

### Performance
```bash
# Profile performance
flutter run --profile

# Trace performance
flutter run --trace-startup

# Build time profiling
flutter build apk --analyze-size
```

---

## 🌐 Firebase Hosting (Optional)

```bash
# Initialize hosting
firebase init hosting

# Deploy hosting
firebase deploy --only hosting

# View hosting URL
firebase hosting:sites:list
```

---

## 📊 Analytics & Monitoring

### Firebase Console
```bash
# Open project in browser
firebase open

# Open specific service
firebase open functions
firebase open database
firebase open hosting
```

### Performance
```bash
# View performance data
# Go to Firebase Console > Performance

# Enable debug mode
adb shell setprop debug.firebase.perf.enable true
```

---

## 🔄 Git Commands (Recommended)

```bash
# Initialize git (if not done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit"

# Create GitHub repo and push
git remote add origin <your-repo-url>
git push -u origin main
```

---

## 🚨 Emergency Commands

### Kill All Flutter Processes
```bash
# Windows
taskkill /F /IM flutter.exe
taskkill /F /IM dart.exe

# macOS/Linux
killall -9 flutter
killall -9 dart
```

### Reset Emulator
```bash
# List emulators
flutter emulators

# Cold boot emulator
flutter emulators --launch <emulator_id> --cold-boot
```

### Fix Common Issues
```bash
# Fix "waiting for device"
adb kill-server
adb start-server

# Fix "Gradle build failed"
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get

# Fix "Firebase initialization failed"
flutter clean
flutter pub get
flutter run
```

---

## 📱 Device Management

### Android
```bash
# List devices
adb devices

# Install APK manually
adb install build/app/outputs/flutter-apk/app-debug.apk

# Uninstall app
adb uninstall com.greengo.chat.greengo_chat

# Screen recording
adb shell screenrecord /sdcard/demo.mp4
```

### iOS (macOS only)
```bash
# List devices
instruments -s devices

# Install on simulator
flutter install
```

---

## 🔑 Environment Variables

### Set Firebase Project
```bash
# Set default project
firebase use <project_id>

# Add project alias
firebase use --add
```

### Set Google Cloud Project
```bash
gcloud config set project <project_id>
```

---

## 📈 Monitoring Commands

### Check App Size
```bash
flutter build apk --analyze-size
flutter build appbundle --analyze-size
```

### Check Dependencies Size
```bash
cd functions
npm ls --depth=0
cd ..
```

### Check Build Performance
```bash
flutter build apk --verbose
```

---

## ⚡ Quick Aliases (Optional)

Add to your `.bashrc` or `.zshrc`:

```bash
# Flutter shortcuts
alias fr='flutter run'
alias fb='flutter build apk'
alias fc='flutter clean'
alias ft='flutter test'

# Firebase shortcuts
alias fd='firebase deploy'
alias fdf='firebase deploy --only functions'
alias fdr='firebase deploy --only firestore:rules'
alias fl='firebase functions:log'

# Combined
alias reset='flutter clean && flutter pub get'
alias rebuild='cd functions && npm run build && cd .. && flutter clean && flutter pub get'
```

---

## 📚 Help Commands

```bash
# Flutter help
flutter help
flutter <command> --help

# Firebase help
firebase help
firebase <command> --help

# npm help
npm help
npm <command> --help
```

---

## 🎯 Most Common Workflow

### Daily Development
```bash
# Morning: Pull latest changes
git pull

# Start coding...

# Run app to test
flutter run

# Make changes... (hot reload with 'r')

# Build for testing
flutter build apk --debug

# Deploy functions if changed
cd functions && npm run build && firebase deploy --only functions && cd ..

# End of day: Commit and push
git add .
git commit -m "Description of changes"
git push
```

### Before Testing
```bash
# Run all checks
run_tests.bat

# Fix any issues
flutter analyze
dart fix --apply

# Build release APK
flutter build apk --release

# Deploy to Firebase Test Lab
firebase_test_lab.bat
```

---

**Quick Reference Card - Keep This Handy!**

| Task | Command |
|------|---------|
| Run app | `flutter run` |
| Build APK | `flutter build apk` |
| Deploy functions | `cd functions && firebase deploy --only functions` |
| View logs | `flutter logs` |
| Clean | `flutter clean` |
| Test | `run_tests.bat` |
| Firebase Test Lab | `firebase_test_lab.bat` |

---

**Last Updated**: January 15, 2025
