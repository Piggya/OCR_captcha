// ==UserScript==
// @name         土著内网验证码识别
// @icon         data:image/png;base64,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
// @namespace    http://local-captcha-ocr.internal/
// @version      0.11.1
// @description  Use a LAN OCR service to recognize and fill captcha fields on every site.
// @description:zh-CN  自托管局域网验证码识别：OCR 自动识别并填入验证码。需自行部署服务端（GitHub 提供 Windows 便携包）。
// @author       Piggya
// @license      MIT
// @homepageURL  https://github.com/Piggya/OCR_captcha
// @supportURL   https://github.com/Piggya/OCR_captcha/issues
// @source       https://github.com/Piggya/OCR_captcha
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
// 0.11.1 - Never ship the .lnk: OCR-Panel.bat rebuilds it on first run.
// 0.11.0 - Repo layout: user-facing .bat files moved to launchers\; panel update progress.
// 0.10.2 - Control panel: redesigned card-based UI (status pill, rounded cards, pill buttons).
// 0.10.1 - Control panel: colored status badge, full connection info with
//          copy buttons, silent launch and a taskbar icon.
// 0.10.0 - New menu item "切换本站识别（开/关）": enable/disable captcha
//          recognition for the current site only (remembered per hostname).
// 0.9.5  - Wording cleanup: use LAN / LAN devices / business systems
//          consistently. Menu item renamed to "OCR 服务器设置" and
//          "从 OCR 服务器更新脚本" (script only, not the server).
// 0.9.4  - Shortened the Tampermonkey menu to five items; site rules, case
//          switching and breaker reset moved into a "高级功能" dialog.
//          Added Show-OCR-Info.bat (server URL + token + install URL,
//          copied to the clipboard).
// 0.9.3  - Replaced the two prompt() boxes with a proper settings dialog
//          (server URL + token, test connection, save). Opened from the
//          Tampermonkey menu. No OCR behavior change.
// 0.9.2  - Added Update-OCR.bat (one-click in-place update, preserves
//          server/config.json and python/, backs up before replacing).
//          Added GreasyFork-friendly metadata (@license, @homepageURL,
//          @supportURL, @source, @description:zh-CN). No OCR behavior change.
// 0.9.1  - LAN auto-config: when installed from the OCR server, the server
//          injects the URL + token and points @updateURL/@downloadURL back at
//          itself, so LAN devices do not type either value. The public GitHub
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
// 0.8.2  - P17: local + LAN device scripts merged into one. Auto-detects
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
  // them once (menu "OCR 服务器设置…") and they are stored in GM
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

  // Per-site master switch: the operator can turn recognition off for the
  // current host from the Tampermonkey menu (e.g. a site where the script
  // misfires). State lives in GM storage, keyed by hostname.
  const CFG_DISABLED_HOSTS_KEY = "ocr_disabled_hosts";

  function getDisabledHosts() {
    let map = null;
    try {
      map = GM_getValue(CFG_DISABLED_HOSTS_KEY, null);
    } catch (_) {
      map = null;
    }
    if (!map || typeof map !== "object" || Array.isArray(map)) return {};
    return map;
  }
  function isHostDisabled(host) {
    const key = String(host || "").toLowerCase();
    if (!key) return false;
    return Boolean(getDisabledHosts()[key]);
  }
  function isCurrentSiteDisabled() {
    return isHostDisabled(window.location.hostname);
  }
  function setCurrentSiteDisabled(disabled) {
    const map = getDisabledHosts();
    const host = String(window.location.hostname || "").toLowerCase();
    if (!host) return;
    if (disabled) {
      map[host] = true;
    } else {
      delete map[host];
    }
    try {
      GM_setValue(CFG_DISABLED_HOSTS_KEY, map);
    } catch (_) {
      /* storage unavailable: the switch simply will not persist */
    }
  }
  function toggleCurrentSiteRecognition() {
    const disabled = !isCurrentSiteDisabled();
    setCurrentSiteDisabled(disabled);
    notify(disabled ? "已关闭本站验证码识别" : "已开启本站验证码识别");
    if (!disabled) {
      window.setTimeout(() => {
        try {
          recognizeAndFill();
        } catch (_) {}
      }, 100);
    }
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
            res.status >= 200 && res.status < 300 ? resolve() : reject(),
          onerror: () => reject(),
          ontimeout: () => reject(),
        });
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // A proper settings dialog instead of two browser prompt() boxes.
  // Opened from the Tampermonkey extension menu. Tampermonkey does not expose
  // an API to add custom entries to its dashboard, so this is the closest
  // supported integration.
  function openServerConfigDialog(force) {
    if (!force && isConfigured()) return Promise.resolve(true);
    const old = document.getElementById("local-captcha-ocr-settings");
    if (old) old.remove();

    return new Promise((resolve) => {
      let resolved = false;
      let allowUnreachable = false;
      const finish = (result) => {
        if (resolved) return;
        resolved = true;
        overlay.remove();
        resolve(result);
      };

      const overlay = document.createElement("div");
      overlay.id = "local-captcha-ocr-settings";
      overlay.setAttribute("role", "dialog");
      overlay.setAttribute("aria-modal", "true");
      overlay.setAttribute("aria-label", "OCR 服务器设置");
      overlay.style.cssText = [
        "position:fixed",
        "inset:0",
        "z-index:2147483647",
        "display:flex",
        "align-items:center",
        "justify-content:center",
        "padding:16px",
        "box-sizing:border-box",
        "background:rgba(0,0,0,.45)",
        "font:14px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif",
        "color:#202124"
      ].join(";");

      const card = document.createElement("div");
      card.style.cssText = [
        "width:100%",
        "max-width:440px",
        "max-height:90vh",
        "overflow:auto",
        "box-sizing:border-box",
        "background:#fff",
        "border-radius:10px",
        "box-shadow:0 12px 40px rgba(0,0,0,.35)",
        "padding:18px 18px 14px"
      ].join(";");
      overlay.appendChild(card);

      const title = document.createElement("div");
      title.textContent = "OCR 服务器设置";
      title.style.cssText = "font-size:18px;font-weight:600;margin:0 0 4px";
      card.appendChild(title);

      const intro = document.createElement("div");
      intro.textContent = "填写局域网 OCR 服务地址和 token。保存后立即生效，无需改脚本。";
      intro.style.cssText = "color:#5f6368;margin:0 0 14px";
      card.appendChild(intro);

      if (hasInjectedConfig()) {
        const injected = document.createElement("div");
        injected.textContent = "当前地址和 token 由局域网服务器注入；手动修改只在本次会话生效，下次脚本更新会恢复服务器配置。";
        injected.style.cssText = [
          "background:#fff7e0",
          "border:1px solid #f0c36d",
          "color:#6b4f00",
          "border-radius:6px",
          "padding:8px 10px",
          "margin:0 0 12px"
        ].join(";");
        card.appendChild(injected);
      }

      const field = (labelText, input) => {
        const label = document.createElement("label");
        label.textContent = labelText;
        label.style.cssText = "display:block;font-weight:600;margin:10px 0 4px";
        label.htmlFor = input.id;
        card.appendChild(label);
        input.style.cssText = [
          "display:block",
          "width:100%",
          "box-sizing:border-box",
          "padding:8px 10px",
          "border:1px solid #dadce0",
          "border-radius:6px",
          "font:14px/1.4 Arial,sans-serif",
          "color:#202124",
          "background:#fff"
        ].join(";");
        card.appendChild(input);
      };

      const urlInput = document.createElement("input");
      urlInput.id = "local-captcha-ocr-settings-url";
      urlInput.type = "text";
      urlInput.inputMode = "url";
      urlInput.autocomplete = "off";
      urlInput.spellcheck = false;
      urlInput.placeholder = "http://192.168.1.100:1205";
      urlInput.value = effectiveServerUrl();
      field("服务器地址", urlInput);

      const tokenInput = document.createElement("input");
      tokenInput.id = "local-captcha-ocr-settings-token";
      tokenInput.type = "password";
      tokenInput.autocomplete = "off";
      tokenInput.spellcheck = false;
      tokenInput.placeholder = "server/config.json 中的 api_token";
      tokenInput.value = effectiveToken();
      field("访问 token", tokenInput);

      const showWrap = document.createElement("label");
      showWrap.style.cssText = "display:flex;align-items:center;gap:6px;margin:8px 0 0;color:#5f6368;cursor:pointer";
      const showToken = document.createElement("input");
      showToken.type = "checkbox";
      showToken.style.cssText = "margin:0";
      showToken.addEventListener("change", () => {
        tokenInput.type = showToken.checked ? "text" : "password";
      });
      showWrap.appendChild(showToken);
      showWrap.appendChild(document.createTextNode("显示 token"));
      card.appendChild(showWrap);

      const status = document.createElement("div");
      status.setAttribute("role", "status");
      status.style.cssText = "min-height:20px;margin:10px 0 0;font-size:13px;display:none";
      card.appendChild(status);
      const setStatus = (text, ok) => {
        status.textContent = text || "";
        status.style.display = text ? "block" : "none";
        status.style.color = ok === true ? "#137333" : ok === false ? "#c5221f" : "#5f6368";
      };

      const actions = document.createElement("div");
      actions.style.cssText = "display:flex;justify-content:flex-end;gap:8px;margin-top:16px;flex-wrap:wrap";
      card.appendChild(actions);

      const btn = (text, primary) => {
        const b = document.createElement("button");
        b.type = "button";
        b.textContent = text;
        b.style.cssText = [
          "border:0",
          "border-radius:6px",
          "padding:8px 14px",
          "font:14px/1.4 Arial,sans-serif",
          "cursor:pointer",
          primary ? "background:#1a73e8" : "background:#f1f3f4",
          primary ? "color:#fff" : "color:#202124"
        ].join(";");
        return b;
      };

      const cancelBtn = btn("取消", false);
      const testBtn = btn("测试连接", false);
      const saveBtn = btn("保存", true);
      actions.appendChild(cancelBtn);
      actions.appendChild(testBtn);
      actions.appendChild(saveBtn);

      const readValues = () => {
        const serverUrl = normalizeServerUrl(urlInput.value);
        const token = String(tokenInput.value || "").trim();
        if (!serverUrl) {
          setStatus("请填写服务器地址。", false);
          return null;
        }
        if (!/^https?:\/\//i.test(serverUrl)) {
          setStatus("服务器地址必须以 http:// 或 https:// 开头。", false);
          return null;
        }
        if (!token) {
          setStatus("请填写访问 token。", false);
          return null;
        }
        return { serverUrl, token };
      };

      [urlInput, tokenInput].forEach((input) => {
        input.addEventListener("input", () => {
          allowUnreachable = false;
          setStatus("", null);
        });
      });

      testBtn.addEventListener("click", async () => {
        allowUnreachable = false;
        const serverUrl = normalizeServerUrl(urlInput.value);
        if (!serverUrl || !/^https?:\/\//i.test(serverUrl)) {
          setStatus("请先填写以 http:// 或 https:// 开头的服务器地址。", false);
          return;
        }
        setStatus("正在连接 /health ...", null);
        const ok = await probeServer(serverUrl);
        setStatus(ok ? "连接成功，/health 正常。" : "无法连接 /health，请检查地址、防火墙和网段。", ok);
      });

      saveBtn.addEventListener("click", async () => {
        const values = readValues();
        if (!values) return;
        setStatus("正在检查服务器...", null);
        const ok = await probeServer(values.serverUrl);
        if (!ok && !allowUnreachable) {
          allowUnreachable = true;
          setStatus("无法连接 /health。请检查地址、防火墙和网段；仍要保存请再点一次“保存”。", false);
          return;
        }
        GM_setValue(CFG_SERVER_KEY, values.serverUrl);
        GM_setValue(CFG_TOKEN_KEY, values.token);
        CONFIG.serverUrl = values.serverUrl;
        CONFIG.token = values.token;
        notify("服务器配置已保存：" + values.serverUrl);
        finish(true);
      });

      cancelBtn.addEventListener("click", () => finish(false));
      overlay.addEventListener("click", (event) => {
        if (event.target === overlay) finish(false);
      });
      overlay.addEventListener("keydown", (event) => {
        if (event.key === "Escape") {
          event.preventDefault();
          finish(false);
        } else if (event.key === "Enter" && (event.target === urlInput || event.target === tokenInput)) {
          event.preventDefault();
          saveBtn.click();
        }
      });

      document.documentElement.appendChild(overlay);
      window.setTimeout(() => urlInput.focus(), 0);
    });
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
        // Change host to your company domain (e.g. "app.company.local") to limit
        // it to just your site, or use GM_registerMenuCommand → "为本网站添加规则..."
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
        // ddddocr emits lowercase letters, but this site's captcha is shown in
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
    // Per-site switch: stay completely passive while disabled for this host.
    if (isCurrentSiteDisabled()) return;
    if (!CONFIG.token) {
      // Prompt at most once automatically (the menu can always re-open the
      // settings). Prevents the MutationObserver from spamming prompts.
      if (GM_getValue("ocr_prompted", false)) return;
      GM_setValue("ocr_prompted", true);
      const configured = await openServerConfigDialog(true);
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
    if (isCurrentSiteDisabled()) {
      notify("本站验证码识别已关闭，可在油猴菜单重新开启");
      return;
    }
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

  // Keep the Tampermonkey menu short: common actions at top, site rules and
  // recovery tools behind one "高级功能" dialog.
  function openAdvancedDialog() {
    const old = document.getElementById("local-captcha-ocr-advanced");
    if (old) old.remove();

    const overlay = document.createElement("div");
    overlay.id = "local-captcha-ocr-advanced";
    overlay.setAttribute("role", "dialog");
    overlay.setAttribute("aria-modal", "true");
    overlay.setAttribute("aria-label", "OCR 高级功能");
    overlay.style.cssText = [
      "position:fixed",
      "inset:0",
      "z-index:2147483647",
      "display:flex",
      "align-items:center",
      "justify-content:center",
      "padding:16px",
      "box-sizing:border-box",
      "background:rgba(0,0,0,.45)",
      "font:14px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Arial,sans-serif",
      "color:#202124"
    ].join(";");

    const card = document.createElement("div");
    card.style.cssText = [
      "width:100%",
      "max-width:420px",
      "max-height:90vh",
      "overflow:auto",
      "box-sizing:border-box",
      "background:#fff",
      "border-radius:10px",
      "box-shadow:0 12px 40px rgba(0,0,0,.35)",
      "padding:18px 18px 14px"
    ].join(";");
    overlay.appendChild(card);

    const title = document.createElement("div");
    title.textContent = "OCR 高级功能";
    title.style.cssText = "font-size:18px;font-weight:600;margin:0 0 4px";
    card.appendChild(title);

    const intro = document.createElement("div");
    intro.textContent = "日常用不到；遇到验证码规则或识别异常时再打开。";
    intro.style.cssText = "color:#5f6368;margin:0 0 10px";
    card.appendChild(intro);

    const current = document.createElement("div");
    const siteState = isCurrentSiteDisabled() ? "已关闭" : "已开启";
    current.textContent =
      `本站识别：${siteState}` +
      (isConfigured() ? `　当前服务器：${effectiveServerUrl()}` : "　当前服务器：未配置");
    current.style.cssText = "color:#5f6368;font-size:13px;margin:0 0 12px;word-break:break-all";
    card.appendChild(current);

    const addAction = (label, desc, fn) => {
      const button = document.createElement("button");
      button.type = "button";
      button.style.cssText = [
        "display:block",
        "width:100%",
        "text-align:left",
        "border:1px solid #dadce0",
        "background:#fff",
        "border-radius:6px",
        "padding:9px 11px",
        "margin:0 0 8px",
        "font:14px/1.4 Arial,sans-serif",
        "color:#202124",
        "cursor:pointer"
      ].join(";");
      const name = document.createElement("div");
      name.textContent = label;
      name.style.cssText = "font-weight:600";
      const sub = document.createElement("div");
      sub.textContent = desc;
      sub.style.cssText = "font-size:12px;color:#5f6368;margin-top:2px";
      button.appendChild(name);
      button.appendChild(sub);
      button.addEventListener("mouseenter", () => { button.style.background = "#f8f9fa"; });
      button.addEventListener("mouseleave", () => { button.style.background = "#fff"; });
      button.addEventListener("click", () => {
        finish();
        window.setTimeout(() => { try { fn(); } catch (_) {} }, 0);
      });
      card.appendChild(button);
    };

    let resolved = false;
    const finish = () => {
      if (resolved) return;
      resolved = true;
      overlay.remove();
    };

    addAction("切换验证码大小写", "按当前网站切换：大写 / 小写 / 原样", cycleCaseForHost);
    addAction("重置本网站断路器", "连续失败被暂停后手动恢复", resetBreaker);
    addAction("添加本网站规则…", "自定义验证码图片和输入框选择器", promptUserRule);
    addAction("查看本网站规则", "查看当前网站已保存的规则", listUserRulesForHost);
    addAction("删除本网站规则", "只删除当前网站的规则", clearUserRulesForHost);
    addAction("清空全部用户规则", "删除所有网站的规则", clearAllUserRules);

    const close = document.createElement("button");
    close.type = "button";
    close.textContent = "关闭";
    close.style.cssText = [
      "display:block",
      "margin:8px 0 0 auto",
      "border:0",
      "border-radius:6px",
      "padding:8px 14px",
      "background:#f1f3f4",
      "color:#202124",
      "font:14px/1.4 Arial,sans-serif",
      "cursor:pointer"
    ].join(";");
    close.addEventListener("click", finish);
    card.appendChild(close);

    overlay.addEventListener("click", (event) => {
      if (event.target === overlay) finish();
    });
    overlay.addEventListener("keydown", (event) => {
      if (event.key === "Escape") {
        event.preventDefault();
        finish();
      }
    });

    document.documentElement.appendChild(overlay);
    window.setTimeout(() => close.focus(), 0);
  }

  GM_registerMenuCommand("识别并填码", recognizeAndFill);
  GM_registerMenuCommand("刷新后识别", refreshAndRecognize);
  GM_registerMenuCommand("切换本站识别（开/关）", toggleCurrentSiteRecognition);
  GM_registerMenuCommand("OCR 服务器设置…", () => openServerConfigDialog(true));
  GM_registerMenuCommand("高级功能…", openAdvancedDialog);
  GM_registerMenuCommand("从 OCR 服务器更新脚本…", openServerUserscript);

  if (CONFIG.autoRun) {
    const boot = () => {
      window.setTimeout(async () => {
        // Per-site switch: do not even prompt or start observing while the
        // current host is disabled.
        if (isCurrentSiteDisabled()) return;
        if (!isConfigured()) {
          // Ask once; the operator can always configure later from the menu.
          if (!GM_getValue("ocr_prompted", false)) {
            GM_setValue("ocr_prompted", true);
            await openServerConfigDialog(true);
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

