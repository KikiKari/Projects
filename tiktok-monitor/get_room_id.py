#!/usr/bin/env python3
"""
get_room_id.py — One-shot TikTok user lookup via SIGI_STATE scrape.

Standalone tool. Python port of the browser-console SIGI_STATE snippet.
Takes a username, fetches /@<user>/live, extracts the embedded SIGI_STATE
JSON, and prints a flat record of identity + room fields to stdout.

This file is intentionally self-contained: no import of tt_live.py, no
shared helpers. It can be dropped anywhere on a system with Python 3.9+
and run on its own.

Usage:
  get_room_id.py <username>

Exit codes:
  0  user is currently live (room.status == 2)
  1  user is offline
  2  error: HTTP fetch failed, SIGI_STATE missing, sec_uid absent

stdout: one JSON object with these fields:
  unique_id    nickname     user_id    sec_uid
  room_id      status       title      start_time
  live         (bool, derived from status == 2)
  fetched_at   (UTC ISO 8601, second precision)
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


def parse_sigi_state(html_bytes: bytes) -> dict | None:
    """
    Locate <script id="SIGI_STATE" type="application/json">...</script>
    in the raw HTML and return the parsed JSON. Returns None on any
    failure: marker missing, unterminated script, JSON decode error.
    """
    try:
        html = html_bytes.decode("utf-8", errors="replace")
    except Exception:
        return None
    marker = '<script id="SIGI_STATE" type="application/json">'
    start = html.find(marker)
    if start < 0:
        return None
    start += len(marker)
    end = html.find("</script>", start)
    if end < 0:
        return None
    try:
        return json.loads(html[start:end])
    except json.JSONDecodeError:
        return None


def extract_record(sigi: dict) -> dict:
    """
    Flatten LiveRoom.liveRoomUserInfo to the eight fields produced by the
    original browser snippet, plus derived 'live' and 'fetched_at'.

    Source paths inside SIGI_STATE:
      uniqueId   <- LiveRoom.liveRoomUserInfo.user.uniqueId
      nickname   <- LiveRoom.liveRoomUserInfo.user.nickname
      userId     <- LiveRoom.liveRoomUserInfo.user.id
      secUid     <- LiveRoom.liveRoomUserInfo.user.secUid
      roomId     <- LiveRoom.liveRoomUserInfo.user.roomId
      status     <- LiveRoom.liveRoomUserInfo.liveRoom.status
      title      <- LiveRoom.liveRoomUserInfo.liveRoom.title
      startTime  <- LiveRoom.liveRoomUserInfo.liveRoom.startTime
    """
    lr = sigi.get("LiveRoom", {}).get("liveRoomUserInfo", {})
    user = lr.get("user", {}) or {}
    room = lr.get("liveRoom", {}) or {}
    status = room.get("status")

    room_id_raw = user.get("roomId")
    room_id = str(room_id_raw) if room_id_raw not in (None, "", "0", 0) else None

    return {
        "unique_id":  user.get("uniqueId"),
        "nickname":   user.get("nickname"),
        "user_id":    user.get("id"),
        "sec_uid":    user.get("secUid"),
        "room_id":    room_id,
        "status":     status,
        "title":      room.get("title"),
        "start_time": room.get("startTime"),
        "live":       (isinstance(status, int) and status == 2),
        "fetched_at": now_iso(),
    }


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main(argv: list[str]) -> int:
    if len(argv) != 2:
        sys.stderr.write("usage: get_room_id.py <username>\n")
        return 2

    username = argv[1].lstrip("@").strip()
    if not username or "/" in username or "\\" in username:
        sys.stderr.write(f"error: invalid username argument: {argv[1]!r}\n")
        return 2

    url = f"https://www.tiktok.com/@{username}/live"
    status, body = http_get(url)
    if status != 200 or not body:
        sys.stderr.write(
            f"error: failed to fetch {url} (status={status})\n"
        )
        return 2

    sigi = parse_sigi_state(body)
    if sigi is None:
        sys.stderr.write(
            f"error: SIGI_STATE not found or unparseable for @{username}\n"
        )
        return 2

    record = extract_record(sigi)
    if not record.get("sec_uid"):
        sys.stderr.write(
            f"error: SIGI_STATE missing user.secUid for @{username}\n"
        )
        return 2

    print(json.dumps(record, indent=2, ensure_ascii=False))
    return 0 if record["live"] else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
