#!/usr/bin/env python3
"""MCP-Server-Monitor — Kommandozeile.

  python cli.py states                 Die fuenf Zustaende nachschlagen
  python cli.py errors                 Fehlerbilder und ihre Ursachen
  python cli.py probe DOMAIN [...]     Discovery: gibt es einen MCP-Server?
  python cli.py config                 Konfigurationsdatei pruefen (MSIX-Falle)
  python cli.py doctor --tools ja|nein [--gelistet] [--haekchen]
                       [--auth-noetig] [--plugin] [--angemeldet]
  python cli.py serve [PORT]           Weboberflaeche auf 127.0.0.1

Nur Standardbibliothek. --json haengt an jeden Befehl maschinenlesbare Ausgabe.
"""
import argparse
import json
import sys

from mcpmon import config as cfg
from mcpmon import discovery, report, state


def main(argv=None):
    ap = argparse.ArgumentParser(prog="cli.py", add_help=True,
                                 description="MCP-Server-Monitor")
    ap.add_argument("--json", action="store_true", help="Ausgabe als JSON")

    # --json soll vor *und* nach dem Unterbefehl gelten. SUPPRESS sorgt dafuer,
    # dass ein weggelassenes Flag den Wert der Hauptebene nicht ueberschreibt.
    gemeinsam = argparse.ArgumentParser(add_help=False)
    gemeinsam.add_argument("--json", action="store_true",
                           default=argparse.SUPPRESS, help="Ausgabe als JSON")

    sub = ap.add_subparsers(dest="cmd")
    sub.add_parser("states", parents=[gemeinsam], help="die fuenf Zustaende")
    sub.add_parser("errors", parents=[gemeinsam], help="Fehlerbilder")
    sub.add_parser("config", parents=[gemeinsam], help="claude_desktop_config.json pruefen")

    p = sub.add_parser("probe", parents=[gemeinsam],
                       help="Discovery fuer eine oder mehrere Domains")
    p.add_argument("domain", nargs="+")

    d = sub.add_parser("doctor", parents=[gemeinsam],
                       help="Zustand aus beobachteten Signalen bestimmen")
    d.add_argument("--tools", choices=["ja", "nein"], required=True,
                   help="Sind Tools mit dem Namensmuster des Servers vorhanden?")
    d.add_argument("--gelistet", action="store_true", help="steht in der Konnektoren-Liste")
    d.add_argument("--haekchen", action="store_true", help="Konnektor zeigt Haekchen")
    d.add_argument("--auth-noetig", action="store_true",
                   help="System meldet 'benoetigt Authentifizierung'")
    d.add_argument("--plugin", action="store_true",
                   help="derselbe Name laeuft auch als plugin:…")
    d.add_argument("--angemeldet", action="store_true", help="es wurde je etwas angemeldet")

    s = sub.add_parser("serve", parents=[gemeinsam], help="lokale Weboberflaeche")
    s.add_argument("port", nargs="?", type=int, default=8787)

    a = ap.parse_args(argv)
    if not a.cmd:
        ap.print_help()
        return 1

    if a.cmd == "states":
        print(json.dumps(state.ZUSTAENDE, ensure_ascii=False, indent=2)
              if a.json else report.zustandstabelle())
    elif a.cmd == "errors":
        print(json.dumps(state.FEHLERBILDER, ensure_ascii=False, indent=2)
              if a.json else report.fehlerbilder())
    elif a.cmd == "config":
        res = cfg.pruefe()
        print(json.dumps(res, ensure_ascii=False, indent=2) if a.json else report.konfig(res))
    elif a.cmd == "probe":
        out = [discovery.pruefe(d_) for d_ in a.domain]
        if a.json:
            print(json.dumps(out, ensure_ascii=False, indent=2))
        else:
            print("\n\n".join(report.discovery(r) for r in out))
    elif a.cmd == "doctor":
        b = state.bestimme(hat_tools=(a.tools == "ja"), ist_gelistet=a.gelistet,
                           hat_haekchen=a.haekchen, meldet_auth_noetig=a.auth_noetig,
                           auch_als_plugin=a.plugin, je_angemeldet=a.angemeldet)
        print(json.dumps(b.as_dict(), ensure_ascii=False, indent=2)
              if a.json else report.befund(b))
    elif a.cmd == "serve":
        import server
        server.run(a.port)
    return 0


if __name__ == "__main__":
    sys.exit(main())
