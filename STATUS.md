# Script Abstractions — Status

**Letzter Lauf:** 2026-11-06 05:38 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 678 |
| perl5 | 769 |
| powershell | 735 |
| python | 707 |
| shell | 561 |
| tcl | 794 |
| **gesamt** | **4244** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4677 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4900** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **23292**

## Letzter Lauf

- bearbeitete Quelldateien: 8
- erzeugte Uebersetzungen: 1
- verworfen: 14

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
