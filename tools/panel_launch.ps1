# panel_launch.ps1
# -----------------------------------------------------------------------------
# Hidden launcher used by OCR-Panel.bat.
#
# Running PowerShell with -WindowStyle Hidden means the user never sees a black
# console window next to the panel. The catch: with no console, an unhandled
# error would fail silently, so anything that goes wrong is reported in a
# message box instead.
#
# This is also where a FRESH EXTRACT completes its first-run setup: when
# server\config.json does not exist yet, the service config and token are
# generated here, silently, before the panel opens. That keeps the promise
# "extract the portable zip, double-click OCR-Panel.bat, done" true on a
# machine that has nothing installed.
#
# Set OCR_PANEL_DEBUG=1 to keep a console window and see the errors inline.
# -----------------------------------------------------------------------------

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$panel = Join-Path $PSScriptRoot "panel.ps1"
$configPath = Join-Path $root "server\config.json"

function Invoke-FirstRunSetup {
    <#
        Generates server\config.json (with a random token) if it is missing.
        Deliberately does NOT touch the firewall or power settings: those need
        administrator rights, and the panel's "首次配置/修复" button covers them.
        Failures are non-fatal so the panel still opens and can explain.
    #>
    if (Test-Path -LiteralPath $configPath) { return }

    $example = Join-Path $root "server\config.example.json"
    if (-not (Test-Path -LiteralPath $example)) { return }

    try {
        $pyCheck = Join-Path $PSScriptRoot "python_env.ps1"
        if (Test-Path -LiteralPath $pyCheck) {
            . $pyCheck
            $envCheck = Resolve-OcrPython -Root $root
            if (-not $envCheck.Ok) {
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.MessageBox]::Show(
                    ("OCR 服务缺少运行环境，暂时无法启动。`r`n`r`n" + $envCheck.Reason),
                    "OCR 控制面板",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
                return
            }
        }

        # Mirror config.example.json, then fill in a fresh random token and
        # auto-detected LAN address. Same shape setup_new_server.ps1 produces.
        $cfg = Get-Content -LiteralPath $example -Raw -Encoding UTF8 | ConvertFrom-Json
        $bytes = New-Object byte[] 24
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
        $token = -join ($bytes | ForEach-Object { $_.ToString("x2") })
        $cfg | Add-Member -NotePropertyName api_token -NotePropertyValue $token -Force
        if (-not $cfg.work_lan_ip) {
            $cfg | Add-Member -NotePropertyName work_lan_ip -NotePropertyValue "" -Force
        }
        $json = $cfg | ConvertTo-Json -Depth 8
        [IO.File]::WriteAllText($configPath, $json, (New-Object Text.UTF8Encoding($false)))
    } catch {
        # Non-fatal: the panel opens and the user can use "首次配置/修复".
    }
}

Invoke-FirstRunSetup

try {
    $panelArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $panel)
    if ($env:OCR_PANEL_DEBUG -eq "1") {
        & powershell.exe @panelArgs
        exit $LASTEXITCODE
    }
    & powershell.exe @panelArgs
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
