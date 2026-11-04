# Script Abstractions — Status

**Letzter Lauf:** 2026-11-04 13:59 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 633 |
| perl5 | 720 |
| powershell | 690 |
| python | 659 |
| shell | 542 |
| tcl | 742 |
| **gesamt** | **3986** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4413 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4636** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **21969**

## Letzter Lauf

- bearbeitete Quelldateien: 17
- erzeugte Uebersetzungen: 6
- verworfen: 15

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
