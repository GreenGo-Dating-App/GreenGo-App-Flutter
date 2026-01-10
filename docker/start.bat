@echo off
REM GreenGo Docker Quick Start Script for Windows

echo ========================================
echo GreenGo Docker Environment
echo ========================================
echo.

REM Check if Docker is running
docker info >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running!
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo [OK] Docker is running
echo.

REM Check if .env file exists
if not exist ".env" (
    echo [INFO] Creating .env file from .env.example...
    if exist ".env.example" (
        copy .env.example .env
        echo [INFO] Please edit .env with your configuration
    ) else (
        echo [WARNING] .env.example not found, creating basic .env...
        echo FIREBASE_PROJECT_ID=greengo-chat-dev > .env
        echo POSTGRES_PASSWORD=greengo_dev_password >> .env
        echo REDIS_PASSWORD=greengo_redis_password >> .env
    )
    echo.
)

REM Clean up old containers (optional - prevents conflicts)
echo [INFO] Cleaning up old containers...
docker-compose down 2>nul
echo.

REM Rebuild Firebase container (to get Node 20 + latest Firebase CLI)
echo [INFO] Building/Rebuilding Firebase container with Node 20...
docker-compose build firebase
echo.

REM Start services
echo [INFO] Starting all services...
docker-compose up -d

REM Wait for services to be ready
echo [INFO] Waiting for services to initialize...
timeout /t 5 /nobreak >nul

REM Check Firebase emulator health
echo [INFO] Checking Firebase Emulator status...
timeout /t 3 /nobreak >nul

if errorlevel 0 (
    echo.
    echo ========================================
    echo Services Started Successfully!
    echo ========================================
    echo.
    echo Firebase Services:
    echo   - Emulator UI:       http://localhost:4000
    echo   - Auth Emulator:     localhost:9099
    echo   - Firestore:         localhost:8080
    echo   - Storage:           localhost:9199
    echo   - Functions:         localhost:5001
    echo.
    echo Database Services:
    echo   - Database Admin:    http://localhost:8081
    echo   - Redis Admin:       http://localhost:8082
    echo   - API Gateway:       http://localhost
    echo.
    echo Useful Commands:
    echo   - View logs:         docker-compose logs -f
    echo   - View Firebase logs: docker-compose logs -f firebase
    echo   - Stop services:     docker-compose down
    echo   - Restart:           docker-compose restart
    echo.
    echo [TIP] Open http://localhost:4000 to access Firebase Emulator UI
    echo [TIP] Make sure your Flutter app has useLocalEmulators=true in app_config.dart
    echo.
) else (
    echo.
    echo [ERROR] Failed to start services!
    echo Check the error messages above.
    echo.
    echo Troubleshooting:
    echo   1. Run: docker-compose logs firebase
    echo   2. Check if ports are already in use
    echo   3. Try: docker-compose down && docker-compose up -d
)

pause
