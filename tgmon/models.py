"""Einheitliches Datenmodell fuer alle Plattformen (Telegram, Discord, ...).

Jeder Adapter liefert dieselben Strukturen zurueck, damit UI, CLI und
Artefakt plattformunabhaengig bleiben.
"""
from __future__ import annotations

from dataclasses import dataclass, field, asdict
from datetime import datetime, timezone
from typing import Any, Optional


def _now() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


@dataclass
class Channel:
    """Ein Kanal / eine Gruppe / ein Profil auf irgendeiner Plattform."""

    platform: str                      # "telegram" | "discord"
    kind: str = "unknown"              # channel | group | user | bot | guild | text_channel
    id: Optional[str] = None           # native ID, falls bekannt
    username: Optional[str] = None     # @handle bzw. Slug
    title: str = ""
    description: str = ""
    url: str = ""
    members: Optional[int] = None      # Abonnenten / Mitglieder
    online: Optional[int] = None       # nur Discord (approximate_presence_count)
    avatar_url: Optional[str] = None
    public: bool = False               # oeffentlich lesbar ohne Login?
    readable: bool = False             # koennen wir Beitraege lesen?
    verified: bool = False
    source: str = ""                   # welcher Adapter/Methode
    confidence: float = 1.0            # 0..1, relevant bei Suchtreffern
    fetched_at: str = field(default_factory=_now)
    extra: dict[str, Any] = field(default_factory=dict)

    def key(self) -> str:
        return f"{self.platform}:{self.username or self.id}".lower()

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class Post:
    """Eine einzelne Nachricht / ein Beitrag."""

    platform: str
    channel: str                       # username oder ID des Kanals
    id: Optional[str] = None
    url: str = ""
    date: Optional[str] = None         # ISO 8601
    author: str = ""
    text: str = ""
    views: Optional[int] = None
    media: list[dict[str, str]] = field(default_factory=list)
    source: str = ""
    extra: dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class MethodStatus:
    """Zustand einer Zugangsmethode - fuer die 'Was ist konfiguriert?'-Anzeige."""

    name: str
    platform: str
    available: bool
    reason: str = ""
    capabilities: list[str] = field(default_factory=list)

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)
