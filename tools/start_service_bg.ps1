# start_service_bg.ps1
# -----------------------------------------------------------------------------
# Start the OCR service in the background if it is not already running.
# Does NOT change any configuration (no firewall / power changes), so it can
# be used by the control panel and by the Windows scheduled task that starts
# the service at logon. No administrator rights are required for the start
# itself (the firewall rule is created once by Start-OCR.bat).
# -----------------------------------------------------------------------------

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $root "server\config.json"

$port = 1205
$bindHost = "0.0.0.0"
if (Test-Path -LiteralPath $configPath) {
    try {
        $cfg = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.port) { $port = [int]$cfg.port }
        if ($cfg.bind_host) { $bindHost = [string]$cfg.bind_host }
    } catch { }
}

function Get-ListenerPid([int]$p) {
    try {
        $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($c) { return [int]$c.OwningProcess }
    } catch { }
    return 0
}

$python = Join-Path $root "python\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    $python = Join-Path $root ".venv\Scripts\python.exe"
}
if (-not (Test-Path -LiteralPath $python)) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host "[ERROR] Python not found (looked for python\, .venv\ and PATH)." -ForegroundColor Red
        exit 1
    }
    $python = $cmd.Source
}

# Probe the interpreter BEFORE launching anything. Without this, a system
# Python that has uvicorn but not ddddocr starts uvicorn fine and then dies
# 40 lines deep into a traceback, leaving the user with "service stopped" and
# no idea why. python_env.ps1 owns the candidate order and the probe.
. (Join-Path $PSScriptRoot "python_env.ps1")
$envCheck = Resolve-OcrPython -Root $root
if (-not $envCheck.Ok) {
    Write-Host "[ERROR] The OCR service cannot start: Python dependencies are missing." -ForegroundColor Red
    Write-Host ""
    ($envCheck.Attempts | ForEach-Object {
        Write-Host ("  [{0}] {1}" -f $_.Source, $_.Path)
        Write-Host ("         {0}" -f $_.Detail)
    })
    Write-Host ""
    Write-Host "Fix: run launchers\Start-OCR.bat once (it installs the dependencies),"
    Write-Host "     or run:  python -m pip install -r requirements.txt"
    Write-Host ""
    Write-Host ("Reason: " + $envCheck.Reason) -ForegroundColor Yellow
    exit 2
}
$python = $envCheck.Path

$running = Get-ListenerPid $port
if ($running -gt 0 -and -not $Force) {
    Write-Host ("Service already running on port {0} (PID {1})." -f $port, $running)
    exit 0
}
if ($running -gt 0) {
    Write-Host ("Stopping existing listener on port {0} (PID {1})..." -f $port, $running)
    Stop-Process -Id $running -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

$logOut = Join-Path $root "server.log"
$logErr = Join-Path $root "server.err.log"
Start-Process -FilePath $python -ArgumentList @(
    '-m', 'uvicorn', 'server.app:app',
    '--host', $bindHost, '--port', [string]$port, '--no-proxy-headers'
) -WorkingDirectory $root `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr `
  -WindowStyle Hidden

Start-Sleep -Seconds 5
$pid0 = Get-ListenerPid $port
if ($pid0 -gt 0) {
    Write-Host ("Service started on port {0} (PID {1})." -f $port, $pid0) -ForegroundColor Green
    exit 0
}

Write-Host "[ERROR] Service did not start; check server.err.log." -ForegroundColor Red
exit 1
