# Architektur

## Ziel und Kontext

Das Werkzeug beantwortet eine einzige Frage zuverlässig: *In welchem Zustand ist
dieser MCP-Server, und was ist der nächste Schritt?* Alles andere ist Beiwerk.

Daraus folgt der Zuschnitt: drei Schichten, klar getrennt, jede für sich prüfbar.

```
Signale ──► Sonde ──────────► Klassifikation ──────► Ausgabe
(Nutzer)    mcpmon/discovery   mcpmon/state          mcpmon/report
            mcpmon/config                             public/index.html
```

| Schicht | Modul | Verantwortung | Kennt nicht |
|---|---|---|---|
| Sonde | `discovery.py`, `config.py` | Netz und Dateisystem befragen, Rohbefunde liefern | Zustände, Formatierung |
| Klassifikation | `state.py` | Signale → einer von fünf Zuständen + ein Schritt | Netz, Dateisystem, Terminal |
| Ausgabe | `report.py`, `public/index.html` | Text bzw. HTML | Netz |

`state.py` hat **keine** Importe außer `dataclasses`. Das ist Absicht: Die
Klassifikationsregeln sind der Kern und müssen ohne Netz, ohne Dateien und ohne
Terminal testbar bleiben.

## Datenfluss

1. `cli.py` sammelt Signale — entweder aus Flags (`doctor`) oder aus Proben (`probe`, `config`).
2. `discovery.pruefe(domain)` läuft die fünf Pfade ab und liefert je Pfad eine
   `Probe` (Status, Content-Type, Fehler) plus ein **begründetes Urteil**. Nicht nur
   ja/nein — die Begründung ist der eigentliche Wert.
3. `state.bestimme(...)` bildet die Signale auf einen Zustand ab und hängt Warnungen an.
4. `report.*` bzw. die HTML-Seite stellen das dar.

## Zwei Entscheidungen, die den Zuschnitt erklären

### Die öffentliche Seite probt nicht

Ein `fetch` aus dem Browser auf `https://mcp.DOMAIN/` scheitert an CORS — der
Anbieter setzt keine Freigabe für eine fremde Herkunft. Eine Seite, die es trotzdem
versucht, bleibt beim Nutzer leer und sieht dabei kaputt aus.

Deshalb: Dieselbe Datei erkennt ihre Herkunft. Auf `127.0.0.1` schaltet sie den
Prüf-Knopf frei und ruft `/api/probe` des lokalen Servers; auf Vercel zeigt sie
stattdessen den Grund und die Startanweisung für den Companion. Kein toter Knopf,
keine Ausrede.

### Tools sind das stärkste Signal

Die Klassifikation fragt zuerst nach Tools, nicht nach dem Konnektor-Häkchen.
Grund: Tool-Listen sind scope-gefiltert. Was da ist, ist auch nutzbar — während ein
Häkchen nur sagt, dass ein OAuth-Flow einmal durchlief. Ein fehlendes Tool bedeutet
fast immer einen nicht erteilten Scope, nicht eine fehlende Funktion des Servers.

## Abhängigkeiten

Keine. Standardbibliothek: `urllib`, `ssl`, `json`, `http.server`, `argparse`,
`dataclasses`, `pathlib`. Das Werkzeug soll auf einem frisch installierten Python
laufen, ohne dass jemand erst eine Umgebung baut.

## Was bewusst fehlt

- **Kein MCP-Client.** Das Werkzeug spricht das Protokoll nicht, es stellt nur fest,
  ob und wo ein Server erreichbar ist. Ein Handshake bräuchte Anmeldung — genau das,
  was hier nicht passieren soll.
- **Kein Schreiben in `claude_desktop_config.json`.** Gelesen wird, geschrieben nicht.
  Eine Konfigurationsdatei, die ein Werkzeug hinter dem Rücken ändert, ist kein Gewinn.
- **Keine Zustandsspeicherung.** Jeder Lauf fragt neu. Ein Cache würde genau die
  Frage falsch beantworten, für die es das Werkzeug gibt.
