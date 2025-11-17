#!/bin/bash

###############################################################################
# GreenGoChat - Test Deployment Script
# This script sets up and deploys the application for test purposes
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
TEST_DIR="$PROJECT_DIR/test"
TEMP_DIR="$PROJECT_DIR/.deployment_temp"

# Environment variables
ENVIRONMENT="${ENVIRONMENT:-test}"
SKIP_TESTS="${SKIP_TESTS:-false}"
CLEAN_BUILD="${CLEAN_BUILD:-false}"
PLATFORM="${PLATFORM:-android}"  # android, ios, or both

###############################################################################
# Helper Functions
###############################################################################

print_banner() {
    echo -e "${CYAN}"
    echo "════════════════════════════════════════════════════════"
    echo "    GreenGoChat - Test Deployment"
    echo "════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    printf "${BLUE}║${NC} %-54s ${BLUE}║${NC}\n" "$1"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

print_step() {
    echo -e "${CYAN}▶${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Progress bar function
show_progress() {
    local duration=$1
    local message=$2
    local width=50

    echo -n "$message: ["
    for ((i=0; i<=width; i++)); do
        sleep $(echo "scale=2; $duration / $width" | bc)
        echo -n "="
    done
    echo "] Done!"
}

# Check if command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 is not installed"
        return 1
    else
        print_success "$1 is available"
        return 0
    fi
}

# Cleanup function
cleanup() {
    print_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    print_success "Cleanup complete"
}

# Trap errors and cleanup
trap cleanup EXIT
trap 'print_error "Deployment failed!"; exit 1' ERR

###############################################################################
# Main Deployment Process
###############################################################################

print_banner

print_info "Deployment Configuration:"
echo "  - Environment: $ENVIRONMENT"
echo "  - Platform: $PLATFORM"
echo "  - Skip Tests: $SKIP_TESTS"
echo "  - Clean Build: $CLEAN_BUILD"
echo "  - Project Directory: $PROJECT_DIR"
echo ""

###############################################################################
# Step 1: Prerequisites Check
###############################################################################

print_header "Step 1: Checking Prerequisites"

MISSING_TOOLS=0

# Check Flutter
if check_command flutter; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_info "$FLUTTER_VERSION"
else
    print_error "Flutter SDK is required. Install from: https://flutter.dev/docs/get-started/install"
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

# Check Dart
if check_command dart; then
    DART_VERSION=$(dart --version | head -n 1)
    print_info "$DART_VERSION"
else
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

# Check Git
if check_command git; then
    GIT_VERSION=$(git --version)
    print_info "$GIT_VERSION"
else
    MISSING_TOOLS=$((MISSING_TOOLS + 1))
fi

# Platform-specific checks
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    print_step "Checking Android development tools..."

    if [ -d "$ANDROID_HOME" ] || [ -d "$ANDROID_SDK_ROOT" ]; then
        print_success "Android SDK found"
    else
        print_warning "Android SDK not found. Set ANDROID_HOME or ANDROID_SDK_ROOT"
        print_info "Download from: https://developer.android.com/studio"
    fi
fi

if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "both" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "Checking iOS development tools..."

        if check_command xcodebuild; then
            XCODE_VERSION=$(xcodebuild -version | head -n 1)
            print_info "$XCODE_VERSION"
        else
            print_warning "Xcode not found. Install from App Store"
        fi

        if check_command pod; then
            POD_VERSION=$(pod --version)
            print_info "CocoaPods $POD_VERSION"
        else
            print_warning "CocoaPods not found. Install with: sudo gem install cocoapods"
        fi
    else
        print_warning "iOS builds are only supported on macOS"
    fi
fi

# Check Node.js (for Firebase Emulator)
if check_command node; then
    NODE_VERSION=$(node --version)
    print_info "Node.js $NODE_VERSION"
else
    print_warning "Node.js recommended for Firebase Emulators"
    print_info "Install from: https://nodejs.org/"
fi

if [ $MISSING_TOOLS -gt 0 ]; then
    print_error "Missing $MISSING_TOOLS required tools"
    exit 1
fi

print_success "All prerequisites met!"

###############################################################################
# Step 2: Project Setup
###############################################################################

print_header "Step 2: Setting Up Project"

cd "$PROJECT_DIR"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_step "Performing clean build..."
    flutter clean
    print_success "Clean complete"
fi

# Get Flutter dependencies
print_step "Getting Flutter dependencies..."
flutter pub get

print_success "Dependencies installed"

# Run code generation
print_step "Running code generation..."
if flutter pub run build_runner build --delete-conflicting-outputs 2>/dev/null; then
    print_success "Code generation complete"
else
    print_warning "Code generation skipped (no generators found)"
fi

###############################################################################
# Step 3: Firebase Emulator Setup
###############################################################################

print_header "Step 3: Setting Up Firebase Emulators"

# Check if Firebase CLI is installed
if check_command firebase; then
    FIREBASE_VERSION=$(firebase --version)
    print_info "Firebase CLI $FIREBASE_VERSION"

    # Check if firebase.json exists
    if [ ! -f "$PROJECT_DIR/firebase.json" ]; then
        print_step "Creating firebase.json configuration..."
        cat > firebase.json <<EOF
{
  "emulators": {
    "auth": {
      "port": 9099
    },
    "firestore": {
      "port": 8081
    },
    "storage": {
      "port": 9199
    },
    "ui": {
      "enabled": true,
      "port": 4000
    }
  },
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
EOF
        print_success "Firebase configuration created"
    else
        print_success "Firebase configuration already exists"
    fi

    # Create Firestore rules
    if [ ! -f "$PROJECT_DIR/firestore.rules" ]; then
        print_step "Creating Firestore rules..."
        cat > firestore.rules <<'EOF'
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Test environment - permissive rules
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
EOF
        print_success "Firestore rules created"
    fi

    # Create Storage rules
    if [ ! -f "$PROJECT_DIR/storage.rules" ]; then
        print_step "Creating Storage rules..."
        cat > storage.rules <<'EOF'
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Test environment - permissive rules
    match /{allPaths=**} {
      allow read, write: if true;
    }
  }
}
EOF
        print_success "Storage rules created"
    fi

    # Create Firestore indexes
    if [ ! -f "$PROJECT_DIR/firestore.indexes.json" ]; then
        echo '{"indexes":[],"fieldOverrides":[]}' > firestore.indexes.json
        print_success "Firestore indexes created"
    fi

    print_success "Firebase Emulator setup complete"
else
    print_warning "Firebase CLI not found. Emulators will not be available"
    print_info "Install with: npm install -g firebase-tools"
fi

###############################################################################
# Step 4: Mock Server Setup
###############################################################################

print_header "Step 4: Setting Up Mock API Server"

MOCK_SERVER_DIR="$TEST_DIR/mock_server"

if [ -f "$PROJECT_DIR/TEST_MOCK_SETUP.sh" ]; then
    print_step "Running mock server setup script..."
    chmod +x TEST_MOCK_SETUP.sh
    ./TEST_MOCK_SETUP.sh
    print_success "Mock server setup complete"
else
    print_warning "Mock server setup script not found"
    print_info "Create it with: TEST_MOCK_SETUP.sh"
fi

###############################################################################
# Step 5: Run Tests (Optional)
###############################################################################

if [ "$SKIP_TESTS" = false ]; then
    print_header "Step 5: Running Tests"

    print_step "Running Flutter unit tests..."
    if flutter test; then
        print_success "All tests passed!"
    else
        print_error "Some tests failed"
        read -p "Continue with deployment? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
else
    print_header "Step 5: Skipping Tests"
    print_warning "Tests skipped (SKIP_TESTS=true)"
fi

###############################################################################
# Step 6: Build Application
###############################################################################

print_header "Step 6: Building Application"

mkdir -p "$TEMP_DIR"

# Android Build
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    print_step "Building Android APK (debug)..."

    flutter build apk --debug --dart-define=ENV=test

    if [ -f "$BUILD_DIR/app/outputs/flutter-apk/app-debug.apk" ]; then
        APK_SIZE=$(du -h "$BUILD_DIR/app/outputs/flutter-apk/app-debug.apk" | cut -f1)
        print_success "Android APK built successfully ($APK_SIZE)"
        print_info "Location: build/app/outputs/flutter-apk/app-debug.apk"
    else
        print_error "Android build failed"
        exit 1
    fi
fi

# iOS Build
if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "both" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_step "Building iOS app (debug)..."

        cd ios
        pod install
        cd ..

        flutter build ios --debug --dart-define=ENV=test --no-codesign

        if [ -d "$BUILD_DIR/ios/iphoneos/Runner.app" ]; then
            print_success "iOS app built successfully"
            print_info "Location: build/ios/iphoneos/Runner.app"
        else
            print_error "iOS build failed"
            exit 1
        fi
    else
        print_warning "iOS builds skipped (not running on macOS)"
    fi
fi

###############################################################################
# Step 7: Start Servers
###############################################################################

print_header "Step 7: Starting Test Servers"

# Start Firebase Emulators
if command -v firebase &> /dev/null; then
    print_step "Starting Firebase Emulators in background..."
    firebase emulators:start --only auth,firestore,storage > /dev/null 2>&1 &
    FIREBASE_PID=$!
    echo $FIREBASE_PID > "$TEMP_DIR/firebase.pid"
    sleep 3
    print_success "Firebase Emulators started (PID: $FIREBASE_PID)"
fi

# Start Mock API Server
if [ -d "$MOCK_SERVER_DIR" ] && [ -f "$MOCK_SERVER_DIR/server.js" ]; then
    print_step "Starting Mock API Server in background..."
    cd "$MOCK_SERVER_DIR"
    npm start > /dev/null 2>&1 &
    API_PID=$!
    echo $API_PID > "$TEMP_DIR/api.pid"
    cd "$PROJECT_DIR"
    sleep 2
    print_success "Mock API Server started (PID: $API_PID)"
fi

###############################################################################
# Step 8: Create Environment Info
###############################################################################

print_header "Step 8: Generating Environment Info"

cat > "$TEMP_DIR/deployment_info.txt" <<EOF
GreenGoChat Test Deployment
============================

Deployment Date: $(date)
Environment: $ENVIRONMENT
Platform: $PLATFORM

Build Information:
- Flutter Version: $(flutter --version | head -n 1)
- Dart Version: $(dart --version 2>&1 | head -n 1)

Test Servers:
- Firebase Emulator UI: http://localhost:4000
- Firestore Emulator: http://localhost:8081
- Auth Emulator: http://localhost:9099
- Storage Emulator: http://localhost:9199
- Mock API Server: http://localhost:8080

Build Artifacts:
$(if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    echo "- Android APK: build/app/outputs/flutter-apk/app-debug.apk"
fi)
$(if [[ "$PLATFORM" == "ios" ]] || [[ "$PLATFORM" == "both" ]]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "- iOS App: build/ios/iphoneos/Runner.app"
    fi
fi)

Process IDs:
$(if [ -f "$TEMP_DIR/firebase.pid" ]; then
    echo "- Firebase Emulators: $(cat $TEMP_DIR/firebase.pid)"
fi)
$(if [ -f "$TEMP_DIR/api.pid" ]; then
    echo "- Mock API Server: $(cat $TEMP_DIR/api.pid)"
fi)
EOF

print_success "Environment info saved to: .deployment_temp/deployment_info.txt"

###############################################################################
# Deployment Complete
###############################################################################

print_header "Deployment Complete! 🚀"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Test Environment is Ready!${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}📱 Application Built:${NC}"
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    echo "   Android APK: build/app/outputs/flutter-apk/app-debug.apk"
fi
if [[ "$PLATFORM" == "ios" ]] && [[ "$OSTYPE" == "darwin"* ]]; then
    echo "   iOS App: build/ios/iphoneos/Runner.app"
fi

echo ""
echo -e "${CYAN}🔧 Test Servers Running:${NC}"
if command -v firebase &> /dev/null; then
    echo "   Firebase Emulator UI:    ${BLUE}http://localhost:4000${NC}"
    echo "   Firestore Emulator:      ${BLUE}http://localhost:8081${NC}"
    echo "   Auth Emulator:           ${BLUE}http://localhost:9099${NC}"
    echo "   Storage Emulator:        ${BLUE}http://localhost:9199${NC}"
fi
if [ -f "$TEMP_DIR/api.pid" ]; then
    echo "   Mock API Server:         ${BLUE}http://localhost:8080${NC}"
fi

echo ""
echo -e "${CYAN}🚀 Next Steps:${NC}"
echo "   1. Install the app on device/emulator:"
if [[ "$PLATFORM" == "android" ]] || [[ "$PLATFORM" == "both" ]]; then
    echo "      ${YELLOW}adb install build/app/outputs/flutter-apk/app-debug.apk${NC}"
fi
echo ""
echo "   2. Or run directly with Flutter:"
echo "      ${YELLOW}flutter run --dart-define=ENV=test --dart-define=USE_MOCK=true${NC}"
echo ""
echo "   3. Test the mock API:"
echo "      ${YELLOW}curl http://localhost:8080/health${NC}"
echo ""
echo "   4. Access Firebase Emulator UI:"
echo "      ${YELLOW}open http://localhost:4000${NC}"
echo ""

echo -e "${CYAN}🛑 To Stop Servers:${NC}"
echo "   Run: ${YELLOW}./stop_mock_servers.sh${NC}"
echo "   Or manually:"
if [ -f "$TEMP_DIR/firebase.pid" ]; then
    echo "      ${YELLOW}kill $(cat $TEMP_DIR/firebase.pid)${NC} (Firebase)"
fi
if [ -f "$TEMP_DIR/api.pid" ]; then
    echo "      ${YELLOW}kill $(cat $TEMP_DIR/api.pid)${NC} (Mock API)"
fi

echo ""
echo -e "${CYAN}📚 Documentation:${NC}"
echo "   - Deployment Guide:    ${BLUE}DEPLOYMENT.md${NC}"
echo "   - Implementation:      ${BLUE}IMPLEMENTATION_SUMMARY.md${NC}"
echo "   - Test Setup:          ${BLUE}TEST_MOCK_SETUP.sh${NC}"

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Happy Testing! 🎉${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════${NC}"
echo ""

# Save deployment info to console output
cat "$TEMP_DIR/deployment_info.txt"

exit 0
