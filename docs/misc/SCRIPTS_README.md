# GreenGoChat - Scripts Guide

This document provides a quick reference for all deployment and testing scripts available in the project.

---

## 📜 Available Scripts

### 1. **deployment.sh** - Complete Test Deployment
**Purpose**: Automated setup and deployment for test environment

**Usage**:
```bash
./deployment.sh
```

**What it does**:
- ✅ Checks all prerequisites (Flutter, Dart, Android SDK, etc.)
- ✅ Installs dependencies and runs code generation
- ✅ Sets up Firebase Emulators
- ✅ Configures Mock API Server
- ✅ Runs tests (optional)
- ✅ Builds the app (Android/iOS)
- ✅ Starts all test servers
- ✅ Provides complete deployment summary

**Options**:
```bash
# Skip tests
SKIP_TESTS=true ./deployment.sh

# Clean build
CLEAN_BUILD=true ./deployment.sh

# Specify platform (android, ios, or both)
PLATFORM=android ./deployment.sh
PLATFORM=ios ./deployment.sh
PLATFORM=both ./deployment.sh

# Combine options
SKIP_TESTS=true CLEAN_BUILD=true PLATFORM=android ./deployment.sh
```

---

### 2. **TEST_MOCK_SETUP.sh** - Mock Environment Setup
**Purpose**: Sets up mock servers and testing infrastructure

**Usage**:
```bash
./TEST_MOCK_SETUP.sh
```

**What it does**:
- ✅ Installs Node.js dependencies for mock server
- ✅ Creates Firebase emulator configuration
- ✅ Generates mock API server with endpoints
- ✅ Creates test data seed scripts
- ✅ Generates control scripts (start/stop)

**First-time setup**:
```bash
# Run once to set up everything
./TEST_MOCK_SETUP.sh

# After setup, use the generated scripts:
./start_mock_servers.sh
./stop_mock_servers.sh
```

---

### 3. **start_mock_servers.sh** - Start Test Servers
**Purpose**: Starts all mock servers in background

**Usage**:
```bash
./start_mock_servers.sh
```

**What it starts**:
- Firebase Auth Emulator (port 9099)
- Firebase Firestore Emulator (port 8081)
- Firebase Storage Emulator (port 9199)
- Firebase Emulator UI (port 4000)
- Mock API Server (port 8080)

**Access points**:
- Emulator UI: http://localhost:4000
- Mock API: http://localhost:8080
- Health check: http://localhost:8080/health

---

### 4. **stop_mock_servers.sh** - Stop Test Servers
**Purpose**: Stops all running mock servers

**Usage**:
```bash
./stop_mock_servers.sh
```

**What it does**:
- Stops Firebase Emulators
- Stops Mock API Server
- Cleans up process IDs
- Kills any remaining processes on used ports

---

### 5. **run_tests.sh** - Test Runner
**Purpose**: Runs all Flutter tests with mock environment

**Usage**:
```bash
./run_tests.sh
```

**What it does**:
- Checks if mock servers are running (starts them if not)
- Runs all Flutter unit tests
- Displays test results

---

## 🚀 Quick Start Workflows

### Workflow 1: Complete Test Deployment
```bash
# One command to set up everything
./deployment.sh

# App will be built and servers will be running
# Follow on-screen instructions to install/run
```

### Workflow 2: Development with Mock Servers
```bash
# First time: Set up mock environment
./TEST_MOCK_SETUP.sh

# Daily development:
# 1. Start servers
./start_mock_servers.sh

# 2. Run app with mock data
flutter run --dart-define=USE_MOCK=true

# 3. When done, stop servers
./stop_mock_servers.sh
```

### Workflow 3: Testing
```bash
# Start servers and run tests
./run_tests.sh

# Or manually:
./start_mock_servers.sh
flutter test
./stop_mock_servers.sh
```

### Workflow 4: Build Only
```bash
# Android debug build
flutter build apk --debug

# Android release build
flutter build appbundle --release

# iOS debug build
flutter build ios --debug

# iOS release build
flutter build ios --release
```

---

## 🔧 Environment Variables

### deployment.sh Options
```bash
ENVIRONMENT=test          # Deployment environment (test/staging/prod)
SKIP_TESTS=false         # Skip running tests
CLEAN_BUILD=false        # Perform clean build
PLATFORM=android         # Target platform (android/ios/both)
```

### Flutter Dart Defines
```bash
ENV=test                 # Application environment
USE_MOCK=true           # Use mock servers instead of Firebase
```

**Example**:
```bash
flutter run \
  --dart-define=ENV=test \
  --dart-define=USE_MOCK=true
```

---

## 📦 What Each Script Generates

### deployment.sh Generates:
- `.deployment_temp/` - Temporary deployment files
- `.deployment_temp/deployment_info.txt` - Deployment summary
- `.deployment_temp/firebase.pid` - Firebase emulator process ID
- `.deployment_temp/api.pid` - Mock API server process ID
- `build/` - Built application artifacts

### TEST_MOCK_SETUP.sh Generates:
- `test/mock_server/` - Mock API server implementation
  - `package.json` - Node.js dependencies
  - `server.js` - Express server
  - `seed_data.sh` - Test data seeding script
- `firebase.json` - Firebase emulator configuration
- `firestore.rules` - Test Firestore security rules
- `storage.rules` - Test Storage security rules
- `firestore.indexes.json` - Firestore indexes
- `start_mock_servers.sh` - Server startup script
- `stop_mock_servers.sh` - Server shutdown script
- `run_tests.sh` - Test runner script
- `lib/core/config/test_config.dart` - Test configuration

---

## 🐛 Troubleshooting

### Problem: Scripts won't execute
**Solution**:
```bash
chmod +x deployment.sh
chmod +x TEST_MOCK_SETUP.sh
chmod +x start_mock_servers.sh
chmod +x stop_mock_servers.sh
chmod +x run_tests.sh
```

### Problem: Port already in use
**Solution**:
```bash
# Find and kill processes using the ports
lsof -ti:4000,8080,8081,9099,9199 | xargs kill -9

# Or use the stop script
./stop_mock_servers.sh
```

### Problem: Firebase emulators won't start
**Solution**:
```bash
# Install/update Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Try starting manually
firebase emulators:start
```

### Problem: Mock API server fails
**Solution**:
```bash
# Reinstall dependencies
cd test/mock_server
rm -rf node_modules
npm install
cd ../..

# Try starting manually
cd test/mock_server && npm start
```

### Problem: Flutter build fails
**Solution**:
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --debug
```

---

## 📋 Script Dependencies

### Required for All Scripts:
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Git

### Required for deployment.sh:
- All of the above
- Android SDK (for Android builds)
- Xcode & CocoaPods (for iOS builds, macOS only)

### Required for TEST_MOCK_SETUP.sh:
- Node.js (>= 14.0.0)
- npm (comes with Node.js)
- Firebase CLI (`npm install -g firebase-tools`)

---

## 🎯 Best Practices

1. **Always run TEST_MOCK_SETUP.sh first** if it's your first time setting up the test environment
2. **Use deployment.sh for complete deployments** - it handles everything
3. **Use start_mock_servers.sh for daily development** - faster than full deployment
4. **Stop servers when not in use** to free up system resources
5. **Run tests before committing code** using `./run_tests.sh`
6. **Use environment variables** to customize behavior without modifying scripts

---

## 📚 Additional Resources

- **DEPLOYMENT.md** - Complete deployment guide for production
- **IMPLEMENTATION_SUMMARY.md** - Summary of all implemented features
- **Test data seeding**: `cd test/mock_server && ./seed_data.sh`
- **Mock API documentation**: Check `test/mock_server/server.js` for endpoints

---

## 🆘 Getting Help

If you encounter issues:

1. Check this README for troubleshooting steps
2. Review the script output for error messages
3. Check the deployment info: `cat .deployment_temp/deployment_info.txt`
4. Verify prerequisites: `./deployment.sh` will check automatically
5. View mock server logs: `cat test/mock_server/npm-debug.log`

---

**Last Updated**: January 2025

For more information, see:
- [DEPLOYMENT.md](DEPLOYMENT.md) - Production deployment
- [IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md) - Feature summary
