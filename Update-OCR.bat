@echo off
setlocal
cd /d "%~dp0"
title OCR Service - Update

rem --- The service was started elevated, so update it elevated too -------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0python\python.exe" (
    echo.
    echo [ERROR] python\python.exe was not found.
    echo This updater is for the portable package. Dev checkouts should use git pull.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  OCR Service - update
echo ============================================================
echo.
echo This will:
echo   1. Download the latest source from GitHub
echo   2. Back up server\config.json, server\ and userscript\
echo   3. Replace code while keeping server\config.json and python\
echo   4. Restart the service
echo.
echo If this machine cannot reach GitHub, press Ctrl+C and use:
echo   powershell -ExecutionPolicy Bypass -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\update_ocr.ps1"
set "rc=%errorlevel%"

echo.
if "%rc%"=="0" (
    echo Update finished.
) else (
    echo [ERROR] Update failed with exit code %rc%.
    echo Your config was backed up. Run Start-OCR.bat to restart the current version.
)
echo.
pause
exit /b %rc%
