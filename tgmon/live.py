"""Fortlaufende Beobachtung: Kanaele im Turnus abfragen und Beitraege
inkrementell sammeln.

Kernidee: jeder Abruf holt nur die neuesten Beitraege und legt sie in einem
Verlauf ab (data/live/<plattform>_<ziel>.json). So entsteht ueber die Zeit
ein durchgehender Chat-Verlauf, auch wenn Telegram in der Web-Vorschau
immer nur einen Ausschnitt zeigt.
"""
from __future__ import annotations

import json
import os
import threading
import time
from datetime import datetime, timezone
from typing import Any, Callable, Optional

from .adapters import discord_bot as dc
from .adapters import telegram_mtproto as mt
from .adapters import telegram_web as tw
from .adapters import tiktok_live as tt
from .config import DATA_DIR

LIVE_DIR = os.path.join(DATA_DIR, "live")
MAX_KEEP = 500                      # Beitraege pro Kanal im Verlauf
_lock = threading.RLock()


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def _path(platform: str, target: str) -> str:
    safe = "".join(c if c.isalnum() or c in "_-" else "_" for c in target)
    return os.path.join(LIVE_DIR, f"{platform}_{safe}.json")


def read(platform: str, target: str) -> dict[str, Any]:
    p = _path(platform, target)
    if not os.path.exists(p):
        return {"platform": platform, "target": target, "posts": [],
                "last_poll": None, "last_new": None, "polls": 0, "errors": []}
    try:
        with open(p, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except (json.JSONDecodeError, OSError):
        return {"platform": platform, "target": target, "posts": [],
                "last_poll": None, "last_new": None, "polls": 0, "errors": []}


def _write(state: dict[str, Any]) -> None:
    os.makedirs(LIVE_DIR, exist_ok=True)
    p = _path(state["platform"], state["target"])
    tmp = p + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(state, fh, ensure_ascii=False, indent=1)
    os.replace(tmp, p)


def _sort_key(post: dict[str, Any]) -> tuple:
    """Nach Datum sortieren, bei Gleichstand nach numerischer Beitrags-ID."""
    ident = str(post.get("id") or "")
    tail = ident.split("/")[-1]
    return (post.get("date") or "", int(tail) if tail.isdigit() else 0)


def poll_once(platform: str, target: str, cfg: dict[str, Any],
              limit: int = 25) -> dict[str, Any]:
    """Einen Kanal abfragen und den Verlauf ergaenzen.

    Rueckgabe: {"new": [...], "total": n, "state": {...}}
    """
    with _lock:
        state = read(platform, target)

    fetched: list[dict[str, Any]] = []
    error: Optional[str] = None
    live_state: Optional[dict[str, Any]] = None
    try:
        if platform == "tiktok":
            live_state = tt.live_status(target)
            fetched = [p.to_dict() for p in tt.posts(target, limit, cfg)]
        elif platform == "discord":
            fetched = [p.to_dict() for p in dc.messages(target, limit, cfg)]
        else:
            fetched = [p.to_dict() for p in tw.posts(target, limit)]
            if not fetched and mt.status(cfg).available:
                fetched = [p.to_dict() for p in mt.posts(target, limit, cfg)]
    except Exception as exc:                     # noqa: BLE001
        error = f"{type(exc).__name__}: {exc}"

    with _lock:
        state = read(platform, target)
        known = {str(p.get("id")) for p in state["posts"]}
        new = [p for p in fetched if str(p.get("id")) not in known]
        for p in new:
            p["seen_at"] = _now()
        if new:
            state["posts"].extend(new)
            state["posts"].sort(key=_sort_key)
            state["posts"] = state["posts"][-MAX_KEEP:]
            state["last_new"] = _now()
        state["last_poll"] = _now()
        state["polls"] = int(state.get("polls", 0)) + 1
        if live_state is not None:
            was_live = bool((state.get("live") or {}).get("live"))
            state["live"] = live_state
            state["live_changed"] = (was_live != bool(live_state.get("live")))
        if error:
            state["errors"] = ([{"at": _now(), "error": error}] +
                               state.get("errors", []))[:10]
        _write(state)

    return {"new": new, "total": len(state["posts"]), "state": state,
            "live": live_state, "live_changed": state.get("live_changed", False)}


def history(platform: str, target: str, limit: int = 50) -> dict[str, Any]:
    state = read(platform, target)
    posts = sorted(state["posts"], key=_sort_key)[-limit:]
    return {"platform": platform, "target": target, "live": state.get("live"),
            "last_poll": state.get("last_poll"), "last_new": state.get("last_new"),
            "polls": state.get("polls", 0), "errors": state.get("errors", [])[:3],
            "count": len(posts), "total": len(state["posts"]),
            "posts": list(reversed(posts))}       # neueste zuerst


class Poller(threading.Thread):
    """Hintergrund-Thread: fragt alle Ziele in festem Turnus ab."""

    def __init__(self, targets_fn: Callable[[], list[dict[str, str]]],
                 cfg: dict[str, Any], interval: int = 120,
                 on_new: Optional[Callable[[str, str, list], None]] = None):
        super().__init__(daemon=True, name="tgmon-poller")
        self.targets_fn = targets_fn
        self.cfg = cfg
        self.interval = max(30, int(interval))    # unter 30 s waere unhoeflich
        self.on_new = on_new
        self.stop_event = threading.Event()
        self.last_run: Optional[str] = None
        self.next_run: Optional[float] = None
        self.cycles = 0

    def run(self) -> None:
        while not self.stop_event.is_set():
            started = time.time()
            try:
                for item in self.targets_fn():
                    if self.stop_event.is_set():
                        break
                    platform = item.get("platform", "telegram")
                    target = item.get("target", "")
                    if not target:
                        continue
                    res = poll_once(platform, target, self.cfg)
                    if res["new"] and self.on_new:
                        self.on_new(platform, target, res["new"])
                    if res.get("live_changed") and res.get("live") is not None:
                        from . import notify
                        st = res["live"]
                        if st.get("live"):
                            notify.send("live_start", f"{target} ist live",
                                        st.get("title") or "Sendung gestartet",
                                        st.get("live_url") or "", self.cfg,
                                        platform=platform, target=target,
                                        embed_url=st.get("embed_url"))
                        else:
                            notify.send("live_end", f"{target} ist offline",
                                        "Sendung beendet", st.get("profile_url") or "",
                                        self.cfg, platform=platform, target=target)
            except Exception as exc:              # noqa: BLE001
                print(f"  [poller] Fehler: {exc}")
            self.cycles += 1
            self.last_run = _now()
            self.next_run = started + self.interval
            self.stop_event.wait(max(1.0, self.interval - (time.time() - started)))

    def status(self) -> dict[str, Any]:
        return {"running": self.is_alive(), "interval": self.interval,
                "cycles": self.cycles, "last_run": self.last_run,
                "next_run_in": (max(0, int(self.next_run - time.time()))
                                if self.next_run else None)}

    def stop(self) -> None:
        self.stop_event.set()
