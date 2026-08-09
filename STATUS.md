# Script Abstractions — Status

**Letzter Lauf:** 2026-08-09 05:46 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 103 |
| perl5 | 96 |
| powershell | 89 |
| python | 93 |
| shell | 100 |
| tcl | 114 |
| **gesamt** | **595** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 120 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 735 | uebriger ausfuehrbarer Code |
| low | 57 | Markup und Stilvorlagen |
| **gesamt** | **912** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **4234**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 201
- verworfen: 32

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
