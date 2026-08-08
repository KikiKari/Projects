# Script Abstractions — Status

**Letzter Lauf:** 2026-08-08 08:33 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 43 |
| perl5 | 46 |
| powershell | 36 |
| python | 36 |
| shell | 43 |
| tcl | 49 |
| **gesamt** | **253** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 502 | uebriger ausfuehrbarer Code |
| low | 57 | Markup und Stilvorlagen |
| **gesamt** | **676** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **3247**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 73
- verworfen: 167

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
