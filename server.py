#!/usr/bin/env python3
"""Lokale Web-App fuer den Telegram Monitor.

Nur Standardbibliothek - kein pip, kein Framework.
Start:  python server.py           -> http://127.0.0.1:8765
"""
from __future__ import annotations

import json
import os
import traceback
import urllib.parse
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

from tgmon import config, live, notify, registry, store
from tgmon.adapters import discord_bot as dc

ROOT = os.path.dirname(os.path.abspath(__file__))
WEB = os.path.join(ROOT, "web")
CFG = config.load()
POLLER: "live.Poller | None" = None


class Handler(BaseHTTPRequestHandler):
    server_version = "TelegramMonitor/1.0"

    # ------------------------------------------------------------ helpers ---
    def _send(self, status: int, body: bytes, ctype: str) -> None:
        self.send_response(status)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        # Der Embed-Viewer laeuft als lokale Datei oder als Erweiterungsseite und
        # damit auf einer anderen Herkunft. Ohne diese Kopfzeilen blockiert der
        # Browser den Abruf ("Failed to fetch"). Der Server hoert nur auf
        # 127.0.0.1 und liefert ausschliesslich oeffentliche Daten aus.
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self) -> None:                        # noqa: N802
        """Vorabanfrage des Browsers beantworten."""
        self._send(204, b"", "text/plain")

    def _json(self, data, status: int = 200) -> None:
        self._send(status, json.dumps(data, ensure_ascii=False).encode("utf-8"),
                   "application/json; charset=utf-8")

    #: Ein Service Worker darf nur ausgeliefert werden, wenn der Typ stimmt;
    #: ein Manifest nur als application/manifest+json. Sonst lehnt der Browser
    #: die Installation als App ab.
    TYPES = {
        ".html": "text/html; charset=utf-8",
        ".js":   "text/javascript; charset=utf-8",
        ".css":  "text/css; charset=utf-8",
        ".json": "application/json; charset=utf-8",
        ".webmanifest": "application/manifest+json; charset=utf-8",
        ".png":  "image/png",
        ".svg":  "image/svg+xml",
        ".ico":  "image/x-icon",
    }

    def _file(self, name: str) -> None:
        # Kein Ausbruch aus dem web/-Ordner.
        safe = os.path.normpath(name).replace("\\", "/").lstrip("/")
        if safe.startswith(".."):
            return self._send(403, b"forbidden", "text/plain")
        path = os.path.join(WEB, safe)
        if not os.path.isfile(path):
            return self._send(404, b"not found", "text/plain")
        with open(path, "rb") as fh:
            body = fh.read()
        ext = os.path.splitext(safe)[1].lower()
        self._send(200, body, self.TYPES.get(ext, "text/plain; charset=utf-8"))

    def log_message(self, fmt: str, *args) -> None:      # leiser Log
        print(f"  {self.address_string()} {fmt % args}")

    # ---------------------------------------------------------------- GET ---
    def do_GET(self) -> None:                            # noqa: N802
        parsed = urllib.parse.urlsplit(self.path)
        q = urllib.parse.parse_qs(parsed.query)
        one = lambda k, d="": (q.get(k) or [d])[0]       # noqa: E731
        route = parsed.path.rstrip("/") or "/"

        try:
            if route in ("/", "/index.html"):
                return self._file("index.html")

            # --- PWA: installierbar unter 127.0.0.1 -------------------------
            if route in ("/manifest.webmanifest", "/sw.js", "/companion.html"):
                return self._file(route.lstrip("/"))
            if route.startswith("/icons/"):
                return self._file(route.lstrip("/"))

            if route == "/api/status":
                return self._json({
                    "methods": [s.to_dict() for s in registry.statuses(CFG)],
                    "available": registry.available_methods(CFG),
                })

            if route == "/api/search":
                methods = one("methods")
                return self._json(registry.search(
                    one("q"), CFG,
                    methods=methods.split(",") if methods else None,
                    limit=int(one("limit", "20"))))

            if route == "/api/resolve":
                return self._json(registry.resolve(
                    one("target"), CFG, one("platform", "telegram")))

            if route == "/api/posts":
                return self._json(registry.posts(
                    one("target"), CFG, limit=int(one("limit", "20")),
                    platform=one("platform", "telegram")))

            if route == "/api/watchlist":
                return self._json(store.watchlist())

            if route == "/api/scan":
                res = registry.overview(store.watchlist(), CFG,
                                        posts_per_channel=int(one("limit", "5")))
                store.save_snapshot(res)
                return self._json(res)

            if route == "/api/tiktok/status":
                from tgmon.adapters import tiktok_live as tt
                users = [u for u in one("users").split(",") if u] or \
                        [i["target"] for i in store.watchlist() if i.get("platform") == "tiktok"] or \
                        CFG.get("tiktok", {}).get("accounts", [])
                return self._json({"accounts": [tt.live_status(u) for u in users[:8]]})

            if route == "/api/events":
                return self._json(notify.events(int(one("limit", "50"))))

            if route == "/api/discord/invite":
                ch = dc.invite_info(one("code"))
                return self._json(ch.to_dict() if ch else None)

            if route == "/api/discord/guilds":
                return self._json([c.to_dict() for c in dc.guilds(CFG)])

            if route == "/api/discord/channels":
                return self._json([c.to_dict()
                                   for c in dc.channels(one("guild_id"), CFG)])

            if route == "/api/discord/messages":
                return self._json([p.to_dict() for p in dc.messages(
                    one("channel_id"), int(one("limit", "20")), CFG)])

            if route == "/api/live":
                return self._json(live.history(
                    one("platform", "telegram"), one("target"),
                    limit=int(one("limit", "50"))))

            if route == "/api/live/all":
                limit = int(one("limit", "25"))
                return self._json({"entries": [
                    live.history(i.get("platform", "telegram"), i["target"], limit)
                    for i in store.watchlist()]})

            if route == "/api/live/poll":
                res = live.poll_once(one("platform", "telegram"), one("target"), CFG,
                                     limit=int(one("limit", "25")))
                return self._json({"new": res["new"], "total": res["total"]})

            if route == "/api/poller":
                return self._json(POLLER.status() if POLLER else
                                  {"running": False, "reason": "nicht gestartet"})

            return self._json({"error": "unbekannte Route"}, 404)
        except Exception as exc:                          # noqa: BLE001
            traceback.print_exc()
            return self._json({"error": str(exc)}, 500)

    # --------------------------------------------------------------- POST ---
    def do_POST(self) -> None:                            # noqa: N802
        length = int(self.headers.get("Content-Length") or 0)
        try:
            payload = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            return self._json({"error": "ungueltiges JSON"}, 400)

        route = urllib.parse.urlsplit(self.path).path.rstrip("/")
        try:
            if route == "/api/watchlist":
                action = payload.get("action", "add")
                platform = payload.get("platform", "telegram")
                target = (payload.get("target") or "").lstrip("@")
                if not target:
                    return self._json({"error": "target fehlt"}, 400)
                items = (store.watch_add(platform, target, payload.get("note", ""))
                         if action == "add" else store.watch_remove(platform, target))
                return self._json(items)
            if route == "/api/live":
                return self._json(live.history(
                    one("platform", "telegram"), one("target"),
                    limit=int(one("limit", "50"))))

            if route == "/api/live/all":
                limit = int(one("limit", "25"))
                return self._json({"entries": [
                    live.history(i.get("platform", "telegram"), i["target"], limit)
                    for i in store.watchlist()]})

            if route == "/api/live/poll":
                res = live.poll_once(one("platform", "telegram"), one("target"), CFG,
                                     limit=int(one("limit", "25")))
                return self._json({"new": res["new"], "total": res["total"]})

            if route == "/api/poller":
                return self._json(POLLER.status() if POLLER else
                                  {"running": False, "reason": "nicht gestartet"})

            return self._json({"error": "unbekannte Route"}, 404)
        except Exception as exc:                          # noqa: BLE001
            traceback.print_exc()
            return self._json({"error": str(exc)}, 500)


def run(port: int = 8765, host: str = "127.0.0.1", open_browser: bool = True,
        poll_interval: int = 120) -> None:
    global POLLER
    httpd = ThreadingHTTPServer((host, port), Handler)

    def announce(platform: str, target: str, posts: list) -> None:
        print(f"  [live] {platform}/{target}: {len(posts)} neue(r) Beitrag/Beitraege")

    POLLER = live.Poller(store.watchlist, CFG, interval=poll_interval, on_new=announce)
    POLLER.start()
    print(f"Live-Abfrage alle {POLLER.interval} s fuer {len(store.watchlist())} Ziel(e)")
    url = f"http://{host}:{port}"
    print(f"Telegram Monitor laeuft auf {url}   (Beenden mit Strg+C)")
    for s in registry.statuses(CFG):
        print(f"  [{'x' if s.available else ' '}] {s.name}: {s.reason}")
    if open_browser:
        try:
            webbrowser.open(url)
        except Exception:                                 # noqa: BLE001
            pass
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nBeendet.")
        if POLLER:
            POLLER.stop()
        httpd.server_close()


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser()
    ap.add_argument("--port", type=int, default=8765)
    ap.add_argument("--host", default="127.0.0.1")
    ap.add_argument("--no-browser", action="store_true")
    ap.add_argument("--poll-interval", type=int, default=120,
                    help="Abstand der Live-Abfragen in Sekunden (min. 30)")
    a = ap.parse_args()
    run(a.port, a.host, not a.no_browser, a.poll_interval)
