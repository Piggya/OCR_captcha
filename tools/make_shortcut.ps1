# make_shortcut.ps1
# -----------------------------------------------------------------------------
# Create "OCR 控制面板.lnk" in the install root. A .bat cannot carry a custom
# icon (Explorer always draws the generic cmd/script glyph), but a shortcut has
# its own IconLocation, so double-clicking it shows the logo instead of a black
# console sheet.
#
# The shortcut does NOT point at OCR-Panel.bat. It launches wscript.exe with the
# VBS launcher directly, which:
#   - avoids a cmd.exe window entirely (nothing flashes before elevation)
#   - keeps the existing silent elevation path (ShellExecute "runas")
#   - does not depend on cmd.exe shell parsing of a Chinese path
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File tools\make_shortcut.ps1
#   ... -Desktop        also create a copy on the current user's desktop
#   ... -Quiet          no output (used by setup/update)
# -----------------------------------------------------------------------------

param(
    [string]$TargetRoot = "",
    [switch]$Desktop,
    [switch]$Quiet
)

$ErrorActionPreference = "Stop"
if ($TargetRoot) {
    $root = (Resolve-Path -LiteralPath $TargetRoot).Path
} else {
    $root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}

$linkName = "OCR 控制面板.lnk"
$linkPath = Join-Path $root $linkName
$vbs = Join-Path $root "tools\panel_launch.vbs"
$ico = Join-Path $root "assets\ocr-panel.ico"

if (-not (Test-Path -LiteralPath $vbs)) {
    throw ("Launcher not found: " + $vbs)
}

# Generate the icon once if the package lost it.
if (-not (Test-Path -LiteralPath $ico)) {
    $maker = Join-Path $root "tools\make_icon.ps1"
    if (Test-Path -LiteralPath $maker) {
        & powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File $maker -OutFile $ico | Out-Null
    }
}

function New-PanelShortcut([string]$path) {
    $shell = New-Object -ComObject WScript.Shell
    try {
        $sc = $shell.CreateShortcut($path)
        # wscript.exe has its own icon; IconLocation overrides it.
        $sc.TargetPath = Join-Path $env:SystemRoot "System32\wscript.exe"
        $sc.Arguments = '//nologo "' + $vbs + '"'
        $sc.WorkingDirectory = $root
        $sc.Description = "OCR 验证码识别服务 - 控制面板（启动/停止/更新/查看连接信息）"
        if (Test-Path -LiteralPath $ico) {
            $sc.IconLocation = $ico + ",0"
        }
        # 1 = normal window; the VBS keeps everything hidden/elevated.
        $sc.WindowStyle = 1
        $sc.Save()
    } finally {
        [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shell)
    }
}

New-PanelShortcut $linkPath
if (-not $Quiet) {
    Write-Host ("shortcut=" + $linkPath)
    Write-Host ("icon=" + $ico)
}

if ($Desktop) {
    $desk = [Environment]::GetFolderPath("Desktop")
    if ($desk -and (Test-Path -LiteralPath $desk)) {
        $deskLink = Join-Path $desk $linkName
        New-PanelShortcut $deskLink
        if (-not $Quiet) { Write-Host ("desktop=" + $deskLink) }
    }
}
