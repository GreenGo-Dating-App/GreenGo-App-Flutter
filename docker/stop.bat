@echo off
REM GreenGo Docker Stop Script for Windows

echo ========================================
echo Stopping GreenGo Docker Services
echo ========================================
echo.

docker-compose down

if errorlevel 0 (
    echo.
    echo [OK] All services stopped successfully!
    echo.
    echo To remove all data, run: docker-compose down -v
) else (
    echo.
    echo [ERROR] Failed to stop services!
)

pause
