"""Discovery: betreibt der Anbieter selbst einen MCP-Server?

Reihenfolge und Deutung folgen einer harten Regel: Eine leere Antwort auf ein
nacktes GET beweist nichts. Streamable-HTTP-Endpunkte antworten darauf oft mit
gar nichts. Erst wenn auch die Discovery-Pfade fehlen, ist von Abwesenheit
auszugehen.
"""
import json
import socket
import ssl
import urllib.error
import urllib.request
from dataclasses import dataclass, asdict

UA = "MCP-Server-Monitor/0.1 (+https://github.com/KikiKari/Projects)"
TIMEOUT = 8.0


@dataclass
class Probe:
    """Ergebnis eines einzelnen Abrufs."""

    url: str
    art: str
    status: int = 0
    fehler: str = ""
    laenge: int = 0
    content_type: str = ""
    json_keys: list = None

    @property
    def erreichbar(self):
        return self.status and self.status < 500


def _get(url, art, accept="application/json, text/event-stream, */*"):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": accept})
    ctx = ssl.create_default_context()
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as r:
            body = r.read(65536)
            p = Probe(url=url, art=art, status=r.status, laenge=len(body),
                      content_type=r.headers.get("Content-Type", ""))
            if "json" in p.content_type:
                try:
                    p.json_keys = sorted(json.loads(body.decode("utf-8", "replace")).keys())
                except Exception:
                    p.json_keys = None
            return p
    except urllib.error.HTTPError as e:
        return Probe(url=url, art=art, status=e.code, fehler=e.reason or "")
    except (urllib.error.URLError, socket.timeout, ssl.SSLError, OSError) as e:
        return Probe(url=url, art=art, status=0, fehler=str(getattr(e, "reason", e)))


def kandidaten(domain):
    """Die vier Pfade, die bei den meisten Anbietern greifen."""
    d = domain.strip().lower().removeprefix("https://").removeprefix("http://").strip("/")
    return [
        (f"https://mcp.{d}/", "endpunkt"),
        (f"https://mcp.{d}/mcp", "endpunkt"),
        (f"https://docs.{d}/mcp", "doku"),
        (f"https://mcp.{d}/.well-known/oauth-protected-resource", "well-known"),
        (f"https://{d}/.well-known/oauth-protected-resource", "well-known"),
        (f"https://{d}/.well-known/oauth-authorization-server", "well-known"),
    ]


def pruefe(domain):
    """Prueft eine Domain und liefert Proben plus eine begruendete Deutung."""
    proben = [_get(url, art) for url, art in kandidaten(domain)]
    wk = [p for p in proben if p.art == "well-known" and p.status == 200]
    eps = [p for p in proben if p.art == "endpunkt"]
    treffer = [p for p in eps if p.status in (200, 202, 400, 401, 405, 406, 415)]
    ep = treffer[0] if treffer else (eps[0] if eps else None)
    doku = next((p for p in proben if p.art == "doku"), None)

    if wk:
        urteil = "oauth-faehiger-server"
        text = ("Discovery-Metadaten vorhanden — es gibt einen OAuth-faehigen "
                "MCP-Server. Eintragen unter Anpassen -> Konnektoren.")
    elif treffer:
        urteil = "endpunkt-antwortet"
        text = (f"{ep.url} antwortet (HTTP {ep.status}). Auch 400/401/405 "
                "zaehlen: ein Streamable-HTTP-Endpunkt lehnt ein nacktes GET "
                "regulaer ab. Das ist ein Fund, kein Fehler.")
    elif doku and doku.status == 200:
        urteil = "doku-vorhanden"
        text = ("Eine Doku-Seite zu MCP existiert; der Endpunkt steht dort. "
                "URL aus der Doku nehmen und eintragen.")
    elif doku and doku.status in (401, 403, 405, 406, 429):
        urteil = "doku-blockiert"
        text = (f"docs.{domain}/mcp antwortet mit HTTP {doku.status} — die Seite "
                "existiert, blockt aber automatisierte Abrufe. Das ist kein "
                "Negativbefund: im Browser nachsehen.")
    else:
        urteil = "kein-befund"
        text = ("Weder Endpunkt noch Discovery-Pfade noch Doku-Seite. "
                "Erst jetzt ist von Abwesenheit auszugehen — als Naechstes die "
                "Connector-Registry nach Anbietername und Domaene durchsuchen.")

    return {
        "domain": domain,
        "urteil": urteil,
        "deutung": text,
        "proben": [asdict(p) for p in proben],
    }
