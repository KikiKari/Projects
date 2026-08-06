"""Sehr einfache JSON-Ablage fuer Watchlist und Scan-Ergebnisse."""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from typing import Any

from .config import DATA_DIR

WATCHLIST = os.path.join(DATA_DIR, "watchlist.json")
SNAPSHOTS = os.path.join(DATA_DIR, "snapshots.json")


def _read(path: str, fallback: Any) -> Any:
    if not os.path.exists(path):
        return fallback
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (json.JSONDecodeError, OSError):
        return fallback


def _write(path: str, data: Any) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, indent=2)
    os.replace(tmp, path)


def watchlist() -> list[dict[str, Any]]:
    return _read(WATCHLIST, [])


def watch_add(platform: str, target: str, note: str = "") -> list[dict[str, Any]]:
    items = watchlist()
    key = f"{platform}:{target}".lower()
    if any(f"{i['platform']}:{i['target']}".lower() == key for i in items):
        return items
    items.append({"platform": platform, "target": target, "note": note,
                  "added_at": datetime.now(timezone.utc).isoformat(timespec="seconds")})
    _write(WATCHLIST, items)
    return items


def watch_remove(platform: str, target: str) -> list[dict[str, Any]]:
    key = f"{platform}:{target}".lower()
    items = [i for i in watchlist()
             if f"{i['platform']}:{i['target']}".lower() != key]
    _write(WATCHLIST, items)
    return items


def save_snapshot(payload: dict[str, Any]) -> None:
    snaps = _read(SNAPSHOTS, [])
    payload["at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    snaps.append(payload)
    _write(SNAPSHOTS, snaps[-200:])


def snapshots() -> list[dict[str, Any]]:
    return _read(SNAPSHOTS, [])
