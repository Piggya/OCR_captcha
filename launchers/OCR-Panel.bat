@echo off
rem OCR-Panel.bat - daily entry point for the OCR control panel.
rem
rem Lives in launchers\ but is still reachable from the install root
rem (OCR-Panel.bat in the root is a one-line forwarder).
rem
rem Silent launch: panel_launch.vbs runs PowerShell hidden and elevates
rem through ShellExecute "runas", so no console window ever appears.
rem
rem Keep this file minimal for the same reason as the root forwarder: cmd.exe's
rem console only closes when this script ends, so icon and shortcut generation
rem are left to panel_launch.vbs (async, hidden). Never call powershell in the
rem foreground here - it would keep the black window alive for seconds.
setlocal
set "ROOT=%~dp0.."
cd /d "%ROOT%"

if exist "%ROOT%\tools\panel_launch.vbs" (
    start "" /b wscript.exe //nologo "%ROOT%\tools\panel_launch.vbs"
    exit /b 0
)

rem Fallback for installs that lost the VBS (flashes one console briefly).
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\panel_launch.ps1"
