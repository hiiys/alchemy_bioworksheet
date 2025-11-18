@echo off
REM Batch file to convert Markdown to DOCX
REM Simpler alternative to PowerShell script

echo ========================================
echo   MARKDOWN TO DOCX CONVERTER
echo ========================================
echo.

cd /d "%~dp0"

if not exist "FIREBASE_IMPLEMENTATION_WORKPLAN.md" (
    echo ERROR: Could not find FIREBASE_IMPLEMENTATION_WORKPLAN.md
    echo Please run this script in the same directory as the markdown file.
    pause
    exit /b 1
)

echo Found: FIREBASE_IMPLEMENTATION_WORKPLAN.md
echo.

REM Check for Pandoc
where pandoc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo Pandoc found! Converting...
    echo.
    pandoc FIREBASE_IMPLEMENTATION_WORKPLAN.md -o FIREBASE_WORKPLAN.docx --toc --toc-depth=3

    if exist "FIREBASE_WORKPLAN.docx" (
        echo.
        echo SUCCESS! Document created: FIREBASE_WORKPLAN.docx
        echo.
        echo Opening document...
        start FIREBASE_WORKPLAN.docx
        echo.
        echo Done! You can now print the document from Word.
        pause
        exit /b 0
    ) else (
        echo ERROR: Conversion failed
        goto :manual_instructions
    )
) else (
    echo Pandoc not found.
    echo.
    goto :manual_instructions
)

:manual_instructions
echo ========================================
echo MANUAL CONVERSION INSTRUCTIONS
echo ========================================
echo.
echo Option 1 - Install Pandoc (Recommended):
echo   1. Visit: https://pandoc.org/installing.html
echo   2. Download and install Pandoc
echo   3. Run this script again
echo.
echo Option 2 - Use Microsoft Word:
echo   1. Open Microsoft Word
echo   2. File -^> Open
echo   3. Change filter to "All Files (*.*)"
echo   4. Select: FIREBASE_IMPLEMENTATION_WORKPLAN.md
echo   5. File -^> Save As -^> Choose .docx format
echo.
echo Option 3 - Online Converter:
echo   1. Visit: https://cloudconvert.com/md-to-docx
echo   2. Upload: FIREBASE_IMPLEMENTATION_WORKPLAN.md
echo   3. Download converted .docx file
echo.
echo Current directory: %CD%
echo.
pause
