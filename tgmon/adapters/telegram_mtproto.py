"""Telegram-Adapter ueber MTProto / Telethon (Methode 3).

Das ist der einzige Weg zu einer ECHTEN Telegram-Kanalsuche
(contacts.search / SearchGlobal). Voraussetzungen:
  1. api_id + api_hash von https://my.telegram.org  ->  API development tools
  2. Einmaliger Login mit Telefonnummer + Code (Session wird lokal gespeichert)
  3. pip install telethon

Der Import erfolgt bewusst lazy, damit das restliche Projekt ohne
Telethon laeuft.
"""
from __future__ import annotations

import os
from typing import Any, Optional

from ..models import Channel, MethodStatus, Post

NAME = "telegram-mtproto"


def _creds(cfg: Optional[dict[str, Any]] = None) -> tuple[str, str, str]:
    tg = (cfg or {}).get("telegram", {})
    api_id = str(tg.get("api_id") or os.environ.get("TELEGRAM_API_ID", "")).strip()
    api_hash = str(tg.get("api_hash") or os.environ.get("TELEGRAM_API_HASH", "")).strip()
    session = str(tg.get("session") or os.environ.get("TELEGRAM_SESSION", "tgmon")).strip()
    return api_id, api_hash, session


def _telethon_available() -> bool:
    try:
        import telethon  # noqa: F401
        return True
    except ImportError:
        return False


def status(cfg: Optional[dict[str, Any]] = None) -> MethodStatus:
    api_id, api_hash, _ = _creds(cfg)
    if not _telethon_available():
        return MethodStatus(NAME, "telegram", False,
                            "Telethon fehlt - 'pip install telethon'.", [])
    if not (api_id and api_hash):
        return MethodStatus(
            NAME, "telegram", False,
            "api_id/api_hash fehlen - von https://my.telegram.org holen.", [])
    return MethodStatus(NAME, "telegram", True,
                        "Telethon + Zugangsdaten vorhanden (Login beim ersten Lauf).",
                        ["global-search", "resolve", "posts", "private-channels"])


def _client(cfg: Optional[dict[str, Any]] = None):
    from telethon.sync import TelegramClient
    api_id, api_hash, session = _creds(cfg)
    if not (api_id and api_hash):
        raise RuntimeError("api_id/api_hash fehlen (my.telegram.org).")
    sess_dir = os.path.join(os.path.dirname(os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))), "data")
    os.makedirs(sess_dir, exist_ok=True)
    return TelegramClient(os.path.join(sess_dir, session), int(api_id), api_hash)


def _to_channel(entity: Any) -> Channel:
    username = getattr(entity, "username", None)
    kind = "channel"
    if getattr(entity, "megagroup", False):
        kind = "group"
    if entity.__class__.__name__ == "User":
        kind = "bot" if getattr(entity, "bot", False) else "user"
    title = getattr(entity, "title", None) or " ".join(filter(None, [
        getattr(entity, "first_name", None), getattr(entity, "last_name", None)])) or ""
    return Channel(
        platform="telegram", kind=kind, id=str(getattr(entity, "id", "")),
        username=username, title=title,
        description=getattr(entity, "about", "") or "",
        url=f"https://t.me/{username}" if username else "",
        members=getattr(entity, "participants_count", None),
        public=bool(username), readable=True, verified=bool(getattr(entity, "verified", False)),
        source=NAME,
    )


def search(query: str, limit: int = 30, cfg: Optional[dict[str, Any]] = None) -> list[Channel]:
    """Echte globale Telegram-Suche nach Kanaelen, Gruppen und Nutzern."""
    from telethon.tl import functions
    out: list[Channel] = []
    with _client(cfg) as client:
        res = client(functions.contacts.SearchRequest(q=query, limit=limit))
        for entity in list(res.chats) + list(res.users):
            out.append(_to_channel(entity))
    return out


def resolve(username: str, cfg: Optional[dict[str, Any]] = None) -> Optional[Channel]:
    with _client(cfg) as client:
        try:
            entity = client.get_entity(username.lstrip("@"))
        except Exception:
            return None
        ch = _to_channel(entity)
        try:
            full = client.get_participants(entity, limit=0)
            ch.members = getattr(full, "total", ch.members)
        except Exception:
            pass
        return ch


def posts(username: str, limit: int = 20, cfg: Optional[dict[str, Any]] = None) -> list[Post]:
    """Beitraege lesen - funktioniert auch fuer Kanaele ohne Web-Vorschau,
    sofern der eingeloggte Account sie sehen darf."""
    out: list[Post] = []
    with _client(cfg) as client:
        entity = client.get_entity(username.lstrip("@"))
        uname = getattr(entity, "username", None) or username.lstrip("@")
        for msg in client.iter_messages(entity, limit=limit):
            out.append(Post(
                platform="telegram", channel=uname, id=str(msg.id),
                url=f"https://t.me/{uname}/{msg.id}" if uname else "",
                date=msg.date.isoformat(timespec="seconds") if msg.date else None,
                text=msg.message or "", views=getattr(msg, "views", None),
                media=[{"type": msg.media.__class__.__name__, "url": ""}] if msg.media else [],
                source=NAME,
            ))
    return out
