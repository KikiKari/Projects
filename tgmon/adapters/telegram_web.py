"""Telegram-Adapter OHNE Login (Methode 1).

Nutzt ausschliesslich die oeffentliche Web-Vorschau von Telegram:
  * https://t.me/<name>      -> Visitenkarte (Titel, Beschreibung, Typ)
  * https://t.me/s/<name>    -> Kanal-Verlauf, falls oeffentlich

Keine App, kein Account, keine API-Keys. Funktioniert nur fuer
oeffentliche Kanaele; private Nutzerprofile liefern nur Metadaten.
"""
from __future__ import annotations

import re
from concurrent.futures import ThreadPoolExecutor
from typing import Iterable, Optional

from ..models import Channel, MethodStatus, Post
from ..util import HttpError, fetch, meta, parse_count, slugify, strip_html

NAME = "telegram-web"
BASE = "https://t.me"

# Username-Regeln von Telegram: 5-32 Zeichen, a-z 0-9 _
USERNAME_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_]{3,31}$")

# Haeufige Endungen, mit denen Creator ihre Kanaele benennen.
SUFFIXES = [
    "", "_official", "official", "_channel", "channel", "_tv", "_news", "news",
    "_lounge", "lounge", "_updates", "updates", "_vip", "vip", "_de", "_hq",
    "_fanclub", "fanclub", "_chat", "chat", "_group", "_backup", "_club",
    "_community", "_insider", "_privat", "_private", "tg",
]
PREFIXES = ["", "real", "its", "the", "official", "team"]


def status() -> MethodStatus:
    return MethodStatus(
        name=NAME, platform="telegram", available=True,
        reason="Immer verfuegbar - benoetigt keinerlei Zugangsdaten.",
        capabilities=["resolve", "posts", "candidate-search", "web-discovery"],
    )


# ---------------------------------------------------------------- resolve ---

def _extract_counters(page: str) -> dict[str, int]:
    out: dict[str, int] = {}
    pattern = (r'counter_value">([^<]+)</span>\s*'
               r'<span class="counter_type">([^<]+)</span>')
    for value, label in re.findall(pattern, page):
        n = parse_count(value)
        if n is not None:
            out[label.strip().lower()] = n
    return out


def resolve(username: str, *, timeout: int = 20) -> Optional[Channel]:
    """Ein @name aufloesen. None, wenn es den Namen nicht gibt."""
    username = username.lstrip("@").strip()
    if not username:
        return None

    try:
        card = fetch(f"{BASE}/{username}", timeout=timeout)
    except HttpError:
        return None

    title = meta(card, "og:title")
    description = meta(card, "og:description")
    avatar = meta(card, "og:image") or None
    if avatar and "t_logo" in avatar:
        avatar = None

    # Existenz-Check: nur echte Profile/Kanaele haben einen tgme_page_title.
    # Unbelegte Namen liefern eine generische Seite ("Telegram: Contact @x").
    if "tgme_page_title" not in card or title.lower().startswith("telegram: contact"):
        return None
    if not title or title.strip().lower() in {"telegram", "telegram messenger"}:
        return None

    # tgme_page_extra: "747 subscribers" | "12 345 members" | "last seen recently"
    extra_m = re.search(r'tgme_page_extra">(.*?)</div>', card, re.S)
    page_extra = strip_html(extra_m.group(1)) if extra_m else ""
    low = page_extra.lower()

    kind = "user"
    if "subscriber" in low or "abonnent" in low:
        kind = "channel"
    elif "member" in low or "mitglied" in low:
        kind = "group"
    if username.lower().endswith("bot"):
        kind = "bot"

    ch = Channel(
        platform="telegram", kind=kind, username=username, title=title,
        description=description, url=f"{BASE}/{username}", avatar_url=avatar,
        source=NAME, extra={"page_extra": page_extra},
    )
    if kind in ("channel", "group"):
        ch.members = parse_count(page_extra)

    # Gibt es eine oeffentliche Verlaufs-Vorschau?
    try:
        preview = fetch(f"{BASE}/s/{username}", timeout=timeout)
    except HttpError:
        preview = ""

    if "tgme_channel_history" in preview or "tgme_widget_message" in preview:
        ch.public = True
        ch.readable = True
        ch.kind = "channel" if ch.kind == "user" else ch.kind
        counters = _extract_counters(preview)
        ch.members = (counters.get("subscribers") or counters.get("members")
                      or ch.members)
        ch.extra["counters"] = counters
        ch.extra["preview_url"] = f"{BASE}/s/{username}"
    else:
        ch.extra["note"] = (
            "Keine oeffentliche Verlaufs-Vorschau. Entweder privates Nutzerkonto, "
            "private Gruppe oder Kanal mit deaktivierter Vorschau."
        )
    if "tgme_page_verified" in card or "verified" in card.lower()[:4000]:
        ch.verified = "tgme_page_verified" in card
    return ch


def exists(username: str) -> bool:
    return resolve(username) is not None


# ------------------------------------------------------------------ posts ---

_MSG_SPLIT = re.compile(r'<div class="tgme_widget_message[^"]*"[^>]*data-post="')


def _parse_posts(page: str, channel: str) -> list[Post]:
    posts: list[Post] = []
    chunks = _MSG_SPLIT.split(page)[1:]
    for chunk in chunks:
        m = re.match(r'([^"]+)"', chunk)
        if not m:
            continue
        post_id = m.group(1)
        body = chunk

        text_m = re.search(
            r'class="tgme_widget_message_text[^"]*"[^>]*>(.*?)</div>', body, re.S)
        text = strip_html(text_m.group(1)) if text_m else ""

        time_m = re.search(r'<time[^>]+datetime="([^"]+)"', body)
        views_m = re.search(r'tgme_widget_message_views">([^<]+)<', body)
        author_m = re.search(r'tgme_widget_message_from_author">([^<]*)<', body)

        media: list[dict[str, str]] = []
        for url in re.findall(
                r"tgme_widget_message_photo_wrap[^>]*background-image:url\('([^']+)'\)", body):
            media.append({"type": "photo", "url": url})
        for url in re.findall(r'<video[^>]+src="([^"]+)"', body):
            media.append({"type": "video", "url": url})
        if 'tgme_widget_message_document' in body:
            media.append({"type": "document", "url": ""})

        posts.append(Post(
            platform="telegram", channel=channel, id=post_id,
            url=f"{BASE}/{post_id}",
            date=time_m.group(1) if time_m else None,
            author=strip_html(author_m.group(1)) if author_m else "",
            text=text,
            views=parse_count(views_m.group(1)) if views_m else None,
            media=media, source=NAME,
        ))
    return posts


def posts(username: str, limit: int = 20, *, timeout: int = 20) -> list[Post]:
    """Neueste Beitraege eines oeffentlichen Kanals (neueste zuerst)."""
    username = username.lstrip("@").strip()
    collected: list[Post] = []
    before: Optional[str] = None
    seen: set[str] = set()

    for _ in range(6):                       # max. 6 Seiten blaettern
        url = f"{BASE}/s/{username}"
        if before:
            url += f"?before={before}"
        try:
            page = fetch(url, timeout=timeout)
        except HttpError:
            break
        batch = _parse_posts(page, username)
        if not batch:
            break
        fresh = [p for p in batch if p.id not in seen]
        for p in fresh:
            seen.add(p.id or "")
        collected.extend(fresh)
        if len(collected) >= limit:
            break
        first_id = (batch[0].id or "").split("/")[-1]
        if not first_id.isdigit() or first_id == before:
            break
        before = first_id

    collected.sort(key=lambda p: p.date or "", reverse=True)
    return collected[:limit]


# ----------------------------------------------------------------- search ---

def candidates(query: str, *, extra: Iterable[str] = ()) -> list[str]:
    """Plausible Usernamen aus einem Suchbegriff ableiten."""
    core = slugify(query)
    variants = {core, core.replace("_", ""), query.lstrip("@").strip()}
    out: list[str] = []
    for base in filter(None, variants):
        for pre in PREFIXES:
            for suf in SUFFIXES:
                cand = f"{pre}{base}{suf}"
                if USERNAME_RE.match(cand) and cand not in out:
                    out.append(cand)
    for cand in extra:
        cand = cand.lstrip("@")
        if USERNAME_RE.match(cand) and cand not in out:
            out.append(cand)
    return out


def discover_via_web(query: str, *, limit: int = 25) -> list[str]:
    """Optionale Entdeckung ueber eine oeffentliche Websuche (site:t.me).

    Rein additiv: schlaegt sie fehl, faellt die Suche auf die
    Kandidaten-Pruefung zurueck.
    """
    import urllib.parse
    found: list[str] = []
    q = urllib.parse.quote_plus(f"site:t.me {query}")
    try:
        page = fetch(f"https://html.duckduckgo.com/html/?q={q}", timeout=20)
    except HttpError:
        return found
    raw = re.findall(r"t\.me(?:%2F|/)(?:s(?:%2F|/))?([A-Za-z0-9_]{4,32})", page)
    for name in raw:
        if name.lower() in {"s", "share", "joinchat", "iv", "proxy", "socks"}:
            continue
        if USERNAME_RE.match(name) and name not in found:
            found.append(name)
        if len(found) >= limit:
            break
    return found


def _score(ch: Channel, query: str) -> float:
    """0 = unpassend (wird verworfen), 1 = perfekter Treffer.

    Popularitaets-Boni zaehlen erst, wenn ueberhaupt eine Namens- oder
    Titel-Aehnlichkeit vorliegt - sonst spuelt eine Websuche zufaellige
    Grosskanaele nach oben.
    """
    q = query.lstrip("@").lower()
    qs = slugify(query)
    name = (ch.username or "").lower()
    title = (ch.title or "").lower()

    relevance = 0.0
    if name in (q, qs):
        relevance = 0.6
    elif name.startswith(qs) or qs in name or name in qs:
        relevance = 0.4
    if q in title or qs.replace("_", " ") in title:
        relevance += 0.25
    if relevance == 0.0:
        return 0.0

    bonus = 0.15 if ch.readable else 0.0
    if ch.members:
        bonus += min(0.1, ch.members / 500_000)
    return round(min(relevance + bonus, 1.0), 2)


def search(query: str, *, limit: int = 20, use_web: bool = True,
           extra_candidates: Iterable[str] = (), workers: int = 8) -> list[Channel]:
    """Kanaele zu einem Suchbegriff finden.

    Zwei Wege, kombiniert und dedupliziert:
      1. Kandidaten-Pruefung (Namensvarianten gegen t.me testen)
      2. Websuche site:t.me (optional, kein Key noetig)
    """
    names: list[str] = []
    if use_web:
        names.extend(discover_via_web(query))
    for cand in candidates(query, extra=extra_candidates):
        if cand not in names:
            names.append(cand)
    names = names[: max(limit * 4, 40)]

    results: list[Channel] = []
    with ThreadPoolExecutor(max_workers=workers) as pool:
        for ch in pool.map(lambda n: resolve(n), names):
            if ch:
                ch.confidence = _score(ch, query)
                results.append(ch)

    seen: set[str] = set()
    unique: list[Channel] = []
    for ch in sorted(results, key=lambda c: c.confidence, reverse=True):
        if ch.key() in seen or ch.confidence <= 0.0:
            continue
        seen.add(ch.key())
        unique.append(ch)
    return unique[:limit]
