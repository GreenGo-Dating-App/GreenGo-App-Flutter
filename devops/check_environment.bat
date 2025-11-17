@echo off
REM ============================================================================
REM Environment Verification Script
REM ============================================================================
REM Checks all prerequisites for Firebase Test Lab testing
REM ============================================================================

echo.
echo ============================================================================
echo GreenGo App - Environment Verification
echo ============================================================================
echo.

set PASS_COUNT=0
set FAIL_COUNT=0
set WARN_COUNT=0

REM Node.js Check
echo [1/12] Checking Node.js...
node --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Node.js is installed
    node --version
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: Node.js not found
    echo   Install from: https://nodejs.org/
    set /a FAIL_COUNT+=1
)
echo.

REM npm Check
echo [2/12] Checking npm...
npm --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: npm is installed
    npm --version
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: npm not found
    set /a FAIL_COUNT+=1
)
echo.

REM Flutter Check
echo [3/12] Checking Flutter...
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Flutter is installed
    flutter --version | findstr "Flutter"
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: Flutter not found
    echo   Install from: https://flutter.dev/docs/get-started/install
    set /a FAIL_COUNT+=1
)
echo.

REM Firebase CLI Check
echo [4/12] Checking Firebase CLI...
firebase --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Firebase CLI is installed
    firebase --version
    set /a PASS_COUNT+=1
) else (
    echo ⚠ WARN: Firebase CLI not found
    echo   Will be installed by setup script
    set /a WARN_COUNT+=1
)
echo.

REM Google Cloud SDK Check
echo [5/12] Checking Google Cloud SDK...
gcloud --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Google Cloud SDK is installed
    gcloud --version | findstr "Google Cloud SDK"
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: Google Cloud SDK not found
    echo   REQUIRED: Install from https://cloud.google.com/sdk/docs/install
    set /a FAIL_COUNT+=1
)
echo.

REM TypeScript Check
echo [6/12] Checking TypeScript...
tsc --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: TypeScript is installed globally
    tsc --version
    set /a PASS_COUNT+=1
) else (
    echo ⚠ WARN: TypeScript not found globally
    echo   Will be installed locally in functions/
    set /a WARN_COUNT+=1
)
echo.

REM Git Check
echo [7/12] Checking Git...
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Git is installed
    git --version
    set /a PASS_COUNT+=1
) else (
    echo ⚠ WARN: Git not found
    echo   Recommended for version control
    set /a WARN_COUNT+=1
)
echo.

REM Check functions directory
echo [8/12] Checking functions directory...
if exist "functions" (
    echo ✓ PASS: functions/ directory exists
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: functions/ directory not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check package.json
echo [9/12] Checking functions/package.json...
if exist "functions\package.json" (
    echo ✓ PASS: package.json exists
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: package.json not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check lib directory
echo [10/12] Checking Flutter lib directory...
if exist "lib" (
    echo ✓ PASS: lib/ directory exists
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: lib/ directory not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check pubspec.yaml
echo [11/12] Checking pubspec.yaml...
if exist "pubspec.yaml" (
    echo ✓ PASS: pubspec.yaml exists
    set /a PASS_COUNT+=1
) else (
    echo ✗ FAIL: pubspec.yaml not found
    set /a FAIL_COUNT+=1
)
echo.

REM Check Firebase authentication
echo [12/12] Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PASS: Firebase authenticated
    set /a PASS_COUNT+=1
) else (
    echo ⚠ WARN: Not authenticated with Firebase
    echo   Run: firebase login
    set /a WARN_COUNT+=1
)
echo.

REM Summary
echo ============================================================================
echo Environment Check Summary
echo ============================================================================
echo.
echo ✓ Passed:  %PASS_COUNT%
echo ⚠ Warnings: %WARN_COUNT%
echo ✗ Failed:  %FAIL_COUNT%
echo.

if %FAIL_COUNT% gtr 0 (
    echo Status: ❌ NOT READY - Please install missing dependencies
    echo.
    echo Required Actions:
    if not exist "c:\Program Files\Google\Cloud SDK" (
        echo 1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
    )
    echo.
) else if %WARN_COUNT% gtr 0 (
    echo Status: ⚠ MOSTLY READY - Some optional components missing
    echo.
    echo You can proceed with setup_and_test.bat
    echo.
) else (
    echo Status: ✅ READY - All prerequisites met!
    echo.
    echo Next Steps:
    echo 1. Run: setup_and_test.bat
    echo 2. Run: firebase_test_lab.bat
    echo.
)

echo ============================================================================
pause
