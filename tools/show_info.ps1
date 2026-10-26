# show_info.ps1
# -----------------------------------------------------------------------------
# Show the LAN server URL, API token and userscript install URL, and put a
# ready-to-forward message on the clipboard.
#
# Run by double-clicking Show-OCR-Info.bat on the server machine. No admin
# rights required. The token is sensitive: only share the output with LAN
# LAN devices, never post it publicly.
# -----------------------------------------------------------------------------

param(
    [switch]$NoClipboard
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $root "server\config.json"

if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Host "[ERROR] server\config.json not found." -ForegroundColor Red
    Write-Host "        Run Start-OCR.bat first." -ForegroundColor Yellow
    exit 1
}

$config = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$token = [string]$config.api_token
if ([string]::IsNullOrWhiteSpace($token) -or $token -eq "change-me-to-a-random-internal-token") {
    Write-Host "[ERROR] api_token is empty or still the placeholder." -ForegroundColor Red
    Write-Host "        Run Start-OCR.bat to generate a real token." -ForegroundColor Yellow
    exit 1
}

$port = 1205
try { $port = [int]$config.port } catch { }
if ($port -le 0) { $port = 1205 }

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

$lanIp = [string]$config.work_lan_ip
if ([string]::IsNullOrWhiteSpace($lanIp)) {
    $lanIp = Get-PrimaryLanIPv4
}

$serverUrl = "http://${lanIp}:$port"
$userscriptUrl = "$serverUrl/userscript.user.js"

$message = @"
【验证码识别 - 局域网连接信息】
服务器地址：$serverUrl
API token：$token
安装地址：$userscriptUrl

推荐把“安装地址”发给局域网设备：
1. 浏览器安装 Tampermonkey
2. 打开上面的安装地址，点安装
3. 不需要手动填服务器地址和 token

需要手动配置时：
油猴图标菜单 →「OCR 服务器设置…」→ 填上面的服务器地址和 token

只发给局域网内的设备，不要发到公网。
"@

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " OCR 连接信息（只发给局域网内的设备）" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host ("  服务器地址: " + $serverUrl) -ForegroundColor White
Write-Host ("  API token : " + $token) -ForegroundColor Yellow
Write-Host ("  安装地址  : " + $userscriptUrl) -ForegroundColor Cyan
Write-Host ""
Write-Host "  手动配置入口：油猴图标菜单 →「OCR 服务器设置…」" -ForegroundColor DarkGray
Write-Host ""

if (-not $NoClipboard) {
    try {
        Set-Clipboard -Value $message
        Write-Host "已把完整连接信息复制到剪贴板，可直接粘贴到局域网群聊。" -ForegroundColor Green
    } catch {
        Write-Host ("[WARNING] 复制到剪贴板失败: " + $_.Exception.Message) -ForegroundColor Yellow
    }
}

Write-Host "提示：token 等同于访问密码，只发给局域网内的设备；不要截图发到公网。" -ForegroundColor DarkYellow
Write-Host ""
