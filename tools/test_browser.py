r"""End-to-end browser test using Playwright + Edge.

This is a real end-to-end test: it launches a headless Edge browser, loads a
mock OA page (served by a local static server), injects the actual generated
userscript, and verifies that the captcha input gets filled with the OCR result.

NOTE on CORS:
  The real userscript uses GM_xmlhttpRequest which bypasses CORS. This test
  polyfills GM_xmlhttpRequest with plain `fetch`, which IS subject to CORS.
  We pass --disable-web-security to Edge so the test can hit the OCR service
  running on <服务器内网 IP>:1205. This flag has NO EFFECT on real users using
  the actual Tampermonkey extension.

Prerequisites:
  - Playwright + Edge installed (pip install playwright; Playwright uses
    the system Edge via `channel="msedge"`)
  - uvicorn running on 0.0.0.0:1205 with config.json trust_proxy=false
  - Static mock server running on 127.0.0.1:8001:
      python tools\mock_oa_server.py   (run this in another terminal)

Usage:
  & .\.venv\Scripts\python.exe tools\test_browser.py
"""
import os
import time
from playwright.sync_api import sync_playwright

_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT_PATH = os.path.join(_ROOT, "userscript", "local-captcha-autofill.user.js")
MOCK_URL = "http://127.0.0.1:8001/test-oa.html"
SCREENSHOT_OUT = os.path.join(_ROOT, "tools", "test-assets", "result.png")

# Selectors with Chinese placeholder, built with chr() to keep this file ASCII.
SEL_IMG = "div.captcha img"
SEL_INPUT = "input[placeholder*='" + chr(0x9a8c) + chr(0x8bc1) + chr(0x7801) + "']"

# GM polyfill - lets the userscript run as plain JS in a non-Tampermonkey context.
GM_POLYFILL = r'''
window.GM_xmlhttpRequest = function(details) {
  const f = fetch(details.url, {
    method: details.method || "GET",
    headers: details.headers || {},
    body: details.data,
  });
  f.then(r => r.text().then(text => {
    let body = text;
    try { body = JSON.parse(text); } catch (_) {}
    const fake = { status: r.status, response: body, responseText: text };
    if (details.onload) details.onload(fake);
  })).catch(e => {
    if (details.onerror) details.onerror({ error: String(e) });
  });
};
window.GM_registerMenuCommand = function(name, fn) {
  console.log("[polyfill] menu registered:", name);
  window.__menu__ = window.__menu__ || {};
  window.__menu__[name] = fn;
};
window.__warns__ = [];
const _origWarn = console.warn.bind(console);
console.warn = function(...args) {
  window.__warns__.push(args.map(a => String(a)).join(" "));
  _origWarn(...args);
};
'''


def main():
    userscript_src = open(SCRIPT_PATH, "r", encoding="utf-8-sig").read()
    print(f"userscript size: {len(userscript_src)} bytes")

    with sync_playwright() as p:
        print("[1] launching Edge (CORS disabled for test)")
        browser = p.chromium.launch(
            channel="msedge",
            headless=True,
            args=["--no-sandbox", "--disable-web-security"],
        )
        page = browser.new_page()
        page.on("console", lambda m: print(f"  [console.{m.type}] {m.text}"))

        print("[2] injecting GM polyfill as init script")
        page.add_init_script(GM_POLYFILL)

        print(f"[3] loading mock OA page: {MOCK_URL}")
        page.goto(MOCK_URL, wait_until="networkidle")
        print(f"  page title: {page.title()!r}")

        print("[4] verifying selectors")
        print(f"  {SEL_IMG} count      : {page.locator(SEL_IMG).count()}")
        print(f"  {SEL_INPUT!r} count : {page.locator(SEL_INPUT).count()}")

        print("[5] injecting userscript + waiting 3s for autoRun")
        page.add_script_tag(content=userscript_src)
        page.wait_for_timeout(3000)

        print("[6] reading input value")
        val = page.eval_on_selector(SEL_INPUT, "el => el.value")
        print(f"  input.value = {val!r}")

        print("[7] reading toast")
        toast = page.evaluate(
            "() => { const el = document.getElementById('local-captcha-ocr-tip'); return el ? el.textContent : null; }"
        )
        print(f"  toast = {toast!r}")

        print("[8] warns captured")
        warns = page.evaluate("() => window.__warns__ || []")
        for w in warns:
            print(f"  warn: {w}")

        os.makedirs(os.path.dirname(SCREENSHOT_OUT), exist_ok=True)
        page.screenshot(path=SCREENSHOT_OUT, full_page=True)
        print(f"\nscreenshot -> {SCREENSHOT_OUT}")

        browser.close()

    print("DONE")


if __name__ == "__main__":
    main()


