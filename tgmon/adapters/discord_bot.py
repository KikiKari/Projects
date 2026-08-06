"""Discord-Adapter - volle Bot-Integration ueber die REST-API v10.

Zwei Betriebsarten:
  A) OHNE Token: oeffentliche Invite-Metadaten (Servername, Mitglieder,
     Online-Zahl, Kanalhinweis) ueber /invites/<code>?with_counts=true
  B) MIT Bot-Token: Server, Kanaele und Nachrichten lesen

Bot einrichten:
  1. https://discord.com/developers/applications -> New Application -> Bot
  2. Token kopieren -> DISCORD_BOT_TOKEN oder config.json discord.bot_token
  3. Privileged Intent "MESSAGE CONTENT" aktivieren (fuer Nachrichtentexte)
  4. Bot einladen: invite_url() aufrufen und Link im Browser oeffnen
"""
from __future__ import annotations

import os
import re
import urllib.parse
from typing import Any, Optional

from ..models import Channel, MethodStatus, Post
from ..util import HttpError, fetch_json

NAME = "discord-bot"
API = "https://discord.com/api/v10"
CDN = "https://cdn.discordapp.com"

# Kanaltypen laut Discord-Doku
CHANNEL_TYPES = {0: "text", 2: "voice", 4: "category", 5: "announcement",
                 10: "news_thread", 11: "public_thread", 12: "private_thread",
                 13: "stage", 15: "forum", 16: "media"}
READABLE_TYPES = {0, 5, 15, 16}


def _token(cfg: Optional[dict[str, Any]] = None) -> str:
    return ((cfg or {}).get("discord", {}).get("bot_token")
            or os.environ.get("DISCORD_BOT_TOKEN", "")).strip()


def status(cfg: Optional[dict[str, Any]] = None) -> MethodStatus:
    if not _token(cfg):
        return MethodStatus(
            NAME, "discord", False,
            "Kein Bot-Token - Invite-Lookup funktioniert trotzdem.",
            ["invite-lookup"])
    return MethodStatus(NAME, "discord", True, "Bot-Token vorhanden.",
                        ["invite-lookup", "guilds", "channels", "messages", "search"])


def _headers(cfg: Optional[dict[str, Any]] = None) -> dict[str, str]:
    tok = _token(cfg)
    if not tok:
        raise RuntimeError("Kein Discord-Bot-Token konfiguriert.")
    return {"Authorization": f"Bot {tok}", "Content-Type": "application/json"}


def _get(path: str, cfg: Optional[dict[str, Any]] = None, auth: bool = True) -> Any:
    return fetch_json(f"{API}{path}",
                      headers=_headers(cfg) if auth else None)


def invite_url(client_id: str, permissions: int = 66560) -> str:
    """Einladungslink fuer den eigenen Bot (Lesen + Verlauf lesen)."""
    q = urllib.parse.urlencode({"client_id": client_id, "scope": "bot",
                                "permissions": permissions})
    return f"https://discord.com/oauth2/authorize?{q}"


# ------------------------------------------------------- ohne Token nutzbar ---

def invite_code(value: str) -> str:
    """Akzeptiert Code oder vollstaendigen Link."""
    value = value.strip()
    m = re.search(r"(?:discord\.gg|discord\.com/invite)/([A-Za-z0-9_-]+)", value)
    return m.group(1) if m else value.lstrip("/")


def invite_info(code_or_url: str) -> Optional[Channel]:
    """Oeffentliche Server-Infos aus einem Invite - ganz ohne Token."""
    code = invite_code(code_or_url)
    try:
        data = fetch_json(f"{API}/invites/{code}?with_counts=true&with_expiration=true")
    except HttpError:
        return None
    guild = data.get("guild") or {}
    icon = guild.get("icon")
    ch = Channel(
        platform="discord", kind="guild", id=str(guild.get("id") or ""),
        username=code, title=guild.get("name", ""),
        description=guild.get("description") or "",
        url=f"https://discord.gg/{code}",
        members=data.get("approximate_member_count"),
        online=data.get("approximate_presence_count"),
        avatar_url=(f"{CDN}/icons/{guild['id']}/{icon}.png?size=128"
                    if icon and guild.get("id") else None),
        public=True, readable=False,
        verified="VERIFIED" in (guild.get("features") or []),
        source=NAME,
        extra={"features": guild.get("features", []),
               "invite_channel": (data.get("channel") or {}).get("name"),
               "expires_at": data.get("expires_at"),
               "vanity": guild.get("vanity_url_code")},
    )
    return ch


# ------------------------------------------------------------- mit Bot-Token ---

def me(cfg: Optional[dict[str, Any]] = None) -> dict[str, Any]:
    return _get("/users/@me", cfg)


def guilds(cfg: Optional[dict[str, Any]] = None) -> list[Channel]:
    out: list[Channel] = []
    for g in _get("/users/@me/guilds?with_counts=true", cfg):
        icon = g.get("icon")
        out.append(Channel(
            platform="discord", kind="guild", id=str(g["id"]), title=g.get("name", ""),
            url=f"https://discord.com/channels/{g['id']}",
            members=g.get("approximate_member_count"),
            online=g.get("approximate_presence_count"),
            avatar_url=f"{CDN}/icons/{g['id']}/{icon}.png?size=128" if icon else None,
            public=False, readable=True, source=NAME,
            extra={"permissions": g.get("permissions")},
        ))
    return out


def channels(guild_id: str, cfg: Optional[dict[str, Any]] = None) -> list[Channel]:
    out: list[Channel] = []
    for c in _get(f"/guilds/{guild_id}/channels", cfg):
        ctype = CHANNEL_TYPES.get(c.get("type", -1), str(c.get("type")))
        out.append(Channel(
            platform="discord", kind=f"{ctype}_channel", id=str(c["id"]),
            username=c.get("name"), title=c.get("name", ""),
            description=c.get("topic") or "",
            url=f"https://discord.com/channels/{guild_id}/{c['id']}",
            readable=c.get("type") in READABLE_TYPES, source=NAME,
            extra={"type": ctype, "parent_id": c.get("parent_id"),
                   "nsfw": c.get("nsfw", False), "position": c.get("position")},
        ))
    out.sort(key=lambda c: (c.extra.get("position") or 0))
    return out


def messages(channel_id: str, limit: int = 20,
             cfg: Optional[dict[str, Any]] = None) -> list[Post]:
    data = _get(f"/channels/{channel_id}/messages?limit={min(limit, 100)}", cfg)
    out: list[Post] = []
    for m in data:
        author = m.get("author", {})
        media = [{"type": a.get("content_type", "file"), "url": a.get("url", "")}
                 for a in m.get("attachments", [])]
        for e in m.get("embeds", []):
            if e.get("url"):
                media.append({"type": "embed", "url": e["url"]})
        out.append(Post(
            platform="discord", channel=str(channel_id), id=str(m.get("id")),
            url=f"https://discord.com/channels/@me/{channel_id}/{m.get('id')}",
            date=m.get("timestamp"),
            author=author.get("global_name") or author.get("username", ""),
            text=m.get("content", ""), media=media, source=NAME,
            extra={"reactions": [
                {"emoji": (r.get("emoji") or {}).get("name"), "count": r.get("count")}
                for r in m.get("reactions", [])]},
        ))
    return out


def search(query: str, cfg: Optional[dict[str, Any]] = None,
           limit: int = 30) -> list[Channel]:
    """Ueber alle Server des Bots nach passenden Servern/Kanaelen suchen."""
    q = query.lower().lstrip("#@")
    hits: list[Channel] = []
    try:
        gs = guilds(cfg)
    except (RuntimeError, HttpError):
        return hits
    for g in gs:
        if q in (g.title or "").lower():
            g.confidence = 0.9
            hits.append(g)
        try:
            for c in channels(g.id or "", cfg):
                if q in (c.title or "").lower() or q in (c.description or "").lower():
                    c.confidence = 0.7
                    c.extra["guild"] = g.title
                    hits.append(c)
        except (RuntimeError, HttpError):
            continue
    return hits[:limit]
