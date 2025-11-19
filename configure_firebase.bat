@echo off
echo ========================================
echo   Firebase Configuration Script
echo ========================================
echo.

cd /d "%~dp0"

echo Setting up PATH...
set "PATH=%PATH%;C:\Program Files\nodejs"
set "PATH=%PATH%;C:\Users\%USERNAME%\AppData\Roaming\npm"
set "PATH=%PATH%;C:\Users\%USERNAME%\AppData\Local\Pub\Cache\bin"

echo.
echo Logging into Firebase...
echo This will open your browser.
echo.

call firebase login --no-localhost

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Firebase login failed. Please try manually:
    echo 1. Open PowerShell
    echo 2. Run: firebase login
    pause
    exit /b 1
)

echo.
echo ========================================
echo Running FlutterFire Configuration...
echo ========================================
echo.
echo Please select the following when prompted:
echo - Project: macrobenthos-taxonomy-prod
echo - Platforms: android (press space to select)
echo.
pause

call dart pub global run flutterfire_cli:flutterfire configure --project=macrobenthos-taxonomy-prod

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo ✓ Firebase configuration complete!
    echo ========================================
    echo.
    echo Files created:
    echo - lib/firebase_options.dart
    echo - android/app/google-services.json
    echo.
) else (
    echo.
    echo ========================================
    echo Configuration failed
    echo ========================================
    echo.
    echo Please try manual configuration or contact support.
    echo.
)

pause
