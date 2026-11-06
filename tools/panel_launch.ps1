# panel_launch.ps1
# -----------------------------------------------------------------------------
# Hidden launcher used by OCR-Panel.bat.
#
# Running PowerShell with -WindowStyle Hidden means the user never sees a black
# console window next to the panel. The catch: with no console, an unhandled
# error would fail silently, so anything that goes wrong is reported in a
# message box instead.
#
# Set OCR_PANEL_DEBUG=1 to keep a console window and see the errors inline.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$panel = Join-Path $PSScriptRoot "panel.ps1"

try {
    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $panel)
    if ($env:OCR_PANEL_DEBUG -eq "1") {
        & powershell.exe @args
        exit $LASTEXITCODE
    }
    & powershell.exe @args
    if ($LASTEXITCODE -ne 0) { throw "panel.ps1 exited with code $LASTEXITCODE" }
} catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        ("控制面板启动失败：`r`n`r`n" + $_.Exception.Message + "`r`n`r`n" +
         "排查方法：在该文件夹打开 PowerShell，运行`r`n" +
         "  `$env:OCR_PANEL_DEBUG='1'; .\OCR-Panel.bat`r`n" +
         "可以看到详细报错。"),
        "OCR 控制面板",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}
