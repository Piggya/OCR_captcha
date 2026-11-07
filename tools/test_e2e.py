r"""End-to-end smoke test for the local captcha OCR service.

Usage:
    python tools\test_e2e.py
    # add `--trust-proxy` to also exercise the XFF=on path
    # add `--round-b` to also test trust_proxy=true behavior (requires a config edit + restart)

Exits 0 if all expectations pass, 1 otherwise.
"""
import argparse
import base64
import ipaddress
import json
import os
import socket
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:1205"
CONFIG_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "server",
    "config.json",
)

PNG_1x1 = bytes([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
])
PNG_B64 = "data:image/png;base64," + base64.b64encode(PNG_1x1).decode()


def _probed_lan_ipv4():
    """Same preference order as server/app.py: outbound route, then hostname."""
    found = []
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.settimeout(0.2)
            probe.connect(("10.255.255.255", 1))
            found.append(probe.getsockname()[0])
    except OSError:
        pass
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            found.append(info[4][0])
    except OSError:
        pass
    for ip in found:
        try:
            addr = ipaddress.ip_address(ip)
        except ValueError:
            continue
        if addr.is_loopback or addr.is_link_local:
            continue
        return ip
    return "127.0.0.1"


def _is_bound_locally(ip):
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind((ip, 0))
        return True
    except OSError:
        return False


def _expected_public_base(cfg):
    """The base URL the server should inject.

    Mirrors server/app.py get_public_base_url(): configured work_lan_ip when it
    is really bound to this host, otherwise the probed LAN address. Deliberately
    independent of BASE, which is just where the test connects to.
    """
    port = int(cfg.get("port", 1205))
    configured = str(cfg.get("work_lan_ip") or "").strip()
    host = configured if configured and _is_bound_locally(configured) else _probed_lan_ipv4()
    return f"http://{host}:{port}"


def probe_panel_ast(panel_path):
    """Summarise panel.ps1 from its PowerShell AST.

    Substring checks cannot tell code from comments, so a marker inside a
    comment satisfied the old assertions. Parsing gives real functions, real
    command names and the actual body of each event handler.

    Runs through a temporary .ps1 file with -File: passing a multi-line script
    via -Command / -EncodedCommand silently produced an empty result.
    """
    probe = r'''
$ErrorActionPreference = "Stop"
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile("__PANEL__", [ref]$tokens, [ref]$errors)

$funcs = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
$cmds = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true)
$invokes = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] }, $true)
$assigns = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true)

$handlers = @{}
foreach ($m in $invokes) {
    if ($m.Member -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $m.Member.Value -like "Add_*") {
        $handlers[$m.Member.Value] = (@($m.Arguments) | ForEach-Object { $_.Extent.Text }) -join "|"
    }
}

@{
    functionNames = @($funcs | ForEach-Object { $_.Name })
    commands      = @($cmds | ForEach-Object { $_.GetCommandName() } | Where-Object { $_ })
    handlers      = $handlers
    scriptAssignments = @($assigns | ForEach-Object { $_.Left.Extent.Text } |
        Where-Object { $_ -like '$script:*' })
} | ConvertTo-Json -Depth 5 -Compress
'''.replace("__PANEL__", panel_path.replace('"', '`"'))

    fd, probe_path = tempfile.mkstemp(suffix=".ps1", prefix="panel_ast_")
    try:
        with os.fdopen(fd, "w", encoding="utf-8-sig", newline="\r\n") as fh:
            fh.write(probe)
        proc = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", probe_path],
            capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=180,
        )
        if proc.returncode != 0 or not (proc.stdout or "").strip():
            raise RuntimeError("panel AST probe failed: " + (proc.stderr or "")[:300])
        return json.loads(proc.stdout)
    finally:
        try:
            os.remove(probe_path)
        except OSError:
            pass


def call(path, body=None, headers=None):
    headers = dict(headers or {})
    data = None
    if body is not None:
        headers.setdefault("Content-Type", "application/json")
        data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(BASE + path, data=data, method="POST" if body else "GET", headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=10) as r:
            return r.status, r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", "replace")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--trust-proxy", action="store_true",
                        help="also run Round B tests (XFF chain) - requires the service to be configured trust_proxy=true")
    args = parser.parse_args()

    cfg = json.load(open(CONFIG_PATH, "r", encoding="utf-8-sig"))
    token = cfg["api_token"]

    passed = 0
    total = 0
    failures = []

    def check(name, got, expected, body=None):
        nonlocal passed, total
        total += 1
        if got == expected:
            print(f"[OK  ] {name}: status={got}")
            passed += 1
        else:
            print(f"[FAIL] {name}: status={got} (expected {expected})")
            if body is not None:
                print(f"      body={body[:200]}")
            failures.append(name)

    print("=" * 60)
    print(f"Round A: smoke (trust_proxy={cfg.get('trust_proxy')!r})")
    print("=" * 60)
    s, b = call("/health")
    check("health 200", s, 200, b)

    # 0.9.1: the LAN endpoint must embed the current URL + token, while the
    # repository copy must stay token-free (never print b here: it has a token).
    #
    # 0.12.2: the URL no longer comes from the request. Mirror the server's
    # own rule (configured work_lan_ip if bound here, else the probed LAN
    # address) so the assertion still means "the right address was injected"
    # without re-introducing the Host-header dependency that was the bug.
    expected_base = _expected_public_base(cfg)
    s, b = call("/userscript.user.js")
    injected = (
        s == 200
        and "const INJECTED_CONFIG = {" in b
        and f'"serverUrl": "{expected_base}"' in b
        and f'"token": "{token}"' in b
        and f"// @updateURL    {expected_base}/userscript.user.js" in b
    )
    check("userscript injects URL + token (LAN)", injected, True)

    # The Host header is attacker-controlled; it must never reach the response.
    # Before 0.12.2 `Host: attacker.evil.com` rewrote serverUrl/@updateURL and
    # leaked the plaintext token to that domain.
    s, b_host = call("/userscript.user.js", headers={"Host": "attacker.evil.com"})
    check(
        "userscript ignores forged Host header",
        s == 200 and "attacker.evil.com" not in b_host
        and f'"serverUrl": "{expected_base}"' in b_host,
        True,
    )
    repo_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "userscript",
        "local-captcha-autofill.user.js",
    )
    repo_text = open(repo_path, "r", encoding="utf-8").read()
    check(
        "repo userscript stays token-free",
        "const INJECTED_CONFIG = null;" in repo_text and token not in repo_text,
        True,
    )

    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    # v0.11.0 moved the launchers into launchers\ and start_server/install
    # into tools\; the root keeps only OCR-Panel.bat as a forwarder.
    updater_ok = (
        os.path.isfile(os.path.join(root, "launchers", "Update-OCR.bat"))
        and os.path.isfile(os.path.join(root, "tools", "update_ocr.ps1"))
    )
    check("portable updater present", updater_ok, True)
    panel_ok = all(
        os.path.isfile(os.path.join(root, rel))
        for rel in (
            "OCR-Panel.bat",
            os.path.join("launchers", "OCR-Panel.bat"),
            os.path.join("tools", "panel.ps1"),
            os.path.join("tools", "start_service_bg.ps1"),
        )
    )
    check("control panel present", panel_ok, True)
    silent_ok = (
        os.path.isfile(os.path.join(root, "tools", "panel_launch.vbs"))
        and os.path.isfile(os.path.join(root, "assets", "ocr-panel.ico"))
        and "panel_launch.vbs"
        in open(os.path.join(root, "launchers", "OCR-Panel.bat"), "r", encoding="utf-8").read()
    )
    check("control panel silent launch + icon", silent_ok, True)

    # v0.11.0: the visible entry point is a .lnk, because a .bat can never carry
    # a custom icon. It targets wscript.exe + the VBS directly (no cmd window
    # flash) and is machine-specific, so it is rebuilt locally, not shipped.
    # Note: .lnk strings mix narrow ASCII (ASCII part of the item ID list,
    # written in the shell's ANSI codepage) with UTF-16LE (LinkInfo, string
    # data), so check both encodings.
    shortcut_ok = True
    shortcut_detail = ""
    try:
        import struct

        lnk = os.path.join(root, "OCR 控制面板.lnk")
        data = open(lnk, "rb").read()
        magic = struct.unpack_from("<I", data, 0)[0] == 0x0000004C
        # .lnk strings mix narrow ASCII (ANSI item ID list) with UTF-16LE
        # (LinkInfo / string data). Search the raw bytes for both forms.
        raw = data.lower()

        def has(token):
            wide = b"".join(bytes((c, 0)) for c in token)
            return token in raw or wide in raw

        magic = struct.unpack_from("<I", data, 0)[0] == 0x0000004C
        has_icon = has(b"ocr-panel.ico")
        has_vbs = has(b"panel_launch.vbs")
        has_wscript = has(b"wscript.exe")
        # Must not point at a .bat (that would flash a console and lose the icon).
        points_at_bat = has(b".bat")
        shortcut_ok = magic and has_icon and has_vbs and has_wscript and not points_at_bat
        shortcut_detail = "magic=%s icon=%s vbs=%s wscript=%s bat=%s" % (
            magic, has_icon, has_vbs, has_wscript, points_at_bat)
    except Exception as exc:  # noqa: BLE001 - report as a failed check
        shortcut_ok = False
        shortcut_detail = repr(exc)
    check("launcher shortcut with logo icon", shortcut_ok, True, shortcut_detail)

    # The source artwork lives in assets/ and is what make_icon.ps1 renders.
    art_ok = all(
        os.path.isfile(os.path.join(root, "assets", name))
        for name in ("logo.png", "ocr-logo.png", "ocr-panel.ico")
    )
    icon_tool = open(os.path.join(root, "tools", "make_icon.ps1"), "r", encoding="utf-8-sig").read()
    # make_icon.ps1 must write every size as a real 32bpp DIB payload.
    # GDI+ (Explorer / WinForms / System.Drawing.Icon) cannot decode PNG entries,
    # which is what corrupted 48px+ in 0.10.x.
    dib_ok = "ConvertTo-IconDib" in icon_tool and "ImageFormat]::Png" not in icon_tool
    check(
        "icon built from assets/logo.png",
        art_ok and r"assets\logo.png" in icon_tool and dib_ok,
        True,
        "art=%s dib=%s" % (art_ok, dib_ok),
    )

    # setup/update/panel must all be able to (re)create the shortcut.
    hook_ok = all(
        "make_shortcut.ps1" in open(os.path.join(root, "tools", name), "r", encoding="utf-8-sig").read()
        for name in ("setup_new_server.ps1", "update_ocr.ps1", "panel.ps1")
    )
    check("shortcut recreated on install/update/panel", hook_ok, True)

    # Control-panel structure is checked from the PowerShell AST, not by
    # grepping panel.ps1 for marker words: the old substring checks passed as
    # long as a name appeared in a comment, so they verified nothing.
    panel_facts = probe_panel_ast(os.path.join(root, "tools", "panel.ps1"))
    panel_funcs = set(panel_facts.get("functionNames") or [])
    panel_cmds = set(panel_facts.get("commands") or [])
    panel_handlers = panel_facts.get("handlers") or {}
    panel_assigns = set(panel_facts.get("scriptAssignments") or [])

    closing = panel_handlers.get("Add_FormClosing", "")
    check(
        "control panel keep-service-on-close",
        bool(closing)
        and not any(k in closing for k in ("Stop-Process", "taskkill", "Terminate"))
        and "Get-ListenerPid" in panel_funcs
        and ("Stop-Process" in panel_cmds or "taskkill" in panel_cmds),
        True,
        "closing=%r" % closing[:80],
    )

    info_ok = (
        all(name in panel_funcs for name in ("Get-ShareMessage", "Copy-Text", "Get-ServiceState"))
        and all(name in panel_cmds for name in ("Get-ShareMessage", "Copy-Text", "Get-ServiceState"))
        and all(
            var in panel_assigns
            for var in ("$script:serverUrl", "$script:token", "$script:userscriptUrl")
        )
    )
    check("control panel shows url+token+state", info_ok, True)
    metadata_ok = all(tag in repo_text for tag in (
        "// @license      MIT",
        "// @homepageURL  https://github.com/Piggya/OCR_captcha",
        "// @supportURL   https://github.com/Piggya/OCR_captcha/issues",
        "// @source       https://github.com/Piggya/OCR_captcha",
        "// @description:zh-CN",
    ))
    check("GreasyFork metadata present", metadata_ok, True)
    app_text = open(os.path.join(root, "server", "app.py"), "r", encoding="utf-8").read()
    app_version = app_text.split('__version__ = "', 1)[1].split('"', 1)[0]
    us_version = repo_text.split("// @version", 1)[1].split("\n", 1)[0].strip()
    check("server/userscript version sync", (app_version, us_version), (app_version, app_version))

    s, b = call("/recognize", {"image": PNG_B64, "kind": "text"})
    check("auth: no token -> 401", s, 401, b)
    s, b = call("/recognize", {"image": PNG_B64, "kind": "text"}, {"X-API-Token": "wrong"})
    check("auth: wrong token -> 401", s, 401, b)
    s, b = call("/recognize", {"image": PNG_B64, "kind": "text"}, {"X-API-Token": token})
    check("happy path: real PNG + token -> 200", s, 200, b)

    # B1 regression: base64 payload whose length is 1 mod 3 (data URL ends
    # with '==') must not lose its final byte. Before the fix, such a JPEG
    # decoded one byte short and returned 400.
    try:
        import io as _io
        from PIL import Image, ImageDraw
        probe = Image.new("RGB", (80, 28), "white")
        ImageDraw.Draw(probe).text((4, 4), "A8K3", fill="black")
        jpeg_raw = None
        for quality in range(30, 100):
            buf = _io.BytesIO()
            probe.save(buf, format="JPEG", quality=quality)
            if len(buf.getvalue()) % 3 == 1:
                jpeg_raw = buf.getvalue()
                break
        if jpeg_raw is not None:
            jpeg_b64 = "data:image/jpeg;base64," + base64.b64encode(jpeg_raw).decode()
            s, b = call("/recognize", {"image": jpeg_b64, "kind": "text"}, {"X-API-Token": token})
            check(f"B1 JPEG len%3==1 (len={len(jpeg_raw)}) -> 200", s, 200, b)
    except ImportError:
        print("[SKIP] B1 JPEG regression (Pillow not installed)")
    s, b = call("/recognize", {"image": "data:image/png;base64,this-string-is-definitely-not-valid-base64-data-here!@#$%", "kind": "text"}, {"X-API-Token": token})
    check("bad base64 -> 400", s, 400, b)
    s, b = call("/recognize", {"image": PNG_B64, "kind": "image"}, {"X-API-Token": token})
    check("bad kind -> 422 (pydantic Literal)", s, 422, b)
    s, b = call("/recognize", {"image": "abc", "kind": "text"}, {"X-API-Token": token})
    check("image too short -> 422 (pydantic min_length)", s, 422, b)

    if not cfg.get("trust_proxy"):
        s, b = call("/recognize", {"image": PNG_B64, "kind": "text"},
                    {"X-API-Token": token, "X-Forwarded-For": "8.8.8.8"})
        check("XFF=8.8.8.8 + trust_proxy=false -> 200 (XFF ignored)", s, 200, b)
    else:
        s, b = call("/recognize", {"image": PNG_B64, "kind": "text"},
                    {"X-API-Token": token, "X-Forwarded-For": "8.8.8.8"})
        check("XFF=8.8.8.8 + trust_proxy=true -> 403 (public blocked)", s, 403, b)
        s, b = call("/recognize", {"image": PNG_B64, "kind": "text"},
                    {"X-API-Token": token, "X-Forwarded-For": "192.168.1.5"})
        check("XFF=192.168.1.5 + trust_proxy=true -> 200 (private allowed)", s, 200, b)
        s, b = call("/recognize", {"image": PNG_B64, "kind": "text"},
                    {"X-API-Token": token, "X-Forwarded-For": "192.168.1.5, 10.0.0.1, 8.8.8.8"})
        check("XFF chain leftmost used -> 200", s, 200, b)

    # P7 oversize: choose a payload that decodes to >5MB but b64 string <7.34MB cap
    big_raw = b"\x00" * 5_490_000
    big_b64 = "data:image/png;base64," + base64.b64encode(big_raw).decode()
    s, b = call("/recognize", {"image": big_b64, "kind": "text"}, {"X-API-Token": token})
    check("P7 5.49MB raw -> 400 image too large", s, 400, b)
    bigger_raw = b"\x00" * 6_000_000
    bigger_b64 = "data:image/png;base64," + base64.b64encode(bigger_raw).decode()
    s, b = call("/recognize", {"image": bigger_b64, "kind": "text"}, {"X-API-Token": token})
    check("P7 6MB raw -> 422 (pydantic catches first)", s, 422, b)

    print()
    print(f"Result: {passed}/{total} passed")
    if failures:
        print("Failures:", failures)
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
