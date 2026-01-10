#!/bin/bash

# GreenGoChat Unified Deployment Script
# Usage: ./deploy.sh [dev|test|prod] [android|ios|web]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEVOPS_DIR="$SCRIPT_DIR/devops"

# Print colored message
print_msg() {
    local color=$1
    shift
    echo -e "${color}$@${NC}"
}

print_header() {
    echo ""
    print_msg "$BLUE" "============================================"
    print_msg "$BLUE" "$@"
    print_msg "$BLUE" "============================================"
    echo ""
}

# Print usage
usage() {
    cat << EOF
Usage: $0 [ENVIRONMENT] [PLATFORM] [OPTIONS]

ENVIRONMENT:
    dev         Deploy to development environment (with emulators)
    test        Deploy to staging/test environment
    prod        Deploy to production environment

PLATFORM:
    android     Build and deploy Android app
    ios         Build and deploy iOS app (macOS only)
    web         Build and deploy web app
    all         Build all platforms

OPTIONS:
    --skip-tests        Skip running tests
    --clean             Clean build before deploying
    --help              Show this help message

Examples:
    $0 dev android
    $0 test all --clean
    $0 prod android --skip-tests
EOF
    exit 1
}

# Check arguments
if [ "$#" -lt 2 ]; then
    print_msg "$RED" "Error: Missing required arguments"
    usage
fi

ENVIRONMENT=$1
PLATFORM=$2
SKIP_TESTS=false
CLEAN_BUILD=false

# Parse optional arguments
shift 2
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help)
            usage
            ;;
        *)
            print_msg "$RED" "Unknown option: $1"
            usage
            ;;
    esac
done

# Validate environment
case $ENVIRONMENT in
    dev|test|prod)
        ;;
    *)
        print_msg "$RED" "Error: Invalid environment '$ENVIRONMENT'"
        print_msg "$YELLOW" "Must be one of: dev, test, prod"
        exit 1
        ;;
esac

# Validate platform
case $PLATFORM in
    android|ios|web|all)
        ;;
    *)
        print_msg "$RED" "Error: Invalid platform '$PLATFORM'"
        print_msg "$YELLOW" "Must be one of: android, ios, web, all"
        exit 1
        ;;
esac

print_header "GreenGoChat Deployment - $ENVIRONMENT Environment"

# Load environment configuration
CONFIG_FILE="$DEVOPS_DIR/$ENVIRONMENT/config.env"
if [ ! -f "$CONFIG_FILE" ]; then
    print_msg "$RED" "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

print_msg "$GREEN" "Loading configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Display configuration
print_msg "$YELLOW" "Environment: $ENV_NAME"
print_msg "$YELLOW" "Firebase Project: $FIREBASE_PROJECT_ID"
print_msg "$YELLOW" "Build Mode: $BUILD_MODE"
print_msg "$YELLOW" "Platform(s): $PLATFORM"
echo ""

# Check prerequisites
print_header "Checking Prerequisites"

# Check Flutter
if ! command -v flutter &> /dev/null; then
    print_msg "$RED" "Flutter is not installed or not in PATH"
    exit 1
fi
print_msg "$GREEN" "✓ Flutter found: $(flutter --version | head -n 1)"

# Check Firebase CLI
if ! command -v firebase &> /dev/null; then
    print_msg "$YELLOW" "⚠ Firebase CLI not found (optional)"
else
    print_msg "$GREEN" "✓ Firebase CLI found"
fi

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_header "Cleaning Build"
    flutter clean
    print_msg "$GREEN" "✓ Build cleaned"
fi

# Get dependencies
print_header "Getting Dependencies"
flutter pub get
print_msg "$GREEN" "✓ Dependencies installed"

# Generate localization files
print_header "Generating Localization"
flutter gen-l10n
print_msg "$GREEN" "✓ Localization files generated"

# Start mock servers for dev environment
if [ "$ENVIRONMENT" = "dev" ] && [ "$MOCK_SERVERS_ENABLED" = "true" ]; then
    print_header "Starting Mock Servers"
    bash "$DEVOPS_DIR/start_mock_servers.sh" &
    MOCK_SERVERS_PID=$!
    print_msg "$GREEN" "✓ Mock servers started (PID: $MOCK_SERVERS_PID)"
    sleep 3
fi

# Start Firebase emulators for dev environment
if [ "$ENVIRONMENT" = "dev" ] && [ "$USE_FIREBASE_EMULATORS" = "true" ]; then
    print_header "Starting Firebase Emulators"
    firebase emulators:start --only auth,firestore,storage &
    EMULATORS_PID=$!
    print_msg "$GREEN" "✓ Firebase emulators started (PID: $EMULATORS_PID)"
    sleep 5
fi

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ]; then
    print_header "Running Tests"
    if flutter test; then
        print_msg "$GREEN" "✓ All tests passed"
    else
        print_msg "$RED" "✗ Tests failed"
        # Cleanup
        [ -n "$MOCK_SERVERS_PID" ] && kill $MOCK_SERVERS_PID 2>/dev/null || true
        [ -n "$EMULATORS_PID" ] && kill $EMULATORS_PID 2>/dev/null || true
        exit 1
    fi
fi

# Build function
build_platform() {
    local platform=$1

    case $platform in
        android)
            print_header "Building Android App"
            if [ "$BUILD_MODE" = "debug" ]; then
                flutter build apk --debug
            else
                flutter build apk --release
            fi
            print_msg "$GREEN" "✓ Android app built successfully"
            print_msg "$YELLOW" "APK location: build/app/outputs/flutter-apk/"
            ;;

        ios)
            print_header "Building iOS App"
            if [ "$(uname)" != "Darwin" ]; then
                print_msg "$RED" "iOS build requires macOS"
                return 1
            fi
            if [ "$BUILD_MODE" = "debug" ]; then
                flutter build ios --debug
            else
                flutter build ios --release
            fi
            print_msg "$GREEN" "✓ iOS app built successfully"
            ;;

        web)
            print_header "Building Web App"
            flutter build web --release
            print_msg "$GREEN" "✓ Web app built successfully"
            print_msg "$YELLOW" "Web build location: build/web/"
            ;;
    esac
}

# Build based on platform
if [ "$PLATFORM" = "all" ]; then
    build_platform android
    [ "$(uname)" = "Darwin" ] && build_platform ios
    build_platform web
else
    build_platform $PLATFORM
fi

# Deploy to Firebase (for prod/test)
if [ "$ENVIRONMENT" != "dev" ] && ([ "$PLATFORM" = "web" ] || [ "$PLATFORM" = "all" ]); then
    print_header "Deploying to Firebase Hosting"
    firebase deploy --only hosting --project $FIREBASE_PROJECT_ID
    print_msg "$GREEN" "✓ Deployed to Firebase Hosting"
fi

# Cleanup
print_header "Cleanup"
if [ -n "$MOCK_SERVERS_PID" ]; then
    kill $MOCK_SERVERS_PID 2>/dev/null || true
    print_msg "$GREEN" "✓ Mock servers stopped"
fi
if [ -n "$EMULATORS_PID" ]; then
    kill $EMULATORS_PID 2>/dev/null || true
    print_msg "$GREEN" "✓ Firebase emulators stopped"
fi

# Success
print_header "Deployment Complete!"
print_msg "$GREEN" "Environment: $ENVIRONMENT"
print_msg "$GREEN" "Platform(s): $PLATFORM"
print_msg "$GREEN" "Build Mode: $BUILD_MODE"
echo ""
print_msg "$YELLOW" "Next steps:"

case $ENVIRONMENT in
    dev)
        print_msg "$YELLOW" "  - Test the app on your local device/emulator"
        print_msg "$YELLOW" "  - Mock servers: http://localhost:3000"
        print_msg "$YELLOW" "  - Firebase Emulators UI: http://localhost:4000"
        ;;
    test)
        print_msg "$YELLOW" "  - Upload APK to Firebase App Distribution"
        print_msg "$YELLOW" "  - Run integration tests"
        print_msg "$YELLOW" "  - Get QA approval"
        ;;
    prod)
        print_msg "$YELLOW" "  - Upload to Google Play Console / App Store Connect"
        print_msg "$YELLOW" "  - Submit for review"
        print_msg "$YELLOW" "  - Monitor crashlytics and analytics"
        ;;
esac

echo ""
print_msg "$GREEN" "✓ Deployment successful!"
