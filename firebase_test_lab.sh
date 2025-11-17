#!/bin/bash

# ============================================================================
# Firebase Test Lab - Run GreenGo App on Virtual Devices
# ============================================================================
# This script runs your app on Firebase Test Lab with multiple device configs
# Requires: Google Cloud SDK, Firebase CLI, APK built
# ============================================================================

set -e  # Exit on any error

echo ""
echo "============================================================================"
echo "Firebase Test Lab - Virtual Device Testing"
echo "============================================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if APK exists
if [ ! -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo -e "${RED}ERROR: APK not found!${NC}"
    echo "Please run ./setup_and_test.sh first to build the APK"
    exit 1
fi

echo -e "${GREEN}✓ Found APK: build/app/outputs/flutter-apk/app-debug.apk${NC}"
echo ""

# Get Firebase project ID
echo "Retrieving Firebase project ID..."
PROJECT_ID=$(firebase projects:list --json 2>/dev/null | grep -o '"projectId":"[^"]*' | head -1 | cut -d'"' -f4)
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}ERROR: No Firebase project found!${NC}"
    echo "Please run: firebase use --add"
    exit 1
fi

echo -e "${GREEN}✓ Using project: $PROJECT_ID${NC}"
echo ""

echo "============================================================================"
echo "Test Configuration Options"
echo "============================================================================"
echo ""
echo "Choose a test configuration:"
echo ""
echo -e "${BLUE}[1]${NC} Quick Test - 1 device, 5 minutes"
echo "    - Nexus 6P, Android API 29"
echo ""
echo -e "${BLUE}[2]${NC} Standard Test - 3 devices, 10 minutes  ${GREEN}(RECOMMENDED)${NC}"
echo "    - Pixel 4, Android API 30"
echo "    - Samsung Galaxy S21, Android API 31"
echo "    - Nexus 6P, Android API 29"
echo ""
echo -e "${BLUE}[3]${NC} Comprehensive Test - 6 devices, 15 minutes"
echo "    - Latest flagship devices"
echo "    - Multiple Android versions (API 28-33)"
echo ""
echo -e "${BLUE}[4]${NC} Custom Test - Configure manually"
echo ""
read -p "Enter choice (1-4): " CHOICE

case $CHOICE in
    1)
        echo ""
        echo "Running Quick Test (1 device)..."
        echo ""
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=Nexus6P,version=29,locale=en,orientation=portrait \
          --timeout 5m \
          --results-bucket=gs://${PROJECT_ID}-test-results \
          --results-dir=quick-test-$(date +%Y%m%d-%H%M%S) \
          --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
        ;;
    2)
        echo ""
        echo "Running Standard Test (3 devices)..."
        echo ""
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=Pixel4,version=30,locale=en,orientation=portrait \
          --device model=a51,version=31,locale=en,orientation=portrait \
          --device model=Nexus6P,version=29,locale=en,orientation=portrait \
          --timeout 10m \
          --results-bucket=gs://${PROJECT_ID}-test-results \
          --results-dir=standard-test-$(date +%Y%m%d-%H%M%S) \
          --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
        ;;
    3)
        echo ""
        echo "Running Comprehensive Test (6 devices)..."
        echo ""
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=Pixel5,version=33,locale=en,orientation=portrait \
          --device model=Pixel4,version=30,locale=en,orientation=portrait \
          --device model=a51,version=31,locale=en,orientation=portrait \
          --device model=gts8ultra,version=32,locale=en,orientation=portrait \
          --device model=Nexus6P,version=29,locale=en,orientation=portrait \
          --device model=OnePlus7Pro,version=28,locale=en,orientation=portrait \
          --timeout 15m \
          --results-bucket=gs://${PROJECT_ID}-test-results \
          --results-dir=comprehensive-test-$(date +%Y%m%d-%H%M%S) \
          --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
        ;;
    4)
        echo ""
        echo "Available devices:"
        echo ""
        echo "Common Android Devices:"
        echo "  - Pixel 5 (API 33)       model=Pixel5,version=33"
        echo "  - Pixel 4 (API 30)       model=Pixel4,version=30"
        echo "  - Samsung S21 (API 31)   model=a51,version=31"
        echo "  - Samsung Tab S8 (API 32) model=gts8ultra,version=32"
        echo "  - OnePlus 7 Pro (API 28) model=OnePlus7Pro,version=28"
        echo "  - Nexus 6P (API 29)      model=Nexus6P,version=29"
        echo ""
        echo "For full device catalog, run: gcloud firebase test android models list"
        echo ""
        read -p "Enter device model (e.g., Pixel4): " DEVICE_MODEL
        read -p "Enter Android API version (e.g., 30): " DEVICE_VERSION
        read -p "Enter timeout in minutes (e.g., 10): " TEST_TIMEOUT

        echo ""
        echo "Running Custom Test..."
        echo "Device: $DEVICE_MODEL, API $DEVICE_VERSION"
        echo ""
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=$DEVICE_MODEL,version=$DEVICE_VERSION,locale=en,orientation=portrait \
          --timeout ${TEST_TIMEOUT}m \
          --results-bucket=gs://${PROJECT_ID}-test-results \
          --results-dir=custom-test-$(date +%Y%m%d-%H%M%S) \
          --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
        ;;
    *)
        echo "Invalid choice. Using Standard Test."
        gcloud firebase test android run \
          --type instrumentation \
          --app build/app/outputs/flutter-apk/app-debug.apk \
          --device model=Pixel4,version=30,locale=en,orientation=portrait \
          --device model=a51,version=31,locale=en,orientation=portrait \
          --device model=Nexus6P,version=29,locale=en,orientation=portrait \
          --timeout 10m \
          --results-bucket=gs://${PROJECT_ID}-test-results \
          --results-dir=standard-test-$(date +%Y%m%d-%H%M%S) \
          --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
        ;;
esac

echo ""
echo "============================================================================"
echo "Test Submitted Successfully!"
echo "============================================================================"
echo ""
echo "Your app is now running on Firebase Test Lab virtual devices."
echo ""
echo "View Results:"
echo "1. Firebase Console: https://console.firebase.google.com/project/${PROJECT_ID}/testlab/histories/"
echo "2. Cloud Console: https://console.cloud.google.com/storage/browser/${PROJECT_ID}-test-results"
echo ""
echo "Test results include:"
echo "  - Screenshots"
echo "  - Video recordings"
echo "  - Performance metrics"
echo "  - Crash logs"
echo "  - Code coverage"
echo ""
echo "The test will complete in 5-15 minutes depending on configuration."
echo "You will receive an email notification when complete."
echo ""
echo "============================================================================"
