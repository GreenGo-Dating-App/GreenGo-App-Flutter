@echo off
REM ============================================================================
REM GreenGo App - Complete Setup and Firebase Test Lab Testing Script
REM ============================================================================
REM This script will:
REM 1. Install all dependencies
REM 2. Build TypeScript Cloud Functions
REM 3. Set up Firebase environment
REM 4. Build Flutter app for testing
REM 5. Run app on Firebase Test Lab (Google Cloud Beta Testing)
REM ============================================================================

echo.
echo ============================================================================
echo GreenGo Dating App - Setup and Test Lab Deployment
echo ============================================================================
echo.

REM Check Node.js installation
echo [1/10] Checking Node.js installation...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)
echo ✓ Node.js is installed
node --version
echo.

REM Check Flutter installation
echo [2/10] Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed!
    echo Please install Flutter from https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)
echo ✓ Flutter is installed
flutter --version | findstr "Flutter"
echo.

REM Check Firebase CLI
echo [3/10] Checking Firebase CLI installation...
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo WARNING: Firebase CLI not found. Installing...
    npm install -g firebase-tools
    if %errorlevel% neq 0 (
        echo ERROR: Failed to install Firebase CLI
        pause
        exit /b 1
    )
)
echo ✓ Firebase CLI is installed
firebase --version
echo.

REM Check gcloud CLI
echo [4/10] Checking Google Cloud SDK installation...
gcloud --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Google Cloud SDK is not installed!
    echo Please install from: https://cloud.google.com/sdk/docs/install
    echo After installation, run: gcloud init
    pause
    exit /b 1
)
echo ✓ Google Cloud SDK is installed
gcloud --version | findstr "Google Cloud SDK"
echo.

REM Install Cloud Functions dependencies
echo [5/10] Installing Cloud Functions dependencies...
cd functions
echo Installing dependencies (this may take 2-3 minutes)...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies
    cd ..
    pause
    exit /b 1
)
echo ✓ Dependencies installed successfully
cd ..
echo.

REM Build TypeScript
echo [6/10] Building TypeScript Cloud Functions...
cd functions
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: TypeScript compilation failed
    cd ..
    pause
    exit /b 1
)
echo ✓ TypeScript compiled successfully
cd ..
echo.

REM Install Flutter dependencies
echo [7/10] Installing Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install Flutter dependencies
    pause
    exit /b 1
)
echo ✓ Flutter dependencies installed
echo.

REM Firebase login check
echo [8/10] Checking Firebase authentication...
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to login to Firebase...
    firebase login
    if %errorlevel% neq 0 (
        echo ERROR: Firebase login failed
        pause
        exit /b 1
    )
)
echo ✓ Firebase authentication verified
echo.

REM Google Cloud authentication check
echo [9/10] Checking Google Cloud authentication...
gcloud auth list >nul 2>&1
if %errorlevel% neq 0 (
    echo You need to login to Google Cloud...
    gcloud auth login
    if %errorlevel% neq 0 (
        echo ERROR: Google Cloud login failed
        pause
        exit /b 1
    )
)
echo ✓ Google Cloud authentication verified
echo.

REM Build Flutter APK for testing
echo [10/10] Building Flutter APK for Firebase Test Lab...
echo This may take 3-5 minutes...
call flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Flutter APK build failed
    pause
    exit /b 1
)
echo ✓ APK built successfully
echo.

echo ============================================================================
echo Setup Complete! All environment settings are configured.
echo ============================================================================
echo.
echo APK Location: build\app\outputs\flutter-apk\app-debug.apk
echo.
echo Next Steps:
echo 1. Review firebase_test_lab.bat to configure test devices
echo 2. Run: firebase_test_lab.bat to start testing
echo.
echo ============================================================================
pause
