# Restart the local OCR uvicorn process cleanly.
#
# Steps:
#   1. Kill the process currently listening on the configured port
#   2. Clear __pycache__
#   3. Start a fresh uvicorn with --no-proxy-headers (see docs/README.md P5)
#   4. Verify the listener is up on the configured port
#
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\tools\restart_server.ps1

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'python_env.ps1')
$envCheck = Resolve-OcrPython -Root $root
if (-not $envCheck.Ok) {
    Write-Host '[ERROR] Python dependencies are missing, refusing to start.' -ForegroundColor Red
    foreach ($attempt in $envCheck.Attempts) {
        Write-Host ("  [{0}] {1} -> {2}" -f $attempt.Source, $attempt.Path, $attempt.Detail)
    }
    Write-Host ''
    Write-Host 'Fix: python -m pip install -r requirements.txt'
    exit 2
}
$python = $envCheck.Path
$configPath = Join-Path $root 'server\config.json'
if (-not (Test-Path $configPath)) { throw "config not found at $configPath" }
$cfg = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$bindHost = $cfg.bind_host
if ([string]::IsNullOrWhiteSpace($bindHost)) { $bindHost = '0.0.0.0' }

Write-Host ("[1/4] stopping existing listener on port {0}" -f $cfg.port)
$listeners = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $cfg.port }
foreach ($listener in $listeners) {
    Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 3

Write-Host ("[2/4] clearing __pycache__")
Remove-Item (Join-Path $root 'server\__pycache__\*.pyc') -Force -ErrorAction SilentlyContinue

Write-Host ("[3/4] starting uvicorn (trust_proxy={0}, port={1})" -f $cfg.trust_proxy, $cfg.port)
$logOut = Join-Path $root 'server.log'
$logErr = Join-Path $root 'server.err.log'
Start-Process -FilePath $python -ArgumentList @(
    '-m', 'uvicorn', 'server.app:app',
    '--host', $bindHost, '--port', [string]$cfg.port,
    '--no-proxy-headers'
) -WorkingDirectory $root `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr `
  -WindowStyle Hidden

Start-Sleep -Seconds 5

Write-Host ("[4/4] verifying port {0} listener" -f $cfg.port)
$listener = Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
    Where-Object { $_.LocalPort -eq $cfg.port }
if ($listener) {
    $listener | Format-Table LocalAddress, LocalPort, OwningProcess -AutoSize
    Write-Host "OK - uvicorn is up. Last 5 lines of stderr:"
    Get-Content $logErr -Encoding UTF8 -Tail 5
} else {
    Write-Error "FAIL - no listener on port $($cfg.port). Check $logErr"
    exit 1
}
