// ==UserScript==
// @name         土著内网验证码识别
// @icon         data:image/png;base64,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
// @namespace    http://local-captcha-ocr.internal/
// @version      0.9.1
// @description  Use an internal OCR service to recognize and fill captcha fields on every site.
// @author       Piggya
// @updateURL    https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
// @downloadURL  https://raw.githubusercontent.com/Piggya/OCR_captcha/main/userscript/local-captcha-autofill.user.js
// @match        http://*/*
// @match        https://*/*
// @connect      localhost
// @connect      127.0.0.1
// @connect      *
// @grant        GM_xmlhttpRequest
// @grant        GM_registerMenuCommand
// @grant        GM_getValue
// @grant        GM_setValue
// @grant        GM_openInTab
// ==/UserScript==

// CHANGELOG (see docs/README.md):
// 0.9.1  - LAN auto-config: when installed from the OCR server, the server
//          injects the URL + token and points @updateURL/@downloadURL back at
//          itself, so colleagues do not type either value. The public GitHub
//          copy stays token-free. Added one-click portable launchers.
// 0.9.0  - Public-release model: no token/server URL is embedded. Configure
//          once via the menu (stored in GM storage). Added @updateURL /
//          @downloadURL (GitHub) plus an in-LAN update command that opens
//          the server's /userscript.user.js. Old profile auto-detection was
//          removed.
// 0.8.5  - Hardening from TEST-REPORT-0.8.4: constant-time token compare,
//          missing-token rejection, and "add rule" prompts for captcha
//          length instead of hardcoding 4/6. Server-side fixes (base64
//          tail, debug buckets, start script) ship in the same release.
// 0.8.4  - Letter case fix: ddddocr emits lowercase letters, which broke
//          case-sensitive uppercase captchas. normalizeText now supports a
//          rule.letterCase option ("upper" | "lower" | "preserve"); the
//          default rule uses "upper". Added a per-site override plus a
//          Tampermonkey menu command to cycle case without editing code.
// 0.8.3  - Server-side release: /recognize adds time_ms; new tools/benchmark.py
//          accuracy + latency report; Swagger UI at /docs. No userscript logic
//          change; version aligned with the server.
// 0.8.2  - P17: local + colleague scripts merged into one. Auto-detects
//          the OCR server (local dev vs office production) on first run
//          and caches the choice in GM_setValue. Menu commands let you
//          switch between profiles at any time.
// 0.8.1  - P14: MutationObserver now watches src attribute changes too,
//          so clicking a captcha to refresh it triggers re-recognition.
//        - P15: HTTP 400 error now includes the server's detail field
//          in the error message for easier debugging.
//        - P16: data:image/ URLs are now re-encoded through canvas before
//          being sent to the server, stripping any CRLF corruption that
//          some sites embed in the base64 stream.
// 0.8.0  - P12: breaker changed from sessionStorage to localStorage for
//          cross-tab sharing of failure state.
//        - P13: MutationObserver auto-restarts every 60 minutes to prevent
//          observer accumulation on long-lived SPA pages.
//        - Server: ONNX thread-safety lock added to DdddOcrEngine to
//          prevent silent result corruption under concurrent requests.
//        - Server: dual-model warmup now loads both default and beta models
//          explicitly, eliminating cold-start latency on first request.
//        - Server: debug image bucket cleanup moved from per-request to a
//          periodic background task (every 30 minutes), reducing IO overhead.
// 0.7.0  - C1: divBackgroundToDataUrl supports <div style="background-image:url(...)">
//          (Element UI / iView captchas) plus background-position / background-size.
//        - C2: rotationCorrectedDataUrl undoes CSS transform:rotate before OCR.
//        - A:  setNativeValue fans out 7 DOM events and invokes the React
//          fiber's __reactProps.onChange directly (controlled component fix).
//        - B:  autoFindElements heuristic fallback (keyword + tightened size
//          envelope + nearest-input ancestry walk) so the script works on
//          arbitrary websites without per-host selectors.
//        - P8: per-host failure breaker + image fingerprint dedupe; 401/403
//          trip the breaker immediately to stop request floods.
//        - P10: MutationObserver only reacts to added image-like nodes
//          (childList only, no attribute / characterData wake-ups).
//        - Server: dual-model voting (default + beta), per-char confidence
//          gating, LRU sha256 cache, startup warm-up, bucketed debug dumps
//          (ok / low-conf / engine-err).
// 0.6.0  - findCaptchaElements walks same-origin iframes; user rule menu UI;
//          MutationObserver with 800ms debounce; default selectors extended.
// 0.5.0  - requestTimeoutMs, retry on length mismatch, click-to-recognize hook.
// 0.1.0  - initial release

(function () {
  "use strict";

  // Public release: NO token or server URL is baked in. The operator enters
  // them once (menu "设置服务器地址与 token…") and they are stored in GM
  // storage, so the same script works for any deployment and can be
  // auto-updated without exposing secrets.
  //
  // LAN install: when this file is downloaded from
  // http://<server>:1205/userscript.user.js, the server replaces the null
  // below with the current server URL and token. No manual setup is needed.
  const CFG_SERVER_KEY = "ocr_server_url";
  const CFG_TOKEN_KEY = "ocr_api_token";
  const DEFAULT_SERVER_URL = "http://127.0.0.1:1205";

  const INJECTED_CONFIG = null;

  function normalizeServerUrl(url) {
    return String(url || "").trim().replace(/\/+$/, "");
  }
  function getStoredServerUrl() {
    return normalizeServerUrl(GM_getValue(CFG_SERVER_KEY, ""));
  }
  function getStoredToken() {
    return String(GM_getValue(CFG_TOKEN_KEY, "") || "");
  }
  function hasInjectedConfig() {
    return Boolean(INJECTED_CONFIG && typeof INJECTED_CONFIG === "object");
  }
  function injectedServerUrl() {
    return hasInjectedConfig()
      ? normalizeServerUrl(INJECTED_CONFIG.serverUrl)
      : "";
  }
  function injectedToken() {
    return hasInjectedConfig()
      ? String(INJECTED_CONFIG.token || "").trim()
      : "";
  }
  // Injected values win over stored ones: after a token rotation, bumping the
  // script version makes every LAN client pick up the new token automatically.
  function effectiveServerUrl() {
    return injectedServerUrl() || getStoredServerUrl() || DEFAULT_SERVER_URL;
  }
  function effectiveToken() {
    return injectedToken() || getStoredToken();
  }
  function isConfigured() {
    return Boolean(effectiveServerUrl() && effectiveToken());
  }

  // Cache injected values so the menu still works if the script is later
  // loaded from a copy where INJECTED_CONFIG is null.
  if (hasInjectedConfig()) {
    if (injectedServerUrl()) GM_setValue(CFG_SERVER_KEY, injectedServerUrl());
    if (injectedToken()) GM_setValue(CFG_TOKEN_KEY, injectedToken());
  }

  async function probeServer(serverUrl) {
    try {
      await new Promise((resolve, reject) => {
        GM_xmlhttpRequest({
          method: "GET",
          url: normalizeServerUrl(serverUrl) + "/health",
          timeout: 3000,
          onload: (res) =>
            res.status >= 200 && res.status < 500 ? resolve() : reject(),
          onerror: () => reject(),
          ontimeout: () => reject(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  async function promptForServerConfig(force) {
    if (!force && isConfigured()) return true;
    const enteredUrl = prompt(
      "OCR 服务器地址（例如 http://192.168.1.100:1205）",
      effectiveServerUrl()
    );
    if (enteredUrl === null) return false;
    const enteredToken = prompt(
      "OCR 访问 token（向管理员索取）",
      effectiveToken()
    );
    if (enteredToken === null) return false;
    const serverUrl = normalizeServerUrl(enteredUrl);
    const token = String(enteredToken).trim();
    if (!serverUrl || !token) {
      alert("服务器地址或 token 不能为空。");
      return false;
    }
    if (!(await probeServer(serverUrl))) {
      if (!confirm("无法连接该服务器（/health 无响应），仍要保存配置吗？")) {
        return false;
      }
    }
    GM_setValue(CFG_SERVER_KEY, serverUrl);
    GM_setValue(CFG_TOKEN_KEY, token);
    CONFIG.serverUrl = serverUrl;
    CONFIG.token = token;
    notify("服务器配置已保存：" + serverUrl);
    return true;
  }

  function showCurrentServer() {
    if (!isConfigured()) {
      notify("尚未配置服务器，请使用菜单「设置服务器地址与 token…」");
      return;
    }
    notify(`当前服务器: ${CONFIG.serverUrl}`);
  }

  // Isolated-LAN update path: the OCR server also hosts the script at
  // /userscript.user.js. Opening it lets Tampermonkey offer an update even
  // when github.com is unreachable.
  function openServerUserscript() {
    const serverUrl = injectedServerUrl() || getStoredServerUrl();
    if (!serverUrl) {
      notify("尚未配置服务器地址");
      return;
    }
    GM_openInTab(serverUrl + "/userscript.user.js", {
      active: true,
      insert: true,
    });
  }

  const CONFIG = {
    serverUrl: effectiveServerUrl(),
    token: effectiveToken(),
    autoRun: true,
    retryAfterRefreshMs: 800,
    rules: [
      {
        host: "*",
        // SECURITY WARNING: host:"*" makes the script attempt OCR on every website.
        // Change host to your company domain (e.g. "oa.company.local") to limit
        // it to just your OA, or use GM_registerMenuCommand → "为本网站添加规则..."
        // to persist a per-host override in browser storage.
        imageSelector: [
          "img.captcha",
          "img[id*='captcha' i]",
          "img[class*='captcha' i]",
          "img[id*='verify' i]",
          "img[class*='verify' i]",
          "img[id*='vcode' i]",
          "img[class*='vcode' i]",
          "img[id*='yzm' i]",
          "img[class*='yzm' i]",
          "img[id*='kaptcha' i]",
          "img[class*='kaptcha' i]",
          "img[id*='secCode' i]",
          "img[id*='verifyCode' i]",
          "img[id*='authcode' i]",
          ".yzm img",
          ".kaptcha img",
          "#captchaImg",
          "#captcha",
          "img[alt*='captcha' i]",
          "img[src*='captcha' i]",
          "div.captcha > img",
          ".captcha > img",
          // C1: div with background-image (Element UI / iView etc.)
          "div.captcha[style*='background-image']",
          "div[class*='captcha' i][style*='background-image']",
          "div[id*='captcha' i][style*='background-image']",
        ].join(","),
        inputSelector: [
          "input[name*='captcha' i]",
          "input[id*='captcha' i]",
          "input[class*='captcha' i]",
          "input[name*='verify' i]",
          "input[id*='verify' i]",
          "input[class*='verify' i]",
          "input[name*='vcode' i]",
          "input[id*='vcode' i]",
          "input[class*='vcode' i]",
          "input[name*='yzm' i]",
          "input[id*='yzm' i]",
          "input[class*='yzm' i]",
          "input[name*='kaptcha' i]",
          "input[id*='kaptcha' i]",
          "input[class*='kaptcha' i]",
          "input[id*='verifyCode' i]",
          "input[id*='authcode' i]",
          ".yzm input",
          ".kaptcha input",
          "#captchaCode",
          "input[placeholder*='验证码']",
          "input[placeholder*='captcha' i]",
          "input[placeholder*='verify' i]",
          "input[placeholder*='vcode' i]",
          "input[placeholder*='yzm' i]",
          ".el-input__inner[placeholder*='验证码']",
        ].join(","),
        refreshSelector: [
          "img.captcha",
          "img[id*='captcha' i]",
          "img[class*='captcha' i]",
          "img[id*='verify' i]",
          "img[class*='verify' i]",
          "img[id*='vcode' i]",
          "img[class*='vcode' i]",
          "img[id*='yzm' i]",
          "img[class*='yzm' i]",
          "img[id*='kaptcha' i]",
          "img[class*='kaptcha' i]",
          "#captchaImg",
          "#captcha",
          "img[alt*='captcha' i]",
          "img[src*='captcha' i]",
          "div.captcha > img",
          ".captcha > img",
          "div.captcha[style*='background-image']",
          "div[class*='captcha' i][style*='background-image']",
          "div[id*='captcha' i][style*='background-image']",
        ].join(","),
        minLength: 4,
        maxLength: 6,
        maxAttempts: 5,
        requestTimeoutMs: 10000,
        // P8: any character below this confidence is treated as suspect
        // and not auto-filled. Set to 0 to always trust the engine result.
        minConfidence: 0.55,
        // ddddocr emits lowercase letters, but this OA's captcha is shown in
        // uppercase and validated case-sensitively. Apply case client-side.
        // Toggle per-site from the Tampermonkey menu if a site differs.
        letterCase: "upper",
      },
    ],
  };

  // Read user-added rules stored via GM_setValue. User rules take precedence
  // over the default CONFIG.rules so the operator can teach the script a
  // new captcha layout via the Tampermonkey menu without editing the file.
  function getUserRules() {
    try { return JSON.parse(GM_getValue("userRules", "[]")); }
    catch (_) { return []; }
  }
  function saveUserRules(rules) {
    GM_setValue("userRules", JSON.stringify(rules));
  }

  function getCaseOverrides() {
    try { return JSON.parse(GM_getValue("caseOverrides", "{}")); }
    catch (_) { return {}; }
  }
  function getCaseOverride(host) {
    return getCaseOverrides()[host] || null;
  }
  function setCaseOverride(host, value) {
    const m = getCaseOverrides();
    m[host] = value;
    GM_setValue("caseOverrides", JSON.stringify(m));
  }

  function getRule() {
    const host = window.location.hostname;
    const userRules = getUserRules();
    const all = [].concat(userRules, CONFIG.rules);
    const rule = all.find((r) => {
      if (r.host instanceof RegExp) return r.host.test(host);
      if (r.host === "*") return true;
      return String(r.host).toLowerCase() === host.toLowerCase();
    });
    if (!rule) return rule;
    const override = getCaseOverride(host);
    if (override) return Object.assign({}, rule, { letterCase: override });
    return rule;
  }

  function notify(message) {
    const id = "local-captcha-ocr-tip";
    let el = document.getElementById(id);
    if (!el) {
      el = document.createElement("div");
      el.id = id;
      el.style.cssText = [
        "position:fixed",
        "right:16px",
        "bottom:16px",
        "z-index:2147483647",
        "background:#202124",
        "color:#fff",
        "font:13px/1.4 Arial,sans-serif",
        "padding:8px 10px",
        "border-radius:6px",
        "box-shadow:0 4px 16px rgba(0,0,0,.25)",
        "max-width:320px"
      ].join(";");
      document.documentElement.appendChild(el);
    }
    el.textContent = message;
    window.clearTimeout(notify.timer);
    notify.timer = window.setTimeout(() => el.remove(), 3000);
  }

  function toAbsoluteUrl(url) {
    if (!url) return "";
    return new URL(url, window.location.href).href;
  }

  function canvasToDataUrl(canvas) {
    return canvas.toDataURL("image/png");
  }

  function imageElementToDataUrl(img) {
    return new Promise((resolve, reject) => {
      const canvas = document.createElement("canvas");
      const width = img.naturalWidth || img.width;
      const height = img.naturalHeight || img.height;
      if (!width || !height) {
        reject(new Error("captcha image has no size"));
        return;
      }
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext("2d");
      try {
        ctx.drawImage(img, 0, 0, width, height);
        resolve(canvas.toDataURL("image/png"));
      } catch (error) {
        reject(error);
      }
    });
  }

  // C2: undo CSS transform:rotate so the captured pixels match the user's
  // visual perception of the captcha. Returns null if no rotation is
  // present so callers can keep the original (faster) data URL.
  function rotationCorrectedDataUrl(img) {
    try {
      const style = window.getComputedStyle(img);
      const transform = style && style.transform;
      if (!transform || transform === "none") return null;
      const matrix = new DOMMatrixReadOnly(transform);
      const angle = Math.round(Math.atan2(matrix.b, matrix.a) * (180 / Math.PI));
      if (!angle) return null;
      const w = img.naturalWidth || img.width;
      const h = img.naturalHeight || img.height;
      if (!w || !h) return null;
      const canvas = document.createElement("canvas");
      canvas.width = w;
      canvas.height = h;
      const ctx = canvas.getContext("2d");
      ctx.translate(w / 2, h / 2);
      ctx.rotate(-angle * Math.PI / 180);
      ctx.drawImage(img, -w / 2, -h / 2, w, h);
      return canvas.toDataURL("image/png");
    } catch (_) {
      return null;
    }
  }

  function fetchImageAsDataUrl(src) {
    return new Promise((resolve, reject) => {
      GM_xmlhttpRequest({
        method: "GET",
        url: toAbsoluteUrl(src),
        responseType: "blob",
        onload: (response) => {
          if (response.status < 200 || response.status >= 300) {
            reject(new Error(`image request failed: ${response.status}`));
            return;
          }
          const reader = new FileReader();
          reader.onloadend = () => resolve(String(reader.result));
          reader.onerror = () => reject(new Error("failed to read image blob"));
          reader.readAsDataURL(response.response);
        },
        onerror: () => reject(new Error("failed to fetch image"))
      });
    });
  }

  function parseLengthPair(value) {
    if (!value) return null;
    const parts = String(value).trim().split(/\s+/);
    if (parts.length < 2) return null;
    const x = parseFloat(parts[0]);
    const y = parseFloat(parts[1]);
    if (!isFinite(x) || !isFinite(y)) return null;
    return { x, y };
  }

  // C1: <div style="background-image:url(...)"> captchas (Element UI etc.).
  // We replicate the visible region onto a canvas, honouring background-position
  // and background-size, then export PNG. The remote URL is fetched through
  // GM_xmlhttpRequest to dodge canvas cross-origin tainting.
  async function divBackgroundToDataUrl(element) {
    const style = window.getComputedStyle(element);
    const bg = style.backgroundImage;
    const match = bg && bg.match(/url\(["']?(.+?)["']?\)/);
    if (!match) throw new Error("captcha element has no background image");
    const url = match[1];
    const dataUrl = url.startsWith("data:image/")
      ? url
      : await fetchImageAsDataUrl(url);

    const w = parseFloat(style.width) || element.offsetWidth || 0;
    const h = parseFloat(style.height) || element.offsetHeight || 0;
    if (!w || !h) throw new Error("captcha div has no size");

    return new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        try {
          const canvas = document.createElement("canvas");
          canvas.width = w;
          canvas.height = h;
          const ctx = canvas.getContext("2d");
          const pos = parseLengthPair(style.backgroundPosition) || { x: 0, y: 0 };
          const size = parseLengthPair(style.backgroundSize);
          const drawW = size ? size.x : img.width;
          const drawH = size ? size.y : img.height;
          ctx.drawImage(img, pos.x, pos.y, drawW, drawH);
          resolve(canvas.toDataURL("image/png"));
        } catch (e) {
          reject(e);
        }
      };
      img.onerror = () => reject(new Error("failed to load background image"));
      img.src = dataUrl;
    });
  }

  // elementToDataUrl is the wrapper that knows how to extract a captcha
  // image from a canvas / img / input / background-image element.
  async function elementToDataUrl(element) {
    const tag = element.tagName.toLowerCase();
    if (tag === "canvas") {
      return canvasToDataUrl(element);
    }
    if (tag === "img" || tag === "input") {
      const src = element.currentSrc || element.src || element.getAttribute("src");
      if (src && src.startsWith("data:image/")) {
        // Use canvas to re-encode the image, bypassing any CRLF corruption
        // in the raw data URL that the browser already decoded.
        const drawn = await imageElementToDataUrl(element);
        const rotated = tag === "img" ? rotationCorrectedDataUrl(element) : null;
        return rotated || drawn;
      }
      try {
        const drawn = await imageElementToDataUrl(element);
        const rotated = tag === "img" ? rotationCorrectedDataUrl(element) : null;
        return rotated || drawn;
      } catch (_) {
        return fetchImageAsDataUrl(src);
      }
    }
    // C1: <div> with background-image (Element UI / iView).
    return divBackgroundToDataUrl(element);
  }

  // A1: Look for the captcha image + input in the given document root, and
  // recursively walk into same-origin iframes. Cross-origin iframes throw on
  // contentDocument access and are silently skipped.
  function findCaptchaElements(root) {
    root = root || document;
    const rule = getRule();
    if (!rule) return null;
    let imageEl = null, inputEl = null;
    try {
      imageEl = root.querySelector(rule.imageSelector);
      inputEl = root.querySelector(rule.inputSelector);
    } catch (_) { /* selector invalid, skip */ }
    if (imageEl && inputEl) return { imageEl, inputEl, frame: root };
    const iframes = root.querySelectorAll("iframe");
    for (const iframe of iframes) {
      let doc = null;
      try { doc = iframe.contentDocument || (iframe.contentWindow && iframe.contentWindow.document); }
      catch (_) { doc = null; }
      if (!doc) continue;
      const found = findCaptchaElements(doc);
      if (found) return found;
    }
    return null;
  }

  // B: heuristic discovery for sites that match no explicit selector.
  // Walk every captcha-shaped element on the page, score it by attribute
  // keywords + a tightened size envelope, and pair it with the nearest
  // <input type=text> in its DOM ancestry.
  const HEURISTIC_KEYWORDS = [
    "captcha", "verify", "vcode", "yzm", "kaptcha", "seccode", "verifycode",
    "authcode", "checkcode", "randcode",
    "验证码", "看不清", "换一张"
  ];
  const HEURISTIC_BLACKLIST = ["logo", "avatar", "icon-", "qrcode", "banner", "ad-"];

  function getCaptchaFeatures(el) {
    if (!el || !el.getAttribute) return [];
    return [
      el.id || "",
      typeof el.className === "string" ? el.className : "",
      el.getAttribute("alt") || "",
      el.getAttribute("src") || "",
      el.getAttribute("name") || "",
      el.getAttribute("title") || "",
      el.getAttribute("placeholder") || ""
    ].filter(Boolean);
  }

  function looksLikeCaptcha(el) {
    const tag = el.tagName.toLowerCase();
    const style = window.getComputedStyle(el);
    if (style.visibility === "hidden" || style.display === "none") return false;
    const w = parseFloat(style.width) || el.offsetWidth || 0;
    const h = parseFloat(style.height) || el.offsetHeight || 0;
    // P10: tighter bounds. Real captcha images are almost always
    // 60x25 .. 180x70. Wider envelopes matched ad slots, hero banners
    // and share buttons - exactly the false positives that triggered
    // the 401 storm earlier.
    if (w < 60 || w > 200 || h < 25 || h > 80) return false;
    const ratio = w / Math.max(h, 1);
    if (ratio < 1.4 || ratio > 7) return false;
    if (tag === "img") {
      const src = el.getAttribute("src") || "";
      if (!src || src === "#" || src === "about:blank") return false;
    }
    if (tag === "div" && style.backgroundImage === "none") return false;

    const features = [
      ...getCaptchaFeatures(el),
      ...getCaptchaFeatures(el.parentElement || {})
    ].join(" ").toLowerCase();
    if (!features) return false;
    if (HEURISTIC_BLACKLIST.some((bad) => features.includes(bad))) return false;
    return HEURISTIC_KEYWORDS.some((kw) => features.includes(kw.toLowerCase()));
  }

  function findNearbyInput(imgEl) {
    let parent = imgEl.parentElement;
    for (let i = 0; i < 4 && parent; i++) {
      const inputs = parent.querySelectorAll("input");
      for (const input of inputs) {
        const type = (input.getAttribute("type") || "text").toLowerCase();
        if (type === "password") return null; // captchas come before passwords
        const w = parseFloat(window.getComputedStyle(input).width) || input.offsetWidth || 0;
        if ((type === "text" || !type) && w > 50) return input;
      }
      parent = parent.parentElement;
    }
    return null;
  }

  function autoFindElements() {
    const candidates = document.querySelectorAll(
      "img, canvas, input[type='image'], div"
    );
    for (const el of candidates) {
      if (!looksLikeCaptcha(el)) continue;
      const input = findNearbyInput(el);
      if (input) return { imageEl: el, inputEl: input };
    }
    return null;
  }

  // P8: per-host failure breaker. State is kept in localStorage (cross-tab
  // shared) so all tabs on the same hostname honour a single breaker state.
  const BREAKER_MAX = 5;
  const BREAKER_TTL_MS = 60 * 60 * 1000;
  const BREAKER_WINDOW_MS = 5 * 60 * 1000;
  // P8: Per-host failure breaker using localStorage (cross-tab shared).
  // A single tab's repeated failures trip the breaker for all tabs on the
  // same hostname, preventing parallel request storms when OCR is failing.
  function breakerKey() {
    return "ocr_breaker:" + window.location.hostname;
  }
  function isBreakerOpen() {
    try {
      const raw = localStorage.getItem(breakerKey());
      if (!raw) return false;
      const data = JSON.parse(raw);
      if (data.openedAt && Date.now() - data.openedAt < BREAKER_TTL_MS) {
        if (!window.__ocrBreakerNotified) {
          window.__ocrBreakerNotified = true;
          console.warn(
            "[Local Captcha OCR] Breaker open for " + window.location.hostname +
            "; OCR disabled for this host until " +
            new Date(data.openedAt + BREAKER_TTL_MS).toLocaleTimeString()
          );
        }
        return true;
      }
      localStorage.removeItem(breakerKey());
      return false;
    } catch (_) { return false; }
  }
  function recordFailure(reason) {
    try {
      const raw = localStorage.getItem(breakerKey());
      const data = raw ? JSON.parse(raw) : { failures: [] };
      const now = Date.now();
      data.failures = (data.failures || []).filter((t) => now - t < BREAKER_WINDOW_MS);
      data.failures.push(now);
      if (data.failures.length >= BREAKER_MAX) {
        data.openedAt = now;
        notify("识别多次失败，已暂停 1 小时（菜单可手动重置）");
        console.warn("[Local Captcha OCR] Breaker tripped:", reason);
      }
      localStorage.setItem(breakerKey(), JSON.stringify(data));
    } catch (_) {}
  }
  function recordSuccess() {
    try { localStorage.removeItem(breakerKey()); } catch (_) {}
  }
  function resetBreaker() {
    try {
      localStorage.removeItem(breakerKey());
      window.__ocrBreakerNotified = false;
      notify("断路器已重置，本网站恢复识别");
    } catch (_) {}
  }

  // P10: MutationObserver only fires on added image-like nodes (childList
  // only, no attribute / characterData wake-ups). The previous broad
  // observer caused feedback loops on sites that re-render input
  // attributes on focus / animate refresh icons.
  //
  // To prevent memory leaks on long-lived SPA pages, the observer is
  // disconnected and re-created every 60 minutes.
  const MUTATION_OBSERVER_RESTART_MS = 60 * 60 * 1000;
  function setupMutationObserver() {
    if (window.__ocrMutationInstalled) return;
    if (!getRule()) return;
    window.__ocrMutationInstalled = true;
    let timer = null;
    const isImagey = (el) => {
      if (!el || el.nodeType !== 1) return false;
      const tag = el.tagName ? el.tagName.toLowerCase() : "";
      if (tag === "img" || tag === "canvas") return true;
      if (tag === "div" || tag === "span") {
        const style = el.getAttribute && el.getAttribute("style");
        if (style && /background-image\s*:/i.test(style)) return true;
      }
      return el.querySelector && !!el.querySelector("img, canvas");
    };
    let obs = null;
    function startObserver() {
      if (obs) obs.disconnect();
      obs = new MutationObserver((mutations) => {
        let relevant = false;
        for (const m of mutations) {
          if (m.type === "childList") {
            for (const node of m.addedNodes) {
              if (isImagey(node)) { relevant = true; break; }
            }
          } else if (m.type === "attributes") {
            if (m.attributeName === "src" && isImagey(m.target)) {
              relevant = true;
            }
          }
          if (relevant) break;
        }
        if (!relevant) return;
        if (timer) clearTimeout(timer);
        timer = setTimeout(() => {
          if (window.__ocrInFlight) return;
          recognizeAndFill();
        }, 800);
      });
      const target = document.body || document.documentElement;
      if (target) {
        obs.observe(target, { childList: true, subtree: true, attributes: true, attributeFilter: ["src"] });
      }
    }
    startObserver();
    // Periodic restart to avoid observer accumulation on long-lived pages
    window.setInterval(startObserver, MUTATION_OBSERVER_RESTART_MS);
  }

  // Click on the captcha image -> auto re-recognize. Used for both the
  // user's manual refresh clicks and the retry path.
  function setupCaptchaClickHook(rule) {
    const refreshEl = rule.refreshSelector
      ? document.querySelector(rule.refreshSelector)
      : document.querySelector(rule.imageSelector);
    if (!refreshEl) return;
    if (refreshEl.__ocrHookInstalled) return;
    refreshEl.__ocrHookInstalled = true;

    const refreshMs = rule.retryAfterRefreshMs || CONFIG.retryAfterRefreshMs || 800;
    let pendingClick = null;
    refreshEl.addEventListener("click", () => {
      if (window.__ocrScriptRefreshing) return;
      if (pendingClick) window.clearTimeout(pendingClick);
      pendingClick = window.setTimeout(() => {
        pendingClick = null;
        recognizeAndFill();
      }, refreshMs);
    });
  }

  // A: setNativeValue fans out 7 DOM events and invokes the React fiber's
  // __reactProps.onChange directly. Required for controlled components
  // (Element UI / iView / formik / custom React wrappers) where the
  // native setter alone does not propagate.
  function setNativeValue(input, value) {
    const prototype = Object.getPrototypeOf(input);
    const descriptor = Object.getOwnPropertyDescriptor(prototype, "value");
    if (descriptor && descriptor.set) {
      descriptor.set.call(input, value);
    } else {
      input.value = value;
    }
    const eventNames = ["input", "change", "keydown", "keypress", "keyup", "blur", "focus"];
    for (const name of eventNames) {
      try { input.dispatchEvent(new Event(name, { bubbles: true })); }
      catch (_) {}
    }
    try {
      const reactKey = Object.keys(input).find(
        (k) => k.startsWith("__reactProps$") || k.startsWith("__reactEventHandlers$")
      );
      if (reactKey && typeof input[reactKey].onChange === "function") {
        input[reactKey].onChange({
          target: input,
          currentTarget: input,
          type: "change",
          bubbles: true,
          cancelable: true,
          preventDefault() {},
          stopPropagation() {},
          persist() {}
        });
      }
    } catch (_) {}
  }

  function normalizeText(text, rule) {
    let result = text.replace(/\s+/g, "");
    if (rule.charset) {
      const allowed = new RegExp(`[^${rule.charset}]`, "g");
      result = result.replace(allowed, "");
    }
    // ddddocr cannot reliably preserve letter case (it tends to emit
    // lowercase), so case is applied per-site here. Precedence:
    //   rule.letterCase ("upper" | "lower" | "preserve") > legacy
    //   rule.uppercase / rule.lowercase > preserve.
    const mode = rule.letterCase
      || (rule.uppercase ? "upper" : (rule.lowercase ? "lower" : "preserve"));
    if (mode === "upper") result = result.toUpperCase();
    else if (mode === "lower") result = result.toLowerCase();
    return result;
  }

  function requestOcr(image, rule) {
    return new Promise((resolve, reject) => {
      const timeoutMs = rule.requestTimeoutMs || 10000;
      const timer = setTimeout(
        () => reject(new Error(`OCR 请求超时，${timeoutMs}ms 内未响应（检查网络、防火墙、代理）`)),
        timeoutMs
      );

      GM_xmlhttpRequest({
        method: "POST",
        url: `${CONFIG.serverUrl.replace(/\/+$/, "")}/recognize`,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "X-API-Token": CONFIG.token
        },
        data: JSON.stringify({
          image,
          kind: rule.kind || "text",
          site: window.location.host
        }),
        responseType: "json",
        onload: (response) => {
          clearTimeout(timer);
          let body = response.response;
          if (typeof body === "string") {
            try { body = JSON.parse(body); } catch (_) { body = null; }
          }
          if (!body && response.responseText) {
            try { body = JSON.parse(response.responseText); } catch (_) {}
          }
          if (response.status < 200 || response.status >= 300) {
            // P8: 401/403 are persistent configuration errors. Trip the
            // breaker immediately so we don't flood the server while the
            // user fixes the token / IP whitelist.
            if (response.status === 401 || response.status === 403) {
              for (let i = 0; i < BREAKER_MAX; i++) {
                try { recordFailure("HTTP " + response.status); } catch (_) {}
              }
            }
            const detail = (body && body.detail) ? `: ${body.detail}` : "";
            reject(new Error(`OCR service returned ${response.status}${detail}`));
            return;
          }
          if (!body || !body.ok) {
            reject(new Error((body && body.error) || "OCR failed"));
            return;
          }
          resolve({
            text: String(body.text || "").trim(),
            confidence: typeof body.confidence === "number" ? body.confidence : 1.0,
            engine: body.engine || "ddddocr",
            cached: !!body.cached,
          });
        },
        onerror: (err) => {
          clearTimeout(timer);
          const detail = err && err.error ? ` (${err.error})` : "";
          reject(new Error(`OCR service is not reachable${detail}`));
        }
      });
    });
  }

  async function recognizeAndFill() {
    if (!CONFIG.token) {
      // Prompt at most once automatically (the menu can always re-open the
      // settings). Prevents the MutationObserver from spamming prompts.
      if (GM_getValue("ocr_prompted", false)) return;
      GM_setValue("ocr_prompted", true);
      const configured = await promptForServerConfig(true);
      if (!configured) return;
    }
    const rule = getRule();
    if (!rule) return;
    if (isBreakerOpen()) return;

    // Try the rule's selectors first, then fall back to heuristic discovery.
    let found = findCaptchaElements();
    if (!found) {
      const auto = autoFindElements();
      if (!auto) return;
      try {
        auto.imageEl.style.outline = "2px solid #f44";
        auto.inputEl.style.outline = "1px solid #f44";
      } catch (_) {}
      found = auto;
    }
    const imageElement = found.imageEl;
    const inputElement = found.inputEl;

    setupCaptchaClickHook(rule);

    // P8: dedupe. MutationObserver / click hook / auto-run can each kick
    // off recognizeAndFill against the same image. Tag with the src
    // signature; if we already filled this exact image in this tab, skip.
    const fingerprint = imageElement.getAttribute("src") || "";
    if (fingerprint && imageElement.dataset.ocrLastFilled === fingerprint) {
      return;
    }

    const minOk = rule.minLength || 0;
    const maxOk = rule.maxLength || Infinity;
    const maxAttempts = rule.maxAttempts || 3;
    const refreshMs = rule.retryAfterRefreshMs || CONFIG.retryAfterRefreshMs || 800;
    const minConf = typeof rule.minConfidence === "number" ? rule.minConfidence : 0;

    let lastError = null;
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        if (attempt === 1) {
          notify("正在本地识别验证码...");
        } else {
          notify(`识别结果不合长度，刷新重试 (${attempt}/${maxAttempts})...`);
        }
        const image = await elementToDataUrl(imageElement);
        const result = await requestOcr(image, rule);
        const text = normalizeText(result.text, rule);
        if (text.length < minOk) throw new Error(`识别结果过短: ${text}`);
        if (text.length > maxOk) throw new Error(`识别结果过长: ${text}`);
        if (result.confidence < minConf) {
          throw new Error(`置信度过低 ${result.confidence.toFixed(2)} < ${minConf}: ${text}`);
        }
        setNativeValue(inputElement, text);
        const tag = result.cached ? "缓存" : (result.engine || "ocr");
        notify(`验证码已填入: ${text} [${tag} ${result.confidence.toFixed(2)}]`);
        try {
          imageElement.dataset.ocrLastFilled = fingerprint;
          recordSuccess();
        } catch (_) {}
        return;
      } catch (error) {
        lastError = error;
        console.warn("[Local Captcha OCR]", error);
        if (attempt < maxAttempts) {
          const refreshEl = rule.refreshSelector
            ? document.querySelector(rule.refreshSelector)
            : imageElement;
          if (refreshEl) {
            window.__ocrScriptRefreshing = true;
            try { refreshEl.click(); }
            finally {
              window.setTimeout(() => { window.__ocrScriptRefreshing = false; }, refreshMs);
            }
            await new Promise(r => window.setTimeout(r, refreshMs));
          }
        }
      }
    }
    notify(`验证码识别失败: ${lastError ? lastError.message : "未知错误"}`);
    recordFailure(lastError ? lastError.message : "");
  }

  function refreshAndRecognize() {
    const rule = getRule();
    if (!rule) return;
    const refreshElement = rule.refreshSelector
      ? document.querySelector(rule.refreshSelector)
      : document.querySelector(rule.imageSelector);
    if (refreshElement) refreshElement.click();
    window.setTimeout(recognizeAndFill, rule.retryAfterRefreshMs || CONFIG.retryAfterRefreshMs);
  }

  // ---- User rules UI -----------------------------------------------
  function promptUserRule() {
    const host = window.location.hostname;
    const imageSel = prompt("验证码图片的 CSS selector（多个用逗号分隔）：", "");
    if (imageSel === null) return;
    const inputSel = prompt("验证码输入框的 CSS selector（多个用逗号分隔）：", "");
    if (inputSel === null) return;
    const minLenRaw = prompt("验证码最小长度：", "4");
    if (minLenRaw === null) return;
    const maxLenRaw = prompt("验证码最大长度：", "6");
    if (maxLenRaw === null) return;
    const toLen = (value, fallback, lowerBound) => {
      const n = parseInt(value, 10);
      return Number.isFinite(n) && n >= lowerBound ? n : fallback;
    };
    const minLength = toLen(minLenRaw, 4, 1);
    let maxLength = toLen(maxLenRaw, 6, minLength);
    if (maxLength < minLength) maxLength = minLength;
    const split = (s) => s.split(",").map((x) => x.trim()).filter(Boolean);
    const rule = {
      host,
      imageSelector: split(imageSel).join(","),
      inputSelector: split(inputSel).join(","),
      refreshSelector: split(imageSel).join(","),
      minLength,
      maxLength,
    };
    const rules = getUserRules();
    rules.push(rule);
    saveUserRules(rules);
    notify("已保存规则：" + host);
  }
  function listUserRulesForHost() {
    const host = window.location.hostname;
    const rules = getUserRules().filter((r) => r.host === host);
    if (rules.length === 0) { alert("当前网站（" + host + "）没有用户规则。"); return; }
    const txt = rules.map((r, i) =>
      "[" + (i + 1) + "]  image: " + r.imageSelector + "\n     input:  " + r.inputSelector
    ).join("\n\n");
    alert("当前网站的用户规则：\n\n" + txt);
  }
  function clearUserRulesForHost() {
    const host = window.location.hostname;
    if (!confirm("删除当前网站（" + host + "）的所有用户规则？")) return;
    const others = getUserRules().filter((r) => r.host !== host);
    saveUserRules(others);
    notify("当前网站规则已删除");
  }
  function clearAllUserRules() {
    if (!confirm("清空所有用户规则？（会删除所有网站）")) return;
    saveUserRules([]);
    notify("已清空所有用户规则");
  }

  // Cycle the letter case for the current site: 大写 → 小写 → 原样 → 大写.
  // Stored as a per-host override so operators can fix a case-sensitive
  // captcha without editing the script. Re-runs recognition afterwards.
  function cycleCaseForHost() {
    const host = window.location.hostname;
    const order = ["upper", "lower", "preserve"];
    const labels = { upper: "大写", lower: "小写", preserve: "保持原样" };
    const current = getCaseOverride(host)
      || (getRule() && getRule().letterCase)
      || "preserve";
    const next = order[(order.indexOf(current) + 1) % order.length];
    setCaseOverride(host, next);
    notify(`本网站验证码大小写: ${labels[next]}（${host}）`);
    setTimeout(() => { try { recognizeAndFill(); } catch (_) {} }, 50);
  }

  GM_registerMenuCommand("识别并填入验证码", recognizeAndFill);
  GM_registerMenuCommand("刷新验证码后识别", refreshAndRecognize);
  GM_registerMenuCommand("切换验证码大小写（大写/小写/原样）", cycleCaseForHost);
  GM_registerMenuCommand("重置本网站断路器", resetBreaker);
  GM_registerMenuCommand("为本网站添加规则...", promptUserRule);
  GM_registerMenuCommand("查看本网站规则", listUserRulesForHost);
  GM_registerMenuCommand("删除本网站规则", clearUserRulesForHost);
  GM_registerMenuCommand("清空所有用户规则", clearAllUserRules);
  GM_registerMenuCommand("--- 服务器 ---", () => {});
  GM_registerMenuCommand("设置服务器地址与 token…", () => promptForServerConfig(true));
  GM_registerMenuCommand("查看当前服务器", showCurrentServer);
  GM_registerMenuCommand("从服务器更新脚本（内网）", openServerUserscript);

  if (CONFIG.autoRun) {
    const boot = () => {
      window.setTimeout(async () => {
        if (!isConfigured()) {
          // Ask once; the operator can always configure later from the menu.
          if (!GM_getValue("ocr_prompted", false)) {
            GM_setValue("ocr_prompted", true);
            await promptForServerConfig(true);
          }
        }
        const rule = getRule();
        if (rule) setupCaptchaClickHook(rule);
        setupMutationObserver();
        if (CONFIG.token) recognizeAndFill();
      }, 300);
    };
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", boot);
    } else {
      boot();
    }
  }
})();

