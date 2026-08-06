"""Benachrichtigungen bei Zustandswechseln (z. B. Livegang).

Drei Wege, alle optional und einzeln abschaltbar:
  1. Ereignisprotokoll  data/events.json  (immer)
  2. Webhook            notify.webhook_url in config.json (POST mit JSON)
  3. Systemmeldung      notify.command (Platzhalter {title} {text} {url})
     Vorlage fuer Windows liegt in config.example.json.
"""
from __future__ import annotations

import json
import os
import shlex
import subprocess
import urllib.request
from datetime import datetime, timezone
from typing import Any, Optional

from .config import DATA_DIR

EVENTS = os.path.join(DATA_DIR, "events.json")
MAX_EVENTS = 500


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def events(limit: int = 100) -> list[dict[str, Any]]:
    if not os.path.exists(EVENTS):
        return []
    try:
        with open(EVENTS, "r", encoding="utf-8") as fh:
            return json.load(fh)[-limit:][::-1]      # neueste zuerst
    except (json.JSONDecodeError, OSError):
        return []


def _append(event: dict[str, Any]) -> None:
    os.makedirs(DATA_DIR, exist_ok=True)
    data: list[dict[str, Any]] = []
    if os.path.exists(EVENTS):
        try:
            with open(EVENTS, "r", encoding="utf-8") as fh:
                data = json.load(fh)
        except (json.JSONDecodeError, OSError):
            data = []
    data.append(event)
    tmp = EVENTS + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data[-MAX_EVENTS:], fh, ensure_ascii=False, indent=1)
    os.replace(tmp, EVENTS)


def _webhook(url: str, payload: dict[str, Any]) -> Optional[str]:
    try:
        req = urllib.request.Request(
            url, data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}, method="POST")
        with urllib.request.urlopen(req, timeout=15) as resp:
            return f"HTTP {resp.status}"
    except Exception as exc:                          # noqa: BLE001
        return f"Fehler: {exc}"


def _command(template: str, title: str, text: str, url: str) -> Optional[str]:
    cmd = (template.replace("{title}", title).replace("{text}", text)
                   .replace("{url}", url))
    try:
        subprocess.Popen(cmd if os.name == "nt" else shlex.split(cmd),
                         shell=(os.name == "nt"),
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return "gestartet"
    except Exception as exc:                          # noqa: BLE001
        return f"Fehler: {exc}"


def send(kind: str, title: str, text: str, url: str = "",
         cfg: Optional[dict[str, Any]] = None, **extra: Any) -> dict[str, Any]:
    """Ein Ereignis melden. kind z. B. 'live_start', 'live_end', 'neue_beitraege'."""
    cfg = cfg or {}
    n = cfg.get("notify", {}) or {}
    event = {"at": _now(), "kind": kind, "title": title, "text": text,
             "url": url, **extra}
    _append(event)
    print(f"  [{kind}] {title} — {text}")

    channels: dict[str, str] = {}
    if n.get("webhook_url"):
        channels["webhook"] = _webhook(n["webhook_url"],
                                       {"kind": kind, "title": title,
                                        "text": text, "url": url}) or "?"
    if n.get("command"):
        channels["command"] = _command(n["command"], title, text, url) or "?"
    if channels:
        event["delivered"] = channels
    return event
