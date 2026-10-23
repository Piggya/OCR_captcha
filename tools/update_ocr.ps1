# update_ocr.ps1
# -----------------------------------------------------------------------------
# Update an existing portable OCR install in place.
#
# What it does:
#   1. Downloads the latest source zip from GitHub (or uses -SourceZip)
#   2. Stops the running service
#   3. Backs up server/config.json + server/ + userscript/ to backup-<time>/
#   4. Copies server/, userscript/, tools/, docs/, launchers and root files
#   5. NEVER overwrites server/config.json and NEVER touches python/
#   6. Restarts the service via tools/setup_new_server.ps1 -NonInteractive
#
# Usage (normally via Update-OCR.bat, which self-elevates):
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\update_ocr.ps1
#   powershell ... -SourceZip "D:\Downloads\OCR_captcha-main.zip"
#   powershell ... -InstallRoot "D:\OCR" -Force
#
# Offline / isolated LAN: download this on another machine, copy it over, then
#   powershell ... -File tools\update_ocr.ps1 -SourceZip "C:\path\main.zip"
# -----------------------------------------------------------------------------

param(
    [string]$SourceZip = "",
    [string]$InstallRoot = "",
    [switch]$Force,
    [switch]$SkipDependencies
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$text) {
    Write-Host "[UPDATE] $text" -ForegroundColor Cyan
}

function Get-AppVersion([string]$path) {
    $match = Select-String -LiteralPath $path -Pattern '__version__\s*=\s*"([^"]+)"' | Select-Object -First 1
    if ($match) { return $match.Matches[0].Groups[1].Value }
    return ""
}

$root = if ($InstallRoot) {
    (Resolve-Path -LiteralPath $InstallRoot).Path
} else {
    (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
$serverDir = Join-Path $root "server"
$userscriptDir = Join-Path $root "userscript"
$configPath = Join-Path $serverDir "config.json"
$appPy = Join-Path $serverDir "app.py"
$python = Join-Path $root "python\python.exe"

if (-not (Test-Path -LiteralPath $appPy)) {
    Write-Host "[ERROR] server\app.py not found under $root" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -LiteralPath $python)) {
    Write-Host "[ERROR] python\python.exe not found." -ForegroundColor Red
    Write-Host "        This updater targets the portable package. A dev checkout should use git pull." -ForegroundColor Yellow
    exit 1
}

$isAdmin = $false
try {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch { }
if (-not $isAdmin) {
    Write-Host "[WARNING] Not running as Administrator; stopping/starting the service may fail." -ForegroundColor Yellow
}

$oldVersion = Get-AppVersion $appPy
if (-not $oldVersion) { $oldVersion = "unknown" }
Write-Step ("Installed version: " + $oldVersion)

$work = Join-Path $env:TEMP ("ocr-update-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $work -Force | Out-Null

try {
    $zipPath = $SourceZip
    if (-not $zipPath) {
        $zipPath = Join-Path $work "main.zip"
        $url = "https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip"
        Write-Step "Downloading the latest source from GitHub..."
        $ok = $false
        try {
            Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 120
            $ok = $true
        } catch {
            Write-Host ("      Direct download failed: " + $_.Exception.Message) -ForegroundColor Yellow
        }
        if (-not $ok) {
            $proxies = @()
            if ($env:HTTPS_PROXY) { $proxies += $env:HTTPS_PROXY }
            if ($env:HTTP_PROXY) { $proxies += $env:HTTP_PROXY }
            $proxies += "http://127.0.0.1:7890"
            foreach ($proxy in ($proxies | Select-Object -Unique)) {
                try {
                    Write-Step ("Retrying via proxy " + $proxy)
                    Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 120 -Proxy $proxy
                    $ok = $true
                    break
                } catch {
                    Write-Host ("      Proxy failed: " + $_.Exception.Message) -ForegroundColor Yellow
                }
            }
        }
        if (-not $ok) {
            Write-Host "[ERROR] Cannot download the update from GitHub." -ForegroundColor Red
            Write-Host "        1. On a machine with internet, download:" -ForegroundColor Yellow
            Write-Host "           https://github.com/Piggya/OCR_captcha/archive/refs/heads/main.zip" -ForegroundColor Yellow
            Write-Host "        2. Copy the zip to this machine, then run (as Administrator):" -ForegroundColor Yellow
            Write-Host ('           powershell -ExecutionPolicy Bypass -File "' + (Join-Path $root "tools\update_ocr.ps1") + '" -SourceZip "C:\path\main.zip"') -ForegroundColor Yellow
            exit 1
        }
    } elseif (-not (Test-Path -LiteralPath $zipPath)) {
        Write-Host ("[ERROR] Source zip not found: " + $zipPath) -ForegroundColor Red
        exit 1
    }

    Write-Step "Extracting..."
    $extract = Join-Path $work "src"
    New-Item -ItemType Directory -Path $extract -Force | Out-Null
    Expand-Archive -LiteralPath $zipPath -DestinationPath $extract -Force

    $srcRoot = $null
    if (Test-Path (Join-Path $extract "server\app.py")) {
        $srcRoot = $extract
    } else {
        $candidate = Get-ChildItem -LiteralPath $extract -Directory | Where-Object {
            Test-Path (Join-Path $_.FullName "server\app.py")
        } | Select-Object -First 1
        if ($candidate) { $srcRoot = $candidate.FullName }
    }
    if (-not $srcRoot) {
        Write-Host "[ERROR] server\app.py not found in the source zip." -ForegroundColor Red
        exit 1
    }

    $newVersion = Get-AppVersion (Join-Path $srcRoot "server\app.py")
    if (-not $newVersion) { $newVersion = "unknown" }
    Write-Step ("Source version: " + $newVersion)

    if (-not $Force -and $oldVersion -ne "unknown" -and $newVersion -ne "unknown") {
        try {
            if ([version]$newVersion -le [version]$oldVersion) {
                Write-Host ("Already up to date (" + $oldVersion + "). Use -Force to reinstall.") -ForegroundColor Green
                exit 0
            }
        } catch { }
    }

    $port = 1205
    if (Test-Path -LiteralPath $configPath) {
        try { $port = [int](Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json).port } catch { }
    }

    Write-Step ("Stopping the service on port " + $port + " (if running)...")
    $connections = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue
    if ($connections) {
        $connections | ForEach-Object {
            Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
    }

    $backup = Join-Path $root ("backup-" + (Get-Date -Format "yyyyMMdd-HHmmss"))
    New-Item -ItemType Directory -Path $backup -Force | Out-Null
    if (Test-Path -LiteralPath $configPath) {
        Copy-Item -LiteralPath $configPath -Destination (Join-Path $backup "config.json") -Force
    }
    if (Test-Path -LiteralPath $serverDir) {
        Copy-Item -LiteralPath $serverDir -Destination (Join-Path $backup "server") -Recurse -Force
    }
    if (Test-Path -LiteralPath $userscriptDir) {
        Copy-Item -LiteralPath $userscriptDir -Destination (Join-Path $backup "userscript") -Recurse -Force
    }
    Write-Step ("Backup: " + $backup)

    $oldReq = Join-Path $root "requirements.txt"
    $newReq = Join-Path $srcRoot "requirements.txt"
    $reqChanged = $false
    if ((Test-Path -LiteralPath $oldReq) -and (Test-Path -LiteralPath $newReq)) {
        $reqChanged = ((Get-FileHash -LiteralPath $oldReq).Hash -ne (Get-FileHash -LiteralPath $newReq).Hash)
    }

    function Copy-ProjectTree([string]$source, [string]$destination, [string[]]$excludeFiles = @()) {
        if (-not (Test-Path -LiteralPath $source)) { return }
        New-Item -ItemType Directory -Path $destination -Force | Out-Null
        $robocopyArgs = @(
            $source, $destination, "/E", "/XD", "__pycache__",
            "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP"
        )
        if ($excludeFiles.Count -gt 0) {
            $robocopyArgs += "/XF"
            $robocopyArgs += $excludeFiles
        }
        & robocopy @robocopyArgs | Out-Null
        if ($LASTEXITCODE -ge 8) {
            throw ("robocopy failed with exit code " + $LASTEXITCODE)
        }
    }

    Write-Step "Copying code (config.json and python/ are preserved)..."
    Copy-ProjectTree (Join-Path $srcRoot "server") $serverDir @("config.json", "*.pyc", "server.log", "server.err.log")
    Copy-ProjectTree (Join-Path $srcRoot "userscript") $userscriptDir
    # Do not overwrite the running updater itself; a future updater change
    # should ship as a full package. Still install it when upgrading from a
    # package that predates Update-OCR.bat.
    Copy-ProjectTree (Join-Path $srcRoot "tools") (Join-Path $root "tools") @("*.pyc", "update_ocr.ps1")
    $destUpdater = Join-Path $root "tools\update_ocr.ps1"
    $srcUpdater = Join-Path $srcRoot "tools\update_ocr.ps1"
    if (-not (Test-Path -LiteralPath $destUpdater) -and (Test-Path -LiteralPath $srcUpdater)) {
        Copy-Item -LiteralPath $srcUpdater -Destination $destUpdater -Force
    }
    Copy-ProjectTree (Join-Path $srcRoot "docs") (Join-Path $root "docs")

    $rootFiles = @(
        "Start-OCR.bat", "Stop-OCR.bat", "Update-OCR.bat", "README-FIRST.txt",
        "start_server.ps1", "start_server.bat", "install.ps1",
        "requirements.txt", "README.md", "LICENSE"
    )
    foreach ($name in $rootFiles) {
        $source = Join-Path $srcRoot $name
        if (Test-Path -LiteralPath $source) {
            Copy-Item -LiteralPath $source -Destination (Join-Path $root $name) -Force
        }
    }

    if ($reqChanged) {
        if ($SkipDependencies) {
            Write-Host "[WARNING] requirements.txt changed; dependencies were NOT installed (-SkipDependencies)." -ForegroundColor Yellow
            Write-Host "          Run: .\python\python.exe -m pip install -r requirements.txt" -ForegroundColor Yellow
        } else {
            Write-Step "requirements.txt changed; installing dependencies into the portable Python..."
            $previousEAP = $ErrorActionPreference
            $ErrorActionPreference = "Continue"
            & $python -m pip install -r (Join-Path $srcRoot "requirements.txt") --no-warn-script-location
            $pipExit = $LASTEXITCODE
            $ErrorActionPreference = $previousEAP
            if ($pipExit -ne 0) {
                Write-Host "[WARNING] pip install failed. If the service does not start, download the full portable package." -ForegroundColor Yellow
            }
        }
    }

    Write-Step "Restarting the service..."
    $setup = Join-Path $root "tools\setup_new_server.ps1"
    if (Test-Path -LiteralPath $setup) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $setup -NonInteractive
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[WARNING] Restart returned a non-zero exit code. Run Start-OCR.bat." -ForegroundColor Yellow
        }
    } else {
        Write-Host "[WARNING] tools\setup_new_server.ps1 not found. Run Start-OCR.bat." -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host (" Update complete: " + $oldVersion + " -> " + $newVersion) -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ("  Backup: " + $backup) -ForegroundColor White
    Write-Host "  Colleagues: Tampermonkey will pick up the new @version." -ForegroundColor White
    Write-Host "  If their script was installed from GitHub, ask them to open" -ForegroundColor DarkGray
    Write-Host "  http://<server-ip>:$port/userscript.user.js once to switch to LAN updates." -ForegroundColor DarkGray
    Write-Host ""
    exit 0
} catch {
    Write-Host ("[ERROR] Update failed: " + $_.Exception.Message) -ForegroundColor Red
    Write-Host "        server\config.json is preserved. Run Start-OCR.bat to restart the current version." -ForegroundColor Yellow
    exit 1
} finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -Recurse -Force -LiteralPath $work -ErrorAction SilentlyContinue
    }
}
