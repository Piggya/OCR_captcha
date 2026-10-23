r"""End-to-end smoke test for the local captcha OCR service.

Usage:
    & .\.venv\Scripts\python.exe tools\test_e2e.py
    # add `--trust-proxy` to also exercise the XFF=on path
    # add `--round-b` to also test trust_proxy=true behavior (requires a config edit + restart)

Exits 0 if all expectations pass, 1 otherwise.
"""
import argparse
import base64
import json
import os
import sys
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
