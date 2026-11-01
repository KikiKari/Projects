# Script Abstractions — Status

**Letzter Lauf:** 2026-11-01 15:13 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 595 |
| perl5 | 666 |
| powershell | 635 |
| python | 603 |
| shell | 514 |
| tcl | 690 |
| **gesamt** | **3703** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 149 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4011 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4233** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **19841**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 165
- verworfen: 35

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
