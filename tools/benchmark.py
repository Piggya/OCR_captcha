r"""Accuracy + latency benchmark for the local captcha OCR service.

Runs every labelled captcha image through the live /recognize endpoint and
reports:

  * exact-match rate   - how often the whole string is correct
  * char accuracy      - 1 - edit_distance / max(len_expected, len_actual)
  * average / min / max latency (round-trip wall clock)
  * a per-image table and, optionally, an HTML review page

"Labelled" means the answer is encoded in the filename. Two naming styles
are supported:

    captcha-A8K3.png      -> expected "A8K3"   (prefix "captcha-" stripped)
    1234.png              -> expected "1234"   (bare filename)
    some_site_A8K3_x.png  -> expected "A8K3"   (only when --labelled picks it)

By default it scans tools/test-assets for files matching captcha-<answer>.png.

Usage (run from the repo root):
    python tools\benchmark.py
    python tools\benchmark.py --dir C:\captchas
    python tools\benchmark.py --repeat 5 --warmup 2
    python tools\benchmark.py --report report.html

Exit code: 0 if the service was reachable and ran, 1 otherwise. Accuracy is
reported but does not fail the process (accuracy is informational).
"""
import argparse
import base64
import json
import re
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_BASE = "http://127.0.0.1:1205"
CONFIG_PATH = ROOT / "server" / "config.json"
DEFAULT_DIR = ROOT / "tools" / "test-assets"

# captcha-A8K3.png / captcha-1234.png  -> group is the answer
CAPTCHA_PREFIX_RE = re.compile(r"^captcha-(.+)\.(?:png|jpe?g|bmp|webp|gif)$", re.IGNORECASE)


def load_token() -> str:
    if not CONFIG_PATH.exists():
        return ""
    try:
        cfg = json.loads(CONFIG_PATH.read_text(encoding="utf-8-sig"))
        return str(cfg.get("api_token") or "")
    except Exception:
        return ""


def collect_images(folder: Path, allow_bare: bool):
    """Return list of (path, expected_answer)."""
    items = []
    if not folder.is_dir():
        return items
    for path in sorted(folder.iterdir()):
        if not path.is_file():
            continue
        m = CAPTCHA_PREFIX_RE.match(path.name)
        if m:
            items.append((path, m.group(1)))
            continue
        if allow_bare and path.suffix.lower() in {".png", ".jpg", ".jpeg", ".bmp", ".webp", ".gif"}:
            items.append((path, path.stem))
    return items


def call_recognize(base: str, token: str, image_bytes: bytes, timeout: float):
    """POST image to /recognize. Returns (ok, text, confidence, engine, time_ms)."""
    data_url = "data:image/png;base64," + base64.b64encode(image_bytes).decode("ascii")
    body = json.dumps({"image": data_url, "kind": "text", "site": "benchmark"}).encode("utf-8")
    headers = {"Content-Type": "application/json; charset=UTF-8"}
    if token:
        headers["X-API-Token"] = token
    req = urllib.request.Request(base.rstrip("/") + "/recognize", data=body, method="POST", headers=headers)
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            raw = r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")
        raise RuntimeError(f"HTTP {e.code}: {detail}") from e
    wall_ms = (time.perf_counter() - started) * 1000
    payload = json.loads(raw)
    return (
        bool(payload.get("ok")),
        str(payload.get("text") or "").strip(),
        float(payload.get("confidence", 1.0)),
        str(payload.get("engine") or ""),
        float(payload.get("time_ms", wall_ms)),
        wall_ms,
    )


def edit_distance(a: str, b: str) -> int:
    """Levenshtein distance (iterative, O(len(a)*len(b)))."""
    if a == b:
        return 0
    if not a:
        return len(b)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a, 1):
        cur = [i]
        for j, cb in enumerate(b, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (ca != cb)))
        prev = cur
    return prev[-1]


def char_accuracy(expected: str, actual: str) -> float:
    if not expected and not actual:
        return 1.0
    dist = edit_distance(expected, actual)
    return max(0.0, 1.0 - dist / max(len(expected), len(actual)))


def build_html(rows, summary) -> str:
    def esc(s):
        return (str(s).replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace('"', "&quot;"))

    cards = []
    for r in rows:
        img_b64 = base64.b64encode(r["image_bytes"]).decode("ascii")
        ok_class = "ok" if r["exact"] else "bad"
        cards.append(f"""
        <div class="card {ok_class}">
          <img src="data:image/png;base64,{img_b64}" alt="{esc(r['name'])}">
          <div class="meta">
            <div><b>文件</b>: {esc(r['name'])}</div>
            <div><b>期望</b>: <span class="exp">{esc(r['expected'])}</span></div>
            <div><b>识别</b>: <span class="act">{esc(r['actual'])}</span></div>
            <div><b>字符准确率</b>: {r['char_acc']*100:.1f}%</div>
            <div><b>置信度</b>: {r['confidence']:.3f} &nbsp; <b>引擎</b>: {esc(r['engine'])}</div>
            <div><b>耗时</b>: {r['time_ms']:.1f} ms</div>
          </div>
        </div>""")

    return f"""<!doctype html>
<html lang="zh-CN"><head><meta charset="utf-8">
<title>OCR 准确率报告</title>
<style>
  body {{ font-family: system-ui, Arial, sans-serif; margin: 24px; background:#f7f7f8; color:#202124; }}
  h1 {{ font-size: 20px; }}
  .summary {{ background:#fff; border-radius:8px; padding:16px 20px; margin-bottom:20px; box-shadow:0 1px 4px rgba(0,0,0,.08); }}
  .grid {{ display:grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap:16px; }}
  .card {{ background:#fff; border-radius:8px; padding:12px; box-shadow:0 1px 4px rgba(0,0,0,.08); display:flex; gap:12px; }}
  .card.ok {{ border-left:4px solid #1a7f37; }}
  .card.bad {{ border-left:4px solid #cf222e; }}
  .card img {{ width:120px; height:auto; border:1px solid #e1e4e8; border-radius:4px; align-self:flex-start; image-rendering:pixelated; }}
  .meta {{ font-size:13px; line-height:1.7; }}
  .exp {{ color:#1a7f37; font-weight:600; }}
  .act {{ color:#0969da; font-weight:600; }}
  .bad .act {{ color:#cf222e; }}
</style></head>
<body>
  <h1>OCR 准确率报告</h1>
  <div class="summary">
    <div><b>样本数</b>: {summary['total']}</div>
    <div><b>完全匹配率</b>: {summary['exact_rate']*100:.1f}% ({summary['exact']}/{summary['total']})</div>
    <div><b>平均字符准确率</b>: {summary['char_acc']*100:.1f}%</div>
    <div><b>平均耗时</b>: {summary['avg_ms']:.1f} ms &nbsp; <b>最小</b>: {summary['min_ms']:.1f} ms &nbsp; <b>最大</b>: {summary['max_ms']:.1f} ms</div>
    <div><b>服务地址</b>: {esc(summary['base'])}</div>
  </div>
  <div class="grid">{''.join(cards)}</div>
</body></html>"""


def main() -> int:
    parser = argparse.ArgumentParser(description="Captcha OCR accuracy + latency benchmark")
    parser.add_argument("--base", default=DEFAULT_BASE, help=f"service base url (default {DEFAULT_BASE})")
    parser.add_argument("--dir", default=str(DEFAULT_DIR), help="folder of labelled captcha images")
    parser.add_argument("--bare", action="store_true", help="also treat bare filenames as labels")
    parser.add_argument("--token", default=None, help="API token (default: read server/config.json)")
    parser.add_argument("--repeat", type=int, default=1, help="run the whole set N times")
    parser.add_argument("--warmup", type=int, default=0, help="warmup requests before timing")
    parser.add_argument("--timeout", type=float, default=15.0, help="per-request timeout seconds")
    parser.add_argument("--ignore-case", action="store_true",
                        help="compare case-insensitively (useful when the site is not case-sensitive)")
    parser.add_argument("--report", default=None, help="write an HTML review report to this path")
    args = parser.parse_args()

    token = args.token if args.token is not None else load_token()
    images = collect_images(Path(args.dir), args.bare)
    if not images:
        print(f"[ERROR] no labelled images found in {args.dir}")
        print("        expected names like captcha-A8K3.png")
        return 1

    print("=" * 64)
    print(f"Benchmark: {len(images)} images x {args.repeat} run(s) -> {args.base}")
    print("=" * 64)

    # warmup
    for _ in range(args.warmup):
        try:
            call_recognize(args.base, token, images[0][0].read_bytes(), args.timeout)
        except Exception as exc:  # noqa: BLE001
            print(f"[ERROR] service unreachable during warmup: {exc}")
            return 1

    rows = []
    total = 0
    exact = 0
    char_sum = 0.0
    times = []

    for run in range(args.repeat):
        for path, expected in images:
            try:
                ok, text, conf, engine, server_ms, wall_ms = call_recognize(
                    args.base, token, path.read_bytes(), args.timeout
                )
            except Exception as exc:  # noqa: BLE001
                print(f"[ERROR] {path.name}: {exc}")
                return 1
            if not ok:
                print(f"[FAIL ] {path.name}: server returned ok=false")
                return 1
            cmp_expected = expected.lower() if args.ignore_case else expected
            cmp_text = text.lower() if args.ignore_case else text
            is_exact = (cmp_text == cmp_expected)
            acc = char_accuracy(cmp_expected, cmp_text)
            total += 1
            exact += 1 if is_exact else 0
            char_sum += acc
            times.append(server_ms)
            flag = "OK  " if is_exact else "MISS"
            print(f"[{flag}] {path.name:<28} expect={expected!r:<10} got={text!r:<10} "
                  f"conf={conf:.2f} {server_ms:.1f}ms")
            if run == 0:
                rows.append({
                    "name": path.name, "expected": expected, "actual": text,
                    "exact": is_exact, "char_acc": acc, "confidence": conf,
                    "engine": engine, "time_ms": server_ms,
                    "image_bytes": path.read_bytes(),
                })

    summary = {
        "base": args.base,
        "total": total,
        "exact": exact,
        "exact_rate": exact / total if total else 0.0,
        "char_acc": char_sum / total if total else 0.0,
        "avg_ms": sum(times) / len(times) if times else 0.0,
        "min_ms": min(times) if times else 0.0,
        "max_ms": max(times) if times else 0.0,
    }

    print("-" * 64)
    print(f"完全匹配率 : {summary['exact_rate']*100:.1f}% ({exact}/{total})")
    print(f"字符准确率 : {summary['char_acc']*100:.1f}%")
    print(f"延迟       : avg {summary['avg_ms']:.1f} ms | min {summary['min_ms']:.1f} | max {summary['max_ms']:.1f}")
    print(f"样本目录   : {args.dir}")

    if args.report:
        report_path = Path(args.report).resolve()
        report_path.write_text(build_html(rows, summary), encoding="utf-8")
        print(f"HTML 报告  : {report_path}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
