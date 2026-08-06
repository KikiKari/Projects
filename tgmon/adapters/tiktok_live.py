"""TikTok-Adapter: Live/Offline-Erkennung und Sendungshistorie.

Bewusst ohne jede Umgehung von Zugangskontrollen. Zwei oeffentliche Quellen:

  1. StreamRecorder (streamrecorder.io) - oeffentliche Profilseite eines
     Drittanbieters mit Sendungsverlauf. Die Seite traegt ihre Daten in
     `window.ALT_DAILY_DATA` als JSON: Tag -> Sendungen mit Titel, Uhrzeit,
     Dauer und `is_live`-Kennzeichen.
  2. TikTok Embed Live - der offiziell dokumentierte Einbettungs-Endpunkt
     (developers.tiktok.com/doc/embed-live). Er dient hier nur zur
     Verfuegbarkeitspruefung und liefert die URL fuer die Anzeige.

Der Embed-Player ist der vorgesehene Weg fuer schreibgeschuetztes Zuschauen:
keine Anmeldung, keine Geschenk- oder Kauf-Oberflaeche.
"""
from __future__ import annotations

import json
import re
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

from ..models import Channel, MethodStatus, Post
from ..util import HttpError, fetch, meta

NAME = "tiktok-live"
SR = "https://streamrecorder.io/tiktok/@{user}"
EMBED = "https://www.tiktok.com/embed/live/@{user}"
PROFILE = "https://www.tiktok.com/@{user}"
LIVE_PAGE = "https://www.tiktok.com/@{user}/live"

USERNAME_RE = re.compile(r"^[A-Za-z0-9._]{2,24}$")


def status_method() -> MethodStatus:
    return MethodStatus(
        name=NAME, platform="tiktok", available=True,
        reason="Oeffentliche Quellen, keine Zugangsdaten noetig.",
        capabilities=["live-status", "sendungshistorie", "embed-url"],
    )


def embed_url(username: str) -> str:
    return EMBED.format(user=username.lstrip("@"))


# --------------------------------------------------------- StreamRecorder ---

def _daily_data(html: str) -> dict[str, Any]:
    m = re.search(r"window\.ALT_DAILY_DATA\s*=\s*(\{.*?\});\s*\n", html, re.S)
    if not m:
        return {}
    try:
        return json.loads(m.group(1))
    except json.JSONDecodeError:
        return {}


def _summary(html: str) -> dict[str, Any]:
    """Kopfzeilen der Profilseite auswerten (Anzahl Sendungen, Sendezeit ...)."""
    text = re.sub(r"<[^>]+>", " ", html)
    out: dict[str, Any] = {}
    m = re.search(r"tracked\s+([\d.,]+)\s+streams", text)
    if m:
        out["streams_total"] = int(m.group(1).replace(".", "").replace(",", ""))
    m = re.search(r"with\s+([\dhm\s]+)\s+of total airtime", text)
    if m:
        out["airtime"] = m.group(1).strip()
    m = re.search(r"across\s+(\d+)\s+active days", text)
    if m:
        out["active_days"] = int(m.group(1))
    m = re.search(r"last seen on ([A-Za-z]{3} \d{1,2}, \d{4})", text)
    if m:
        out["last_seen"] = m.group(1)
    return out


def _flatten(daily: dict[str, Any]) -> list[dict[str, Any]]:
    """Tages-Struktur -> flache, chronologisch absteigende Sendungsliste."""
    out: list[dict[str, Any]] = []
    for day in sorted(daily, reverse=True):
        entry = daily[day] or {}
        for s in entry.get("streams", []):
            out.append({
                "day": day,
                "time": s.get("time"),
                "title": s.get("title") or "",
                "duration": s.get("duration_hr") or s.get("duration_hms"),
                "duration_sec": s.get("duration"),
                "is_live": bool(s.get("is_live")),
                "thumbnail": s.get("thumbnail"),
                "started_at": f"{day}T{s.get('time') or '00:00'}:00",
            })
    out.sort(key=lambda s: (s["day"], s.get("time") or ""), reverse=True)
    return out


def live_status(username: str, *, timeout: int = 25) -> dict[str, Any]:
    """Aktueller Zustand eines TikTok-Kontos.

    Rueckgabe:
      live        - True/False/None (None = nicht ermittelbar)
      title       - Titel der laufenden bzw. letzten Sendung
      started_at  - Beginn (ISO, ortsbezogen wie von der Quelle geliefert)
      since       - lesbare Dauer seit Beginn, wenn live
      streams     - letzte Sendungen (neueste zuerst)
    """
    user = username.lstrip("@").strip()
    res: dict[str, Any] = {"platform": "tiktok", "username": user, "live": None,
                           "embed_url": embed_url(user), "profile_url": PROFILE.format(user=user),
                           "live_url": LIVE_PAGE.format(user=user), "source": NAME,
                           "checked_at": datetime.now(timezone.utc).isoformat(timespec="seconds")}
    if not USERNAME_RE.match(user):
        res["error"] = "Ungueltiger Nutzername."
        return res

    try:
        html = fetch(SR.format(user=user), timeout=timeout)
    except HttpError as exc:
        res["error"] = f"StreamRecorder nicht erreichbar: {exc.status}"
        return res

    daily = _daily_data(html)
    streams = _flatten(daily)
    res.update(_summary(html))
    res["streams"] = streams[:20]

    current = next((s for s in streams if s["is_live"]), None)
    res["live"] = bool(current)
    ref = current or (streams[0] if streams else None)
    if ref:
        res["title"] = ref["title"]
        res["started_at"] = ref["started_at"]
        res["last_stream_day"] = ref["day"]
        res["duration"] = ref["duration"]
        if current:
            try:
                begin = datetime.fromisoformat(ref["started_at"])
                delta = datetime.now() - begin
                if delta < timedelta(0):
                    delta = timedelta(0)
                h, rem = divmod(int(delta.total_seconds()), 3600)
                res["since"] = f"{h}h {rem // 60}m"
            except ValueError:
                pass
    return res


# ---------------------------------------------------------------- Kanaele ---

def resolve(username: str, cfg: Optional[dict[str, Any]] = None) -> Optional[Channel]:
    """Kanalkarte im gemeinsamen Datenmodell."""
    user = username.lstrip("@").strip()
    st = live_status(user)
    if st.get("error") and not st.get("streams"):
        return None

    title, avatar, desc = user, None, ""
    try:                                   # Profil-Metadaten, falls erreichbar
        page = fetch(PROFILE.format(user=user), timeout=20)
        title = meta(page, "og:title") or user
        desc = meta(page, "og:description") or ""
        avatar = meta(page, "og:image") or None
    except HttpError:
        pass

    ch = Channel(
        platform="tiktok", kind="live-kanal", username=user,
        title=title.replace(" | TikTok", "").strip() or user,
        description=desc, url=PROFILE.format(user=user), avatar_url=avatar,
        public=True, readable=True, source=NAME,
        extra={"live": st.get("live"), "embed_url": st.get("embed_url"),
               "live_url": st.get("live_url"), "stream_title": st.get("title"),
               "started_at": st.get("started_at"), "since": st.get("since"),
               "last_seen": st.get("last_seen"), "streams_total": st.get("streams_total"),
               "airtime": st.get("airtime"), "active_days": st.get("active_days")},
    )
    return ch


def posts(username: str, limit: int = 20, cfg: Optional[dict[str, Any]] = None) -> list[Post]:
    """Sendungen als Beitraege - passt den Verlauf ins gemeinsame Modell ein."""
    st = live_status(username)
    out: list[Post] = []
    for s in (st.get("streams") or [])[:limit]:
        out.append(Post(
            platform="tiktok", channel=st["username"],
            id=f"{st['username']}/{s['day']}T{s.get('time') or ''}",
            url=st["live_url"] if s["is_live"] else st["profile_url"],
            date=s["started_at"],
            text=(("LIVE: " if s["is_live"] else "") + (s["title"] or "(ohne Titel)")
                  + (f" · {s['duration']}" if s.get("duration") else "")),
            media=[{"type": "thumbnail", "url": s["thumbnail"]}] if s.get("thumbnail") else [],
            source=NAME, extra={"is_live": s["is_live"], "duration_sec": s.get("duration_sec")},
        ))
    return out
