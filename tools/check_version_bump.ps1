# check_version_bump.ps1
# -----------------------------------------------------------------------------
# Guard for the GreasyFork webhook.
#
# GreasyFork is connected to this repository's main branch. A push only creates
# a new GreasyFork script version when the userscript file changes AND its
# @version is strictly greater than the version already published. Pushing the
# same version again makes the webhook reject the update (or users never see it).
#
# Run this before committing/pushing a release:
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\check_version_bump.ps1
#
# It compares the working tree with origin/main (fetch first if needed). It:
#   - passes when only docs/tools changed;
#   - fails when userscript/ or server/ changed but @version was not increased;
#   - fails when server/app.py __version__ and userscript @version disagree.
# -----------------------------------------------------------------------------

param(
    [string]$BaseRef = "origin/main",
    [string]$Root = ""
)

$ErrorActionPreference = "Stop"

function Get-TextVersion([string]$text, [string]$pattern) {
    $match = [regex]::Match($text, $pattern)
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value
}

if (-not $Root) {
    $Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
$userscriptRel = "userscript/local-captcha-autofill.user.js"
$serverRel = "server/app.py"
$userscriptPath = Join-Path $Root $userscriptRel
$serverPath = Join-Path $Root $serverRel

if (-not (Test-Path -LiteralPath $userscriptPath)) {
    Write-Host "[FAIL] userscript not found: $userscriptPath" -ForegroundColor Red
    exit 1
}

$currentText = Get-Content -LiteralPath $userscriptPath -Raw -Encoding UTF8
$currentVersion = Get-TextVersion $currentText '//\s*@version\s+([0-9]+\.[0-9]+\.[0-9]+)'
if (-not $currentVersion) {
    Write-Host "[FAIL] Cannot read // @version from userscript." -ForegroundColor Red
    exit 1
}

$serverText = Get-Content -LiteralPath $serverPath -Raw -Encoding UTF8
$serverVersion = Get-TextVersion $serverText '__version__\s*=\s*"([0-9]+\.[0-9]+\.[0-9]+)"'
if (-not $serverVersion) {
    Write-Host "[FAIL] Cannot read __version__ from server/app.py." -ForegroundColor Red
    exit 1
}
if ($serverVersion -ne $currentVersion) {
    Write-Host ("[FAIL] Version mismatch: server/app.py={0}, userscript={1}" -f $serverVersion, $currentVersion) -ForegroundColor Red
    Write-Host "       Both must be identical (see docs/CHANGELOG.md for the version rules)." -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[WARN] git not found; skipping base comparison." -ForegroundColor Yellow
    exit 0
}

$baseText = $null
$previousEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
try {
    $baseText = (git -C $Root show ("{0}:{1}" -f $BaseRef, $userscriptRel) 2>$null) -join "`n"
} catch { }
$ErrorActionPreference = $previousEap
if (-not $baseText) {
    Write-Host ("[WARN] Cannot read {0}:{1}; skipping bump check (fetch first for a strict check)." -f $BaseRef, $userscriptRel) -ForegroundColor Yellow
    exit 0
}
$baseVersion = Get-TextVersion $baseText '//\s*@version\s+([0-9]+\.[0-9]+\.[0-9]+)'
if (-not $baseVersion) {
    Write-Host ("[FAIL] Cannot read // @version from {0}." -f $BaseRef) -ForegroundColor Red
    exit 1
}

$previousEap = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$changed = @(git -C $Root diff --name-only $BaseRef -- userscript server 2>$null | Where-Object { $_ })
$ErrorActionPreference = $previousEap
if ($changed.Count -eq 0) {
    Write-Host ("[OK] No userscript/server changes vs {0}; no version bump required." -f $BaseRef) -ForegroundColor Green
    Write-Host ("     Version: {0}" -f $currentVersion) -ForegroundColor DarkGray
    exit 0
}

try {
    $isNewer = ([version]$currentVersion).CompareTo([version]$baseVersion) -gt 0
} catch {
    Write-Host ("[FAIL] Cannot compare versions: {0} vs {1}" -f $currentVersion, $baseVersion) -ForegroundColor Red
    exit 1
}

if (-not $isNewer) {
    Write-Host ("[FAIL] Code changed but @version was not increased: current={0}, {1}={2}" -f $currentVersion, $BaseRef, $baseVersion) -ForegroundColor Red
    Write-Host "       GreasyFork webhook will reject the same/older version." -ForegroundColor Yellow
    Write-Host "       Bump BOTH server/app.py __version__ and userscript // @version." -ForegroundColor Yellow
    Write-Host "       Files changed:" -ForegroundColor Yellow
    $changed | ForEach-Object { Write-Host ("         - {0}" -f $_) -ForegroundColor Yellow }
    exit 1
}

Write-Host ("[OK] Version bumped: {0} -> {1} (base {2})" -f $baseVersion, $currentVersion, $BaseRef) -ForegroundColor Green
Write-Host "     GreasyFork webhook will publish this version after push." -ForegroundColor DarkGray
exit 0
