# Script Abstractions — Status

**Letzter Lauf:** 2026-10-11 23:36 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 296 |
| perl5 | 329 |
| powershell | 292 |
| python | 267 |
| shell | 297 |
| tcl | 348 |
| **gesamt** | **1829** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 127 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2141 | uebriger ausfuehrbarer Code |
| low | 62 | Markup und Stilvorlagen |
| **gesamt** | **2330** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **10688**

## Letzter Lauf

- bearbeitete Quelldateien: 39
- erzeugte Uebersetzungen: 78
- verworfen: 29

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
