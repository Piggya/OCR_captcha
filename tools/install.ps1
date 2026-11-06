#requires -Version 5.1
<#
  First-time setup for a fresh clone: create .venv and install dependencies.
  Run this once, then run tools\start_server.ps1.

  Usage:
      powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\install.ps1
#>
$ErrorActionPreference = "Stop"
# This script lives in tools\; the install root is one level up.
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

function Get-PythonCommand {
    foreach ($name in @("python3", "python")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Python not found in PATH. Install Python 3.10+ from https://www.python.org/downloads/ and enable 'Add python.exe to PATH'."
}

$python = Get-PythonCommand
Write-Host "[1/3] Using Python: $python" -ForegroundColor Cyan

$venv = Join-Path $root ".venv"
if (-not (Test-Path $venv)) {
    Write-Host "[2/3] Creating virtual environment at .venv ..." -ForegroundColor Cyan
    & $python -m venv $venv
    if ($LASTEXITCODE -ne 0) { throw "Failed to create virtual environment." }
} else {
    Write-Host "[2/3] Reusing existing .venv" -ForegroundColor Cyan
}

$venvPython = Join-Path $venv "Scripts\python.exe"
if (-not (Test-Path $venvPython)) { throw "Virtual environment python not found: $venvPython" }

Write-Host "[3/3] Installing dependencies ..." -ForegroundColor Cyan
& $venvPython -m pip install --upgrade pip
if ($LASTEXITCODE -ne 0) { throw "pip upgrade failed." }
& $venvPython -m pip install -r (Join-Path $root "requirements.txt")
if ($LASTEXITCODE -ne 0) { throw "Dependency installation failed." }

Write-Host ""
Write-Host "Install complete." -ForegroundColor Green
Write-Host "Next: .\tools\start_server.ps1   (creates server\config.json + token on first run)" -ForegroundColor Yellow
