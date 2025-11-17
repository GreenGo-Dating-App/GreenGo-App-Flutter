@echo off
REM ============================================================================
REM Firebase Test Lab - Run GreenGo App on Virtual Devices
REM ============================================================================
REM This script runs your app on Firebase Test Lab with multiple device configs
REM Requires: Google Cloud SDK, Firebase CLI, APK built
REM ============================================================================

echo.
echo ============================================================================
echo Firebase Test Lab - Virtual Device Testing
echo ============================================================================
echo.

REM Check if APK exists
if not exist "build\app\outputs\flutter-apk\app-debug.apk" (
    echo ERROR: APK not found!
    echo Please run setup_and_test.bat first to build the APK
    pause
    exit /b 1
)

echo ✓ Found APK: build\app\outputs\flutter-apk\app-debug.apk
echo.

REM Get Firebase project ID
echo Retrieving Firebase project ID...
for /f "delims=" %%i in ('firebase projects:list --json 2^>nul ^| findstr "projectId"') do set PROJECT_LINE=%%i
if "%PROJECT_LINE%"=="" (
    echo ERROR: No Firebase project found!
    echo Please run: firebase use --add
    pause
    exit /b 1
)

REM You can also manually set your project ID here:
REM set PROJECT_ID=your-project-id

echo.
echo ============================================================================
echo Test Configuration Options
echo ============================================================================
echo.
echo Choose a test configuration:
echo.
echo [1] Quick Test - 1 device, 5 minutes
echo     - Nexus 6P, Android API 29
echo.
echo [2] Standard Test - 3 devices, 10 minutes  (RECOMMENDED)
echo     - Pixel 4, Android API 30
echo     - Samsung Galaxy S21, Android API 31
echo     - Nexus 6P, Android API 29
echo.
echo [3] Comprehensive Test - 6 devices, 15 minutes
echo     - Latest flagship devices
echo     - Multiple Android versions (API 28-33)
echo.
echo [4] Custom Test - Configure manually
echo.
set /p CHOICE="Enter choice (1-4): "

if "%CHOICE%"=="1" goto QUICK_TEST
if "%CHOICE%"=="2" goto STANDARD_TEST
if "%CHOICE%"=="3" goto COMPREHENSIVE_TEST
if "%CHOICE%"=="4" goto CUSTOM_TEST

echo Invalid choice. Using Standard Test.
goto STANDARD_TEST

:QUICK_TEST
echo.
echo Running Quick Test (1 device)...
echo.
gcloud firebase test android run ^
  --type instrumentation ^
  --app build\app\outputs\flutter-apk\app-debug.apk ^
  --device model=Nexus6P,version=29,locale=en,orientation=portrait ^
  --timeout 5m ^
  --results-bucket=gs://greengo-test-results ^
  --results-dir=quick-test-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2% ^
  --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
goto TEST_COMPLETE

:STANDARD_TEST
echo.
echo Running Standard Test (3 devices)...
echo.
gcloud firebase test android run ^
  --type instrumentation ^
  --app build\app\outputs\flutter-apk\app-debug.apk ^
  --device model=Pixel4,version=30,locale=en,orientation=portrait ^
  --device model=a51,version=31,locale=en,orientation=portrait ^
  --device model=Nexus6P,version=29,locale=en,orientation=portrait ^
  --timeout 10m ^
  --results-bucket=gs://greengo-test-results ^
  --results-dir=standard-test-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2% ^
  --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
goto TEST_COMPLETE

:COMPREHENSIVE_TEST
echo.
echo Running Comprehensive Test (6 devices)...
echo.
gcloud firebase test android run ^
  --type instrumentation ^
  --app build\app\outputs\flutter-apk\app-debug.apk ^
  --device model=Pixel5,version=33,locale=en,orientation=portrait ^
  --device model=Pixel4,version=30,locale=en,orientation=portrait ^
  --device model=a51,version=31,locale=en,orientation=portrait ^
  --device model=gts8ultra,version=32,locale=en,orientation=portrait ^
  --device model=Nexus6P,version=29,locale=en,orientation=portrait ^
  --device model=OnePlus7Pro,version=28,locale=en,orientation=portrait ^
  --timeout 15m ^
  --results-bucket=gs://greengo-test-results ^
  --results-dir=comprehensive-test-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2% ^
  --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
goto TEST_COMPLETE

:CUSTOM_TEST
echo.
echo Available devices:
echo.
echo Common Android Devices:
echo   - Pixel 5 (API 33)       model=Pixel5,version=33
echo   - Pixel 4 (API 30)       model=Pixel4,version=30
echo   - Samsung S21 (API 31)   model=a51,version=31
echo   - Samsung Tab S8 (API 32) model=gts8ultra,version=32
echo   - OnePlus 7 Pro (API 28) model=OnePlus7Pro,version=28
echo   - Nexus 6P (API 29)      model=Nexus6P,version=29
echo.
echo For full device catalog, run: gcloud firebase test android models list
echo.
set /p DEVICE_MODEL="Enter device model (e.g., Pixel4): "
set /p DEVICE_VERSION="Enter Android API version (e.g., 30): "
set /p TEST_TIMEOUT="Enter timeout in minutes (e.g., 10): "

echo.
echo Running Custom Test...
echo Device: %DEVICE_MODEL%, API %DEVICE_VERSION%
echo.
gcloud firebase test android run ^
  --type instrumentation ^
  --app build\app\outputs\flutter-apk\app-debug.apk ^
  --device model=%DEVICE_MODEL%,version=%DEVICE_VERSION%,locale=en,orientation=portrait ^
  --timeout %TEST_TIMEOUT%m ^
  --results-bucket=gs://greengo-test-results ^
  --results-dir=custom-test-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2% ^
  --environment-variables coverage=true,coverageFile=/sdcard/coverage.ec
goto TEST_COMPLETE

:TEST_COMPLETE
echo.
echo ============================================================================
echo Test Submitted Successfully!
echo ============================================================================
echo.
echo Your app is now running on Firebase Test Lab virtual devices.
echo.
echo View Results:
echo 1. Firebase Console: https://console.firebase.google.com/project/_/testlab/histories/
echo 2. Cloud Console: https://console.cloud.google.com/storage/browser/greengo-test-results
echo.
echo Test results include:
echo   - Screenshots
echo   - Video recordings
echo   - Performance metrics
echo   - Crash logs
echo   - Code coverage
echo.
echo The test will complete in 5-15 minutes depending on configuration.
echo You will receive an email notification when complete.
echo.
echo ============================================================================
pause
