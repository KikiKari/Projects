"""Telegram-Adapter ueber die Bot-API (Methode 2).

Braucht einen Bot-Token von @BotFather. Wichtig zu wissen:
  * Die Bot-API kann NICHT nach Kanaelen suchen.
  * getChat funktioniert aber fuer jeden OEFFENTLICHEN @namen und liefert
    verlaessliche Metadaten (Titel, Beschreibung, Typ, Mitgliederzahl).
  * Nachrichten lesen geht nur in Chats, in denen der Bot Mitglied/Admin ist.
"""
from __future__ import annotations

import json
import os
from typing import Any, Optional

from ..models import Channel, MethodStatus, Post
from ..util import HttpError, fetch_json

NAME = "telegram-bot"
API = "https://api.telegram.org"


def _token(cfg: Optional[dict[str, Any]] = None) -> str:
    cfg = cfg or {}
    return (cfg.get("telegram", {}).get("bot_token")
            or os.environ.get("TELEGRAM_BOT_TOKEN", "")).strip()


def status(cfg: Optional[dict[str, Any]] = None) -> MethodStatus:
    tok = _token(cfg)
    if not tok:
        return MethodStatus(
            NAME, "telegram", False,
            "Kein Bot-Token. Setze TELEGRAM_BOT_TOKEN oder telegram.bot_token in config.json.",
            [])
    return MethodStatus(NAME, "telegram", True, "Bot-Token vorhanden.",
                        ["resolve", "member-count", "own-chat-posts"])


def _call(method: str, params: Optional[dict[str, Any]] = None,
          cfg: Optional[dict[str, Any]] = None) -> Any:
    tok = _token(cfg)
    if not tok:
        raise RuntimeError("Kein Telegram-Bot-Token konfiguriert.")
    import urllib.parse
    url = f"{API}/bot{tok}/{method}"
    if params:
        url += "?" + urllib.parse.urlencode(params)
    data = fetch_json(url)
    if not data.get("ok"):
        raise RuntimeError(f"Telegram-Bot-API: {data.get('description')}")
    return data["result"]


def me(cfg: Optional[dict[str, Any]] = None) -> dict[str, Any]:
    return _call("getMe", cfg=cfg)


def resolve(username: str, cfg: Optional[dict[str, Any]] = None) -> Optional[Channel]:
    handle = username if username.startswith("@") else "@" + username.lstrip("@")
    try:
        chat = _call("getChat", {"chat_id": handle}, cfg=cfg)
    except (RuntimeError, HttpError):
        return None

    members: Optional[int] = None
    try:
        members = _call("getChatMemberCount", {"chat_id": handle}, cfg=cfg)
    except (RuntimeError, HttpError):
        pass

    kind = {"channel": "channel", "supergroup": "group",
            "group": "group", "private": "user"}.get(chat.get("type", ""), "unknown")
    return Channel(
        platform="telegram", kind=kind, id=str(chat.get("id")),
        username=chat.get("username"),
        title=chat.get("title") or " ".join(
            filter(None, [chat.get("first_name"), chat.get("last_name")])) or handle,
        description=chat.get("description") or chat.get("bio") or "",
        url=f"https://t.me/{chat.get('username') or ''}",
        members=members, public=bool(chat.get("username")), readable=False,
        source=NAME, extra={"raw_type": chat.get("type"),
                            "invite_link": chat.get("invite_link")},
    )


def updates_posts(limit: int = 20, cfg: Optional[dict[str, Any]] = None) -> list[Post]:
    """Beitraege aus getUpdates - nur Chats, in denen der Bot Mitglied ist."""
    out: list[Post] = []
    try:
        updates = _call("getUpdates", {"limit": limit, "allowed_updates":
                                       json.dumps(["channel_post", "message"])}, cfg=cfg)
    except (RuntimeError, HttpError):
        return out
    for upd in updates:
        msg = upd.get("channel_post") or upd.get("message")
        if not msg:
            continue
        chat = msg.get("chat", {})
        import datetime as _dt
        out.append(Post(
            platform="telegram", channel=chat.get("username") or str(chat.get("id")),
            id=str(msg.get("message_id")),
            url=(f"https://t.me/{chat['username']}/{msg['message_id']}"
                 if chat.get("username") else ""),
            date=_dt.datetime.fromtimestamp(
                msg.get("date", 0), _dt.timezone.utc).isoformat(timespec="seconds"),
            author=chat.get("title", ""),
            text=msg.get("text") or msg.get("caption") or "", source=NAME,
        ))
    return out
