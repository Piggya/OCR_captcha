# setup_new_server.ps1
# -----------------------------------------------------------------------------
# One-shot setup script for a new OCR server machine. Run AFTER extracting
# OCR-portable.zip. This script:
#   1. Verifies the portable Python is present
#   2. Detects the LAN IP
#   3. Configures config.json (work_lan_ip + real api_token auto-gen)
#   4. Generates userscripts (local + colleagues)
#   5. Opens the configured firewall port (default 1205)
#   6. Sets power policy (sleep = never, so the service stays up)
#   7. Starts the OCR service
#   8. Verifies health and prints summary
#
# Usage (MUST run as Administrator for firewall + power settings):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup_new_server.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup_new_server.ps1 -NonInteractive
#
# -NonInteractive accepts the detected LAN IP without prompting. Start-OCR.bat
# uses it so a colleague only has to double-click and approve the UAC prompt.
#
# If not running as admin, the script will still configure config + start the
# service, but will skip firewall and power settings with a warning.
# -----------------------------------------------------------------------------

param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# --- Helper: check admin -------------------------------------------------------
function Test-Administrator {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($current)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator

# --- Step 1: Verify portable Python --------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " OCR Server Setup" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$portablePython = Join-Path $root "python\python.exe"
$venvPython = Join-Path $root ".venv\Scripts\python.exe"

if (Test-Path $portablePython) {
    $python = $portablePython
    Write-Host "[1/7] Portable Python found: $python" -ForegroundColor Green
} elseif (Test-Path $venvPython) {
    $python = $venvPython
    Write-Host "[1/7] venv Python found: $python" -ForegroundColor Green
    Write-Host "      (This is not a portable build. Consider running build_portable.ps1)" -ForegroundColor Yellow
} else {
    $systemPython = Get-Command python -ErrorAction SilentlyContinue
    if ($systemPython) {
        $python = "python"
        Write-Host "[1/7] System Python found: $($systemPython.Source)" -ForegroundColor Green
    } else {
        Write-Host "[1/7] ERROR: No Python found!" -ForegroundColor Red
        Write-Host "      Expected portable Python at: $portablePython" -ForegroundColor Red
        Write-Host "      Or venv Python at: $venvPython" -ForegroundColor Red
        Write-Host "      Or system Python in PATH" -ForegroundColor Red
        exit 1
    }
}

# Quick import check
$importCheck = & $python -c "
try:
    import ddddocr, fastapi, uvicorn, onnxruntime, PIL, numpy, pydantic
    print('ok')
except Exception as e:
    print('FAIL: ' + str(e))
" 2>&1
if ($importCheck -ne "ok") {
    Write-Host "      Import check FAILED: $importCheck" -ForegroundColor Red
    Write-Host "      Dependencies may be missing. Run build_portable.ps1 on the source machine." -ForegroundColor Red
    exit 1
}
Write-Host "      All imports verified." -ForegroundColor Green

# --- Step 2: Detect LAN IP -----------------------------------------------------
Write-Host ""
Write-Host "[2/7] Detecting LAN IP..." -ForegroundColor Cyan

function Get-PrimaryLanIPv4 {
    $addresses = Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" `
                -and $_.IPAddress -notlike "169.254.*" `
                -and $_.PrefixOrigin -ne "WellKnown" `
                -and $_.AddressState -eq "Preferred"
        }

    $isPrivate = {
        param($ip)
        $ip -like "10.*" -or $ip -like "192.168.*" -or $ip -match "^172\.(1[6-9]|2[0-9]|3[0-1])\."
    }

    $virtualAdapterPattern = '(VPN|Tunnel|Tap|TUN|ZeroTier|WireGuard|Hamachi|vgate|vEthernet|Loopback|Pseudo|Hyper-V|Tailscale)'

    $privateCandidates = $addresses | Where-Object { & $isPrivate $_.IPAddress }

    $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Sort-Object RouteMetric, InterfaceMetric, InterfaceIndex |
        Select-Object -First 1
    if ($defaultRoute) {
        $onDefault = $privateCandidates |
            Where-Object { $_.InterfaceIndex -eq $defaultRoute.InterfaceIndex } |
            Select-Object -First 1
        if ($onDefault) { return $onDefault.IPAddress }
    }

    $physical = $privateCandidates |
        Where-Object { $_.InterfaceAlias -notmatch $virtualAdapterPattern } |
        Sort-Object InterfaceMetric, InterfaceIndex |
        Select-Object -First 1
    if ($physical) { return $physical.IPAddress }

    $anyPrivate = $privateCandidates | Sort-Object InterfaceMetric, InterfaceIndex | Select-Object -First 1
    if ($anyPrivate) { return $anyPrivate.IPAddress }

    $fallback = $addresses | Select-Object -First 1
    if ($fallback) { return $fallback.IPAddress }
    return "127.0.0.1"
}

$lanIp = Get-PrimaryLanIPv4
Write-Host "      Detected LAN IP: $lanIp"
if ($NonInteractive) {
    Write-Host "      Using detected LAN IP (non-interactive): $lanIp" -ForegroundColor Green
} else {
    $confirmedIp = Read-Host "      Confirm or enter correct LAN IP [press Enter to accept '$lanIp']"
    if ([string]::IsNullOrWhiteSpace($confirmedIp)) {
        $confirmedIp = $lanIp
    }
    $lanIp = $confirmedIp
    Write-Host "      Using LAN IP: $lanIp" -ForegroundColor Green
}

# --- Step 3: Configure config.json + generate token ----------------------------
Write-Host ""
Write-Host "[3/8] Configuring server\config.json..." -ForegroundColor Cyan

$configPath = Join-Path $root "server\config.json"
$examplePath = Join-Path $root "server\config.example.json"

if (-not (Test-Path $configPath)) {
    if (Test-Path $examplePath) {
        Copy-Item -LiteralPath $examplePath -Destination $configPath
        Write-Host "      Created config.json from config.example.json"
    } else {
        Write-Host "      [ERROR] Neither config.json nor config.example.json found!" -ForegroundColor Red
        exit 1
    }
}

$config = Get-Content -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json
$config.work_lan_ip = $lanIp

# Generate real random token (no placeholder)
function New-Token {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
    return [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}
if ($config.api_token -eq "change-me-to-a-random-internal-token" -or [string]::IsNullOrWhiteSpace($config.api_token)) {
    $config.api_token = New-Token
    Write-Host "      Generated new api_token"
}

$config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding UTF8
Write-Host "      work_lan_ip set to: $lanIp" -ForegroundColor Green

# --- Step 4: Verify userscript ------------------------------------------------
Write-Host ""
Write-Host "[4/8] Checking userscript..." -ForegroundColor Cyan

$port = [int]$config.port
$userscriptPath = Join-Path $root "userscript\local-captcha-autofill.user.js"
if (Test-Path $userscriptPath) {
    Write-Host "      userscript found: $userscriptPath" -ForegroundColor Green
    Write-Host "      served at: http://${lanIp}:$port/userscript.user.js" -ForegroundColor Green
} else {
    Write-Host "      [WARNING] userscript missing: $userscriptPath" -ForegroundColor Yellow
}

Write-Host ""

if ($isAdmin) {
    $ruleName = "OCR Service ($port)"
    $existingRule = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
    if ($existingRule) {
        Write-Host "      Firewall rule '$ruleName' already exists." -ForegroundColor Green
    } else {
        New-NetFirewallRule -DisplayName $ruleName `
            -Direction Inbound -Protocol TCP -LocalPort $port -Action Allow `
            -Profile Any | Out-Null
        Write-Host "      Created firewall rule: $ruleName - TCP Inbound" -ForegroundColor Green
    }
} else {
    Write-Host "      [WARNING] Not running as admin - skipping firewall rule." -ForegroundColor Yellow
    Write-Host "      Either re-run as admin, or manually allow port $port`:" -ForegroundColor Yellow
    Write-Host "        netsh advfirewall firewall add rule name=""OCR Service ($port)"" dir=in action=allow protocol=TCP localport=$port" -ForegroundColor Yellow
}

# --- Step 6: Power settings ----------------------------------------------------
Write-Host ""
Write-Host "[6/8] Configuring power settings (sleep = never)..." -ForegroundColor Cyan

if ($isAdmin) {
    try {
        powercfg /change standby-timeout-ac 0 2>&1 | Out-Null
        powercfg /change standby-timeout-dc 0 2>&1 | Out-Null
        powercfg /change hibernate-timeout-ac 0 2>&1 | Out-Null
        powercfg /change hibernate-timeout-dc 0 2>&1 | Out-Null
        powercfg /SETACVALUEINDEX SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 2>&1 | Out-Null
        powercfg /SETDCVALUEINDEX SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0 2>&1 | Out-Null
        powercfg /setactive SCHEME_CURRENT 2>&1 | Out-Null
        Write-Host "      Sleep: Never (AC + DC)" -ForegroundColor Green
        Write-Host "      Hibernate: Never (AC + DC)" -ForegroundColor Green
        Write-Host "      Hybrid sleep: Off" -ForegroundColor Green
        Write-Host "      Display will still turn off after timeout (saves power, service keeps running)." -ForegroundColor DarkGray
    } catch {
        Write-Host "      [WARNING] Failed to set power settings: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "      [WARNING] Not running as admin - skipping power settings." -ForegroundColor Yellow
    Write-Host "      Run manually as admin:" -ForegroundColor Yellow
    Write-Host "        powercfg /change standby-timeout-ac 0" -ForegroundColor Yellow
    Write-Host "        powercfg /change standby-timeout-dc 0" -ForegroundColor Yellow
    Write-Host "        powercfg /change hibernate-timeout-ac 0" -ForegroundColor Yellow
    Write-Host "        powercfg /change hibernate-timeout-dc 0" -ForegroundColor Yellow
}

# --- Step 7: Start the service -------------------------------------------------
Write-Host ""
Write-Host "[7/8] Starting OCR service..." -ForegroundColor Cyan

# Kill any existing python that might hold the configured port
$portOwner = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1 -ExpandProperty OwningProcess
if ($portOwner) {
    Write-Host "      Port $port is in use by PID $portOwner, stopping it..."
    try {
        Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $portOwner" |
            Invoke-CimMethod -MethodName Terminate 2>&1 | Out-Null
    } catch {
        Stop-Process -Id $portOwner -Force -ErrorAction SilentlyContinue
    }
    Start-Sleep -Seconds 3
}

# Clear __pycache__ to ensure fresh code
Get-ChildItem -Path (Join-Path $root "server") -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

# Read config for host/port
$config = Get-Content -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json
$bindHost = $config.bind_host
$port = [int]$config.port

# Start uvicorn in background
Start-Process -FilePath $python `
    -ArgumentList @('-m', 'uvicorn', 'server.app:app', '--host', $bindHost, '--port', [string]$port, '--no-proxy-headers') `
    -WorkingDirectory $root `
    -RedirectStandardOutput (Join-Path $root "server.log") `
    -RedirectStandardError (Join-Path $root "server.err.log") `
    -WindowStyle Hidden

Write-Host "      Waiting for service to start..."
Start-Sleep -Seconds 6

# --- Step 8: Verify and print results ------------------------------------------
Write-Host ""
Write-Host "[8/8] Verifying..." -ForegroundColor Cyan

$healthUrl = "http://127.0.0.1:$port/health"
try {
    $response = Invoke-WebRequest -Uri $healthUrl -UseBasicParsing -TimeoutSec 10
    $health = $response.Content | ConvertFrom-Json
    if ($health.ok) {
        Write-Host "      Health check: OK" -ForegroundColor Green
        Write-Host "      Engine: $($health.engine)" -ForegroundColor Green
    } else {
        Write-Host "      Health check returned unexpected response: $($response.Content)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "      [WARNING] Health check failed: $_" -ForegroundColor Yellow
    Write-Host "      Check server.err.log for details:" -ForegroundColor Yellow
    Write-Host "        Get-Content $root\server.err.log -Tail 20" -ForegroundColor Yellow
}

# --- Print summary -------------------------------------------------------------
$userscriptUrl = "http://${lanIp}:$port/userscript.user.js"
try { Set-Clipboard -Value $userscriptUrl } catch { }

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Setup Complete!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Server URL (this machine): http://$lanIp`:$port" -ForegroundColor White
Write-Host "  Health:  $healthUrl" -ForegroundColor White
Write-Host ""
Write-Host "  Userscript: http://${lanIp}:$port/userscript.user.js" -ForegroundColor Yellow
Write-Host "    -> Install this URL in Tampermonkey (no file copy needed)" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Colleagues: open the userscript URL above in a browser with Tampermonkey." -ForegroundColor Yellow
Write-Host "    The server URL and token are injected automatically - no manual setup." -ForegroundColor Yellow
Write-Host ("       API token (admin/reference only): {0}" -f $config.api_token) -ForegroundColor DarkGray
Write-Host "  (The public GitHub script stays token-free; only this LAN URL embeds it.)" -ForegroundColor DarkGray
Write-Host ""

if (-not $isAdmin) {
    Write-Host "  [IMPORTANT] Re-run this script as Administrator to configure" -ForegroundColor Red
    Write-Host "  firewall and power settings, or do them manually:" -ForegroundColor Red
    Write-Host "    netsh advfirewall firewall add rule name=""OCR Service ($port)"" dir=in action=allow protocol=TCP localport=$port" -ForegroundColor Red
    Write-Host "    powercfg /change standby-timeout-ac 0" -ForegroundColor Red
    Write-Host "    powercfg /change hibernate-timeout-ac 0" -ForegroundColor Red
    Write-Host ""
}

Write-Host "  To stop the service: double-click Stop-OCR.bat (or use the command below)" -ForegroundColor DarkGray
Write-Host "    Get-NetTCPConnection -LocalPort $port -State Listen | ForEach-Object { Stop-Process -Id `$_.OwningProcess -Force }" -ForegroundColor DarkGray
Write-Host "  To restart: powershell -File tools\restart_server.ps1" -ForegroundColor DarkGray
Write-Host ""
