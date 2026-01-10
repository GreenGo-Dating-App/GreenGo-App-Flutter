#!/bin/bash

# ============================================================================
# GreenGo Android Release Script
# ============================================================================
# Usage: ./scripts/release_android.sh [version]
# Example: ./scripts/release_android.sh 1.2.0
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
echo -e "${BLUE}  GreenGo Android Release - Version $VERSION${NC}"
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
sed -i "s/version: .*/version: $VERSION+$NEW_BUILD/" pubspec.yaml
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

# Step 5: Run tests
echo -e "${YELLOW}Step 5: Running tests...${NC}"
flutter test || {
    echo -e "${RED}  ✗ Tests failed! Fix tests before releasing.${NC}"
    exit 1
}
echo -e "${GREEN}  ✓ All tests passed${NC}"
echo ""

# Step 6: Build App Bundle
echo -e "${YELLOW}Step 6: Building Android App Bundle...${NC}"
flutter build appbundle --release

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    echo -e "${GREEN}  ✓ App Bundle created successfully${NC}"
    AAB_SIZE=$(du -h build/app/outputs/bundle/release/app-release.aab | cut -f1)
    echo "  Size: $AAB_SIZE"
else
    echo -e "${RED}  ✗ Build failed!${NC}"
    exit 1
fi
echo ""

# Step 7: Create changelog
echo -e "${YELLOW}Step 7: Creating changelog...${NC}"
CHANGELOG_DIR="android/fastlane/metadata/android/en-US/changelogs"
mkdir -p $CHANGELOG_DIR

echo -e "${YELLOW}Enter release notes (press Enter twice to finish):${NC}"
RELEASE_NOTES=""
while IFS= read -r line; do
    [ -z "$line" ] && break
    RELEASE_NOTES="$RELEASE_NOTES$line\n"
done

echo -e "$RELEASE_NOTES" > "$CHANGELOG_DIR/$NEW_BUILD.txt"
echo -e "${GREEN}  ✓ Changelog created: $CHANGELOG_DIR/$NEW_BUILD.txt${NC}"
echo ""

# Summary
echo -e "${BLUE}============================================================================${NC}"
echo -e "${GREEN}  BUILD COMPLETE!${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""
echo "  Version: $VERSION+$NEW_BUILD"
echo "  Bundle:  build/app/outputs/bundle/release/app-release.aab"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Upload to Google Play Console:"
echo "     https://play.google.com/console"
echo ""
echo "  2. After approval, update Firestore (soft update):"
echo "     firebase firestore:update app_config/version --data '{\"android.recommendedVersion\": \"$VERSION\", \"android.currentVersion\": \"$VERSION\"}'"
echo ""
echo "  3. For FORCE update, also set:"
echo "     android.minVersion = \"$VERSION\""
echo ""
echo -e "${BLUE}============================================================================${NC}"
