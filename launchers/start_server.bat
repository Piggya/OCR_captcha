@echo off
rem Developer-only foreground launcher (Ctrl+C to stop).
rem Daily use: OCR-Panel.bat in the install root.
setlocal
cd /d "%~dp0.."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\tools\start_server.ps1"
