# build_portable.ps1
# -----------------------------------------------------------------------------
# Builds a portable OCR package that does NOT require Python to be installed
# on the target machine. Uses the official Python "embeddable" distribution
# (a ~15 MB zip from python.org) plus all pip-installed dependencies bundled
# into a single self-contained directory.
#
# Run this on the OLD machine (the one that already has a working .venv).
# The output is OCR-portable.zip which can be extracted on any Windows x64
# machine and started with start_server.ps1.
#
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\build_portable.ps1
#
# Prerequisites:
#   - Internet access (to download Python embeddable + get-pip.py)
#   - The current project with requirements.txt
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

# --- Detect Python version from the current venv -------------------------------
$venvPython = Join-Path $root ".venv\Scripts\python.exe"
$pyVer = $null
if (Test-Path $venvPython) {
    $pyVer = & $venvPython -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
}
if (-not $pyVer) {
    $pyVer = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}')"
}
if (-not $pyVer) {
    Write-Host "[ERROR] Cannot determine Python version. Make sure Python is in PATH." -ForegroundColor Red
    exit 1
}
Write-Host "[1/8] Python version: $pyVer" -ForegroundColor Cyan

# --- Download Python embeddable ------------------------------------------------
$embedUrl = "https://www.python.org/ftp/python/$pyVer/python-$pyVer-embed-amd64.zip"
$embedZip = Join-Path $env:TEMP "python-$pyVer-embed-amd64.zip"
$pythonDir = Join-Path $root "python"

if (Test-Path $pythonDir) {
    Write-Host "[2/8] Cleaning previous portable python directory..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $pythonDir
}

Write-Host "[2/8] Downloading Python $pyVer embeddable..." -ForegroundColor Cyan
Write-Host "      URL: $embedUrl"
try {
    Invoke-WebRequest -Uri $embedUrl -OutFile $embedZip -UseBasicParsing
} catch {
    Write-Host "[ERROR] Failed to download Python embeddable." -ForegroundColor Red
    Write-Host "        Try manually downloading from: $embedUrl"
    Write-Host "        Save to: $embedZip"
    Write-Host "        Then re-run this script."
    exit 1
}

Write-Host "      Extracting to $pythonDir ..."
Expand-Archive -Path $embedZip -DestinationPath $pythonDir -Force
Remove-Item $embedZip -Force

# --- Enable site-packages in the embeddable Python -----------------------------
# The embeddable package ships with a python3xx._pth file that restricts
# sys.path to only the stdlib zip and the current directory. We need to
# add Lib\site-packages and enable the site module so pip can install
# packages and they can be imported.
$pthFile = Get-ChildItem -Path $pythonDir -Filter "python*._pth" | Select-Object -First 1
if (-not $pthFile) {
    Write-Host "[ERROR] Cannot find python*._pth in $pythonDir" -ForegroundColor Red
    exit 1
}
$pthPath = $pthFile.FullName
# The embeddable zip names the stdlib zip as python{major}{minor}.zip
# (e.g. python314.zip for 3.14.2), NOT python{major}{minor}{micro}.zip.
$pyShortVer = $pyVer.Split('.')[0..1] -join ''
$pthContent = @"
python$pyShortVer.zip
.
Lib\site-packages

# Uncomment to run site.main() automatically
import site
"@
Set-Content -LiteralPath $pthPath -Value $pthContent -Encoding ASCII
Write-Host "[3/8] Configured $($_.Name): enabled site-packages + import site" -ForegroundColor Cyan

# --- Install pip ---------------------------------------------------------------
$getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
$getPipScript = Join-Path $env:TEMP "get-pip.py"

Write-Host "[4/8] Downloading get-pip.py..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipScript -UseBasicParsing

$portablePython = Join-Path $pythonDir "python.exe"
Write-Host "      Installing pip..."
# pip (and other native tools) write progress/warnings to stderr. Under
# $ErrorActionPreference = "Stop", PowerShell 5.1 treats *any* stderr line
# from a native command as a terminating error. Temporarily relax to
# "Continue" for the pip calls so warnings don't abort the script.
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $portablePython $getPipScript --quiet 2>&1 | Out-Null
$pipExit = $LASTEXITCODE
$ErrorActionPreference = $prevEAP
if ($pipExit -ne 0) {
    Write-Host "      [WARNING] pip install had issues, retrying..."
    $ErrorActionPreference = "Continue"
    & $portablePython $getPipScript 2>&1 | Out-Null
    $pipExit = $LASTEXITCODE
    $ErrorActionPreference = $prevEAP
}
Remove-Item $getPipScript -Force -ErrorAction SilentlyContinue

# Verify pip works
$pipCheck = & $portablePython -m pip --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] pip installation failed: $pipCheck" -ForegroundColor Red
    exit 1
}
Write-Host "      pip: $pipCheck"

# --- Install all project dependencies ------------------------------------------
$reqPath = Join-Path $root "requirements.txt"
if (-not (Test-Path $reqPath)) {
    Write-Host "[ERROR] requirements.txt not found at $reqPath" -ForegroundColor Red
    exit 1
}

Write-Host "[5/8] Installing dependencies from requirements.txt..." -ForegroundColor Cyan
Write-Host "      (This may take a few minutes for onnxruntime + ddddocr)"
$prevEAP = $ErrorActionPreference
$ErrorActionPreference = "Continue"
& $portablePython -m pip install -r $reqPath --no-warn-script-location --quiet 2>&1 | Out-Null
$pipExit = $LASTEXITCODE
if ($pipExit -ne 0) {
    Write-Host "      [WARNING] Retrying with verbose output..."
    & $portablePython -m pip install -r $reqPath --no-warn-script-location 2>&1 |
        ForEach-Object { Write-Host "      $_" -ForegroundColor DarkGray }
    $pipExit = $LASTEXITCODE
}
$ErrorActionPreference = $prevEAP
if ($pipExit -ne 0) {
    Write-Host "[ERROR] pip install failed." -ForegroundColor Red
    exit 1
}

# --- Verify critical imports ---------------------------------------------------
Write-Host "[6/8] Verifying imports..." -ForegroundColor Cyan
$verifyScript = @"
imports = [('ddddocr', 'ddddocr'), ('onnxruntime', 'onnxruntime'),
           ('fastapi', 'fastapi'), ('uvicorn', 'uvicorn'),
           ('PIL', 'Pillow'), ('numpy', 'numpy'), ('pydantic', 'pydantic')]
ok = True
for mod, name in imports:
    try:
        __import__(mod)
        print(f'  [OK] {name}')
    except Exception as e:
        print(f'  [FAIL] {name}: {e}')
        ok = False
exit(0 if ok else 1)
"@
$verifyFile = Join-Path $env:TEMP "_verify_imports.py"
Set-Content -LiteralPath $verifyFile -Value $verifyScript -Encoding UTF8
& $portablePython $verifyFile
$verifyResult = $LASTEXITCODE
Remove-Item $verifyFile -Force -ErrorAction SilentlyContinue
if ($verifyResult -ne 0) {
    Write-Host "[ERROR] Import verification failed." -ForegroundColor Red
    exit 1
}

# --- Clean up unnecessary files to reduce size ---------------------------------
Write-Host "[7/8] Cleaning up to reduce package size..." -ForegroundColor Cyan

# Remove __pycache__ directories
Get-ChildItem -Path $pythonDir -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

# Remove .dist-info directories (package metadata, not needed at runtime)
Get-ChildItem -Path (Join-Path $pythonDir "Lib\site-packages") -Directory -Filter "*.dist-info" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

# Remove .exe launchers that pip installed in Scripts/ (we call python -m directly)
$scriptsDir = Join-Path $pythonDir "Scripts"
if (Test-Path $scriptsDir) {
    Remove-Item -Recurse -Force $scriptsDir -ErrorAction SilentlyContinue
}

# Remove tests directories inside site-packages
Get-ChildItem -Path (Join-Path $pythonDir "Lib\site-packages") -Recurse -Directory -Filter "tests" -ErrorAction SilentlyContinue |
    ForEach-Object { Remove-Item -Recurse -Force $_.FullName -ErrorAction SilentlyContinue }

# Calculate final size
$pySize = (Get-ChildItem -Path $pythonDir -Recurse -File -ErrorAction SilentlyContinue |
    Measure-Object -Property Length -Sum).Sum / 1MB
Write-Host "      Portable python size: $([math]::Round($pySize, 1)) MB"

# --- Package everything into a zip ---------------------------------------------
Write-Host "[8/8] Packaging OCR-portable.zip..." -ForegroundColor Cyan

$zipPath = Join-Path $root "OCR-portable.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }

# Files/dirs to include
$includeItems = @(
    "python",
    "server",
    "userscript",
    "tools",
    "docs",
    "start_server.ps1",
    "start_server.bat",
    "install.ps1",
    "requirements.txt",
    "README.md",
    "LICENSE",
    ".gitignore"
)

# Exclude patterns within included dirs
$excludePatterns = @(
    "__pycache__",
    "*.pyc",
    "debug-images",
    "server.log",
    "server.err.log",
    "config.json",

    "result*.png",
    "edge-profile"
)

# Build a temp staging directory for clean zipping
$staging = Join-Path $env:TEMP "ocr-portable-staging"
if (Test-Path $staging) { Remove-Item -Recurse -Force $staging }
New-Item -ItemType Directory -Path $staging -Force | Out-Null

foreach ($item in $includeItems) {
    $src = Join-Path $root $item
    if (-not (Test-Path $src)) {
        Write-Host "      [SKIP] $item not found" -ForegroundColor DarkGray
        continue
    }
    $dst = Join-Path $staging $item
    if (Test-Path $src -PathType Container) {
        # Copy directory with exclusion
        robocopy $src $dst /E /XD __pycache__ debug-images edge-profile /XF *.pyc server.log server.err.log config.json result*.png /NFL /NDL /NJH /NJS /NC /NS /NP | Out-Null
    } else {
        Copy-Item -LiteralPath $src -Destination $dst -Force
    }
}

# Also copy .gitignore (useful reference)
$gitignore = Join-Path $root ".gitignore"
if (Test-Path $gitignore) {
    Copy-Item -LiteralPath $gitignore -Destination (Join-Path $staging ".gitignore") -Force
}

# Create the zip
Compress-Archive -Path (Join-Path $staging "*") -DestinationPath $zipPath -CompressionLevel Optimal

# Clean up staging
Remove-Item -Recurse -Force $staging -ErrorAction SilentlyContinue

$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Portable package built successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Output:  $zipPath" -ForegroundColor White
Write-Host "  Size:    $([math]::Round($zipSize, 1)) MB" -ForegroundColor White
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "  1. Copy OCR-portable.zip to the new machine" -ForegroundColor Yellow
Write-Host "  2. Extract to a directory (e.g. D:\OCR)" -ForegroundColor Yellow
Write-Host "  3. Run as administrator:" -ForegroundColor Yellow
Write-Host "     powershell -NoProfile -ExecutionPolicy Bypass -File tools\setup_new_server.ps1" -ForegroundColor Yellow
Write-Host ""
