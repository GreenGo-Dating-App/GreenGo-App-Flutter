#!/bin/bash
# =============================================================================
# GreenGo Full Deployment Script (Bash)
# Commits, deploys Cloud Functions, merges ios→main, builds APK+AAB locally,
# triggers Codemagic iOS TestFlight
# =============================================================================
set -e

# --- Configuration ---
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FIREBASE_PROJECT="greengo-chat"
CODEMAGIC_API_TOKEN="${CODEMAGIC_API_TOKEN:-}"
CODEMAGIC_APP_ID="${CODEMAGIC_APP_ID:-}"

cd "$PROJECT_DIR"

echo "========================================="
echo " Step 1: Commit changes on ios branch"
echo "========================================="
git add \
  lib/features/matching/domain/entities/match_preferences.dart \
  lib/features/matching/data/models/match_preferences_model.dart \
  lib/core/services/candidate_pool_service.dart \
  lib/features/matching/data/datasources/matching_remote_datasource.dart \
  lib/features/discovery/data/datasources/discovery_remote_datasource.dart \
  functions/src/presence/onPresenceUpdate.ts \
  functions/src/index.ts \
  lib/core/widgets/last_seen_text.dart \
  lib/features/chat/presentation/screens/chat_screen.dart \
  pubspec.yaml \
  codemagic.yaml

git commit -m "$(cat <<'EOF'
Fix country filter, auto-location enrichment, online status text

- Pass preferredCountries through matching pipeline to pool service
- CandidatePoolService accepts List<String> countries (multi-country pools)
- Exclude Unknown/empty country profiles when country filter is active
- Add onPresenceUpdate Cloud Function: reverse-geocodes on isOnline transition
- Update last seen text: "Online Xm/h/d ago", "Offline" after 5 days
- Bump version to 1.0.13+17, add AAB to Codemagic artifacts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"

echo ""
echo "========================================="
echo " Step 2: Push ios branch"
echo "========================================="
git push origin ios

echo ""
echo "========================================="
echo " Step 3: Deploy Cloud Functions"
echo "========================================="
cd "$PROJECT_DIR/functions"
npm run build
cd "$PROJECT_DIR"
firebase deploy --only functions:onPresenceUpdate --project "$FIREBASE_PROJECT"

echo ""
echo "========================================="
echo " Step 4: Merge ios → main"
echo "========================================="
git checkout main
git pull origin main
git merge ios --no-ff -m "Merge ios branch: country filter fix + location enrichment + online status (v1.0.13)"
git push origin main

echo ""
echo "========================================="
echo " Step 5: Delete old branches"
echo "========================================="
git branch -d ios 2>/dev/null || echo "ios branch already deleted locally"
git branch -d Android 2>/dev/null || echo "Android branch not found locally"
git push origin --delete ios 2>/dev/null || echo "Remote ios branch already deleted"
git push origin --delete Android 2>/dev/null || echo "Remote Android branch already deleted"

echo ""
echo "========================================="
echo " Step 6: Build APK and AAB locally"
echo "========================================="
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
flutter build appbundle --release

echo ""
echo "APK: $PROJECT_DIR/build/app/outputs/flutter-apk/app-release.apk"
echo "AAB: $PROJECT_DIR/build/app/outputs/bundle/release/app-release.aab"

echo ""
echo "========================================="
echo " Step 7: Trigger Codemagic iOS build"
echo "========================================="
if [ -z "$CODEMAGIC_API_TOKEN" ] || [ -z "$CODEMAGIC_APP_ID" ]; then
  echo "WARNING: CODEMAGIC_API_TOKEN or CODEMAGIC_APP_ID not set."
  echo "Set them as environment variables and re-run, or trigger manually at https://codemagic.io"
  echo ""
  echo "  export CODEMAGIC_API_TOKEN=your_token_here"
  echo "  export CODEMAGIC_APP_ID=your_app_id_here"
else
  echo "Triggering iOS TestFlight build..."
  curl -s -X POST \
    "https://api.codemagic.io/builds" \
    -H "Content-Type: application/json" \
    -H "x-auth-token: $CODEMAGIC_API_TOKEN" \
    -d "{
      \"appId\": \"$CODEMAGIC_APP_ID\",
      \"workflowId\": \"ios-testflight\",
      \"branch\": \"main\"
    }" | python3 -m json.tool 2>/dev/null || echo "(response above)"
fi

echo ""
echo "========================================="
echo " Done! Deployment complete."
echo "========================================="
