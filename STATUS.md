# Script Abstractions — Status

**Letzter Lauf:** 2026-08-20 01:32 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 210 |
| perl5 | 213 |
| powershell | 188 |
| python | 165 |
| shell | 190 |
| tcl | 235 |
| **gesamt** | **1201** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 115 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1445 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1620** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **7327**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 103
- verworfen: 22

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
