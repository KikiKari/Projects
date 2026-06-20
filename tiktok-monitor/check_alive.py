#!/usr/bin/env python3
"""
check_alive.py — One-shot TikTok room liveness check.

Standalone tool. Python port of the browser-console check_alive snippet.
Takes a numeric room_id, calls webcast/room/check_alive, prints the
result as a flat JSON object to stdout.

Self-contained: no import of tt_live.py, no shared helpers.

Usage:
  check_alive.py <room_id>

Exit codes:
  0  room is alive
  1  room is NOT alive (offline / ended)
  2  error: usage, validation, HTTP fetch, or parse failure

stdout: one JSON object with these fields:
  room_id     (string, as passed in)
  alive       (bool)
  checked_at  (UTC ISO 8601, second precision)
"""

from __future__ import annotations

import json
import sys
import urllib.error
import urllib.request
from datetime import datetime, timezone


# ---------------------------------------------------------------------------
# Constants — match tt_live.py's values, intentionally duplicated to keep
# this tool standalone. If tt_live.py's constants change, mirror them here.
# ---------------------------------------------------------------------------

REQUEST_TIMEOUT_SEC = 15
TT_AID = "1988"  # TikTok webcast app id

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def now_iso() -> str:
    """UTC ISO 8601 with trailing Z, second precision."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def http_get(url: str) -> tuple[int, bytes]:
    """
    GET a URL via stdlib urllib. Returns (status, body_bytes).
    Returns (0, b'') on URL/network/timeout errors.
    """
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/json,*/*",
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": "https://www.tiktok.com/",
    }
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT_SEC) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        body = e.read() if hasattr(e, "read") else b""
        return e.code, body
    except (urllib.error.URLError, TimeoutError, OSError):
        return 0, b""


def check_alive(room_id: str) -> bool | None:
    """
    Call webcast/room/check_alive for a single room_id.

    Endpoint:
      https://webcast.tiktok.com/webcast/room/check_alive/?aid=1988&room_ids=<id>

    Response shape:
      { "data": [ { "alive": bool, "room_id": int } ], "status_code": 0, ... }

    Returns:
      True   if data[0].alive is truthy
      False  if data[0] exists and alive is falsy
      None   on any failure (non-200, JSON decode error, empty data array)
    """
    url = (
        f"https://webcast.tiktok.com/webcast/room/check_alive/"
        f"?aid={TT_AID}&room_ids={room_id}"
    )
    status, body = http_get(url)
    if status != 200 or not body:
        return None
    try:
        envelope = json.loads(body.decode("utf-8", errors="replace"))
    except json.JSONDecodeError:
        return None
    items = envelope.get("data") or []
    if not items:
        return None
    first = items[0] or {}
    return bool(first.get("alive"))


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    if len(argv) != 2:
        sys.stderr.write("usage: check_alive.py <room_id>\n")
        return 2

    room_id = argv[1].strip()
    if not room_id or not room_id.isdigit():
        sys.stderr.write(
            f"error: invalid room_id (must be numeric): {argv[1]!r}\n"
        )
        return 2

    alive = check_alive(room_id)
    if alive is None:
        sys.stderr.write(
            f"error: failed to check room_id {room_id} "
            f"(HTTP, parse, or empty response)\n"
        )
        return 2

    out = {
        "room_id":    room_id,
        "alive":      alive,
        "checked_at": now_iso(),
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0 if alive else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
