@echo off
setlocal
cd /d "%~dp0"
title OCR Service - Connection Info

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\show_info.ps1"
set "rc=%errorlevel%"
echo.
pause
exit /b %rc%
