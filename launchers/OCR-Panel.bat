@echo off
rem OCR-Panel.bat - daily entry point for the OCR control panel.
rem
rem Lives in launchers\ but is still reachable from the install root
rem (OCR-Panel.bat in the root is a one-line forwarder).
rem Silent launch: panel_launch.vbs runs PowerShell hidden and elevates
rem through ShellExecute "runas", so no console window ever appears.
setlocal
set "ROOT=%~dp0.."
cd /d "%ROOT%"

if not exist "%ROOT%\assets\ocr-panel.ico" (
    powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\make_icon.ps1" >nul 2>&1
)

if exist "%ROOT%\tools\panel_launch.vbs" (
    start "" /b wscript.exe //nologo "%ROOT%\tools\panel_launch.vbs"
    exit /b 0
)

rem Fallback for installs that lost the VBS (flashes one console briefly).
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\panel_launch.ps1"
