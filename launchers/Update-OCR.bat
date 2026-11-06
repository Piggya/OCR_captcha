@echo off
setlocal
cd /d "%~dp0.."
set "ROOT=%CD%"
title OCR Service - Update

rem --- Require administrator (stop/start the elevated service) ----------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

if not exist "%ROOT%\python\python.exe" (
    echo.
    echo [ERROR] python\python.exe was not found. This updater targets the portable package.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  OCR Service - update
echo ============================================================
echo.
echo Downloads the latest version from GitHub, backs up config.json,
echo replaces code and restarts the service. python\ and
echo server\config.json are kept.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\update_ocr.ps1"
set "rc=%errorlevel%"

echo.
if not "%rc%"=="0" (
    echo [ERROR] Update failed with exit code %rc%.
    echo Your config was backed up. Open OCR-Panel.bat and use Start to run the current version.
)
echo.
pause
exit /b %rc%
