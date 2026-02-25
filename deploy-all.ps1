# =============================================================================
# GreenGo Full Deployment Script (PowerShell)
# Commits, deploys Cloud Functions, merges ios->main, builds APK+AAB locally,
# triggers Codemagic iOS TestFlight
# =============================================================================
$ErrorActionPreference = "Stop"

# --- Configuration ---
$ProjectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$FirebaseProject = "greengo-chat"
$CodemagicApiToken = $env:CODEMAGIC_API_TOKEN
$CodemagicAppId = $env:CODEMAGIC_APP_ID

Set-Location $ProjectDir

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 1: Commit changes on ios branch" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
git add `
  lib/features/matching/domain/entities/match_preferences.dart `
  lib/features/matching/data/models/match_preferences_model.dart `
  lib/core/services/candidate_pool_service.dart `
  lib/features/matching/data/datasources/matching_remote_datasource.dart `
  lib/features/discovery/data/datasources/discovery_remote_datasource.dart `
  functions/src/presence/onPresenceUpdate.ts `
  functions/src/index.ts `
  lib/core/widgets/last_seen_text.dart `
  lib/features/chat/presentation/screens/chat_screen.dart `
  pubspec.yaml `
  codemagic.yaml

$commitMsg = @"
Fix country filter, auto-location enrichment, online status text

- Pass preferredCountries through matching pipeline to pool service
- CandidatePoolService accepts List<String> countries (multi-country pools)
- Exclude Unknown/empty country profiles when country filter is active
- Add onPresenceUpdate Cloud Function: reverse-geocodes on isOnline transition
- Update last seen text: "Online Xm/h/d ago", "Offline" after 5 days
- Bump version to 1.0.13+17, add AAB to Codemagic artifacts

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
"@
git commit -m $commitMsg

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 2: Push ios branch" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
git push origin ios

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 3: Deploy Cloud Functions" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Push-Location "$ProjectDir\functions"
npm run build
Pop-Location
firebase deploy --only functions:onPresenceUpdate --project $FirebaseProject

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 4: Merge ios -> main" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
git checkout main
git pull origin main
git merge ios --no-ff -m "Merge ios branch: country filter fix + location enrichment + online status (v1.0.13)"
git push origin main

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 5: Delete old branches" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
try { git branch -d ios } catch { Write-Host "ios branch already deleted locally" }
try { git branch -d Android } catch { Write-Host "Android branch not found locally" }
try { git push origin --delete ios } catch { Write-Host "Remote ios branch already deleted" }
try { git push origin --delete Android } catch { Write-Host "Remote Android branch already deleted" }

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 6: Build APK and AAB locally" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
flutter build appbundle --release

Write-Host ""
Write-Host "APK: $ProjectDir\build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
Write-Host "AAB: $ProjectDir\build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " Step 7: Trigger Codemagic iOS build" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
if (-not $CodemagicApiToken -or -not $CodemagicAppId) {
    Write-Host "WARNING: CODEMAGIC_API_TOKEN or CODEMAGIC_APP_ID not set." -ForegroundColor Yellow
    Write-Host "Set them as environment variables and re-run, or trigger manually at https://codemagic.io" -ForegroundColor Yellow
    Write-Host '  $env:CODEMAGIC_API_TOKEN = "your_token_here"'
    Write-Host '  $env:CODEMAGIC_APP_ID = "your_app_id_here"'
} else {
    $headers = @{
        "Content-Type" = "application/json"
        "x-auth-token" = $CodemagicApiToken
    }

    Write-Host "Triggering iOS TestFlight build..."
    $body = @{
        appId = $CodemagicAppId
        workflowId = "ios-testflight"
        branch = "main"
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "https://api.codemagic.io/builds" -Method Post -Headers $headers -Body $body
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " Done! Deployment complete." -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
