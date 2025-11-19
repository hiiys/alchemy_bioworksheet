@echo off
echo ========================================
echo   Adding Node.js to System PATH
echo ========================================
echo.

REM Add Node.js to current session PATH
set "PATH=%PATH%;C:\Program Files\nodejs"

echo Testing Node.js...
node --version
if %ERRORLEVEL% EQU 0 (
    echo ✓ Node.js is working!
    echo.
    npm --version
    echo ✓ npm is working!
    echo.
) else (
    echo ✗ Node.js still not found
    goto :manual
)

echo ========================================
echo Installing Firebase CLI...
echo ========================================
echo.
npm install -g firebase-tools

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✓ Firebase CLI installed successfully!
    echo.
    firebase --version
    echo.
) else (
    echo ✗ Firebase CLI installation failed
    echo Please try running as Administrator
)

echo ========================================
echo Installing FlutterFire CLI...
echo ========================================
echo.
dart pub global activate flutterfire_cli

echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo.
echo For permanent fix, add to System PATH:
echo 1. Press Windows+R
echo 2. Type: systempropertiesadvanced
echo 3. Click "Environment Variables"
echo 4. Edit "Path" under User variables
echo 5. Add: C:\Program Files\nodejs
echo 6. Click OK and restart terminal
echo.
pause
exit /b 0

:manual
echo.
echo ========================================
echo MANUAL STEPS TO FIX PATH:
echo ========================================
echo.
echo 1. Press Windows Key + R
echo 2. Type: systempropertiesadvanced
echo 3. Press Enter
echo 4. Click "Environment Variables" button
echo 5. Under "User variables", find "Path"
echo 6. Click "Edit"
echo 7. Click "New"
echo 8. Type: C:\Program Files\nodejs
echo 9. Click "OK" on all dialogs
echo 10. Close and reopen this window
echo 11. Run this script again
echo.
pause
