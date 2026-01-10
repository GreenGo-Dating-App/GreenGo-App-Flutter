#!/bin/bash

# ============================================================================
# GreenGo iOS Release Script
# ============================================================================
# Usage: ./scripts/release_ios.sh [version]
# Example: ./scripts/release_ios.sh 1.2.0
#
# Prerequisites:
#   - macOS with Xcode installed
#   - Valid Apple Developer account
#   - Distribution certificate and provisioning profile
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}Error: iOS builds require macOS${NC}"
    exit 1
fi

# Get version from argument or prompt
VERSION=${1:-""}
if [ -z "$VERSION" ]; then
    echo -e "${YELLOW}Enter the new version number (e.g., 1.2.0):${NC}"
    read VERSION
fi

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid version format. Use MAJOR.MINOR.PATCH (e.g., 1.2.0)${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  GreenGo iOS Release - Version $VERSION${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# Step 1: Get current build number and increment
echo -e "${YELLOW}Step 1: Reading current version...${NC}"
CURRENT_VERSION=$(grep "version:" pubspec.yaml | head -1 | sed 's/version: //' | tr -d ' ')
CURRENT_BUILD=$(echo $CURRENT_VERSION | cut -d'+' -f2)
NEW_BUILD=$((CURRENT_BUILD + 1))

echo "  Current: $CURRENT_VERSION"
echo "  New: $VERSION+$NEW_BUILD"
echo ""

# Step 2: Update pubspec.yaml
echo -e "${YELLOW}Step 2: Updating pubspec.yaml...${NC}"
sed -i '' "s/version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml
echo -e "${GREEN}  ✓ Version updated to $VERSION+$NEW_BUILD${NC}"
echo ""

# Step 3: Clean and get dependencies
echo -e "${YELLOW}Step 3: Cleaning build...${NC}"
flutter clean
echo -e "${GREEN}  ✓ Clean complete${NC}"
echo ""

echo -e "${YELLOW}Step 4: Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}  ✓ Dependencies updated${NC}"
echo ""

# Step 5: Update CocoaPods
echo -e "${YELLOW}Step 5: Updating CocoaPods...${NC}"
cd ios
pod install --repo-update
cd ..
echo -e "${GREEN}  ✓ CocoaPods updated${NC}"
echo ""

# Step 6: Run tests
echo -e "${YELLOW}Step 6: Running tests...${NC}"
flutter test || {
    echo -e "${RED}  ✗ Tests failed! Fix tests before releasing.${NC}"
    exit 1
}
echo -e "${GREEN}  ✓ All tests passed${NC}"
echo ""

# Step 7: Build iOS
echo -e "${YELLOW}Step 7: Building iOS release...${NC}"
flutter build ios --release

if [ -d "build/ios/iphoneos/Runner.app" ]; then
    echo -e "${GREEN}  ✓ iOS build created successfully${NC}"
else
    echo -e "${RED}  ✗ Build failed!${NC}"
    exit 1
fi
echo ""

# Step 8: Archive options
echo -e "${YELLOW}Step 8: Archive and Upload${NC}"
echo ""
echo "  Choose an option:"
echo "    1. Open Xcode to archive manually"
echo "    2. Use Fastlane to archive and upload"
echo "    3. Skip (build only)"
echo ""
echo -e "${YELLOW}Enter choice (1/2/3):${NC}"
read CHOICE

case $CHOICE in
    1)
        echo -e "${YELLOW}Opening Xcode...${NC}"
        open ios/Runner.xcworkspace
        echo ""
        echo -e "${BLUE}In Xcode:${NC}"
        echo "  1. Select 'Any iOS Device (arm64)' as target"
        echo "  2. Go to Product > Archive"
        echo "  3. Click 'Distribute App' in Organizer"
        echo "  4. Select 'App Store Connect' > 'Upload'"
        ;;
    2)
        echo -e "${YELLOW}Running Fastlane...${NC}"
        cd ios

        if [ ! -f "fastlane/Fastfile" ]; then
            echo -e "${RED}Fastlane not configured. Run 'fastlane init' first.${NC}"
            exit 1
        fi

        # Upload to TestFlight
        fastlane beta
        cd ..
        echo -e "${GREEN}  ✓ Uploaded to TestFlight${NC}"
        ;;
    3)
        echo "  Skipping archive."
        ;;
    *)
        echo "  Invalid choice. Skipping archive."
        ;;
esac

echo ""

# Create release notes
echo -e "${YELLOW}Step 9: Release Notes${NC}"
echo -e "${YELLOW}Enter release notes for App Store (press Enter twice to finish):${NC}"
RELEASE_NOTES=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    RELEASE_NOTES="$RELEASE_NOTES$line\n"
done

# Save release notes
mkdir -p "ios/fastlane/metadata/en-US"
echo -e "$RELEASE_NOTES" > "ios/fastlane/metadata/en-US/release_notes.txt"
echo -e "${GREEN}  ✓ Release notes saved${NC}"
echo ""

# Summary
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}  BUILD COMPLETE!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo "  Version: $VERSION+$NEW_BUILD"
echo "  Build:   build/ios/iphoneos/Runner.app"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Complete archive/upload in Xcode (if not done)"
echo ""
echo "  2. Go to App Store Connect:"
echo "     https://appstoreconnect.apple.com"
echo ""
echo "  3. Select the build and submit for review"
echo ""
echo "  4. After approval, update Firestore (soft update):"
echo "     firebase firestore:update app_config/version --data '{\"ios.recommendedVersion\": \"$VERSION\", \"ios.currentVersion\": \"$VERSION\"}'"
echo ""
echo "  5. For FORCE update, also set:"
echo "     ios.minVersion = \"$VERSION\""
echo ""
echo -e "${BLUE}============================================================================${NC}"
