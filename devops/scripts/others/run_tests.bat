@echo off
REM GreenGo App - Test Execution Script (Windows)
REM This script runs all tests and generates a comprehensive report

echo.
echo ╔════════════════════════════════════════════════╗
echo ║   GreenGo App - Comprehensive Test Suite      ║
echo ╚════════════════════════════════════════════════╝
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Node.js is not installed or not in PATH
    echo Please install Node.js from https://nodejs.org/
    pause
    exit /b 1
)

REM Display Node.js version
echo [INFO] Node.js version:
node --version
echo.

REM Run the test script
echo [INFO] Starting test execution...
echo.
node run_all_tests.js

REM Check exit code
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ╔════════════════════════════════════════════════╗
    echo ║   Test Execution Completed Successfully       ║
    echo ╚════════════════════════════════════════════════╝
    echo.
    echo Reports generated in: test_reports\
    echo.
) else (
    echo.
    echo ╔════════════════════════════════════════════════╗
    echo ║   Test Execution Failed                        ║
    echo ╚════════════════════════════════════════════════╝
    echo.
    echo Check the error messages above for details.
    echo.
)

REM Open the latest report
if exist "test_reports\latest_test_report.md" (
    echo [INFO] Opening test report...
    start test_reports\latest_test_report.md
)

echo.
echo Press any key to exit...
pause >nul
