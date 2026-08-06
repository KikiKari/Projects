#!/usr/bin/env python3
"""Telegram Monitor - Kommandozeile.

Beispiele:
  python cli.py status
  python cli.py search creator
  python cli.py resolve telegram
  python cli.py posts telegram --limit 5
  python cli.py watch add telegram durov
  python cli.py scan --json
  python cli.py discord invite discord.gg/discord-developers
  python cli.py discord guilds
  python cli.py serve --port 8765
"""
from __future__ import annotations

import argparse
import json
import sys

from tgmon import config, registry, store
from tgmon.adapters import discord_bot as dc


def _print(data, as_json: bool) -> None:
    if as_json:
        print(json.dumps(data, ensure_ascii=False, indent=2))


def cmd_status(args, cfg) -> None:
    rows = [s.to_dict() for s in registry.statuses(cfg)]
    if args.json:
        return _print(rows, True)
    print("Zugangsmethoden")
    print("-" * 74)
    for r in rows:
        mark = "OK " if r["available"] else "-- "
        print(f"{mark}{r['name']:<20} {r['platform']:<9} {r['reason']}")
        if r["capabilities"]:
            print(f"{'':>23}kann: {', '.join(r['capabilities'])}")


def cmd_search(args, cfg) -> None:
    res = registry.search(args.query, cfg,
                          methods=args.methods.split(",") if args.methods else None,
                          limit=args.limit)
    if args.json:
        return _print(res, True)
    print(f"Suche: {res['query']}   Methoden: {', '.join(res['methods_used'])}")
    for e in res["errors"]:
        print(f"  ! {e['method']}: {e['error']}")
    print("-" * 92)
    if not res["results"]:
        print("Keine Treffer.")
    for r in res["results"]:
        flag = "oeffentlich lesbar" if r["readable"] else "nicht lesbar"
        members = f"{r['members']:,}".replace(",", ".") if r["members"] else "?"
        print(f"[{r['confidence']:.2f}] {r['platform']:<8} {r['kind']:<14} "
              f"@{r['username'] or r['id']}")
        print(f"        {r['title']}  |  {members} Mitglieder  |  {flag}  |  {r['url']}")
        if r["description"]:
            print(f"        {r['description'][:110]}")


def cmd_resolve(args, cfg) -> None:
    ch = registry.resolve(args.target, cfg, args.platform)
    if args.json:
        return _print(ch, True)
    if not ch:
        print("Nicht gefunden.")
        return
    for k in ("platform", "kind", "username", "title", "members", "public",
              "readable", "url", "source"):
        print(f"{k:<12}: {ch.get(k)}")
    if ch.get("description"):
        print(f"{'beschreibung':<12}: {ch['description'][:300]}")
    if ch.get("extra", {}).get("note"):
        print(f"{'hinweis':<12}: {ch['extra']['note']}")


def cmd_posts(args, cfg) -> None:
    res = registry.posts(args.target, cfg, limit=args.limit, platform=args.platform)
    if args.json:
        return _print(res, True)
    print(f"{res['target']} via {res['source']} - {len(res['posts'])} Beitraege")
    print("-" * 92)
    for p in res["posts"]:
        head = f"{p['date'] or '?'}  {p['url']}"
        views = f"  ({p['views']} Aufrufe)" if p.get("views") else ""
        print(head + views)
        text = (p["text"] or "").replace("\n", " ")
        print(f"   {text[:200]}")
        if p["media"]:
            print(f"   Medien: {', '.join(m['type'] for m in p['media'])}")


def cmd_watch(args, cfg) -> None:
    if args.action == "list":
        items = store.watchlist()
    elif args.action == "add":
        items = store.watch_add(args.platform, args.target, args.note or "")
    else:
        items = store.watch_remove(args.platform, args.target)
    if args.json:
        return _print(items, True)
    for i in items:
        print(f"{i['platform']:<9} {i['target']:<28} {i.get('note','')}")
    if not items:
        print("Watchlist ist leer.")


def cmd_scan(args, cfg) -> None:
    items = store.watchlist()
    if not items:
        print("Watchlist ist leer - erst 'python cli.py watch add ...' ausfuehren.")
        return
    res = registry.overview(items, cfg, posts_per_channel=args.limit)
    store.save_snapshot(res)
    if args.json:
        return _print(res, True)
    for e in res["entries"]:
        ch = e.get("channel") or {}
        print(f"\n=== {e['platform']} / {e['target']} ===")
        if e.get("error"):
            print(f"  Fehler: {e['error']}")
            continue
        if not ch:
            print("  nicht gefunden")
            continue
        print(f"  {ch.get('title')} | {ch.get('members') or '?'} Mitglieder | {ch.get('url')}")
        for p in e.get("posts", []):
            print(f"   - {p['date']}  {(p['text'] or '')[:90]}")


def cmd_discord(args, cfg) -> None:
    if args.sub == "invite":
        ch = dc.invite_info(args.value)
        return _print(ch.to_dict() if ch else None, True) if args.json else _pretty_invite(ch)
    if args.sub == "guilds":
        rows = [c.to_dict() for c in dc.guilds(cfg)]
    elif args.sub == "channels":
        rows = [c.to_dict() for c in dc.channels(args.value, cfg)]
    elif args.sub == "messages":
        rows = [p.to_dict() for p in dc.messages(args.value, args.limit, cfg)]
    elif args.sub == "me":
        rows = dc.me(cfg)
    elif args.sub == "invite-url":
        client_id = args.value or cfg["discord"].get("client_id", "")
        print(dc.invite_url(client_id))
        return
    else:
        rows = []
    _print(rows, True)


def _pretty_invite(ch) -> None:
    if not ch:
        print("Invite ungueltig oder abgelaufen.")
        return
    print(f"{ch.title}  ({ch.url})")
    print(f"  Mitglieder: {ch.members}   online: {ch.online}")
    print(f"  Kanal im Invite: {ch.extra.get('invite_channel')}")
    print(f"  verifiziert: {ch.verified}")
    if ch.description:
        print(f"  {ch.description[:200]}")


def cmd_tiktok(args, cfg) -> None:
    """Live-Status und Sendungshistorie eines TikTok-Kontos."""
    from tgmon.adapters import tiktok_live as tt
    st = tt.live_status(args.user)
    if args.json:
        return _print(st, True)
    mark = "LÄUFT GERADE" if st.get("live") else ("offline" if st.get("live") is False else "unbekannt")
    print(f"@{st['username']}: {mark}")
    if st.get("title"):
        print(f"  Titel      : {st['title']}")
    if st.get("started_at"):
        print(f"  Beginn     : {st['started_at']}" + (f"  (seit ca. {st['since']})" if st.get("since") else ""))
    for k, label in (("last_seen", "zuletzt"), ("streams_total", "Sendungen"),
                     ("airtime", "Sendezeit"), ("active_days", "aktive Tage")):
        if st.get(k) is not None:
            print(f"  {label:<11}: {st[k]}")
    print(f"  Embed      : {st['embed_url']}")
    print("  --- letzte Sendungen ---")
    for x in (st.get("streams") or [])[:args.limit]:
        flag = "LIVE" if x["is_live"] else "    "
        print(f"   {flag} {x['day']} {x.get('time') or '':>5}  {str(x.get('duration') or ''):>7}  {x['title'][:50]}")


def cmd_events(args, cfg) -> None:
    from tgmon import notify
    evs = notify.events(args.limit)
    if args.json:
        return _print(evs, True)
    for e in evs:
        print(f"{e['at']}  [{e['kind']:<11}] {e['title']} — {e['text']}")
    if not evs:
        print("Noch keine Ereignisse.")


def cmd_serve(args, cfg) -> None:
    import server
    server.run(port=args.port, host=args.host, poll_interval=args.poll_interval)


def cmd_live(args, cfg) -> None:
    """Fortlaufend beobachten - im Terminal oder als JSON (--json)."""
    from tgmon import live
    targets = ([{"platform": args.platform, "target": args.target}] if args.target
               else store.watchlist())
    if not targets:
        if args.json:
            return _print({"entries": [], "error": "Kein Ziel"}, True)
        print("Kein Ziel. Entweder Ziel angeben oder Watchlist fuellen.")
        return

    if args.json:
        # Maschinenlesbarer Einzelabruf: abfragen und den gesammelten
        # Verlauf zurueckgeben (fuer Artefakt / externe Oberflaechen).
        entries = []
        for item in targets:
            platform, target = item.get("platform", "telegram"), item["target"]
            res = live.poll_once(platform, target, cfg, limit=args.limit)
            hist = live.history(platform, target, limit=args.limit)
            hist["new_count"] = len(res["new"])
            hist["new_ids"] = [p.get("id") for p in res["new"]]
            entries.append(hist)
        return _print({"entries": entries,
                       "at": __import__("datetime").datetime.now(
                           __import__("datetime").timezone.utc).isoformat(
                               timespec="seconds")}, True)
    print(f"Beobachte {len(targets)} Ziel(e) alle {max(30, args.interval)} s "
          f"- Abbruch mit Strg+C\n")
    seen_first = True
    while True:
        for item in targets:
            platform, target = item.get("platform", "telegram"), item["target"]
            res = live.poll_once(platform, target, cfg, limit=args.limit)
            for p in sorted(res["new"], key=lambda x: x.get("date") or ""):
                marker = "  " if seen_first else "NEU"
                text = (p.get("text") or "(kein Text)").replace("\n", " ")
                print(f"{marker} [{target}] {p.get('date')} {text[:110]}")
        seen_first = False
        if args.once:
            return
        import time as _t
        _t.sleep(max(30, args.interval))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="telegram-monitor")
    parser.add_argument("--json", action="store_true", help="Ausgabe als JSON")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status")

    s = sub.add_parser("search")
    s.add_argument("query")
    s.add_argument("--limit", type=int, default=20)
    s.add_argument("--methods", default="", help="web,bot,mtproto,discord")

    r = sub.add_parser("resolve")
    r.add_argument("target")
    r.add_argument("--platform", default="telegram", choices=["telegram", "discord"])

    p = sub.add_parser("posts")
    p.add_argument("target")
    p.add_argument("--limit", type=int, default=20)
    p.add_argument("--platform", default="telegram", choices=["telegram", "discord"])

    w = sub.add_parser("watch")
    w.add_argument("action", choices=["list", "add", "remove"])
    w.add_argument("platform", nargs="?", default="telegram")
    w.add_argument("target", nargs="?", default="")
    w.add_argument("--note", default="")

    sc = sub.add_parser("scan")
    sc.add_argument("--limit", type=int, default=5)

    d = sub.add_parser("discord")
    d.add_argument("sub", choices=["invite", "guilds", "channels", "messages",
                                   "me", "invite-url"])
    d.add_argument("value", nargs="?", default="")
    d.add_argument("--limit", type=int, default=20)

    tk = sub.add_parser("tiktok")
    tk.add_argument("user")
    tk.add_argument("--limit", type=int, default=8)

    ev = sub.add_parser("events")
    ev.add_argument("--limit", type=int, default=30)

    sv = sub.add_parser("serve")
    sv.add_argument("--port", type=int, default=8765)
    sv.add_argument("--host", default="127.0.0.1")
    sv.add_argument("--poll-interval", type=int, default=120)

    lv = sub.add_parser("live")
    lv.add_argument("target", nargs="?", default="")
    lv.add_argument("--platform", default="telegram", choices=["telegram", "discord"])
    lv.add_argument("--interval", type=int, default=120)
    lv.add_argument("--limit", type=int, default=25)
    lv.add_argument("--once", action="store_true")

    args = parser.parse_args(argv)
    cfg = config.load()
    handlers = {"status": cmd_status, "search": cmd_search, "resolve": cmd_resolve,
                "posts": cmd_posts, "watch": cmd_watch, "scan": cmd_scan,
                "discord": cmd_discord, "serve": cmd_serve, "live": cmd_live,
                "tiktok": cmd_tiktok, "events": cmd_events}
    try:
        handlers[args.cmd](args, cfg)
    except KeyboardInterrupt:
        return 130
    except Exception as exc:                            # noqa: BLE001
        print(f"Fehler: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
