@echo off
rem OCR-Panel.bat - root forwarder for the OCR control panel.
rem
rem This file is the entry point that works on a FRESH EXTRACT: the .lnk
rem shortcut embeds an absolute path and is therefore never shipped in the
rem repository or the portable zip. Double-clicking this file once creates
rem the shortcut, then opens the panel - so afterwards the logo shortcut is
rem available like on the original machine.
rem
rem KEEP THIS FILE MINIMAL. Double-clicking a .bat always makes cmd.exe open a
rem console first; nothing inside the file can prevent that. The console only
rem disappears when cmd.exe exits, so every job that takes time (icon
rem generation, shortcut rebuild) lives in tools\panel_launch.vbs instead.
rem Anything slow here - a foreground powershell call, for example - keeps the
rem black window on screen for as long as it runs. Delegating takes ~0.2 s.
rem
rem Keep this file ASCII with CRLF line endings (see AGENTS.md).
setlocal
set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
cd /d "%ROOT%"

rem wscript.exe has no console; it prepares the icon/shortcut in the
rem background and elevates the panel. The cmd window closes right after.
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
