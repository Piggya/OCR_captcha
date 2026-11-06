@echo off
setlocal
cd /d "%~dp0.."
set "ROOT=%CD%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\show_info.ps1"
if "%errorlevel%"=="0" (
    echo.
    echo Server address / token / install URL were copied to the clipboard.
) else (
    echo.
    echo [ERROR] Could not read the connection info. Open OCR-Panel.bat instead.
)
echo.
pause
