@echo off
setlocal
cd /d "%~dp0.."
set "ROOT=%CD%"
title OCR Service - Stop

rem --- The service was started elevated, so stop it elevated too --------------
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Stopping the OCR service...
powershell -NoProfile -Command "$root = $env:ROOT; $port = 1205; try { $port = [int](Get-Content -LiteralPath (Join-Path $root 'server\config.json') -Raw | ConvertFrom-Json).port } catch { }; $conn = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue; if ($conn) { $conn | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue }; Write-Host ('Stopped OCR service on port ' + $port + '.') } else { Write-Host ('No OCR listener found on port ' + $port + '.') }"
echo.
pause
