import asyncio
import hashlib
import ipaddress
import json
import os
import re
import secrets
import socket
import time
import uuid
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from threading import Lock
from typing import Any, Literal

from fastapi import Depends, FastAPI, Header, HTTPException, Request, Response, status
from pydantic import BaseModel, Field

from .ocr_engine import (
    DEFAULT_MAX_IMAGE_BYTES,
    create_engine,
    decode_image_data,
)

__version__ = "0.12.2"


BASE_DIR = Path(__file__).resolve().parent
CONFIG_PATH = BASE_DIR / "config.json"
DEFAULT_CONFIG_PATH = BASE_DIR / "config.example.json"
USERSCRIPT_PATH = BASE_DIR.parent / "userscript" / "local-captcha-autofill.user.js"


def load_config() -> dict[str, Any]:
    path = CONFIG_PATH if CONFIG_PATH.exists() else DEFAULT_CONFIG_PATH
    with path.open("r", encoding="utf-8-sig") as file:
        return json.load(file)


CONFIG = load_config()
OCR_ENGINE = create_engine(CONFIG)

# ddddocr.classification() runs synchronous Python code that holds the GIL
# for 1-3 seconds per call. With uvicorn's single worker, that means every
# in-flight request queues behind it and the next HTTP accept() is delayed
# until the model returns. We offload both the Pillow decode and the OCR
# inference to a small thread pool so FastAPI's event loop keeps accepting
# new requests, and several recognitions can run in parallel against a
# single ddddocr instance (which releases the GIL between tensor ops).
#
# The pool used to be hard-coded to 2 workers, which capped throughput near
# 18 rps while the model itself could serve ~250 rps on the same image. Scale
# with the CPU instead: a quarter of the logical cores, clamped to 2..8.
# More workers than that only add context switching (and memory) on a LAN box
# serving a handful of browsers.
def _executor_worker_count() -> int:
    override = os.environ.get("OCR_EXECUTOR_WORKERS", "").strip()
    if override:
        try:
            return max(1, int(override))
        except ValueError:
            pass
    return max(2, min(8, (os.cpu_count() or 4) // 4))


_ocr_executor = ThreadPoolExecutor(
    max_workers=_executor_worker_count(),
    thread_name_prefix="ocr",
)


# Simple bounded LRU keyed by sha256(image_bytes). The userscript already
# de-dupes by DOM fingerprint per tab, but multiple tabs / iframes on the
# same captcha (or rapid re-clicks) can still cause repeat work. Hits cost
# ~5us; misses fall through to the model. Stored values are full
# OcrResult tuples so the cached confidence + engine id round-trip too.
_CACHE_MAX = 256
_cache: "OrderedDict[str, Any]" = OrderedDict()
_cache_lock = Lock()


def _cache_get(key: str) -> Any | None:
    with _cache_lock:
        if key not in _cache:
            return None
        _cache.move_to_end(key)
        return _cache[key]


def _cache_put(key: str, value: Any) -> None:
    with _cache_lock:
        _cache[key] = value
        _cache.move_to_end(key)
        while len(_cache) > _CACHE_MAX:
            _cache.popitem(last=False)


# Base64 expands data by ~4/3, plus the data URL prefix. 1.4x is a safe upper
# bound for the legal string length of any image that fits the byte cap.
_BASE64_HEADROOM = 1.4


def _max_image_b64_length() -> int:
    cap = int(CONFIG.get("max_image_bytes", DEFAULT_MAX_IMAGE_BYTES))
    return int(cap * _BASE64_HEADROOM) + 1024


class RecognizeRequest(BaseModel):
    image: str = Field(..., min_length=32, max_length=_max_image_b64_length())
    kind: Literal["text"] = "text"
    site: str | None = None


class RecognizeResponse(BaseModel):
    ok: bool
    text: str = ""
    engine: str
    confidence: float = 1.0
    cached: bool = False
    error: str | None = None
    time_ms: float | None = None


# Note: no CORS middleware. The only legitimate client is the Tampermonkey
# script, which uses GM_xmlhttpRequest and therefore bypasses CORS. Opening
# `allow_origins=["*"]` to a 0.0.0.0:1205 service only invites browser-side
# abuse if the API token ever leaks.
app = FastAPI(title="土著内网验证码识别", version=__version__)


_DEBUG_CLEANUP_INTERVAL = 30 * 60  # 30 minutes


@app.on_event("startup")
def _startup() -> None:
    """Run warmup inference and start background cleanup task."""
    try:
        OCR_ENGINE.warmup()
    except Exception:  # noqa: BLE001 - warmup failure is non-fatal
        pass

    # Trim once at boot. Waiting a full interval first meant a frequently
    # restarted server never reached cleanup at all, and a busy burst could
    # push a bucket far past its cap before the first sweep.
    try:
        _cleanup_debug_buckets()
    except Exception:  # noqa: BLE001 - cleanup must never block startup
        pass

    async def _periodic_debug_cleanup() -> None:
        while True:
            await asyncio.sleep(_DEBUG_CLEANUP_INTERVAL)
            try:
                _cleanup_debug_buckets()
            except Exception:  # noqa: BLE001 - keep the loop alive
                pass

    try:
        loop = asyncio.get_event_loop()
        loop.create_task(_periodic_debug_cleanup())
    except Exception:  # noqa: BLE001 - cleanup task failure is non-fatal
        pass


def get_client_host(request: Request) -> str:
    """Resolve the real client IP.

    When the operator opts in to ``trust_proxy`` (i.e. uvicorn sits behind a
    reverse proxy that strips/replaces client IPs), the leftmost entry of
    ``X-Forwarded-For`` is used. Without the opt-in the header is ignored so
    that callers cannot spoof their source IP to bypass ``allowed_clients``.
    """
    if CONFIG.get("trust_proxy", False):
        xff = request.headers.get("x-forwarded-for")
        if xff:
            return xff.split(",")[0].strip()
    return request.client.host if request.client else ""


def _lan_ipv4_addresses() -> list[str]:
    """Return this machine's non-loopback IPv4 addresses, preferred first.

    Used to build user-facing URLs without trusting the ``Host`` header. Kept
    cheap (a couple of socket calls) and never raises: an empty list simply
    means the caller falls back to loopback.
    """
    found: list[str] = []
    try:
        # connect() on a UDP socket sends nothing; it only lets the OS pick the
        # outbound interface, which is normally the LAN one.
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

    ordered: list[str] = []
    for ip in found:
        try:
            addr = ipaddress.ip_address(ip)
        except ValueError:
            continue
        # Skip loopback and link-local; keep private/global addresses.
        if addr.is_loopback or addr.is_link_local:
            continue
        if ip not in ordered:
            ordered.append(ip)
    return ordered


def _configured_lan_ip() -> str:
    """Return ``work_lan_ip`` only if this host actually owns that address.

    A config copied from another machine (or a stale DHCP lease) used to make
    the server advertise an unreachable address. Probing is cheap and does not
    need the address to be online, so the check runs per call.

    Routable addresses only: loopback, link-local and the unspecified address
    (0.0.0.0) are all bindable here, but handing them to another machine means
    "your own loopback" or "nothing at all". Those fall through to probing.
    """
    configured = str(CONFIG.get("work_lan_ip") or "").strip()
    if not configured:
        return ""
    try:
        addr = ipaddress.ip_address(configured)
    except ValueError:
        return ""
    if addr.is_loopback or addr.is_link_local or addr.is_unspecified:
        return ""
    try:
        # udp connect() never transmits; it only tests routability from a local
        # source address. An unreachable IP raises, which means "not ours".
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind((configured, 0))
        return configured
    except OSError:
        return ""


def get_public_base_url() -> str:
    """Build the base URL handed to LAN clients (userscript injection).

    SECURITY: this deliberately does **not** use ``request.base_url``. That
    value comes straight from the ``Host`` header, so any client could ask for
    ``Host: attacker.example`` and receive a script whose ``serverUrl`` and
    ``@updateURL`` point at the attacker - and whose embedded token leaks with
    it. Trusting configuration instead of the request closes that hole.

    Order: explicit ``work_lan_ip`` (only when bound to this host) -> probed
    LAN address -> loopback. The port always comes from configuration, never
    from Host.
    """
    port = int(CONFIG.get("port", 1205))
    host = _configured_lan_ip() or next(iter(_lan_ipv4_addresses()), "127.0.0.1")
    return f"http://{host}:{port}"


def client_allowed(host: str) -> bool:
    allowed = CONFIG.get("allowed_clients", [])
    try:
        client_ip = ipaddress.ip_address(host)
    except ValueError:
        return False

    for item in allowed:
        try:
            if "/" in item:
                if client_ip in ipaddress.ip_network(item, strict=False):
                    return True
            elif client_ip == ipaddress.ip_address(item):
                return True
        except ValueError:
            continue
    return False


async def require_access(
    request: Request,
    authorization: str | None = Header(default=None),
    x_api_token: str | None = Header(default=None),
) -> None:
    client_host = get_client_host(request)
    if not client_allowed(client_host):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Client is not allowed: {client_host}",
        )

    expected = CONFIG.get("api_token")
    supplied = x_api_token
    if authorization and authorization.lower().startswith("bearer "):
        supplied = authorization[7:].strip()

    # An unset token must not silently disable authentication. Refuse every
    # request until the operator configures one (start_server.ps1 generates
    # it automatically on first run).
    if not expected:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Server API token is not configured; refusing request",
        )
    if not supplied or not secrets.compare_digest(
        supplied.encode("utf-8"), expected.encode("utf-8")
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API token",
        )


@app.get("/health")
def health() -> dict[str, Any]:
    return {"ok": True, "engine": CONFIG.get("ocr", {}).get("engine", "ddddocr")}


@app.get("/version")
def version() -> dict[str, str]:
    return {
        "service": "local-captcha-ocr",
        "version": __version__,
        "ocr_engine": CONFIG.get("ocr", {}).get("engine", "ddddocr"),
    }


@app.get("/userscript.user.js")
def userscript(request: Request) -> Response:
    """Serve the Tampermonkey script with this server pre-configured.

    LAN clients install the script straight from the OCR server, so the
    script body gets ``INJECTED_CONFIG`` (server URL + API token) and its
    ``@updateURL``/``@downloadURL`` point back here. That removes the manual
    "set server URL and token" step for LAN devices.

    Because the rendered script contains the token, this endpoint is limited
    to ``allowed_clients`` (the same IP allowlist used by ``/recognize``).
    The copy committed to git keeps ``INJECTED_CONFIG = null`` and GitHub
    update URLs, so the public raw script never contains a secret.
    """
    client_host = get_client_host(request)
    if not client_allowed(client_host):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Client is not allowed: {client_host}",
        )

    try:
        content = USERSCRIPT_PATH.read_text(encoding="utf-8")
    except OSError as exc:
        raise HTTPException(
            status_code=404, detail="userscript not found on server"
        ) from exc
    content = content.replace("\r\n", "\n").replace("\r", "\n")

    # Never derive this from the Host header (see get_public_base_url).
    base_url = get_public_base_url()
    token = str(CONFIG.get("api_token") or "")
    if token in {"", "change-me-to-a-random-internal-token"}:
        # Keep the URL so the manual prompt is pre-filled, but never hand out
        # a placeholder token (the script would then appear configured and
        # every OCR call would fail with 401).
        token = ""

    injected = json.dumps(
        {"serverUrl": base_url, "token": token}, ensure_ascii=False
    )
    content = re.sub(
        r"^([ \t]*)const INJECTED_CONFIG = null;.*$",
        lambda match: f"{match.group(1)}const INJECTED_CONFIG = {injected};",
        content,
        count=1,
        flags=re.MULTILINE,
    )
    for key in ("@updateURL", "@downloadURL"):
        content = re.sub(
            rf"^// {key}\s+.*$",
            f"// {key}    {base_url}/userscript.user.js",
            content,
            count=1,
            flags=re.MULTILINE,
        )

    return Response(
        content=content,
        media_type="text/javascript; charset=utf-8",
        headers={"Cache-Control": "no-store"},
    )


def _save_debug_image(image_bytes: bytes, text: str, site: str | None, bucket: str) -> None:
    """Persist the post-decode PNG plus the OCR result for offline review.

    Triggered only when ``save_debug_images`` is true. The intent is to
    let the operator look at the *exact* image the recognizer saw and
    decide whether a wrong answer is the recognizer's fault (font edge
    cases) or the userscript's fault (heuristic picked the wrong
    element). Files are bucketed into subdirectories by outcome:

      - ``ok``        - normal recognition
      - ``low-conf``  - any character below ``min_char_confidence``
      - ``engine-err`` - ddddocr raised
      - ``empty``     - engine returned no text (blank/unreadable image)

    Filenames are sanitized so a hostile ``site`` value cannot escape
    the debug directory. UUID suffixes prevent millisecond collisions.
    Bucket cleanup is handled by a periodic background task rather than
    on every write to avoid per-request IO overhead.
    """
    if not CONFIG.get("save_debug_images", False):
        return
    # Don't bother saving cache-hit copies; the original is already on disk.
    if bucket == "cache-hit":
        return
    try:
        rel_dir = CONFIG.get("debug_image_dir", "debug-images")
        debug_dir = (BASE_DIR.parent / rel_dir / bucket).resolve()
        debug_dir.mkdir(parents=True, exist_ok=True)
        safe_site = "".join(
            ch if ch.isalnum() or ch in ".-_" else "_"
            for ch in (site or "unknown")
        )[:64] or "unknown"
        safe_text = "".join(
            ch if ch.isalnum() else "_" for ch in (text or "")
        )[:32] or "EMPTY"
        ts = time.strftime("%Y%m%d-%H%M%S")
        ms = int((time.time() % 1) * 1000)
        suffix = uuid.uuid4().hex[:6]
        name = f"{ts}-{ms:03d}_{safe_site}_{safe_text}_{suffix}.png"
        (debug_dir / name).write_bytes(image_bytes)

        # Cheap safety net: the periodic sweep is slow and restarts reset it,
        # so a burst could push a bucket far past its cap. Count lazily and
        # only sweep once the bucket has clearly overflowed (1.25x the cap).
        try:
            max_keep = int(CONFIG.get("max_debug_images_per_bucket", 100))
            if max_keep > 0:
                png_count = sum(
                    1 for p in debug_dir.iterdir()
                    if p.is_file() and p.suffix.lower() == ".png"
                )
                if png_count > max_keep + max_keep // 4:
                    _cleanup_debug_buckets()
        except Exception:  # noqa: BLE001 - never break the request over this
            pass
    except Exception:  # noqa: BLE001 - debug must never break the request
        pass


def _cleanup_debug_buckets() -> None:
    """Periodic cleanup: cap each debug image bucket to max_keep files.

    Runs in a background asyncio task (``_DEBUG_CLEANUP_INTERVAL``) so
    the per-request hot path never pays for sorting and deletion.
    """
    if not CONFIG.get("save_debug_images", False):
        return
    rel_dir = CONFIG.get("debug_image_dir", "debug-images")
    max_keep = int(CONFIG.get("max_debug_images_per_bucket", 100))
    if max_keep <= 0:
        return
    buckets = ["ok", "low-conf", "engine-err", "empty"]
    for bucket in buckets:
        try:
            debug_dir = (BASE_DIR.parent / rel_dir / bucket).resolve()
            if not debug_dir.is_dir():
                continue
            png_files = sorted(
                (p for p in debug_dir.iterdir()
                 if p.is_file() and p.suffix.lower() == ".png"),
                key=lambda p: p.stat().st_mtime,
                reverse=True,
            )
            for old in png_files[max_keep:]:
                try:
                    old.unlink()
                except OSError:
                    pass
        except Exception:  # noqa: BLE001 - cleanup must never raise
            pass


@app.post("/recognize", response_model=RecognizeResponse)
async def recognize(
    payload: RecognizeRequest,
    _: None = Depends(require_access),
) -> RecognizeResponse:
    # Run both the Pillow decode and the ddddocr inference on the executor
    # so the FastAPI event loop is free to accept and dispatch the next
    # request while a previous recognition is still in flight.
    loop = asyncio.get_running_loop()
    started = time.perf_counter()
    try:
        image_bytes = await loop.run_in_executor(
            _ocr_executor,
            decode_image_data,
            payload.image,
            CONFIG.get("max_image_bytes", DEFAULT_MAX_IMAGE_BYTES),
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    # Cache key is the sha256 of the *post-decode* canonicalised PNG so
    # two clients sending the same captcha encoded slightly differently
    # (eg via re-saving as JPEG) can still share the cache slot.
    cache_key = hashlib.sha256(image_bytes).hexdigest()
    cached = _cache_get(cache_key)
    if cached is not None:
        text, engine_name, confidence = cached
        _save_debug_image(image_bytes, text, payload.site, "cache-hit")
        return RecognizeResponse(
            ok=True, text=text, engine=engine_name,
            confidence=confidence, cached=True,
            time_ms=round((time.perf_counter() - started) * 1000, 2),
        )

    try:
        result = await loop.run_in_executor(
            _ocr_executor,
            OCR_ENGINE.recognize,
            image_bytes,
            payload.kind,
        )
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:  # noqa: BLE001 - last-resort guard around the model
        _save_debug_image(image_bytes, "ERR", payload.site, "engine-err")
        raise HTTPException(
            status_code=500, detail=f"OCR engine error: {exc}"
        ) from exc

    # Bucket by confidence so the operator can browse only the suspect
    # ones. The threshold mirrors DdddOcrEngine's min_char_confidence
    # so what we call "low-conf" here matches what the engine internally
    # treats as suspect.
    threshold = float(CONFIG.get("ocr", {}).get("min_char_confidence", 0.6))
    if not result.text:
        bucket = "empty"
    elif result.confidence < threshold:
        bucket = "low-conf"
    else:
        bucket = "ok"
    _save_debug_image(image_bytes, result.text, payload.site, bucket)

    # Cache only confident results. Caching a low-conf wrong answer
    # would cement that mistake for every future request that hashes to
    # this image.
    if result.confidence >= threshold and result.text:
        _cache_put(cache_key, (result.text, result.engine, result.confidence))

    return RecognizeResponse(
        ok=True, text=result.text, engine=result.engine,
        confidence=result.confidence, cached=False,
        time_ms=round((time.perf_counter() - started) * 1000, 2),
    )
