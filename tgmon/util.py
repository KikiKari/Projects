"""Kleine HTTP-/Parsing-Helfer. Bewusst nur Standardbibliothek -
das Projekt laeuft damit ohne pip-Installation."""
from __future__ import annotations

import html
import json
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from typing import Any, Optional

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

_last_call: dict[str, float] = {}


def _throttle(host: str, min_gap: float = 0.12) -> None:
    prev = _last_call.get(host, 0.0)
    wait = min_gap - (time.time() - prev)
    if wait > 0:
        time.sleep(wait)
    _last_call[host] = time.time()


class HttpError(Exception):
    def __init__(self, status: int, body: str = "", url: str = ""):
        super().__init__(f"HTTP {status} bei {url}: {body[:200]}")
        self.status = status
        self.body = body
        self.url = url


def fetch(url: str, *, headers: Optional[dict[str, str]] = None,
          data: Optional[bytes] = None, method: Optional[str] = None,
          timeout: int = 20, throttle: bool = True) -> str:
    """GET/POST als Text. Wirft HttpError bei >=400."""
    host = urllib.parse.urlsplit(url).netloc
    if throttle:
        _throttle(host)
    hdrs = {"User-Agent": UA, "Accept-Language": "de,en;q=0.8"}
    if headers:
        hdrs.update(headers)
    req = urllib.request.Request(url, data=data, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = resp.read()
            charset = resp.headers.get_content_charset() or "utf-8"
            return raw.decode(charset, errors="replace")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise HttpError(exc.code, body, url) from exc
    except urllib.error.URLError as exc:
        raise HttpError(0, str(exc.reason), url) from exc


def fetch_json(url: str, **kwargs: Any) -> Any:
    return json.loads(fetch(url, **kwargs))


_TAG_RE = re.compile(r"<[^>]+>")
_BR_RE = re.compile(r"<br\s*/?>", re.I)


def strip_html(fragment: str) -> str:
    """HTML-Fragment -> lesbarer Text (Zeilenumbrueche bleiben erhalten)."""
    if not fragment:
        return ""
    text = _BR_RE.sub("\n", fragment)
    text = re.sub(r"</(p|div)>", "\n", text, flags=re.I)
    text = _TAG_RE.sub("", text)
    text = html.unescape(text)
    text = re.sub(r"[ \t]+", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def meta(content: str, prop: str) -> str:
    """<meta property="og:title" content="..."> auslesen."""
    pattern = (rf'<meta[^>]+(?:property|name)=["\']{re.escape(prop)}["\']'
               rf'[^>]*content=["\'](.*?)["\']')
    m = re.search(pattern, content, re.I | re.S)
    if not m:
        pattern = (rf'<meta[^>]+content=["\'](.*?)["\'][^>]*'
                   rf'(?:property|name)=["\']{re.escape(prop)}["\']')
        m = re.search(pattern, content, re.I | re.S)
    return html.unescape(m.group(1)).strip() if m else ""


def parse_count(text: str) -> Optional[int]:
    """'1 234 subscribers' / '12.5K members' / '3,8 Tsd.' -> int."""
    if not text:
        return None
    t = text.replace(" ", " ").replace("\xa0", " ").strip()
    m = re.search(r"([\d][\d\s.,]*)\s*([KkMm])?", t)
    if not m:
        return None
    num = m.group(1).strip()
    suffix = (m.group(2) or "").lower()
    if suffix:
        num = num.replace(",", ".")
        try:
            value = float(num)
        except ValueError:
            return None
        return int(value * (1_000 if suffix == "k" else 1_000_000))
    digits = re.sub(r"[^\d]", "", num)
    return int(digits) if digits else None


def slugify(text: str) -> str:
    """Freitext -> plausibler Telegram-Username-Kern."""
    return re.sub(r"[^a-z0-9_]", "", text.strip().lower().replace(" ", "_"))
