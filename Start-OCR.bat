@echo off
setlocal
cd /d "%~dp0"
title OCR Service - One-click Setup

rem --- Require administrator (firewall + power settings) -----------------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%~dp0python\python.exe" (
    echo.
    echo [ERROR] python\python.exe was not found.
    echo Please extract the complete OCR-portable.zip to a local folder first.
    echo Do not run this file from inside the zip or from a network share.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  OCR Service - one-click setup
echo ============================================================
echo.
echo This will:
echo   1. Create server\config.json and a random API token (first run only)
echo   2. Allow TCP port 1205 through Windows Firewall
echo   3. Disable sleep/hibernate while plugged in
echo   4. Start the OCR service in the background
echo.
echo Keep this window open until setup finishes.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\setup_new_server.ps1" -NonInteractive
set "rc=%errorlevel%"

echo.
if "%rc%"=="0" (
    echo Setup finished.
    echo The colleagues' userscript URL was copied to the clipboard.
    echo To view/copy server URL + token later: double-click Show-OCR-Info.bat
    start "" "http://127.0.0.1:1205/userscript.user.js"
) else (
    echo [ERROR] Setup failed with exit code %rc%.
    echo Check server.err.log in this folder for details.
)
echo.
pause
exit /b %rc%
