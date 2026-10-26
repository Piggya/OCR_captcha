$ErrorActionPreference = "Stop"

$python = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = Join-Path $PSScriptRoot "python\python.exe"
}
if (-not (Test-Path $python)) {
    $python = "python"
}

$configPath = Join-Path $PSScriptRoot "server\config.json"
if (-not (Test-Path $configPath)) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "server\config.example.json") -Destination $configPath
}

$config = Get-Content -LiteralPath $configPath -Encoding UTF8 | ConvertFrom-Json

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

    $anyPrivate = $privateCandidates |
        Sort-Object InterfaceMetric, InterfaceIndex |
        Select-Object -First 1

    if ($anyPrivate) { return $anyPrivate.IPAddress }

    $fallback = $addresses | Select-Object -First 1
    if ($fallback) { return $fallback.IPAddress }

    return "127.0.0.1"
}

function New-Token {
    $bytes = New-Object byte[] 24
    $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $rng.GetBytes($bytes)
    }
    finally {
        $rng.Dispose()
    }
    return [Convert]::ToBase64String($bytes).TrimEnd("=").Replace("+", "-").Replace("/", "_")
}

$lanIp = Get-PrimaryLanIPv4
$port = [int]$config.port

if ($config.api_token -eq "change-me-to-a-random-internal-token" -or [string]::IsNullOrWhiteSpace($config.api_token)) {
    $config.api_token = New-Token
    $config | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $configPath -Encoding UTF8
}

$workIp = $config.work_lan_ip
if ([string]::IsNullOrWhiteSpace($workIp)) { $workIp = $lanIp }

$bindHost = $config.bind_host
if ([string]::IsNullOrWhiteSpace($bindHost)) { $bindHost = "0.0.0.0" }

$serverUrl = "http://{0}:{1}" -f $workIp, $port
$userscriptUrl = "http://{0}:{1}/userscript.user.js" -f $workIp, $port

Write-Host ""
Write-Host "土著内网验证码识别 is starting..."
Write-Host ("  Server URL (current machine): http://{0}:{1}" -f $lanIp, $port)
Write-Host ("  Server URL (work LAN IP):    {0}" -f $serverUrl)
Write-Host ""
Write-Host "  局域网设备脚本配置（油猴菜单『OCR 服务器设置…』）：" -ForegroundColor Yellow
Write-Host ("    Server URL : {0}" -f $serverUrl) -ForegroundColor Yellow
Write-Host ("    API token  : {0}" -f $config.api_token) -ForegroundColor Yellow
Write-Host ("  安装/更新脚本: {0}" -f $userscriptUrl) -ForegroundColor Yellow
Write-Host ""
Write-Host ("启动 uvicorn: http://{0}:{1}  (Ctrl+C 停止)" -f $bindHost, $port)

Push-Location $PSScriptRoot
try {
    & $python -m uvicorn server.app:app --host $bindHost --port $port
}
finally {
    Pop-Location
}