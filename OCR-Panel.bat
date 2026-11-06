@echo off
rem OCR-Panel.bat - root forwarder for the OCR control panel.
rem
rem This file is the entry point that works on a FRESH EXTRACT: the .lnk
rem shortcut embeds an absolute path and is therefore never shipped in the
rem repository or the portable zip. Double-clicking this file once creates
rem the shortcut, then opens the panel - so afterwards the logo shortcut is
rem available like on the original machine.
rem
rem Keep this file ASCII with CRLF line endings (see AGENTS.md).
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
cd /d "%ROOT%"

if not exist "%ROOT%\assets\ocr-panel.ico" (
    if exist "%ROOT%\tools\make_icon.ps1" (
        powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\make_icon.ps1" >nul 2>&1
    )
)

rem The shortcut name is Chinese; do not hardcode it here (codepage safety).
rem If no .lnk exists yet, build it now so the logo entry appears.
dir /b "%ROOT%\*.lnk" >nul 2>&1
if errorlevel 1 (
    if exist "%ROOT%\tools\make_shortcut.ps1" (
        powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\make_shortcut.ps1" -TargetRoot "%ROOT%" -Quiet >nul 2>&1
    )
)

if exist "%ROOT%\tools\panel_launch.vbs" (
    start "" /b wscript.exe //nologo "%ROOT%\tools\panel_launch.vbs"
    exit /b 0
)

if exist "%ROOT%\launchers\OCR-Panel.bat" (
    start "" /b "%ROOT%\launchers\OCR-Panel.bat"
    exit /b 0
)

rem Last resort: run the panel hidden through PowerShell directly.
powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "%ROOT%\tools\panel_launch.ps1"
