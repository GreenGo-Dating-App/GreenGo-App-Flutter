@echo off
REM GreenGo Cloud Functions - Comprehensive Test Runner (Windows)
REM Runs all tests and generates detailed reports

echo ======================================
echo   GreenGo Cloud Functions Test Suite
echo ======================================
echo.

REM Check if we're in the functions directory
if not exist "package.json" (
    echo Error: Please run this script from the functions directory
    exit /b 1
)

echo Step 1: Installing dependencies...
call npm install
if errorlevel 1 (
    echo Failed to install dependencies
    exit /b 1
)
echo Dependencies installed successfully
echo.

echo Step 2: Building TypeScript...
call npm run build
if errorlevel 1 (
    echo TypeScript build failed
    exit /b 1
)
echo TypeScript built successfully
echo.

echo Step 3: Running all tests with coverage...
call npm run test:coverage

set TEST_EXIT_CODE=%errorlevel%

echo.
echo ======================================
echo   Test Results
echo ======================================

if %TEST_EXIT_CODE%==0 (
    echo All tests passed!
) else (
    echo Some tests failed
)

echo.
echo Coverage report generated in: coverage\index.html
echo Detailed report available in: coverage\lcov-report\index.html
echo.

echo To view the HTML coverage report:
echo    start coverage\index.html
echo.

echo ======================================
echo   Additional Commands
echo ======================================
echo   npm test                    - Run all tests
echo   npm run test:watch          - Run tests in watch mode
echo   npm run test:unit           - Run only unit tests
echo   npm run test:integration    - Run only integration tests
echo   npm run test:coverage       - Run with coverage report
echo ======================================

exit /b %TEST_EXIT_CODE%
