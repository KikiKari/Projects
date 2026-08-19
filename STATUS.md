# Script Abstractions — Status

**Letzter Lauf:** 2026-08-19 02:23 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 168 |
| perl5 | 167 |
| powershell | 150 |
| python | 143 |
| shell | 160 |
| tcl | 188 |
| **gesamt** | **976** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 115 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1257 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1432** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **6617**

## Letzter Lauf

- bearbeitete Quelldateien: 27
- erzeugte Uebersetzungen: 76
- verworfen: 34

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
