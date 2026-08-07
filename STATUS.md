# Script Abstractions — Status

**Letzter Lauf:** 2026-08-07 21:20 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 5 |
| perl5 | 6 |
| powershell | 5 |
| python | 2 |
| shell | 5 |
| tcl | 6 |
| **gesamt** | **29** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 329 | uebriger ausfuehrbarer Code |
| low | 57 | Markup und Stilvorlagen |
| **gesamt** | **503** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **2543**

## Letzter Lauf

- bearbeitete Quelldateien: 6
- erzeugte Uebersetzungen: 29
- verworfen: 1

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
