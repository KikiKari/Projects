# Script Abstractions — Status

**Letzter Lauf:** 2026-10-24 21:29 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 402 |
| perl5 | 441 |
| powershell | 411 |
| python | 374 |
| shell | 383 |
| tcl | 461 |
| **gesamt** | **2472** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2898 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3114** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **14429**

## Letzter Lauf

- bearbeitete Quelldateien: 9
- erzeugte Uebersetzungen: 2
- verworfen: 20

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
