# panel.ps1
# -----------------------------------------------------------------------------
# OCR 控制面板（Windows 图形界面）
#
# 功能：
#   - 查看服务状态（运行中/已停止、版本、端口、局域网地址、安装地址）
#   - 启动 / 停止 / 重启服务
#   - 首次配置 / 修复（调用 Start-OCR.bat）
#   - 更新服务端（调用 tools\update_ocr.ps1）
#   - 复制连接信息（服务器地址 + token + 安装地址，调用 tools\show_info.ps1）
#   - 打开安装地址 / 打开日志文件
#   - 开机自启开关（任务计划，默认关闭）
#
# 关闭面板不会停止服务；如需停止请点“停止服务”。
# 面板以管理员身份运行（OCR-Panel.bat 会自提权），这样才能停止以管理员
# 身份启动的服务进程、创建开机自启任务。
# -----------------------------------------------------------------------------

param(
    [switch]$SelfTest
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $root "server\config.json"
$updateScript = Join-Path $root "tools\update_ocr.ps1"
$infoScript = Join-Path $root "tools\show_info.ps1"
$startScript = Join-Path $root "tools\start_service_bg.ps1"
$startBat = Join-Path $root "launchers\Start-OCR.bat"
$errLog = Join-Path $root "server.err.log"
$taskName = "OCR 服务自启"

# ---------------------------------------------------------- single instance --
# Only one control panel may run at a time. Without this, every double-click
# left another elevated powershell process behind - and those cannot be killed
# from a normal-privilege shell, so they pile up and hold the port. A named
# mutex is the reliable Windows-wide check; held for the life of the process.
if (-not $SelfTest) {
    $script:singleInstanceMutex = New-Object System.Threading.Mutex($false, "Global\OcrControlPanel")
    $script:ownsMutex = $false
    try {
        $script:ownsMutex = $script:singleInstanceMutex.WaitOne(0)
    } catch [System.Threading.AbandonedMutexException] {
        # Previous holder crashed without releasing; we inherit ownership.
        $script:ownsMutex = $true
    }

    if (-not $script:ownsMutex) {
        # Bring the existing window forward instead of silently doing nothing.
        try {
            Add-Type -AssemblyName Microsoft.VisualBasic
            [Microsoft.VisualBasic.Interaction]::AppActivate("OCR 控制面板") | Out-Null
        } catch { }
        try { $script:singleInstanceMutex.Dispose() } catch { }
        $script:singleInstanceMutex = $null
        return
    }
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:port = 1205
$script:lanIp = ""
$script:version = "?"
$script:token = ""
$script:serverUrl = ""
$script:userscriptUrl = ""
$script:updateBusy = $false
$script:updateRunner = $null
$script:updateTimer = $null
$script:updateProc = $null
$script:updateTimerRun = $null
$script:updateBarTimer = $null

function Get-PrimaryLanIPv4 {
    # Mirrors tools\show_info.ps1 so the panel and Show-OCR-Info.bat never
    # disagree about the address handed to LAN devices.
    try {
        $addresses = Get-NetIPAddress -AddressFamily IPv4 |
            Where-Object {
                $_.IPAddress -notlike "127.*" `
                    -and $_.IPAddress -notlike "169.254.*" `
                    -and $_.PrefixOrigin -ne "WellKnown" `
                    -and $_.AddressState -eq "Preferred"
            }
    } catch {
        return "127.0.0.1"
    }
    $isPrivate = {
        param($ip)
        $ip -like "10.*" -or $ip -like "192.168.*" -or $ip -match "^172\.(1[6-9]|2[0-9]|3[0-1])\."
    }
    $virtualAdapterPattern = '(VPN|Tunnel|Tap|TUN|ZeroTier|WireGuard|Hamachi|vgate|vEthernet|Loopback|Pseudo|Hyper-V|Tailscale)'
    $privateCandidates = $addresses | Where-Object { & $isPrivate $_.IPAddress }

    $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Sort-Object RouteMetric, InterfaceMetric, InterfaceIndex | Select-Object -First 1
    if ($defaultRoute) {
        $onDefault = $privateCandidates | Where-Object { $_.InterfaceIndex -eq $defaultRoute.InterfaceIndex } | Select-Object -First 1
        if ($onDefault) { return $onDefault.IPAddress }
    }
    $physical = $privateCandidates | Where-Object { $_.InterfaceAlias -notmatch $virtualAdapterPattern } |
        Sort-Object InterfaceMetric, InterfaceIndex | Select-Object -First 1
    if ($physical) { return $physical.IPAddress }
    $anyPrivate = $privateCandidates | Sort-Object InterfaceMetric, InterfaceIndex | Select-Object -First 1
    if ($anyPrivate) { return $anyPrivate.IPAddress }
    $fallback = $addresses | Select-Object -First 1
    if ($fallback) { return $fallback.IPAddress }
    return "127.0.0.1"
}

function Test-LocalIPv4 {
    <#
        True when the given address is actually bound to one of this machine's
        adapters. A stale work_lan_ip (the box got a new DHCP lease, or the
        config was copied from another machine) made the panel advertise an
        address nothing could reach, so it is verified before being trusted.

        Routable addresses only. Loopback, link-local and 0.0.0.0 are bound
        here too, but sending them to another device means "your own loopback"
        or nothing at all, so they must fall back to probing.
    #>
    param([string]$Address)
    if (-not $Address) { return $false }
    $value = $Address.Trim()
    $parsed = $null
    if (-not [System.Net.IPAddress]::TryParse($value, [ref]$parsed)) { return $false }
    if ([System.Net.IPAddress]::IsLoopback($parsed)) { return $false }
    # 0.0.0.0 / :: are "unspecified": bindable, never reachable from elsewhere.
    if ($parsed.Equals([System.Net.IPAddress]::Any)) { return $false }
    if ($parsed.IsIPv6LinkLocal) { return $false }
    if ($value -like "169.254.*") { return $false }   # IPv4 APIPA
    try {
        $hit = Get-NetIPAddress -IPAddress $value -AddressFamily IPv4 -ErrorAction Stop |
            Select-Object -First 1
        return [bool]$hit
    } catch {
        return $false
    }
}

function Get-EffectiveLanIP {
    <#
        Resolves the address handed to LAN devices: the configured work_lan_ip
        when it is genuinely present on this host, otherwise the probed one.
    #>
    param($Config)
    $configured = ""
    if ($Config) { $configured = [string]$Config.work_lan_ip }
    $configured = $configured.Trim()
    if ($configured -and (Test-LocalIPv4 $configured)) { return $configured }
    return (Get-PrimaryLanIPv4)
}

function Read-Config {
    if (Test-Path -LiteralPath $configPath) {
        try {
            return Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        } catch { }
    }
    return $null
}

# Get-NetTCPConnection takes ~950 ms per call on PowerShell 5.1 (it walks the
# whole TCP table through WMI). The panel polls this every 3 s and the
# start/stop/restart paths poll it every 250 ms, so it dominated every action.
# GetExtendedTcpTable answers in microseconds; fall back to the cmdlet only if
# the P/Invoke is unavailable.
$script:tcpHelper = $null
try {
    Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Net;
using System.Runtime.InteropServices;

public static class OcrTcp {
    [DllImport("iphlpapi.dll", SetLastError = true)]
    static extern uint GetExtendedTcpTable(IntPtr buf, ref int size, bool order, int af, int cls, uint reserved);

    const int AF_INET = 2;
    const int TCP_TABLE_OWNER_PID_LISTENER = 3;

    [StructLayout(LayoutKind.Sequential)]
    struct MIB_TCPROW_OWNER_PID {
        public uint state;
        public uint localAddr;
        public uint localPort;
        public uint remoteAddr;
        public uint remotePort;
        public uint owningPid;
    }

    // Returns the owning PID of a listening socket on the given port, or 0.
    public static int ListenerPid(int port) {
        int size = 0;
        uint rc = GetExtendedTcpTable(IntPtr.Zero, ref size, false, AF_INET, TCP_TABLE_OWNER_PID_LISTENER, 0);
        if (rc != 0 && rc != 122) { return 0; }   // 122 = ERROR_INSUFFICIENT_BUFFER
        IntPtr buf = Marshal.AllocHGlobal(size);
        try {
            rc = GetExtendedTcpTable(buf, ref size, false, AF_INET, TCP_TABLE_OWNER_PID_LISTENER, 0);
            if (rc != 0) { return 0; }
            int rows = Marshal.ReadInt32(buf);
            IntPtr cur = (IntPtr)((long)buf + 4);
            int rowSize = Marshal.SizeOf(typeof(MIB_TCPROW_OWNER_PID));
            for (int i = 0; i < rows; i++) {
                var row = (MIB_TCPROW_OWNER_PID)Marshal.PtrToStructure(cur, typeof(MIB_TCPROW_OWNER_PID));
                // localPort is big-endian in the low 16 bits.
                int p = (int)((row.localPort & 0xFF) << 8 | (row.localPort & 0xFF00) >> 8);
                if (p == port) { return (int)row.owningPid; }
                cur = (IntPtr)((long)cur + rowSize);
            }
            return 0;
        } finally {
            Marshal.FreeHGlobal(buf);
        }
    }
}
"@ -ErrorAction Stop
    $script:tcpHelper = $true
} catch {
    $script:tcpHelper = $false
}

function Get-ListenerPid([int]$p) {
    if ($script:tcpHelper) {
        try {
            $owner = [OcrTcp]::ListenerPid($p)
            if ($owner -gt 0) { return [int]$owner }
            return 0
        } catch { }
    }
    try {
        $c = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($c) { return [int]$c.OwningProcess }
    } catch { }
    return 0
}

function Test-Health([int]$p) {
    # A listening port alone is not proof that OCR is usable (the process may
    # still be loading models). Ask /health with a short timeout.
    try {
        $r = Invoke-WebRequest "http://127.0.0.1:$p/health" -UseBasicParsing -TimeoutSec 2
        return ($r.StatusCode -eq 200)
    } catch {
        return $false
    }
}

function Get-ServiceState {
    # Returns one of: Running | Starting | Stopped
    $pid0 = Get-ListenerPid $script:port
    if ($pid0 -le 0) { return "Stopped" }
    if (Test-Health $script:port) { return "Running" }
    return "Starting"
}

function Get-AppVersion {
    $appPy = Join-Path $root "server\app.py"
    if (Test-Path -LiteralPath $appPy) {
        try {
            $m = Select-String -LiteralPath $appPy -Pattern '__version__\s*=\s*"([^"]+)"' |
                Select-Object -First 1
            if ($m) { return $m.Matches[0].Groups[1].Value }
        } catch { }
    }
    return "?"
}

function Set-ServiceStatus {
    $cfg = Read-Config
    $script:token = ""
    if ($cfg) {
        try { $script:port = [int]$cfg.port } catch { }
        if ($script:port -le 0) { $script:port = 1205 }
        $tok = [string]$cfg.api_token
        if ($tok -and $tok -ne "change-me-to-a-random-internal-token") { $script:token = $tok.Trim() }
        # work_lan_ip is only trusted when the address is really on this host;
        # a stale value used to make every displayed URL unreachable.
        $script:lanIp = Get-EffectiveLanIP $cfg
    }
    if (-not $script:lanIp) { $script:lanIp = Get-PrimaryLanIPv4 }
    $script:version = Get-AppVersion
    $script:serverUrl = "http://$($script:lanIp):$($script:port)"
    $script:userscriptUrl = "$($script:serverUrl)/userscript.user.js"
}

function Update-PanelIcon([string]$state) {
    # The window/taskbar icon is recoloured so the state is readable at a
    # glance without opening the window: green running, amber starting, red stopped.
    if (-not $form) { return }
    $color = switch ($state) {
        "Running" { [System.Drawing.Color]::FromArgb(22, 163, 74) }
        "Starting" { [System.Drawing.Color]::FromArgb(217, 119, 6) }
        default { [System.Drawing.Color]::FromArgb(220, 38, 38) }
    }
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($brush, 1, 1, 30, 30)
    $brush.Dispose()
    $font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9, [System.Drawing.FontStyle]::Bold)
    $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $g.DrawString("OCR", $font, $white, (New-Object System.Drawing.RectangleF 0, 0, 32, 32), $fmt)
    $white.Dispose()
    $font.Dispose()
    $fmt.Dispose()
    $g.Dispose()
    $ico = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    $form.Icon = $ico
    $bmp.Dispose()
}

function Get-ShareMessage {
    # Same text Show-OCR-Info.bat puts on the clipboard.
    $tokenLine = $(if ($script:token) { $script:token } else { "（未生成，请先点「首次配置/修复」）" })
    return @"
【验证码识别 - 局域网连接信息】
服务器地址：$($script:serverUrl)
API token：$tokenLine
安装地址：$($script:userscriptUrl)

推荐把“安装地址”发给局域网设备：
1. 浏览器安装 Tampermonkey
2. 打开上面的安装地址，点安装
3. 不需要手动填服务器地址和 token

需要手动配置时：
油猴图标菜单 →「OCR 服务器设置…」→ 填上面的服务器地址和 token

只发给局域网内的设备，不要发到公网。
"@
}

function Invoke-Schtasks([string[]]$Arguments) {
    # schtasks writes errors to stderr; under $ErrorActionPreference = "Stop"
    # that would abort the panel, so run it with a relaxed preference and use
    # the exit code instead.
    $prev = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $out = & schtasks.exe @Arguments 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prev
    }
    return @{ Code = $code; Output = ($out | Out-String) }
}

function Test-AutoStartTask {
    $r = Invoke-Schtasks @('/Query', '/TN', $taskName)
    return ($r.Code -eq 0)
}

function Enable-AutoStart {
    $tr = "powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$startScript`""
    $r = Invoke-Schtasks @('/Create', '/TN', $taskName, '/SC', 'ONLOGON', '/TR', $tr, '/F')
    if ($r.Code -ne 0) { Write-Host ("[autostart] " + $r.Output.Trim()) }
    return ($r.Code -eq 0)
}

function Disable-AutoStart {
    $r = Invoke-Schtasks @('/Delete', '/TN', $taskName, '/F')
    return ($r.Code -eq 0)
}

function Write-Log([string]$text) {
    if ($script:logBox) {
        $script:logBox.AppendText($text + "`r`n")
        $script:logBox.SelectionStart = $script:logBox.TextLength
        $script:logBox.ScrollToCaret()
    }
}

function Refresh-LogTail {
    if (-not $script:logBox) { return }
    if (-not (Test-Path -LiteralPath $errLog)) {
        $script:logBox.Text = "(还没有日志文件)"
        return
    }
    try {
        $lines = Get-Content -LiteralPath $errLog -Tail 120 -ErrorAction SilentlyContinue
        $script:logBox.Text = ($lines -join "`r`n")
        $script:logBox.SelectionStart = $script:logBox.TextLength
        $script:logBox.ScrollToCaret()
    } catch { }
}

function Show-Msg([string]$title, [string]$text, [string]$icon = "Information") {
    [System.Windows.Forms.MessageBox]::Show(
        $text, $title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::$icon) | Out-Null
}

function Copy-Text([string]$text, [string]$label) {
    if ([string]::IsNullOrWhiteSpace($text)) {
        Show-Msg "OCR 控制面板" "$label 还没有内容，请先点「首次配置/修复」。" "Warning"
        return
    }
    try {
        Set-Clipboard -Value $text
    } catch {
        # Set-Clipboard is unavailable in some stripped-down PowerShell hosts;
        # fall back to the WinForms clipboard.
        try {
            [System.Windows.Forms.Clipboard]::SetText($text)
        } catch {
            Show-Msg "OCR 控制面板" ("复制失败：" + $_.Exception.Message) "Error"
            return
        }
    }
    Write-Log "$label 已复制到剪贴板"
    if ($lblFlash) {
        $lblFlash.Text = "$label 已复制"
        $lblFlash.ForeColor = [System.Drawing.Color]::ForestGreen
        $script:flashTimer.Stop()
        $script:flashTimer.Start()
    }
}

if ($SelfTest) {
    Set-ServiceStatus
    $pid0 = Get-ListenerPid $script:port
    $state = Get-ServiceState
    $pyCandidates = @(
        (Join-Path $root "python\python.exe"),
        (Join-Path $root ".venv\Scripts\python.exe")
    )
    $pyFound = ($pyCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1)
    Write-Host ("root=" + $root)
    Write-Host ("port=" + $script:port)
    Write-Host ("lan_ip=" + $script:lanIp)
    Write-Host ("version=" + $script:version)
    Write-Host ("listener_pid=" + $pid0)
    Write-Host ("service_state=" + $state)
    Write-Host ("health_ok=" + (Test-Health $script:port))
    Write-Host ("autostart_task=" + (Test-AutoStartTask))
    Write-Host ("python=" + ($(if ($pyFound) { $pyFound } else { "NOT FOUND" })))
    Write-Host ("config_exists=" + (Test-Path -LiteralPath $configPath))
    Write-Host ("update_script=" + (Test-Path -LiteralPath $updateScript))
    Write-Host ("info_script=" + (Test-Path -LiteralPath $infoScript))
    Write-Host ("start_script=" + (Test-Path -LiteralPath $startScript))
    Write-Host ("token_present=" + [bool]$script:token)
    Write-Host ("token_len=" + $script:token.Length)
    Write-Host ("server_url=" + $script:serverUrl)
    Write-Host ("userscript_url=" + $script:userscriptUrl)
    exit 0
}

# ----------------------------------------------------------------- UI build --
. (Join-Path $PSScriptRoot "ui_kit.ps1")

$ui = $script:ui

$form = New-Object System.Windows.Forms.Form
$form.Text = "OCR 控制面板"
# The design needs 860x894, but 1366x768 laptops (and 125%/150% scaling) have
# less working area than that, which pushed the bottom buttons off-screen.
# Cap the height to the available desktop and let the form scroll instead.
$designWidth = 860
$designHeight = 894
$workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$maxHeight = [Math]::Max(480, $workArea.Height - 60)
$maxWidth = [Math]::Max(720, $workArea.Width - 40)
$formWidth = [Math]::Min($designWidth, $maxWidth)
$formHeight = [Math]::Min($designHeight, $maxHeight)
$form.ClientSize = New-Object System.Drawing.Size($formWidth, $formHeight)
$form.AutoScroll = $true
$form.AutoScrollMinSize = New-Object System.Drawing.Size($designWidth, $designHeight)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$form.MaximizeBox = $false
$form.BackColor = $ui.Bg
$form.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$form.Padding = New-Object System.Windows.Forms.Padding(0)

$script:stateColors = @{
    Running  = $ui.Green
    Starting = $ui.Amber
    Stopped  = $ui.Red
}
$script:stateTexts = @{
    Running  = "运行中"
    Starting = "启动中"
    Stopped  = "已停止"
}

# ---------- header: dark band with the app name and the live state pill ------
$header = New-Object System.Windows.Forms.Panel
$header.Location = New-Object System.Drawing.Point(0, 0)
$header.Size = New-Object System.Drawing.Size(860, 96)
$header.BackColor = $ui.HeaderBg
$header.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    # Soft accent orb in the corner for a bit of depth.
    $glow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(28, 96, 165, 250))
    $g.FillEllipse($glow, ($s.Width - 150), -70, 220, 220)
    $glow.Dispose()
    $title = New-Object System.Drawing.Font("Microsoft YaHei UI", 16, [System.Drawing.FontStyle]::Bold)
    $tb = New-Object System.Drawing.SolidBrush $script:ui.HeaderText
    $g.DrawString("验证码识别服务", $title, $tb, 24, 18)
    $tb.Dispose()
    $title.Dispose()
    $sub = New-Object System.Drawing.Font("Microsoft YaHei UI", 8.5)
    $sb = New-Object System.Drawing.SolidBrush $script:ui.HeaderSub
    $g.DrawString("局域网自托管 OCR · 控制面板", $sub, $sb, 26, 54)
    $sb.Dispose()
    $sub.Dispose()
})
$form.Controls.Add($header)

# State pill: rounded capsule, coloured by state, drawn on the header.
$pill = New-Object System.Windows.Forms.Panel
$pill.Location = New-Object System.Drawing.Point(640, 26)
$pill.Size = New-Object System.Drawing.Size(196, 44)
$pill.BackColor = $ui.HeaderBg
$pill.Tag = @{ State = "Stopped"; Dot = $null }
$pill.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $color = $script:stateColors[$s.Tag.State]
    if (-not $color) { $color = [System.Drawing.Color]::Gray }

    $path = New-RoundedPath $s.Width $s.Height 21
    $bgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(45, $color.R, $color.G, $color.B))
    $g.FillPath($bgBrush, $path)
    $bgBrush.Dispose()
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, $color.R, $color.G, $color.B)), 1.5
    $g.DrawPath($pen, $path)
    $pen.Dispose()
    $path.Dispose()

    # Glowing dot
    $halo = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, $color.R, $color.G, $color.B))
    $g.FillEllipse($halo, 14, 12, 20, 20)
    $halo.Dispose()
    $dotBrush = New-Object System.Drawing.SolidBrush $color
    $g.FillEllipse($dotBrush, 19, 17, 10, 10)
    $dotBrush.Dispose()

    $font = New-Object System.Drawing.Font("Microsoft YaHei UI", 12, [System.Drawing.FontStyle]::Bold)
    $txt = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $g.DrawString($script:stateTexts[$s.Tag.State], $font, $txt, 44, 8)
    $txt.Dispose()
    $font.Dispose()
})
$header.Controls.Add($pill)

$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "正在检测服务状态 ..."
$lblStatus.AutoSize = $false
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$lblStatus.Size = New-Object System.Drawing.Size(580, 22)
$lblStatus.Location = New-Object System.Drawing.Point(26, 72)
$lblStatus.BackColor = [System.Drawing.Color]::Transparent
$lblStatus.ForeColor = $ui.HeaderSub
$header.Controls.Add($lblStatus)

# --------------------------------------------------------------- cards row ---
$cardState = New-Card -Width 420 -Height 118
$cardState.Location = New-Object System.Drawing.Point(20, 112)
$form.Controls.Add($cardState)

$lblStateTitle = New-Label -Text "服务状态" -Bold $true -Size 10
$lblStateTitle.Location = New-Object System.Drawing.Point(18, 12)
$cardState.Controls.Add($lblStateTitle)

$lblStateSub = New-Label -Text "正在检测…" -Color $ui.TextMuted
$lblStateSub.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9.5)
$lblStateSub.Location = New-Object System.Drawing.Point(20, 40)
$cardState.Controls.Add($lblStateSub)

$lblStateDetail = New-Label -Text "" -Color $ui.TextMuted -Size 8.5
$lblStateDetail.Location = New-Object System.Drawing.Point(20, 66)
$cardState.Controls.Add($lblStateDetail)

$lblInfo = New-Label -Text "" -Color $ui.TextMuted -Size 8.5
$lblInfo.Location = New-Object System.Drawing.Point(20, 88)
$cardState.Controls.Add($lblInfo)

$cardInfo = New-Card -Width 396 -Height 118
$cardInfo.Location = New-Object System.Drawing.Point(452, 112)
$form.Controls.Add($cardInfo)

$lblInfoTitle = New-Label -Text "快捷操作" -Bold $true -Size 10
$lblInfoTitle.Location = New-Object System.Drawing.Point(18, 12)
$cardInfo.Controls.Add($lblInfoTitle)

$btnOpenSite = New-StyleButton -Text "打开安装地址" -Width 172 -Height 34 -Variant "accent"
$btnOpenSite.Location = New-Object System.Drawing.Point(18, 42)
$btnOpenSite.Add_Click({
    Start-Process $script:userscriptUrl
})
$cardInfo.Controls.Add($btnOpenSite)

$btnOpenLog = New-StyleButton -Text "查看日志" -Width 92 -Height 34
$btnOpenLog.Location = New-Object System.Drawing.Point(198, 42)
$btnOpenLog.Add_Click({
    if (Test-Path -LiteralPath $errLog) {
        Start-Process notepad.exe -ArgumentList $errLog
    } else {
        Show-Msg "OCR 控制面板" "还没有日志文件（server.err.log）。" "Warning"
    }
})
$cardInfo.Controls.Add($btnOpenLog)

$btnRefresh = New-StyleButton -Text "刷新" -Width 76 -Height 34
$btnRefresh.Location = New-Object System.Drawing.Point(298, 42)
$btnRefresh.Add_Click({
    Update-Status
    Refresh-LogTail
})
$cardInfo.Controls.Add($btnRefresh)

$lblHint = New-Label -Text "关闭面板不会停止服务；停止请点「停止服务」" -Color $ui.TextMuted -Size 8
$lblHint.Location = New-Object System.Drawing.Point(20, 88)
$cardInfo.Controls.Add($lblHint)

# ---------------------------------------------------------- connection card --
$cardConn = New-Card -Width 828 -Height 176 -Title "连接信息"
$cardConn.Location = New-Object System.Drawing.Point(20, 242)
$form.Controls.Add($cardConn)

$lblConnSub = New-Label -Text "直接复制给局域网设备；token 等同于访问密码，不要发到公网" -Color $ui.TextMuted -Size 8.5
$lblConnSub.Location = New-Object System.Drawing.Point(18, 38)
$cardConn.Controls.Add($lblConnSub)

function New-InfoRow {
    param(
        [string]$Caption,
        [int]$Y,
        [scriptblock]$OnCopy
    )
    $lbl = New-Label -Text $Caption -Color $ui.TextMuted -Size 9
    $lbl.Location = New-Object System.Drawing.Point(18, ($Y + 7))
    $cardConn.Controls.Add($lbl)

    $box = New-StyledTextbox -Width 520
    $well = New-InputWell -Box $box -Width 540 -Height 32
    $well.Location = New-Object System.Drawing.Point(104, $Y)
    $cardConn.Controls.Add($well)

    $btn = New-StyleButton -Text "复制" -Width 66 -Height 32
    $btn.Location = New-Object System.Drawing.Point(654, $Y)
    $btn.Add_Click($OnCopy)
    $cardConn.Controls.Add($btn)

    return $box
}

$txtInstall = New-InfoRow -Caption "安装地址" -Y 64 {
    Copy-Text $script:userscriptUrl "安装地址"
}
$txtServer = New-InfoRow -Caption "服务器地址" -Y 104 {
    Copy-Text $script:serverUrl "服务器地址"
}
$txtToken = New-InfoRow -Caption "API token" -Y 144 {
    if (-not $script:token) {
        Show-Msg "OCR 控制面板" "还没有 token，请先点「首次配置/修复」。" "Warning"
        return
    }
    Copy-Text $script:token "API token"
}

$btnCopyAll = New-StyleButton -Text "一键复制全部（含说明）" -Width 200 -Height 32
$btnCopyAll.Location = New-Object System.Drawing.Point(610, 186)
$btnCopyAll.Add_Click({
    Copy-Text (Get-ShareMessage) "完整连接信息"
})
$cardConn.Controls.Add($btnCopyAll)
$cardConn.Height = 236

# ------------------------------------------------------------- service card --
# ------------------------------------------------------ async service start --
# Starting the service takes 10-18 s (probe the interpreter, boot uvicorn, load
# the ONNX model). Running that on the UI thread froze the whole window: the
# user could not move or click it and Windows painted "未响应". Everything below
# runs the work on a background runspace and lets a WinForms timer pick the
# result up, so the panel stays responsive and shows progress instead.
$script:svcBusy = $false
$script:svcPowerShell = $null

function New-ServiceRunner {
    <#
        Builds a closed runspace that can execute start_service_bg.ps1 without
        touching the UI thread. Returns a hashtable carrying the runspace, the
        async handle and the output pipe.
    #>
    $ps = [powershell]::Create()
    [void]$ps.AddCommand($startScript)
    $script:svcPowerShell = $ps
    return @{
        PowerShell = $ps
        Handle     = $ps.BeginInvoke()
    }
}

function Set-ServiceBusy([bool]$busy, [string]$label) {
    $script:svcBusy = $busy
    $form.Tag.Start.Enabled = (-not $busy)
    $form.Tag.Restart.Enabled = (-not $busy)
    $form.Tag.Stop.Enabled = (-not $busy)
    $form.Tag.Start.Text = $(if ($busy) { $label } else { "启动服务" })
    $form.Tag.Restart.Text = $(if ($busy) { "处理中…" } else { "重启服务" })
}

function Complete-ServiceStart($runner) {
    <#
        Called from the UI timer once the background runspace finished. Collects
        output, reports failures in a dialog and refreshes the status card.
    #>
    $ps = $runner.PowerShell
    $output = @()
    try {
        $output = @($ps.EndInvoke($runner.Handle) | ForEach-Object { [string]$_ })
        foreach ($e in $ps.Streams.Error) { $output += [string]$e }
    } catch {
        $output = @($_.Exception.Message)
    } finally {
        $ps.Dispose()
        $script:svcPowerShell = $null
    }

    foreach ($line in $output) { if ($line) { Write-Log $line } }

    $text = ($output | Where-Object { $_ }) -join "`r`n"
    # start_service_bg.ps1 spells out the failure in plain English; the exit
    # code does not survive AddCommand, so the text is the source of truth.
    if ($text -match "(?s)Reason:\s*(.+)$") {
        Show-Msg "服务无法启动：缺少 Python 依赖" ($matches[1].Trim()) "Error"
    } elseif ($text -match "\[ERROR\]") {
        Show-Msg "服务启动失败" ("启动脚本返回错误。详情见面板日志和 server.err.log。" + "`r`n`r`n" + $text) "Error"
    }

    Set-ServiceBusy $false ""
    Update-Status
}

function Start-OcrServiceFromPanel {
    <#
        Kicks off start_service_bg.ps1 in the background and returns at once.
        The caller's button shows "启动中…" until the polling timer reports back.

        -AfterStop is used by the restart path: the caller has already stopped
        the old process and set $script:svcBusy, so the guard below must not
        reject the call and the busy label reads "重启中…" instead.
    #>
    param([switch]$AfterStop)

    if ($script:svcBusy -and -not $AfterStop) { return }
    Set-ServiceBusy $true $(if ($AfterStop) { "重启中…" } else { "启动中…" })
    Write-Log $(if ($AfterStop) { "重新启动服务 ..." } else { "启动服务 ..." })
    try {
        $script:svcRunner = New-ServiceRunner
    } catch {
        Set-ServiceBusy $false ""
        Write-Log ("启动失败：" + $_.Exception.Message)
        Show-Msg "服务启动失败" $_.Exception.Message "Error"
        return
    }
    $script:svcTimer = New-Object System.Windows.Forms.Timer
    $script:svcTimer.Interval = 400
    $script:svcRunnerRef = $script:svcRunner
    $script:svcTimer.Add_Tick({
        try {
            $r = $script:svcRunnerRef
            if (-not $r) { $script:svcTimer.Stop(); return }
            if ($r.Handle.IsCompleted) {
                $script:svcTimer.Stop()
                $script:svcTimer.Dispose()
                $script:svcTimer = $null
                Complete-ServiceStart $r
                $script:svcRunnerRef = $null
            } else {
                # Keep the state chip honest while uvicorn boots.
                try { Update-Status } catch { }
            }
        } catch {
            $script:svcTimer.Stop()
            Set-ServiceBusy $false ""
            Write-Log ("启动轮询失败：" + $_.Exception.Message)
        }
    })
    $script:svcTimer.Start()
}

function Stop-OcrServiceFromPanel {
    <#
        Stop-Process returns immediately, but the killed process can keep the
        listening socket for several seconds while Windows tears down its
        memory (uvicorn + onnxruntime hold ~300 MB). The button is marked busy
        and a timer polls the port until it is really gone, so the panel never
        reports "stopped" while the old process is still answering.
    #>
    if ($script:svcBusy) { return }
    $pid0 = Get-ListenerPid $script:port
    if ($pid0 -le 0) {
        Write-Log "服务本来就没在运行"
        Update-Status
        return
    }

    Set-ServiceBusy $true "停止中…"
    try {
        Stop-Process -Id $pid0 -Force -ErrorAction SilentlyContinue
        Write-Log "正在停止服务 (PID $pid0) ..."
    } catch {
        Write-Log ("停止失败：" + $_.Exception.Message)
    }

    $script:stopTimer = New-Object System.Windows.Forms.Timer
    $script:stopTimer.Interval = 250
    $script:stopTimer.Add_Tick({
        $script:stopTimer.Stop()
        $p = Get-ListenerPid $script:port
        if ($p -le 0) {
            $script:stopTimer.Dispose()
            $script:stopTimer = $null
            Write-Log "服务已停止"
            Set-ServiceBusy $false ""
            Update-Status
            return
        }
        # Give up after ~20 s: the port may be held by a process this user
        # cannot kill, in which case saying "still running" is the honest answer.
        $script:stopTicks = [int]$script:stopTicks + 1
        if ($script:stopTicks -ge 80) {
            $script:stopTimer.Stop()
            $script:stopTimer.Dispose()
            $script:stopTimer = $null
            Write-Log ("停止超时：端口 $($script:port) 仍被 PID $p 占用（可能需要管理员权限）")
            Set-ServiceBusy $false ""
            Update-Status
            return
        }
        $script:stopTimer.Start()
    })
    $script:stopTicks = 0
    $script:stopTimer.Start()
}


$cardSvc = New-Card -Width 828 -Height 92 -Title "服务控制"
$cardSvc.Location = New-Object System.Drawing.Point(20, 494)
$form.Controls.Add($cardSvc)

$btnStart = New-StyleButton -Text "启动服务" -Width 130 -Height 40 -Variant "accent"
    $btnStart.Location = New-Object System.Drawing.Point(18, 40)
    $btnStart.Add_Click({
        Start-OcrServiceFromPanel
    })
$cardSvc.Controls.Add($btnStart)

$btnStop = New-StyleButton -Text "停止服务" -Width 130 -Height 40 -Variant "danger"
$btnStop.Location = New-Object System.Drawing.Point(160, 40)
$btnStop.Add_Click({
    Stop-OcrServiceFromPanel
})
$cardSvc.Controls.Add($btnStop)

$btnRestart = New-StyleButton -Text "重启服务" -Width 130 -Height 40
    $btnRestart.Location = New-Object System.Drawing.Point(302, 40)
    $btnRestart.Add_Click({
        if ($script:svcBusy) { return }
        $pid0 = Get-ListenerPid $script:port
        if ($pid0 -le 0) {
            # Nothing running: a restart is just a start.
            Start-OcrServiceFromPanel
            return
        }

        Set-ServiceBusy $true "重启中…"
        try {
            Stop-Process -Id $pid0 -Force -ErrorAction SilentlyContinue
            Write-Log "正在重启服务 (旧 PID $pid0) ..."
        } catch {
            Write-Log ("停止失败：" + $_.Exception.Message)
        }

        # Wait for the port to actually be released before starting again.
        # Starting too early makes the new uvicorn fail with "address in use".
        $script:restartTicks = 0
        $script:restartTimer = New-Object System.Windows.Forms.Timer
        $script:restartTimer.Interval = 250
        $script:restartTimer.Add_Tick({
            $p = Get-ListenerPid $script:port
            if ($p -le 0) {
                $script:restartTimer.Stop()
                $script:restartTimer.Dispose()
                $script:restartTimer = $null
                Start-OcrServiceFromPanel -AfterStop
                return
            }
            $script:restartTicks = [int]$script:restartTicks + 1
            if ($script:restartTicks -ge 80) {
                $script:restartTimer.Stop()
                $script:restartTimer.Dispose()
                $script:restartTimer = $null
                Write-Log ("重启失败：端口 $($script:port) 仍被 PID $p 占用（可能需要管理员权限）")
                Set-ServiceBusy $false ""
                Update-Status
            }
        })
        $script:restartTimer.Start()
    })
$cardSvc.Controls.Add($btnRestart)

$btnSetup = New-StyleButton -Text "首次配置/修复" -Width 140 -Height 40
$btnSetup.Location = New-Object System.Drawing.Point(444, 40)
$btnSetup.Add_Click({
    Write-Log "打开 Start-OCR.bat（完整配置，会弹 UAC）..."
    Start-Process -FilePath $startBat -WorkingDirectory $root
})
$cardSvc.Controls.Add($btnSetup)

$btnUpdate = New-StyleButton -Text "检查更新" -Width 130 -Height 40
$btnUpdate.Location = New-Object System.Drawing.Point(596, 40)
$updateScriptRef = $updateScript
$startBatRef = $startBat
$rootRef = $root
$cardSvcRef = $cardSvc

# --- update progress: marquee bar + one-line status under the buttons -------
$updateBar = New-Object System.Windows.Forms.ProgressBar
$updateBar.Location = New-Object System.Drawing.Point(20, 114)
$updateBar.Size = New-Object System.Drawing.Size(200, 8)
$updateBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
$updateBar.MarqueeAnimationSpeed = 30
$updateBar.Value = 0
$updateBar.Visible = $false
$cardSvc.Controls.Add($updateBar)

$lblUpdateState = New-Label -Text "" -Color $ui.TextMuted -Size 8.5
$lblUpdateState.Location = New-Object System.Drawing.Point(232, 109)
$lblUpdateState.AutoSize = $false
$lblUpdateState.Size = New-Object System.Drawing.Size(576, 18)
$cardSvc.Controls.Add($lblUpdateState)

function Set-UpdateProgress {
    param([int]$Percent)
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    # NOTE: functions have their own scope; these controls are script-level.
    if ($script:updateBar.Style -ne [System.Windows.Forms.ProgressBarStyle]::Continuous) {
        $script:updateBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
    }
    $script:updateBar.Visible = $true
    $script:updateBar.Value = $Percent
}

function Set-UpdateUi {
    param(
        [string]$Text,
        [System.Drawing.Color]$Color,
        [bool]$Busy,
        [switch]$Done
    )
    if ($null -ne $Text) { $script:lblUpdateState.Text = $Text }
    $script:lblUpdateState.ForeColor = $(if ($Color) { $Color } else { $script:ui.TextMuted })
    $script:updateBar.Visible = $Busy
    $script:btnUpdate.Enabled = -not $Busy
    if ($Busy) {
        $script:updateBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    } elseif ($Done) {
        $script:updateBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
        $script:updateBar.Value = 100
        $script:updateBar.Visible = $true
    } else {
        $script:updateBar.Visible = $false
        $script:updateBar.Value = 0
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-OnlineVersion {
    # Returns the newest version published on GitHub main, or "" when offline.
    # Both the server (__version__) and the userscript (@version) are checked:
    # a release may bump either one, and GreasyFork only cares about @version.
    # NOTE: do not name the loop variable $args - it is an automatic variable
    # and the assignment is silently dropped, which made every request fail.
    $sources = @(
        @{ Url = "https://raw.githubusercontent.com/Piggya/OCR_captcha/main/server/app.py";
           Pattern = '__version__\s*=\s*"([^"]+)"' },
        @{ Url = "https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js";
           Pattern = '@version\s+([0-9][0-9.]*)' }
    )
    $attempts = @(
        @{},                                        # direct (works on most LANs)
        @{ Proxy = "http://127.0.0.1:7890" },       # common local proxy
        @{ Proxy = "http://127.0.0.1:1080" }
    )
    $newest = ""
    $okAny = $false
    foreach ($src in $sources) {
        $found = ""
        foreach ($attempt in $attempts) {
            $tmp = Join-Path $env:TEMP ("ocr-ver-" + [guid]::NewGuid().ToString("N") + ".txt")
            try {
                Invoke-WebRequest -Uri $src.Url -OutFile $tmp -UseBasicParsing -TimeoutSec 20 @attempt | Out-Null
                $m = Select-String -LiteralPath $tmp -Pattern $src.Pattern | Select-Object -First 1
                if ($m) { $found = $m.Matches[0].Groups[1].Value; $okAny = $true }
                break
            } catch { }
            finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
        }
        if ($found) {
            if (-not $newest) { $newest = $found }
            else {
                try { if (([version]$found) -gt ([version]$newest)) { $newest = $found } }
                catch { }
            }
        }
    }
    if (-not $okAny) { return "" }
    return $newest
}

$btnUpdate.Add_Click({
    if ($script:updateBusy) { return }
    $script:updateBusy = $true
    $localVer = [string]$script:version
    Set-UpdateUi -Text "正在连接 GitHub 检查最新版本…" -Busy $true
    Write-Log "检查更新：当前版本 $localVer"

    # The version probe hits GitHub over the network and can block for tens of
    # seconds when the network is down. Running it on the UI thread froze the
    # whole window (same trap that start_service_bg.ps1 had), so it goes to a
    # background runspace and a timer picks the answer up.
    #
    # A fresh runspace has none of this script's functions in scope, so
    # AddCommand("Get-OnlineVersion") fails there with "not recognized".
    # Send the definition plus the call instead.
    $runner = $null
    try {
        $ps = [powershell]::Create()
        $scriptText = "function Get-OnlineVersion {`n" +
            (Get-Command Get-OnlineVersion -CommandType Function).Definition +
            "`n}`nGet-OnlineVersion"
        [void]$ps.AddScript($scriptText)
        $runner = @{ PowerShell = $ps; Handle = $ps.BeginInvoke() }
    } catch {
        $script:updateBusy = $false
        Set-UpdateUi -Text "检查失败：无法启动检查任务" -Color $script:ui.Red
        Write-Log ("检查更新失败：" + $_.Exception.Message)
        return
    }
    $script:updateRunner = $runner

    $script:updateTimer = New-Object System.Windows.Forms.Timer
    $script:updateTimer.Interval = 300
    $script:updateTimer.Add_Tick({
        $r = $script:updateRunner
        if (-not $r) { $script:updateTimer.Stop(); return }
        if (-not $r.Handle.IsCompleted) { return }

        $script:updateTimer.Stop()
        $script:updateTimer.Dispose()
        $script:updateTimer = $null
        $script:updateRunner = $null

        $online = ""
        try {
            $out = @($r.PowerShell.EndInvoke($r.Handle))
            if ($out.Count -gt 0) { $online = [string]$out[-1] }
        } catch {
            Write-Log ("检查更新失败：" + $_.Exception.Message)
        } finally {
            try { $r.PowerShell.Dispose() } catch { }
        }
        $script:updateBusy = $false

        if (-not $online) {
            Set-UpdateUi -Text "检查失败：连不上 GitHub（可点按钮重试或手动更新）" -Color $script:ui.Red
            Write-Log "检查更新失败：无法读取线上版本（网络或代理问题）"
            Show-Msg "OCR 控制面板" ("连不上 GitHub，无法检查更新。`r`n`r`n" +
                "可以：`r`n" +
                "1. 确认本机能访问 github.com（或开代理）后重试；`r`n" +
                "2. 或者到另一台机器下载 main.zip，`r`n" +
                "   再运行 launchers\Update-OCR.bat 手动离线更新。") "Warning"
            return
        }

        if ($online -eq $localVer) {
            Set-UpdateUi -Text ("已是最新版本 " + $localVer + "，无需更新") -Color $script:ui.Green
            Write-Log "已是最新版本：$localVer"
            Show-Msg "OCR 控制面板" ("当前已经是最新版本（" + $localVer + "），不需要更新。") "Information"
            return
        }

        try {
            $isNewer = ([version]$online) -gt ([version]$localVer)
        } catch {
            $isNewer = ($online -ne $localVer)
        }
        if (-not $isNewer) {
            Set-UpdateUi -Text ("本地版本 " + $localVer + " 比线上 " + $online + " 新，跳过更新") -Color $script:ui.TextMuted
            Write-Log "本地 $localVer 比线上 $online 新，不降级"
            Show-Msg "OCR 控制面板" ("线上最新是 " + $online + "，本地是 " + $localVer + "（更旧/相同），不执行更新。") "Information"
            return
        }

        $ans = [System.Windows.Forms.MessageBox]::Show(
            ("发现新版本：" + $localVer + " → " + $online + "`r`n`r`n" +
             "更新会：`r`n" +
             "  1. 停止当前服务`r`n" +
             "  2. 备份 server\config.json`r`n" +
             "  3. 覆盖代码并重启服务`r`n`r`n" +
             "python\ 和 token 都会保留。现在更新吗？"),
            "OCR 控制面板",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question)
        if ($ans -ne [System.Windows.Forms.DialogResult]::Yes) {
            Set-UpdateUi -Text ("发现新版本 " + $online + "，已取消更新") -Color $script:ui.TextMuted
            return
        }

        Set-UpdateUi -Text ("正在更新到 " + $online + "，请稍候（可能需要几分钟）…") -Busy $true
        Write-Log "开始更新：$localVer -> $online"

        $script:updateBaseText = "正在更新到 " + $online + "，请稍候"
        $barTimer = New-Object System.Windows.Forms.Timer
        $barTimer.Interval = 400
        $barTimer.Add_Tick({
            [System.Windows.Forms.Application]::DoEvents()
            if ($script:lblUpdateState.Text.Length -gt 80) {
                $script:lblUpdateState.Text = $script:updateBaseText
            }
            $script:lblUpdateState.Text = $script:lblUpdateState.Text + " ."
        })
        $barTimer.Start()
        $script:updateBarTimer = $barTimer

        $script:updateTimerRun = New-Object System.Windows.Forms.Timer
        $script:updateTimerRun.Interval = 300
        $script:updateTimerRun.Add_Tick({
            if (-not $script:updateProc) { return }
            if ($script:updateProc.HasExited) {
                $script:updateTimerRun.Stop()
                $script:updateTimerRun.Dispose()
                $script:updateTimerRun = $null
                if ($script:updateBarTimer) { $script:updateBarTimer.Stop(); $script:updateBarTimer.Dispose(); $script:updateBarTimer = $null }
                $code = 0
                try { $code = $script:updateProc.ExitCode } catch { }
                $script:updateProc = $null
                $script:updateBusy = $false
                if ($code -eq 0) {
                    Set-UpdateUi -Text ("已更新到 " + $online + "，正在重启服务…") -Color $script:ui.Green
                    Write-Log ("更新完成：" + $online)
                } else {
                    Set-UpdateUi -Text ("更新失败（退出码 " + $code + "），详见日志") -Color $script:ui.Red
                    Write-Log ("更新失败：退出码 " + $code)
                }
                Update-Status
            }
        })

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $updateScriptRef + '"'
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.WorkingDirectory = $rootRef
        try {
            $script:updateProc = [System.Diagnostics.Process]::Start($psi)
            $script:updateTimerRun.Start()
        } catch {
            if ($script:updateBarTimer) { $script:updateBarTimer.Stop(); $script:updateBarTimer.Dispose(); $script:updateBarTimer = $null }
            $script:updateBusy = $false
            Set-UpdateUi -Text ("更新失败：" + $_.Exception.Message) -Color $script:ui.Red
            Write-Log ("更新失败：" + $_.Exception.Message)
        }
    })
    $script:updateTimer.Start()
})

$cardSvc.Controls.Add($btnUpdate)

$chkAuto = New-Object System.Windows.Forms.CheckBox
$chkAuto.Text = "开机自启（登录后自动启动服务）"
$chkAuto.AutoSize = $false
$chkAuto.Size = New-Object System.Drawing.Size(340, 24)
$chkAuto.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 9)
$chkAuto.BackColor = $ui.Card
$chkAuto.FlatStyle = [System.Windows.Forms.FlatStyle]::System
$chkAuto.Location = New-Object System.Drawing.Point(20, 84)
$cardSvc.Controls.Add($chkAuto)
$chkAuto.Add_CheckedChanged({
    if ($chkAuto.Checked) {
        if (Enable-AutoStart) {
            Write-Log "已开启开机自启（任务计划：$taskName）"
        } else {
            $chkAuto.Checked = $false
            Show-Msg "OCR 控制面板" "创建开机自启任务失败，请确认以管理员身份运行面板。" "Error"
        }
    } else {
        if (Disable-AutoStart) {
            Write-Log "已关闭开机自启"
        } else {
            Write-Log "开机自启任务本来就不存在"
        }
    }
})
$cardSvc.Height = 148

# ------------------------------------------------------------------- log -----
$cardLog = New-Card -Width 828 -Height 196
$cardLog.Location = New-Object System.Drawing.Point(20, 654)
$form.Controls.Add($cardLog)

$lblLogTitle = New-Label -Text "服务日志" -Bold $true -Size 10
$lblLogTitle.Location = New-Object System.Drawing.Point(18, 12)
$cardLog.Controls.Add($lblLogTitle)

$lblFlash = New-Label -Text "" -Color $ui.Green -Size 8.5
$lblFlash.Location = New-Object System.Drawing.Point(90, 15)
$cardLog.Controls.Add($lblFlash)

$script:logBox = New-Object System.Windows.Forms.TextBox
$script:logBox.Multiline = $true
$script:logBox.ReadOnly = $true
$script:logBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$script:logBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$script:logBox.BorderStyle = "None"
$script:logBox.BackColor = $ui.SoftBg
$script:logBox.ForeColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$script:logBox.Location = New-Object System.Drawing.Point(16, 40)
$script:logBox.Size = New-Object System.Drawing.Size(796, 140)
$cardLog.Controls.Add($script:logBox)

$lblFoot = New-Label -Text "OCR 局域网验证码识别 · 关闭面板不会停止服务" -Color $ui.TextMuted -Size 8
$lblFoot.Location = New-Object System.Drawing.Point(22, 864)
$form.Controls.Add($lblFoot)

# Update-Status() runs in its own scope, so hand it the controls it updates.
$form.Tag = @{
    State       = $lblStateSub
    StateSub    = $lblStateSub
    StateDetail = $lblStateDetail
    Status      = $lblStatus
    Info        = $lblInfo
    Install     = $txtInstall
    Server      = $txtServer
    Token       = $txtToken
    Auto        = $chkAuto
    # Service buttons: the background start/restart flow disables and relabels
    # them, so it needs them reachable from function scope.
    Start       = $btnStart
    Restart     = $btnRestart
    Stop        = $btnStop
}

function Update-Status {    # NOTE: a PowerShell function has its own scope and cannot see script-level
    # $lbl* / $txt* variables, so the controls are kept on the form's Tag.
    $c = $form.Tag
    Set-ServiceStatus
    $pid0 = Get-ListenerPid $script:port
    $state = Get-ServiceState
    $ui = $script:ui
    $pill.Tag.State = $state
    $pill.Invalidate()
    Update-PanelIcon $state
    switch ($state) {
        "Running" {
            $c.StateSub.Text = "服务运行中 · 可正常识别"
            $c.StateSub.ForeColor = $ui.Green
            $c.StateDetail.Text = "端口 $($script:port) · 进程 PID $pid0 · /health 正常"
            $c.Status.Text = "局域网设备现在可以正常识别验证码"
        }
        "Starting" {
            $c.StateSub.Text = "启动中 · 正在加载模型"
            $c.StateSub.ForeColor = $ui.Amber
            $c.StateDetail.Text = "端口 $($script:port) 已监听（PID $pid0），/health 暂未响应"
            $c.Status.Text = "服务正在启动，请稍等几秒"
        }
        default {
            $c.StateSub.Text = "已停止 · 局域网设备无法识别"
            $c.StateSub.ForeColor = $ui.Red
            $c.StateDetail.Text = "端口 $($script:port) 无监听"
            $c.Status.Text = "服务未运行，点「启动服务」开始"
        }
    }
    $autoText = $(if ($c.Auto.Checked) { "开机自启：已开启" } else { "开机自启：未开启" })
    $c.Info.Text = "版本 $($script:version)　·　$autoText"
    $c.Install.Text = $script:userscriptUrl
    $c.Server.Text = $script:serverUrl
    $c.Token.Text = $(if ($script:token) { $script:token } else { "（尚未生成：请点「首次配置/修复」）" })
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000

# "已复制" feedback clears itself after a couple of seconds.
$script:flashTimer = New-Object System.Windows.Forms.Timer
$script:flashTimer.Interval = 2000
$script:flashTimer.Add_Tick({
    $script:flashTimer.Stop()
    $lblFlash.Text = ""
})

$timer.Add_Tick({ try { Update-Status } catch { Write-Log ("状态刷新失败：" + $_.Exception.Message) } })
$form.Add_Shown({
    try { Update-Status } catch { Write-Log ("状态刷新失败：" + $_.Exception.Message) }
    Refresh-LogTail
    try { $chkAuto.Checked = Test-AutoStartTask } catch { }
    $timer.Start()
    # Keep the desktop/root launcher shortcut present. It is cheap to rewrite
    # and makes the entry point keep its logo after an update or a move. Run it
    # on a short timer instead of inline: spawning powershell from Add_Shown
    # stalls the first paint of the window.
    $mkShortcut = Join-Path $root "tools\make_shortcut.ps1"
    if (Test-Path -LiteralPath $mkShortcut) {
        $script:shortcutScript = $mkShortcut
        $script:shortcutRoot = $root
        $script:shortcutTimer = New-Object System.Windows.Forms.Timer
        $script:shortcutTimer.Interval = 800
        $script:shortcutTimer.Add_Tick({
            $script:shortcutTimer.Stop()
            $script:shortcutTimer.Dispose()
            $script:shortcutTimer = $null
            try {
                Start-Process -FilePath "powershell.exe" -WindowStyle Hidden -ArgumentList @(
                    '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $script:shortcutScript,
                    '-TargetRoot', $script:shortcutRoot, '-Quiet'
                ) | Out-Null
            } catch { }
        })
        $script:shortcutTimer.Start()
    }
})
$form.Add_FormClosing({
    $timer.Stop()
    $script:flashTimer.Stop()
    foreach ($t in @($script:svcTimer, $script:restartTimer, $script:stopTimer, $script:shortcutTimer, $script:updateTimer, $script:updateTimerRun, $script:updateBarTimer)) {
        if ($t) { try { $t.Stop(); $t.Dispose() } catch { } }
    }
    if ($script:updateRunner) {
        try { $script:updateRunner.PowerShell.Stop() } catch { }
        try { $script:updateRunner.PowerShell.Dispose() } catch { }
        $script:updateRunner = $null
    }
    if ($script:svcPowerShell) {
        try { $script:svcPowerShell.Stop() } catch { }
        try { $script:svcPowerShell.Dispose() } catch { }
        $script:svcPowerShell = $null
    }
    # Release the single-instance lock so the next launch is not refused.
    if ($script:singleInstanceMutex) {
        try { if ($script:ownsMutex) { $script:singleInstanceMutex.ReleaseMutex() } } catch { }
        try { $script:singleInstanceMutex.Dispose() } catch { }
        $script:singleInstanceMutex = $null
        $script:ownsMutex = $false
    }
})

[void]$form.ShowDialog()
