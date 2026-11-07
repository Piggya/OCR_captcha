# start_service_bg.ps1
# -----------------------------------------------------------------------------
# Start the OCR service in the background if it is not already running.
# Does NOT change any configuration (no firewall / power changes), so it can
# be used by the control panel and by the Windows scheduled task that starts
# the service at logon. No administrator rights are required for the start
# itself (the firewall rule is created once by Start-OCR.bat).
# -----------------------------------------------------------------------------

param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configPath = Join-Path $root "server\config.json"

$port = 1205
$bindHost = "0.0.0.0"
if (Test-Path -LiteralPath $configPath) {
    try {
        $cfg = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($cfg.port) { $port = [int]$cfg.port }
        if ($cfg.bind_host) { $bindHost = [string]$cfg.bind_host }
    } catch { }
}

# Get-NetTCPConnection costs ~950 ms per call on PowerShell 5.1, and this
# script polls the port in a loop. GetExtendedTcpTable answers in under a
# millisecond, which is what makes the 300 ms poll below cheap.
$script:bgTcpHelper = $false
try {
    Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class OcrTcpBg {
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

    public static int ListenerPid(int port) {
        int size = 0;
        uint rc = GetExtendedTcpTable(IntPtr.Zero, ref size, false, AF_INET, TCP_TABLE_OWNER_PID_LISTENER, 0);
        if (rc != 0 && rc != 122) { return 0; }
        IntPtr buf = Marshal.AllocHGlobal(size);
        try {
            rc = GetExtendedTcpTable(buf, ref size, false, AF_INET, TCP_TABLE_OWNER_PID_LISTENER, 0);
            if (rc != 0) { return 0; }
            int rows = Marshal.ReadInt32(buf);
            IntPtr cur = (IntPtr)((long)buf + 4);
            int rowSize = Marshal.SizeOf(typeof(MIB_TCPROW_OWNER_PID));
            for (int i = 0; i < rows; i++) {
                var row = (MIB_TCPROW_OWNER_PID)Marshal.PtrToStructure(cur, typeof(MIB_TCPROW_OWNER_PID));
                int p = (int)(((row.localPort & 0xFF) << 8) | ((row.localPort & 0xFF00) >> 8));
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
    $script:bgTcpHelper = $true
} catch {
    $script:bgTcpHelper = $false
}

function Get-ListenerPid([int]$p) {
    if ($script:bgTcpHelper) {
        try {
            $owner = [OcrTcpBg]::ListenerPid($p)
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

$python = Join-Path $root "python\python.exe"
if (-not (Test-Path -LiteralPath $python)) {
    $python = Join-Path $root ".venv\Scripts\python.exe"
}
if (-not (Test-Path -LiteralPath $python)) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if (-not $cmd) {
        Write-Host "[ERROR] Python not found (looked for python\, .venv\ and PATH)." -ForegroundColor Red
        exit 1
    }
    $python = $cmd.Source
}

# Probe the interpreter BEFORE launching anything. Without this, a system
# Python that has uvicorn but not ddddocr starts uvicorn fine and then dies
# 40 lines deep into a traceback, leaving the user with "service stopped" and
# no idea why. python_env.ps1 owns the candidate order and the probe.
. (Join-Path $PSScriptRoot "python_env.ps1")
$envCheck = Resolve-OcrPython -Root $root
if (-not $envCheck.Ok) {
    Write-Host "[ERROR] The OCR service cannot start: Python dependencies are missing." -ForegroundColor Red
    Write-Host ""
    ($envCheck.Attempts | ForEach-Object {
        Write-Host ("  [{0}] {1}" -f $_.Source, $_.Path)
        Write-Host ("         {0}" -f $_.Detail)
    })
    Write-Host ""
    Write-Host "Fix: run launchers\Start-OCR.bat once (it installs the dependencies),"
    Write-Host "     or run:  python -m pip install -r requirements.txt"
    Write-Host ""
    Write-Host ("Reason: " + $envCheck.Reason) -ForegroundColor Yellow
    exit 2
}
$python = $envCheck.Path

$running = Get-ListenerPid $port
if ($running -gt 0 -and -not $Force) {
    Write-Host ("Service already running on port {0} (PID {1})." -f $port, $running)
    exit 0
}
if ($running -gt 0) {
    Write-Host ("Stopping existing listener on port {0} (PID {1})..." -f $port, $running)
    Stop-Process -Id $running -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

$logOut = Join-Path $root "server.log"
$logErr = Join-Path $root "server.err.log"
Start-Process -FilePath $python -ArgumentList @(
    '-m', 'uvicorn', 'server.app:app',
    '--host', $bindHost, '--port', [string]$port, '--no-proxy-headers'
) -WorkingDirectory $root `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr `
  -WindowStyle Hidden

# Poll for the listening socket instead of sleeping a flat 5 s. uvicorn binds
# the port within a second or two; waiting the full period made every start
# feel longer for no reason. 20 s is the ceiling for a cold ONNX load.
$pid0 = 0
for ($i = 0; $i -lt 66; $i++) {
    $pid0 = Get-ListenerPid $port
    if ($pid0 -gt 0) { break }
    Start-Sleep -Milliseconds 300
}
if ($pid0 -gt 0) {
    Write-Host ("Service started on port {0} (PID {1})." -f $port, $pid0) -ForegroundColor Green
    exit 0
}

Write-Host "[ERROR] Service did not start; check server.err.log." -ForegroundColor Red
if (Test-Path -LiteralPath $logErr) {
    Write-Host ""
    Get-Content -LiteralPath $logErr -Tail 12 | ForEach-Object { Write-Host ("  " + $_) }
}
exit 1
