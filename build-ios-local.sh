#!/bin/bash
# =============================================================================
# GreenGo iOS Local Build + TestFlight Upload
# Run this on your Mac to build IPA and upload to TestFlight
# Replicates the Codemagic ios-testflight workflow locally
# =============================================================================
set -e

# =============================================================================
# CONFIGURATION — Edit these if needed
# =============================================================================
BUNDLE_ID="com.greengochat.greengochatapp"
TEAM_ID="9885DQB8RF"
BUILD_NAME="1.0.13"
BUILD_NUMBER="${1:-17}"  # Pass as argument or defaults to 17
SCHEME="Runner"
WORKSPACE="ios/Runner.xcworkspace"

# App Store Connect API Key for upload
# Generate at https://appstoreconnect.apple.com/access/integrations/api
# Then fill these in:
ASC_KEY_ID="${ASC_KEY_ID:-}"           # e.g. "ABC123DEF4"
ASC_ISSUER_ID="${ASC_ISSUER_ID:-}"     # e.g. "12345678-abcd-..."
ASC_KEY_FILE="${ASC_KEY_FILE:-}"       # e.g. "$HOME/.appstoreconnect/AuthKey_ABC123DEF4.p8"

# =============================================================================
# DERIVED PATHS
# =============================================================================
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE_PATH="$PROJECT_DIR/build/ios/archive/Runner.xcarchive"
EXPORT_DIR="$PROJECT_DIR/build/ios/ipa"
EXPORT_OPTIONS="$PROJECT_DIR/build/ios/ExportOptions.plist"

cd "$PROJECT_DIR"

echo "========================================="
echo " GreenGo iOS Build v${BUILD_NAME}+${BUILD_NUMBER}"
echo "========================================="
echo ""

# =============================================================================
# Step 1: Verify prerequisites
# =============================================================================
echo "[1/8] Checking prerequisites..."

if ! command -v flutter &>/dev/null; then
  echo "ERROR: flutter not found. Install Flutter first."
  exit 1
fi

if ! command -v xcodebuild &>/dev/null; then
  echo "ERROR: xcodebuild not found. Install Xcode first."
  exit 1
fi

if ! command -v pod &>/dev/null; then
  echo "WARNING: CocoaPods not found. Installing..."
  sudo gem install cocoapods
fi

FLUTTER_VERSION=$(flutter --version | head -1)
XCODE_VERSION=$(xcodebuild -version | head -1)
echo "  Flutter: $FLUTTER_VERSION"
echo "  Xcode:   $XCODE_VERSION"
echo "  Team:    $TEAM_ID"
echo "  Bundle:  $BUNDLE_ID"
echo ""

# =============================================================================
# Step 2: Pull latest code
# =============================================================================
echo "[2/8] Pulling latest from main..."
git checkout main
git pull origin main
echo ""

# =============================================================================
# Step 3: Flutter dependencies + code generation
# =============================================================================
echo "[3/8] Getting Flutter packages..."
flutter pub get

echo "[3/8] Running build_runner..."
dart run build_runner build --delete-conflicting-outputs
echo ""

# =============================================================================
# Step 4: Install CocoaPods
# =============================================================================
echo "[4/8] Installing CocoaPods dependencies..."
cd ios
pod install --repo-update
cd "$PROJECT_DIR"
echo ""

# =============================================================================
# Step 5: Create ExportOptions.plist for App Store distribution
# =============================================================================
echo "[5/8] Creating ExportOptions.plist..."
mkdir -p "$(dirname "$EXPORT_OPTIONS")"
cat > "$EXPORT_OPTIONS" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>destination</key>
    <string>upload</string>
</dict>
</plist>
PLIST
echo "  Created: $EXPORT_OPTIONS"
echo ""

# =============================================================================
# Step 6: Build IPA
# =============================================================================
echo "[6/8] Building IPA (release)..."
echo "  build-name: $BUILD_NAME"
echo "  build-number: $BUILD_NUMBER"

flutter build ipa \
  --release \
  --build-name="$BUILD_NAME" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist="$EXPORT_OPTIONS"

IPA_FILE=$(find "$EXPORT_DIR" -name "*.ipa" -type f | head -1)

if [ -z "$IPA_FILE" ]; then
  echo "ERROR: IPA file not found in $EXPORT_DIR"
  echo "Checking archive..."
  ls -la "$ARCHIVE_PATH" 2>/dev/null || echo "Archive also not found"
  exit 1
fi

IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
echo ""
echo "  IPA built successfully: $IPA_FILE ($IPA_SIZE)"
echo ""

# =============================================================================
# Step 7: Upload to TestFlight
# =============================================================================
echo "[7/8] Uploading to TestFlight..."

if [ -n "$ASC_KEY_ID" ] && [ -n "$ASC_ISSUER_ID" ] && [ -n "$ASC_KEY_FILE" ]; then
  # Method A: App Store Connect API Key (preferred, no 2FA needed)
  echo "  Using App Store Connect API Key..."
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_FILE" \
    --apiKey "$ASC_KEY_ID" \
    --apiIssuer "$ASC_ISSUER_ID" \
    2>&1 || {
      echo ""
      echo "  altool failed, trying xcrun notarytool/transporter..."
      xcrun altool --upload-app \
        --type ios \
        --file "$IPA_FILE" \
        --apiKey "$ASC_KEY_ID" \
        --apiIssuer "$ASC_ISSUER_ID" \
        --show-progress
    }
else
  # Method B: Apple ID authentication (will prompt for app-specific password)
  echo "  No API key configured. Using Apple ID authentication..."
  echo "  Apple ID: tommasi.mauro@icloud.com"
  echo ""
  echo "  You need an App-Specific Password from https://appleid.apple.com/account/manage"
  echo "  Generate one and enter it when prompted."
  echo ""
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_FILE" \
    --username "tommasi.mauro@icloud.com" \
    --password "@keychain:AC_PASSWORD" \
    2>&1 || {
      echo ""
      echo "  If keychain lookup failed, store your app-specific password first:"
      echo "    xcrun altool --store-password-in-keychain-item AC_PASSWORD \\"
      echo "      -u tommasi.mauro@icloud.com -p <your-app-specific-password>"
      echo ""
      echo "  Or upload manually:"
      echo "    xcrun altool --upload-app --type ios --file \"$IPA_FILE\" \\"
      echo "      --username tommasi.mauro@icloud.com --password <app-specific-password>"
      echo ""
      echo "  Or drag the IPA into Transporter.app (download from Mac App Store)"
    }
fi

echo ""

# =============================================================================
# Step 8: Summary
# =============================================================================
echo "========================================="
echo " Build Complete!"
echo "========================================="
echo ""
echo "  Version:  ${BUILD_NAME}+${BUILD_NUMBER}"
echo "  IPA:      $IPA_FILE"
echo "  Size:     $IPA_SIZE"
echo ""
echo "  If upload didn't work automatically:"
echo "    1. Open Transporter.app (Mac App Store)"
echo "    2. Drag the IPA file into it"
echo "    3. Click 'Deliver'"
echo ""
echo "  Or set up API Key for automated uploads:"
echo "    export ASC_KEY_ID=\"your_key_id\""
echo "    export ASC_ISSUER_ID=\"your_issuer_id\""
echo "    export ASC_KEY_FILE=\"\$HOME/.appstoreconnect/AuthKey_XXX.p8\""
echo ""
echo "========================================="
