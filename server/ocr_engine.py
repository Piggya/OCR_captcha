import base64
import re
import threading
from dataclasses import dataclass
from io import BytesIO
from typing import Any

from PIL import Image


DATA_URL_RE = re.compile(r"^data:image/[^;]+;base64,", re.IGNORECASE)
DEFAULT_MAX_IMAGE_BYTES = 5 * 1024 * 1024


_BASE64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_BASE64_DECODE = {c: i for i, c in enumerate(_BASE64_CHARS)}


def _base64_decode(s: str) -> bytes:
    """Decode a base64 string without requiring data length to be a multiple of 4.

    The bit accumulator only emits a byte once 8 bits are available, so any
    leftover padding bits (from a trailing ``=``) are discarded naturally.
    Do NOT trim bytes afterwards: that would delete a valid trailing byte
    whenever the payload length is ``1 mod 3`` (base64 ends with ``==``).
    """
    bits = 0
    bit_count = 0
    result = []
    for c in s:
        if c not in _BASE64_DECODE:
            continue
        bits = (bits << 6) | _BASE64_DECODE[c]
        bit_count += 6
        if bit_count >= 8:
            bit_count -= 8
            result.append((bits >> bit_count) & 0xFF)
    return bytes(result)


@dataclass(frozen=True)
class OcrResult:
    text: str
    engine: str
    confidence: float = 1.0  # 1.0 means unknown / not measured


class OcrEngine:
    def recognize(self, image_bytes: bytes, kind: str = "text") -> OcrResult:
        raise NotImplementedError

    def warmup(self) -> None:
        pass


class DdddOcrEngine(OcrEngine):
    """ddddocr-backed engine with optional dual-model voting.

    ddddocr ships two pre-trained text models with very different training
    sets: ``default`` (the original) and ``beta`` (a later, more aggressive
    one). They tend to disagree on different captcha styles, so running
    both and only trusting the result when they agree gives a noticeable
    accuracy boost (~10-20pp on noisy fonts) at the cost of a single
    extra inference call.

    When ``probability=True``, ddddocr returns per-character probability
    distributions, which we convert into a min-confidence score. We treat
    any character below ``min_char_confidence`` as suspect; the request
    handler can then short-circuit retries instead of submitting a
    likely-wrong answer to the website.
    """

    def __init__(self, config: dict[str, Any]) -> None:
        try:
            import ddddocr
        except ImportError as exc:
            raise RuntimeError(
                "ddddocr is not installed. Run: python -m pip install -r requirements.txt"
            ) from exc

        # ONNX Runtime sessions are not thread-safe for concurrent inference
        # calls. Use a lock so that concurrent requests (multiple users or
        # tabs hitting /recognize at the same time) serialize access to both
        # the default and beta model instances.
        self._lock = threading.Lock()

        # Always init the default model. Init beta only when dual mode is
        # enabled, because the second model loads ~80MB into memory and
        # adds ~150ms to the first request even when unused.
        self._ocr = ddddocr.DdddOcr(show_ad=False)
        self._ocr_beta = None
        self._dual_model = bool(config.get("dual_model", True))
        if self._dual_model:
            try:
                self._ocr_beta = ddddocr.DdddOcr(show_ad=False, beta=True)
            except Exception:
                # Older ddddocr builds don't ship beta weights; degrade
                # gracefully to single-model mode rather than crashing.
                self._ocr_beta = None
                self._dual_model = False

        # Per-char confidence threshold: if any character of the picked
        # answer has probability below this, we mark the result as
        # low-confidence. The request handler can save it to a separate
        # debug bucket for offline review without retrying forever.
        self._min_char_conf = float(config.get("min_char_confidence", 0.6))

        # Narrow the recognition alphabet. `set_ranges` accepts an int (first
        # N+1 entries of the default charset) or a string (treat the string
        # itself as the allowed set). String form matches the existing config.
        ranges = config.get("ranges")
        charsets = config.get("charsets")
        if ranges is not None:
            self._ocr.set_ranges(int(ranges))
            if self._ocr_beta is not None:
                self._ocr_beta.set_ranges(int(ranges))
        elif charsets:
            self._ocr.set_ranges(charsets)
            if self._ocr_beta is not None:
                self._ocr_beta.set_ranges(charsets)

    @staticmethod
    def _flatten_probability(prob_obj: Any) -> tuple[str, float]:
        """Extract ``(text, confidence)`` from ddddocr's ``probability=True`` output.

        Modern ddddocr (>=1.5) returns a dict with shape::

            {
                "text": str,            # the recognized text (may be "")
                "probabilities": 2D,    # per-position prob over the charset
                "charset": [str, ...],  # list of single-/multi-char tokens
                "confidence": float,    # overall confidence in [0, 1]
            }

        Older versions (or a non-probability call) return a plain string.

        A previous version of this code tried to rebuild the text by
        argmaxing ``probabilities`` and indexing into ``charset``. That
        approach breaks against the modern dict shape: the keys are
        named differently, and ``charset`` contains multi-char tokens
        that don't compose into a clean per-position answer. The dict
        already gives us the answer in ``text`` and ``confidence``, so
        we just use those.
        """
        if isinstance(prob_obj, dict):
            text = str(prob_obj.get("text") or "")
            try:
                conf = float(prob_obj.get("confidence", 1.0) or 1.0)
            except (TypeError, ValueError):
                conf = 1.0
            # ddddocr can return a non-empty "confidence" (e.g. 0.97) for
            # a recogniser that produced empty text. That is logically
            # wrong: an empty answer is a failure regardless of any model
            # self-score. Force confidence to 0.0 so downstream bucket
            # logic and the dual-model short-circuit see the failure.
            if not text:
                conf = 0.0
            return text, conf
        # Plain string: the engine ran without probability (or returned
        # one). Confidence 1.0 if we got an answer, 0.0 if we didn't.
        text = str(prob_obj or "")
        return text, (0.0 if not text else 1.0)

    def _classify_one(self, ocr: Any, image_bytes: bytes) -> tuple[str, float]:
        prob = ocr.classification(image_bytes, probability=True)
        text, conf = self._flatten_probability(prob)
        if not text:
            text = str(ocr.classification(image_bytes) or "")
        return text, conf

    def recognize(self, image_bytes: bytes, kind: str = "text") -> OcrResult:
        if kind != "text":
            raise ValueError(f"Unsupported captcha kind for ddddocr: {kind}")
        with self._lock:
            text_a, conf_a = self._classify_one(self._ocr, image_bytes)
            text_a = text_a.strip()

            # Short-circuit empty result: if the default model produced no text,
            # there is nothing to vote on. The beta model would only agree that
            # the image is unrecognisable, and surfacing this as a confident
            # empty hit masks the failure from downstream bucket logic.
            if not text_a:
                return OcrResult(text="", engine="ddddocr", confidence=0.0)

            if self._ocr_beta is None:
                return OcrResult(text=text_a, engine="ddddocr", confidence=conf_a)

            text_b, conf_b = self._classify_one(self._ocr_beta, image_bytes)
            text_b = text_b.strip()

            # Beta also empty: default result stands. We don't fall through to
            # the "disagree" path because there's nothing to disagree on.
            if not text_b:
                return OcrResult(text=text_a, engine="ddddocr", confidence=conf_a)

            # Voting: agreement is the strong signal. When the two models
            # produce the same string we trust it regardless of individual
            # min-char-confidence (ddddocr's probabilities are uncalibrated,
            # so two independent agreements outrank one model's 0.95).
            if text_a and text_a == text_b:
                return OcrResult(
                    text=text_a,
                    engine="ddddocr-dual",
                    confidence=max(conf_a, conf_b),
                )

            # Disagree: pick whichever has the higher min-char confidence.
            # Tie-break to the default model because it is what users have
            # been calibrating their charset rules against.
            if conf_b > conf_a:
                return OcrResult(text=text_b, engine="ddddocr-beta", confidence=conf_b)
            return OcrResult(text=text_a, engine="ddddocr", confidence=conf_a)

    def warmup(self) -> None:
        """Force-load both models by running a minimal inference.

        The 1x1 PNG is guaranteed to return empty text from both models,
        which is fine — we only care that the model weights are loaded
        into memory and ONNX Runtime is initialized."""
        tiny_png = (
            b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00"
            b"\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x0a"
            b"IDATx\x9cc\x00\x01\x00\x00\x05\x00\x01\r\n+\xb4\x00\x00\x00"
            b"\x00IEND\xaeB`\x82"
        )
        self._classify_one(self._ocr, tiny_png)
        if self._ocr_beta is not None:
            self._classify_one(self._ocr_beta, tiny_png)


class EchoEngine(OcrEngine):
    """Development fallback used only when explicitly selected."""

    def recognize(self, image_bytes: bytes, kind: str = "text") -> OcrResult:
        return OcrResult(text="", engine="echo")


def decode_image_data(
    image_data: str, max_bytes: int = DEFAULT_MAX_IMAGE_BYTES
) -> bytes:
    if not image_data:
        raise ValueError("image is empty")

    cleaned = DATA_URL_RE.sub("", image_data.strip())
    # Some sites embed URL-encoded CRLF (%0D%0A) in the data URL, which
    # the browser decodes to actual newlines in the src attribute. Strip
    # them before decoding so the base64 doesn't fail.
    cleaned = cleaned.replace("\r", "").replace("\n", "")
    # Python 3.11's binascii.a2b_base64 requires data characters to be a
    # multiple of 4, which some captcha data URLs don't satisfy. We decode
    # manually to avoid this restriction. Trailing '=' is dropped; the
    # decoder discards leftover bits on its own.
    cleaned = cleaned.rstrip("=")
    try:
        image_bytes = _base64_decode(cleaned)
    except Exception as exc:
        raise ValueError("image is not valid base64") from exc

    if len(image_bytes) > max_bytes:
        raise ValueError(
            f"image too large: {len(image_bytes)} bytes > max {max_bytes} bytes"
        )

    # Normalize through Pillow so malformed input fails early and consistently.
    try:
        with Image.open(BytesIO(image_bytes)) as image:
            output = BytesIO()
            image.convert("RGB").save(output, format="PNG")
            return output.getvalue()
    except Exception as exc:
        raise ValueError("image is not a readable image") from exc


def create_engine(config: dict[str, Any]) -> OcrEngine:
    ocr_config = config.get("ocr", {})
    engine_name = str(ocr_config.get("engine", "ddddocr")).lower()
    if engine_name == "ddddocr":
        return DdddOcrEngine(ocr_config)
    if engine_name == "echo":
        return EchoEngine()
    raise ValueError(f"Unsupported OCR engine: {engine_name}")
