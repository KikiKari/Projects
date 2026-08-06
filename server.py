#!/usr/bin/env python3
"""Lokale Weboberflaeche auf 127.0.0.1.

Der lokale Server darf im Gegensatz zur oeffentlichen Seite tatsaechlich nach
aussen proben — ihn bindet kein CORS. Genau dafuer gibt es ihn.
"""
import json
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

from mcpmon import config as cfg
from mcpmon import discovery, state

SEITE = Path(__file__).with_name("public") / "index.html"


class Handler(BaseHTTPRequestHandler):
    server_version = "MCPServerMonitor/0.1"

    def log_message(self, fmt, *args):  # ruhiges Terminal
        pass

    def _send(self, code, body, ctype="application/json; charset=utf-8"):
        data = body if isinstance(body, bytes) else body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        u = urlparse(self.path)
        q = parse_qs(u.query)
        if u.path in ("/", "/index.html"):
            if SEITE.exists():
                return self._send(200, SEITE.read_bytes(), "text/html; charset=utf-8")
            return self._send(200, "<h1>MCP-Server-Monitor</h1><p>public/index.html fehlt.</p>",
                              "text/html; charset=utf-8")
        if u.path == "/api/states":
            return self._send(200, json.dumps(state.ZUSTAENDE, ensure_ascii=False))
        if u.path == "/api/config":
            return self._send(200, json.dumps(cfg.pruefe(), ensure_ascii=False))
        if u.path == "/api/probe":
            dom = (q.get("domain") or [""])[0].strip()
            if not dom:
                return self._send(400, json.dumps({"fehler": "domain fehlt"}))
            return self._send(200, json.dumps(discovery.pruefe(dom), ensure_ascii=False))
        return self._send(404, json.dumps({"fehler": "nicht gefunden"}))


def run(port=8787, oeffnen=True):
    adresse = f"http://127.0.0.1:{port}"
    srv = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"MCP-Server-Monitor laeuft auf {adresse}  (Strg+C beendet)")
    if oeffnen:
        try:
            webbrowser.open(adresse)
        except Exception:
            pass
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\nbeendet.")
    finally:
        srv.server_close()


if __name__ == "__main__":
    run()
