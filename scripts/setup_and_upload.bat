@echo off
echo ============================================
echo Firebase Test Data Upload Script
echo ============================================
echo.

REM Set PATH for Node.js and npm
set PATH=%PATH%;C:\Program Files\nodejs;%APPDATA%\npm

echo Step 1: Checking Firebase CLI...
firebase --version
if errorlevel 1 (
    echo Firebase CLI not found. Please install it first.
    pause
    exit /b 1
)

echo.
echo Step 2: Logging into Firebase...
echo If a browser window opens, please login with your Google account.
echo.
firebase login

echo.
echo Step 3: Setting up Application Default Credentials...
echo This allows the Node.js script to access Firebase.
echo.

REM Check if gcloud is available for ADC
where gcloud >nul 2>&1
if errorlevel 1 (
    echo.
    echo NOTE: gcloud CLI not found. Using Firebase login token instead.
    echo The upload script will use Firebase Admin SDK with project ID.
    echo.
) else (
    gcloud auth application-default login
)

echo.
echo Step 4: Running upload script...
cd /d "%~dp0"
node upload_test_data.js

echo.
echo ============================================
echo Upload process completed!
echo ============================================
pause
