#!/usr/bin/env python3
"""
tt_live.py — TikTok LIVE monitor

Subcommands
-----------
  check  <username>   One-shot live status check; JSON to stdout
                      Exit 0 = live, 1 = offline, 2 = error
  url    <username>   Resolve current m3u8 stream URL; URL to stdout
                      Exit 0 = ok, 1 = offline, 2 = error
  daemon <username>   Poll over a timer window; emit events on transitions
                      Args: --hours N (default 12), --poll-min M (min 5)
                      Exit 0 always at clean end

Design
------
- stdlib only (urllib + json + subprocess for optional fallbacks)
- Identity store: secUid is the primary key; uniqueId is a pointer with a
  "current" flag and a rename history
- State store: per-secUid, stream URLs retained 3 days via passive stale-strip
- Event log: append-only line file per secUid; sub-agents tail it and announce
- SIGI_STATE only; no UNIVERSAL_DATA fallback
- Stream extraction order: direct webcast API -> yt-dlp -> streamlink
- Hardcoded 360p format cap; not configurable
- No Notifier class. No outbound notifications. Sub-agents own announcement.

Workspace
---------
  $TT_LIVE_WORKSPACE  ||  ~/.openclaw/workspace/tiktok-monitor/

  workspace/
    tiktok-names/identities/<sec_uid>.json
    tiktok-names/pointers/<unique_id>.json
    state/tt-live/<sec_uid>.state.json
    state/tt-live/<sec_uid>.events
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


# ============================================================================
# Constants — none of these are configurable at runtime by design
# ============================================================================

FORMAT_CAP = "360"               # hardcoded; not configurable
MIN_POLL_MINUTES = 5             # daemon poll floor
DEFAULT_DAEMON_HOURS = 12        # daemon default duration
URL_RETENTION_DAYS = 3           # stream URL retention in state store
REQUEST_TIMEOUT_SEC = 15         # per HTTP request
TT_AID = "1988"                  # TikTok webcast app id

USER_AGENT = (
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
)

DEFAULT_WORKSPACE = Path.home() / ".openclaw" / "workspace" / "tiktok-monitor"


# ============================================================================
# Workspace
# ============================================================================

def resolve_workspace() -> Path:
    """Pick workspace root: env override TT_LIVE_WORKSPACE or default."""
    env = os.environ.get("TT_LIVE_WORKSPACE", "").strip()
    if env:
        return Path(env).expanduser().resolve()
    return DEFAULT_WORKSPACE


def ensure_dirs(ws: Path) -> None:
    """Create workspace subdirectories if missing."""
    (ws / "tiktok-names" / "identities").mkdir(parents=True, exist_ok=True)
    (ws / "tiktok-names" / "pointers").mkdir(parents=True, exist_ok=True)
    (ws / "state" / "tt-live").mkdir(parents=True, exist_ok=True)


def now_iso() -> str:
    """UTC ISO-8601 with trailing Z, second precision."""
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


# ============================================================================
# HTTP
# ============================================================================

def http_get(url: str,
             timeout: int = REQUEST_TIMEOUT_SEC,
             extra_headers: dict | None = None) -> tuple[int, bytes]:
    """GET via stdlib urllib. Returns (status, body_bytes)."""
    headers = {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/json,*/*",
        "Accept-Language": "en-US,en;q=0.9",
        "Referer": "https://www.tiktok.com/",
    }
    if extra_headers:
        headers.update(extra_headers)
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        body = e.read() if hasattr(e, "read") else b""
        return e.code, body
    except (urllib.error.URLError, TimeoutError, OSError):
        return 0, b""


# ============================================================================
# SIGI_STATE scrape
# ============================================================================

def parse_sigi_state(html_bytes: bytes) -> dict | None:
    """Extract <script id="SIGI_STATE" ...> JSON from a TikTok page."""
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


def fetch_user_live_page(username: str) -> dict | None:
    """GET /@<user>/live, scrape SIGI_STATE, return flattened identity+room dict."""
    url = f"https://www.tiktok.com/@{username}/live"
    status, body = http_get(url)
    if status != 200 or not body:
        return None
    state = parse_sigi_state(body)
    if not state:
        return None
    lr = state.get("LiveRoom", {}).get("liveRoomUserInfo", {})
    user = lr.get("user", {}) or {}
    room = lr.get("liveRoom", {}) or {}
    return {
        "unique_id": user.get("uniqueId"),
        "nickname": user.get("nickname"),
        "user_id": user.get("id"),
        "sec_uid": user.get("secUid"),
        "room_id": user.get("roomId"),
        "status": room.get("status"),
        "title": room.get("title"),
        "start_time": room.get("startTime"),
    }


def is_live_from_sigi(record: dict) -> bool:
    """Live if status==2 (TikTok webcast LIVE state); else fall back to roomId."""
    status = record.get("status")
    room_id = record.get("room_id")
    if isinstance(status, int):
        return status == 2
    return bool(room_id) and str(room_id) != "0"


# ============================================================================
# Webcast API (room_info, check_alive)
# ============================================================================

def fetch_room_info(room_id: str) -> dict | None:
    """webcast/room/info — returns data dict or None."""
    url = (
        f"https://webcast.tiktok.com/webcast/room/info/"
        f"?aid={TT_AID}&room_id={room_id}"
    )
    status, body = http_get(url)
    if status != 200 or not body:
        return None
    try:
        envelope = json.loads(body.decode("utf-8", errors="replace"))
    except json.JSONDecodeError:
        return None
    return envelope.get("data") or None


def fetch_check_alive(room_id: str) -> bool | None:
    """webcast/room/check_alive — True/False or None on error."""
    url = (
        f"https://webcast.tiktok.com/webcast/room/check_alive/"
        f"?aid={TT_AID}&room_ids={room_id}"
    )
    status, body = http_get(url)
    if status != 200 or not body:
        return None
    try:
        data = json.loads(body.decode("utf-8", errors="replace"))
    except json.JSONDecodeError:
        return None
    items = data.get("data") or []
    if not items:
        return None
    return bool((items[0] or {}).get("alive"))


# ============================================================================
# Stream URL extraction
# ============================================================================

# Quality key → estimated height. Used for the 360p cap preference.
# TikTok keys observed in stream_data: origin, uhd_60, hd_60, hd, sd, ld, ao
QUALITY_HEIGHT = {
    "ao": 0,        # audio-only; excluded unless nothing else
    "ld": 360,
    "sd": 540,
    "hd": 720,
    "hd_60": 720,
    "uhd_60": 1080,
    "origin": 1080,
}


def pick_360p_hls(room_info: dict) -> str | None:
    """
    Pick the best HLS m3u8 URL under the 360p cap.

    Preference:
      1. "ld" (360p) exact match
      2. closest available <= 360 by height
      3. lowest-quality available over the cap (better than nothing)
    Audio-only ("ao") is excluded unless nothing else is available.
    """
    if not room_info:
        return None
    stream_url = room_info.get("stream_url") or {}
    if not stream_url:
        return None

    candidates: list[tuple[str, str]] = []

    # Layout A: stream_url.live_core_sdk_data.pull_data.stream_data
    # stream_data is JSON-encoded string; data.<quality>.main.hls is the URL
    sdk = stream_url.get("live_core_sdk_data") or {}
    pull = sdk.get("pull_data") or {}
    sd_raw = pull.get("stream_data")
    if isinstance(sd_raw, str):
        try:
            sd = json.loads(sd_raw)
        except json.JSONDecodeError:
            sd = None
        if sd:
            data = sd.get("data") or {}
            for key, quality_obj in data.items():
                main = (quality_obj or {}).get("main") or {}
                hls = main.get("hls")
                if isinstance(hls, str) and hls:
                    candidates.append((key, hls))

    # Layout B: stream_url.hls_pull_url_map (flat dict)
    hls_map = stream_url.get("hls_pull_url_map")
    if isinstance(hls_map, dict):
        for key, url in hls_map.items():
            if isinstance(url, str) and url:
                candidates.append((key, url))

    if not candidates:
        return None

    # Exclude audio-only first; if all are audio-only, allow them
    non_audio = [c for c in candidates if c[0] != "ao"]
    pool = non_audio if non_audio else candidates

    def sort_key(kv: tuple[str, str]) -> tuple[int, int]:
        key, _url = kv
        height = QUALITY_HEIGHT.get(key, 9999)
        if key == "ld":
            return (0, 0)             # best preference
        if height <= 360:
            return (1, -height)       # under cap; larger height under cap = better
        return (2, height)            # over cap; smaller height = closer to cap

    pool.sort(key=sort_key)
    return pool[0][1]


def extract_via_ytdlp(username: str) -> str | None:
    """Use yt-dlp -g if available; respect 360p cap."""
    if not shutil.which("yt-dlp"):
        return None
    cmd = [
        "yt-dlp",
        "-g",
        "-f", "best[height<=360]/worst[height<=360]/worst",
        f"https://www.tiktok.com/@{username}/live",
    ]
    try:
        out = subprocess.run(
            cmd, capture_output=True, text=True,
            timeout=REQUEST_TIMEOUT_SEC * 2,
        )
    except (subprocess.TimeoutExpired, OSError):
        return None
    if out.returncode != 0:
        return None
    lines = [ln.strip() for ln in (out.stdout or "").splitlines() if ln.strip()]
    if not lines:
        return None
    for ln in lines:
        if ".m3u8" in ln:
            return ln
    return lines[0]


def extract_via_streamlink(username: str) -> str | None:
    """Use streamlink --stream-url if available."""
    if not shutil.which("streamlink"):
        return None
    cmd = [
        "streamlink",
        "--stream-url",
        f"https://www.tiktok.com/@{username}/live",
        "360p,worst",
    ]
    try:
        out = subprocess.run(
            cmd, capture_output=True, text=True,
            timeout=REQUEST_TIMEOUT_SEC * 2,
        )
    except (subprocess.TimeoutExpired, OSError):
        return None
    if out.returncode != 0:
        return None
    line = (out.stdout or "").strip()
    return line or None


def extract_stream_url(room_id: str, username: str) -> tuple[str | None, str]:
    """
    Orchestrate primary (direct API) and optional fallbacks (yt-dlp, streamlink).
    Returns (url, source). Source is 'api' / 'yt-dlp' / 'streamlink' / 'none'.
    """
    # Primary: direct webcast API
    info = fetch_room_info(room_id)
    if info:
        url = pick_360p_hls(info)
        if url:
            return url, "api"

    # Fallback 1: yt-dlp
    url = extract_via_ytdlp(username)
    if url:
        return url, "yt-dlp"

    # Fallback 2: streamlink
    url = extract_via_streamlink(username)
    if url:
        return url, "streamlink"

    return None, "none"


# ============================================================================
# Identity store
# ============================================================================

class IdentityStore:
    """
    Filesystem identity registry.

      identities/<sec_uid>.json   — canonical record per user (sec_uid is primary key)
      pointers/<unique_id>.json   — uniqueId -> sec_uid pointer with current flag

    Username renames are detected by comparing prior unique_id_current with the
    fresh scrape's unique_id for the same sec_uid. Old pointer rows stay on
    disk but get current=false so historical lookups still resolve.
    """

    def __init__(self, workspace: Path):
        self.ident_dir = workspace / "tiktok-names" / "identities"
        self.ptr_dir = workspace / "tiktok-names" / "pointers"

    def _ident_path(self, sec_uid: str) -> Path:
        return self.ident_dir / f"{sec_uid}.json"

    def _ptr_path(self, unique_id: str) -> Path:
        return self.ptr_dir / f"{unique_id}.json"

    def load_identity(self, sec_uid: str) -> dict | None:
        p = self._ident_path(sec_uid)
        if not p.exists():
            return None
        try:
            return json.loads(p.read_text("utf-8"))
        except (OSError, json.JSONDecodeError):
            return None

    def save_identity(self, sec_uid: str, record: dict) -> None:
        record["sec_uid"] = sec_uid
        record["last_seen"] = now_iso()
        if "first_seen" not in record:
            record["first_seen"] = record["last_seen"]
        self._ident_path(sec_uid).write_text(
            json.dumps(record, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def load_pointer(self, unique_id: str) -> dict | None:
        p = self._ptr_path(unique_id)
        if not p.exists():
            return None
        try:
            return json.loads(p.read_text("utf-8"))
        except (OSError, json.JSONDecodeError):
            return None

    def write_pointer(self, unique_id: str, sec_uid: str,
                      current: bool = True) -> None:
        existing = self.load_pointer(unique_id) or {}
        ts = now_iso()
        record = {
            "unique_id": unique_id,
            "sec_uid": sec_uid,
            "current": current,
            "first_pointed_at": existing.get("first_pointed_at", ts),
            "last_pointed_at": ts,
        }
        self._ptr_path(unique_id).write_text(
            json.dumps(record, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def resolve_sec_uid(self, username: str) -> str | None:
        """Look up sec_uid via pointer file. Returns None if no pointer."""
        ptr = self.load_pointer(username)
        return ptr.get("sec_uid") if ptr else None

    def update_from_scrape(self, scrape: dict) -> tuple[str | None, bool]:
        """
        Update identity + pointer files from a fresh scrape.
        Returns (sec_uid, rename_detected).
        """
        sec_uid = scrape.get("sec_uid")
        unique_id = scrape.get("unique_id")
        if not sec_uid or not unique_id:
            return None, False

        existing = self.load_identity(sec_uid) or {}
        prev_unique = existing.get("unique_id_current")
        rename_detected = bool(prev_unique) and prev_unique != unique_id

        new_record: dict[str, Any] = {
            "sec_uid": sec_uid,
            "unique_id_current": unique_id,
            "nickname": scrape.get("nickname"),
            "user_id": scrape.get("user_id"),
        }
        if existing:
            new_record["first_seen"] = existing.get("first_seen")
            history = existing.get("rename_history") or []
            if rename_detected:
                history.append({
                    "from": prev_unique,
                    "to": unique_id,
                    "detected_at": now_iso(),
                })
                # Mark old pointer not-current
                old_ptr = self.load_pointer(prev_unique) or {}
                if old_ptr.get("sec_uid") == sec_uid:
                    old_ptr["current"] = False
                    old_ptr["last_pointed_at"] = now_iso()
                    self._ptr_path(prev_unique).write_text(
                        json.dumps(old_ptr, indent=2, ensure_ascii=False),
                        encoding="utf-8",
                    )
            if history:
                new_record["rename_history"] = history

        self.save_identity(sec_uid, new_record)
        self.write_pointer(unique_id, sec_uid, current=True)
        return sec_uid, rename_detected


# ============================================================================
# State store
# ============================================================================

class StateStore:
    """
    Per-secUid live state + stream URL cache.

      <sec_uid>.state.json = {
        "sec_uid": "...",
        "is_live": bool,
        "current_room_id": "..." | null,
        "last_check_ts": iso,
        "stream_urls": [ {"room_id": "...", "url": "...", "captured_at": iso}, ... ]
      }

    Stream URL retention is enforced by passive stale-strip called on every
    state write path (no active garbage collector).
    """

    def __init__(self, workspace: Path):
        self.dir = workspace / "state" / "tt-live"

    def _path(self, sec_uid: str) -> Path:
        return self.dir / f"{sec_uid}.state.json"

    def _default(self, sec_uid: str) -> dict:
        return {
            "sec_uid": sec_uid,
            "is_live": False,
            "current_room_id": None,
            "last_check_ts": None,
            "stream_urls": [],
        }

    def read(self, sec_uid: str) -> dict:
        p = self._path(sec_uid)
        if not p.exists():
            return self._default(sec_uid)
        try:
            return json.loads(p.read_text("utf-8"))
        except (OSError, json.JSONDecodeError):
            return self._default(sec_uid)

    def write(self, sec_uid: str, state: dict) -> None:
        state["sec_uid"] = sec_uid
        self._path(sec_uid).write_text(
            json.dumps(state, indent=2, ensure_ascii=False),
            encoding="utf-8",
        )

    def add_url(self, sec_uid: str, room_id: str, url: str) -> None:
        state = self.read(sec_uid)
        urls = state.get("stream_urls") or []
        for entry in urls:
            if entry.get("room_id") == room_id and entry.get("url") == url:
                return
        urls.append({
            "room_id": room_id,
            "url": url,
            "captured_at": now_iso(),
        })
        state["stream_urls"] = urls
        self.write(sec_uid, state)

    def strip_stale_urls(self, sec_uid: str,
                         days: int = URL_RETENTION_DAYS) -> None:
        state = self.read(sec_uid)
        urls = state.get("stream_urls") or []
        if not urls:
            return
        cutoff = time.time() - days * 86400
        fresh = []
        for entry in urls:
            captured = entry.get("captured_at")
            try:
                ts = datetime.strptime(captured, "%Y-%m-%dT%H:%M:%SZ").replace(
                    tzinfo=timezone.utc
                ).timestamp()
            except (ValueError, TypeError):
                continue  # malformed timestamp -> drop entry
            if ts >= cutoff:
                fresh.append(entry)
        if len(fresh) != len(urls):
            state["stream_urls"] = fresh
            self.write(sec_uid, state)

    def get_latest_url(self, sec_uid: str,
                       room_id: str | None = None) -> str | None:
        state = self.read(sec_uid)
        urls = state.get("stream_urls") or []
        if not urls:
            return None
        if room_id:
            for entry in reversed(urls):
                if entry.get("room_id") == room_id:
                    return entry.get("url")
        return urls[-1].get("url")


# ============================================================================
# Event writer
# ============================================================================

class EventWriter:
    """
    Append-only line writer for daemon-mode events.

    Line format:
      ts=<iso> evt=<type> sec_uid=<...> unique_id=<...> [k=v ...] [stream_url=...]

    - ts is always first, evt always second, then sec_uid, then unique_id
    - stream_url is always LAST if present (so values containing & and =
      don't need escaping; parsers can take the substring after 'stream_url=')
    - Values must not contain spaces; URLs are already space-free
    """

    def __init__(self, workspace: Path, sec_uid: str):
        self.path = workspace / "state" / "tt-live" / f"{sec_uid}.events"

    def write(self, evt: str, **fields: Any) -> None:
        ts = now_iso()
        sec_uid = fields.pop("sec_uid", "")
        unique_id = fields.pop("unique_id", "")
        stream_url = fields.pop("stream_url", None)

        parts = [f"ts={ts}", f"evt={evt}"]
        if sec_uid:
            parts.append(f"sec_uid={sec_uid}")
        if unique_id:
            parts.append(f"unique_id={unique_id}")
        for k, v in fields.items():
            if v is None:
                continue
            parts.append(f"{k}={v}")
        if stream_url:
            parts.append(f"stream_url={stream_url}")

        line = " ".join(parts) + "\n"
        with self.path.open("a", encoding="utf-8") as f:
            f.write(line)


# ============================================================================
# Subcommand: check
# ============================================================================

def cmd_check(args: argparse.Namespace) -> int:
    """
    One-shot scrape + identity update.
    Emits a JSON record to stdout.
    Exit 0 = live, 1 = offline, 2 = error.
    """
    ws = resolve_workspace()
    ensure_dirs(ws)
    ids = IdentityStore(ws)
    state_store = StateStore(ws)

    username = args.username
    scrape = fetch_user_live_page(username)
    if not scrape:
        sys.stderr.write(f"error: could not fetch /@{username}/live\n")
        return 2
    if not scrape.get("sec_uid"):
        sys.stderr.write(
            f"error: SIGI_STATE missing user.secUid for /@{username}\n"
        )
        return 2

    sec_uid, rename = ids.update_from_scrape(scrape)
    if not sec_uid:
        sys.stderr.write("error: identity update failed\n")
        return 2

    live = is_live_from_sigi(scrape)
    room_id = scrape.get("room_id") if live else None

    state = state_store.read(sec_uid)
    state["is_live"] = live
    state["current_room_id"] = str(room_id) if room_id else None
    state["last_check_ts"] = now_iso()
    state_store.write(sec_uid, state)
    state_store.strip_stale_urls(sec_uid)

    out = {
        "sec_uid": sec_uid,
        "unique_id": scrape.get("unique_id"),
        "nickname": scrape.get("nickname"),
        "user_id": scrape.get("user_id"),
        "live": live,
        "room_id": str(room_id) if room_id else None,
        "title": scrape.get("title") if live else None,
        "start_time": scrape.get("start_time") if live else None,
        "rename_detected": rename,
        "checked_at": now_iso(),
    }
    print(json.dumps(out, indent=2, ensure_ascii=False))
    return 0 if live else 1


# ============================================================================
# Subcommand: url
# ============================================================================

def cmd_url(args: argparse.Namespace) -> int:
    """
    Resolve current m3u8 stream URL for a live user.
    Prints the URL to stdout. Exit 0 = ok, 1 = offline, 2 = error.
    """
    ws = resolve_workspace()
    ensure_dirs(ws)
    ids = IdentityStore(ws)
    state_store = StateStore(ws)

    username = args.username

    scrape = fetch_user_live_page(username)
    if not scrape:
        sys.stderr.write(f"error: could not fetch /@{username}/live\n")
        return 2

    sec_uid, _ = ids.update_from_scrape(scrape)
    if not sec_uid:
        sys.stderr.write("error: identity update failed\n")
        return 2

    if not is_live_from_sigi(scrape):
        sys.stderr.write(f"error: @{username} is not live\n")
        return 1

    room_id = scrape.get("room_id")
    if not room_id or str(room_id) == "0":
        sys.stderr.write(f"error: no room_id for live user @{username}\n")
        return 2
    room_id = str(room_id)

    cached = state_store.get_latest_url(sec_uid, room_id)
    if cached:
        print(cached)
        if args.verbose:
            sys.stderr.write("# source: cache\n")
        return 0

    url, source = extract_stream_url(room_id, username)
    if not url:
        sys.stderr.write(
            "error: could not extract stream URL "
            "(tried direct API, yt-dlp, streamlink)\n"
        )
        return 2
    state_store.add_url(sec_uid, room_id, url)
    state_store.strip_stale_urls(sec_uid)

    print(url)
    if args.verbose:
        sys.stderr.write(f"# source: {source}\n")
    return 0


# ============================================================================
# Subcommand: daemon
# ============================================================================

def cmd_daemon(args: argparse.Namespace) -> int:
    """
    Poll the user over a timer window. Emit events on transitions.
    Returns 0 at clean end (timer expired or interrupted).
    """
    ws = resolve_workspace()
    ensure_dirs(ws)
    ids = IdentityStore(ws)
    state_store = StateStore(ws)

    username = args.username
    hours = max(1, int(args.hours))
    poll_min = max(MIN_POLL_MINUTES, int(args.poll_min))
    poll_sec = poll_min * 60

    # Anchor identity with first scrape
    first = fetch_user_live_page(username)
    if not first or not first.get("sec_uid"):
        sys.stderr.write(
            f"error: could not anchor identity for @{username}\n"
        )
        return 2
    sec_uid, _ = ids.update_from_scrape(first)
    if not sec_uid:
        sys.stderr.write("error: identity update failed\n")
        return 2

    events = EventWriter(ws, sec_uid)
    unique_id = first.get("unique_id")

    deadline = time.time() + hours * 3600
    transitions = 0
    last_was_live = state_store.read(sec_uid).get("is_live", False)
    end_reason = "timer_expired"

    events.write(
        "daemon_start",
        sec_uid=sec_uid,
        unique_id=unique_id,
        hours=hours,
        poll_sec=poll_sec,
    )
    sys.stderr.write(
        f"[tt-live] daemon started for @{username} "
        f"(sec_uid={sec_uid[:16]}..., hours={hours}, poll={poll_min}min)\n"
    )

    try:
        while time.time() < deadline:
            scrape = fetch_user_live_page(username)
            if not scrape:
                events.write(
                    "poll_err",
                    sec_uid=sec_uid,
                    unique_id=unique_id,
                    reason="fetch_failed",
                )
                _sleep_until(deadline, poll_sec)
                continue

            new_sec_uid, rename = ids.update_from_scrape(scrape)
            if new_sec_uid and new_sec_uid != sec_uid:
                events.write(
                    "poll_err",
                    sec_uid=sec_uid,
                    unique_id=unique_id,
                    reason="sec_uid_changed",
                    new_sec_uid=new_sec_uid,
                )
                _sleep_until(deadline, poll_sec)
                continue

            if rename:
                new_unique = scrape.get("unique_id")
                events.write(
                    "rename_detected",
                    sec_uid=sec_uid,
                    unique_id=new_unique,
                    old_unique_id=unique_id,
                )
                unique_id = new_unique

            live = is_live_from_sigi(scrape)
            events.write(
                "poll_ok",
                sec_uid=sec_uid,
                unique_id=unique_id,
                alive=("true" if live else "false"),
            )

            if live and not last_was_live:
                room_id = str(scrape.get("room_id") or "")
                if room_id:
                    url, _src = extract_stream_url(room_id, username)
                    if url:
                        state_store.add_url(sec_uid, room_id, url)
                else:
                    url = None
                st = state_store.read(sec_uid)
                st["is_live"] = True
                st["current_room_id"] = room_id or None
                st["last_check_ts"] = now_iso()
                state_store.write(sec_uid, st)
                state_store.strip_stale_urls(sec_uid)
                events.write(
                    "go_live",
                    sec_uid=sec_uid,
                    unique_id=unique_id,
                    room_id=room_id,
                    stream_url=url,  # stream_url must be the LAST key
                )
                transitions += 1
                last_was_live = True

            elif not live and last_was_live:
                st = state_store.read(sec_uid)
                last_room = st.get("current_room_id")
                st["is_live"] = False
                st["current_room_id"] = None
                st["last_check_ts"] = now_iso()
                state_store.write(sec_uid, st)
                state_store.strip_stale_urls(sec_uid)
                events.write(
                    "go_offline",
                    sec_uid=sec_uid,
                    unique_id=unique_id,
                    last_room_id=last_room,
                )
                transitions += 1
                last_was_live = False

            else:
                # No transition; still keep stale URLs trimmed
                state_store.strip_stale_urls(sec_uid)

            _sleep_until(deadline, poll_sec)

    except KeyboardInterrupt:
        end_reason = "interrupted"

    events.write(
        "daemon_end",
        sec_uid=sec_uid,
        unique_id=unique_id,
        reason=end_reason,
        transitions=transitions,
    )
    sys.stderr.write(
        f"[tt-live] daemon ended ({end_reason}, transitions={transitions})\n"
    )
    return 0


def _sleep_until(deadline: float, max_sleep: int) -> None:
    """Sleep up to max_sleep seconds, capped at remaining time before deadline."""
    remaining = deadline - time.time()
    if remaining <= 0:
        return
    time.sleep(min(max_sleep, max(1.0, remaining)))


# ============================================================================
# Argparse / main
# ============================================================================

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="tt_live.py",
        description="TikTok LIVE monitor — check, url, daemon",
    )
    sub = p.add_subparsers(dest="cmd", required=True)

    p_check = sub.add_parser(
        "check",
        help="One-shot live status check; JSON to stdout",
    )
    p_check.add_argument("username", help="TikTok @username (no @)")
    p_check.set_defaults(func=cmd_check)

    p_url = sub.add_parser(
        "url",
        help="Print current m3u8 stream URL (cached or fresh)",
    )
    p_url.add_argument("username")
    p_url.add_argument(
        "--verbose", "-v", action="store_true",
        help="Print extraction source to stderr",
    )
    p_url.set_defaults(func=cmd_url)

    p_daemon = sub.add_parser(
        "daemon",
        help="Poll user over a timer window; emit events on transitions",
    )
    p_daemon.add_argument("username")
    p_daemon.add_argument(
        "--hours", type=int, default=DEFAULT_DAEMON_HOURS,
        help=f"Watch duration in hours (default {DEFAULT_DAEMON_HOURS})",
    )
    p_daemon.add_argument(
        "--poll-min", type=int, default=MIN_POLL_MINUTES,
        help=f"Poll interval in minutes (floor {MIN_POLL_MINUTES})",
    )
    p_daemon.set_defaults(func=cmd_daemon)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
