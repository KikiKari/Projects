"""Orchestrierung: alle Methoden gemeinsam ansprechen, Ergebnisse zusammenfuehren."""
from __future__ import annotations

from typing import Any, Optional

from .adapters import discord_bot as dc
from .adapters import telegram_bot as tb
from .adapters import telegram_mtproto as mt
from .adapters import telegram_web as tw
from .adapters import tiktok_live as tt
from .models import Channel, MethodStatus, Post

ALL_METHODS = ["web", "bot", "mtproto", "discord", "tiktok"]


def statuses(cfg: dict[str, Any]) -> list[MethodStatus]:
    return [tw.status(), tb.status(cfg), mt.status(cfg), dc.status(cfg),
            tt.status_method()]


def available_methods(cfg: dict[str, Any]) -> list[str]:
    out = ["web"]
    if tb.status(cfg).available:
        out.append("bot")
    if mt.status(cfg).available:
        out.append("mtproto")
    out.append("discord")           # Invite-Lookup geht immer
    out.append("tiktok")            # oeffentliche Quellen, kein Konto noetig
    return out


def _merge(primary: Channel, other: Channel) -> Channel:
    """Fehlende Felder aus einem zweiten Treffer ergaenzen."""
    for field in ("id", "description", "members", "avatar_url", "online"):
        if not getattr(primary, field) and getattr(other, field):
            setattr(primary, field, getattr(other, field))
    primary.readable = primary.readable or other.readable
    primary.public = primary.public or other.public
    primary.verified = primary.verified or other.verified
    sources = set(primary.source.split("+")) | set(other.source.split("+"))
    primary.source = "+".join(sorted(s for s in sources if s))
    return primary


def search(query: str, cfg: dict[str, Any], *, methods: Optional[list[str]] = None,
           limit: int = 20) -> dict[str, Any]:
    """Suche ueber alle gewaehlten Methoden, Ergebnisse dedupliziert."""
    methods = methods or available_methods(cfg)
    found: dict[str, Channel] = {}
    errors: list[dict[str, str]] = []
    used: list[str] = []

    def add(ch: Channel) -> None:
        k = ch.key()
        if k in found:
            found[k] = _merge(found[k], ch)
            found[k].confidence = max(found[k].confidence, ch.confidence)
        else:
            found[k] = ch

    if "mtproto" in methods and mt.status(cfg).available:
        try:
            for ch in mt.search(query, limit=limit, cfg=cfg):
                ch.confidence = 0.95 if (ch.username or "").lower() == query.lower().lstrip("@") else 0.8
                add(ch)
            used.append("mtproto")
        except Exception as exc:                       # noqa: BLE001
            errors.append({"method": "mtproto", "error": str(exc)})

    if "web" in methods:
        try:
            for ch in tw.search(query, limit=limit,
                                use_web=cfg.get("search", {}).get("use_web_discovery", True)):
                add(ch)
            used.append("web")
        except Exception as exc:                       # noqa: BLE001
            errors.append({"method": "web", "error": str(exc)})

    if "bot" in methods and tb.status(cfg).available:
        try:
            direct = tb.resolve(query, cfg)
            if direct:
                direct.confidence = 0.9
                add(direct)
            used.append("bot")
        except Exception as exc:                       # noqa: BLE001
            errors.append({"method": "bot", "error": str(exc)})

    if "discord" in methods:
        try:
            if dc.status(cfg).available:
                for ch in dc.search(query, cfg):
                    add(ch)
            inv = dc.invite_info(query)
            if inv:
                inv.confidence = 0.9
                add(inv)
            used.append("discord")
        except Exception as exc:                       # noqa: BLE001
            errors.append({"method": "discord", "error": str(exc)})

    results = sorted(found.values(),
                     key=lambda c: (c.confidence, c.members or 0), reverse=True)
    return {"query": query, "methods_used": used, "errors": errors,
            "count": len(results), "results": [c.to_dict() for c in results[:limit]]}


def resolve(target: str, cfg: dict[str, Any], platform: str = "telegram") -> Optional[dict[str, Any]]:
    if platform == "tiktok":
        ch = tt.resolve(target, cfg)
        return ch.to_dict() if ch else None
    if platform == "discord":
        ch = dc.invite_info(target)
        return ch.to_dict() if ch else None
    ch = tw.resolve(target)
    if tb.status(cfg).available:
        try:
            b = tb.resolve(target, cfg)
            if b:
                ch = _merge(ch, b) if ch else b
        except Exception:                              # noqa: BLE001
            pass
    if not ch and mt.status(cfg).available:
        try:
            ch = mt.resolve(target, cfg)
        except Exception:                              # noqa: BLE001
            pass
    return ch.to_dict() if ch else None


def posts(target: str, cfg: dict[str, Any], *, limit: int = 20,
          platform: str = "telegram") -> dict[str, Any]:
    if platform == "tiktok":
        items = tt.posts(target, limit, cfg)
        return {"target": target, "source": "tiktok-live",
                "live": tt.live_status(target), "count": len(items),
                "posts": [p.to_dict() for p in items]}
    if platform == "discord":
        items = dc.messages(target, limit, cfg)
        return {"target": target, "source": "discord-bot",
                "posts": [p.to_dict() for p in items]}

    items: list[Post] = tw.posts(target, limit)
    source = "telegram-web"
    if not items and mt.status(cfg).available:
        try:
            items = mt.posts(target, limit, cfg)
            source = "telegram-mtproto"
        except Exception:                              # noqa: BLE001
            pass
    return {"target": target, "source": source,
            "count": len(items), "posts": [p.to_dict() for p in items]}


def overview(targets: list[dict[str, str]], cfg: dict[str, Any],
             posts_per_channel: int = 5) -> dict[str, Any]:
    """Watchlist -> vollstaendige Uebersicht mit Kanalinfos und letzten Beitraegen."""
    out: list[dict[str, Any]] = []
    for item in targets:
        platform = item.get("platform", "telegram")
        target = item.get("target", "")
        entry: dict[str, Any] = {"platform": platform, "target": target,
                                 "note": item.get("note", "")}
        try:
            entry["channel"] = resolve(target, cfg, platform)
            if entry["channel"] and (entry["channel"].get("readable") or platform == "discord"):
                entry["posts"] = posts(target, cfg, limit=posts_per_channel,
                                       platform=platform).get("posts", [])
            else:
                entry["posts"] = []
        except Exception as exc:                       # noqa: BLE001
            entry["error"] = str(exc)
            entry["posts"] = []
        out.append(entry)
    return {"entries": out}
