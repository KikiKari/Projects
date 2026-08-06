"""claude_desktop_config.json finden, lesen und die MSIX-Falle benennen.

Die Falle: Bei MSIX-Installationen oeffnet 'Edit Config' im Entwickler-Menue die
erste Datei, gelesen wird die zweite. Wer dort eintraegt, wartet vergeblich.
"""
import json
import os
from pathlib import Path

MSIX_PAKET = "Claude_pzs8sxrjxfjjc"


def pfade():
    """Die zwei moeglichen Orte, in der Reihenfolge Standard-Installer / MSIX."""
    appdata = os.environ.get("APPDATA")
    local = os.environ.get("LOCALAPPDATA")
    out = []
    if appdata:
        out.append(("Standard-Installer",
                    Path(appdata) / "Claude" / "claude_desktop_config.json"))
    if local:
        out.append(("MSIX (Store, WinGet, Enterprise)",
                    Path(local) / "Packages" / MSIX_PAKET / "LocalCache" /
                    "Roaming" / "Claude" / "claude_desktop_config.json"))
    if not out:  # macOS / Linux
        out.append(("macOS",
                    Path.home() / "Library" / "Application Support" /
                    "Claude" / "claude_desktop_config.json"))
    return out


def pruefe():
    """Liefert je Pfad: existiert er, welche mcpServers stehen drin, wer wirkt."""
    gefunden = []
    for art, p in pfade():
        eintrag = {"art": art, "pfad": str(p), "existiert": p.exists(),
                   "server": [], "fehler": ""}
        if p.exists():
            try:
                daten = json.loads(p.read_text(encoding="utf-8"))
                eintrag["server"] = sorted(daten.get("mcpServers", {}).keys())
            except Exception as e:
                eintrag["fehler"] = f"nicht lesbar: {e}"
        gefunden.append(eintrag)

    warnungen = []
    vorhanden = [g for g in gefunden if g["existiert"]]
    if len(vorhanden) > 1:
        warnungen.append(
            "Beide Dateien existieren. Bei einer MSIX-Installation wirkt die "
            "MSIX-Datei; 'Edit Config' oeffnet aber die andere. Eintraege in der "
            "falschen Datei bleiben wirkungslos."
        )
    if vorhanden:
        warnungen.append(
            "Die App liest die Datei nur beim Start. Nach dem Aendern die App "
            "vollstaendig beenden und neu oeffnen — Fenster schliessen genuegt nicht."
        )
    if not vorhanden:
        warnungen.append(
            "Keine Konfigurationsdatei gefunden. Ferne Server gehoeren ohnehin "
            "unter Anpassen -> Konnektoren, nicht unter Erweiterungen."
        )
    return {"gefunden": gefunden, "warnungen": warnungen}


def eintrag_vorlage(name, url):
    """Vorlage fuer einen manuell definierten fernen Server."""
    return json.dumps(
        {"mcpServers": {name: {"type": "http", "url": url}}},
        indent=2, ensure_ascii=False,
    )
