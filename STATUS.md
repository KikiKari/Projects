# Script Abstractions — Status

**Letzter Lauf:** 2026-11-03 00:55 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 611 |
| perl5 | 695 |
| powershell | 663 |
| python | 635 |
| shell | 534 |
| tcl | 720 |
| **gesamt** | **3858** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4289 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4512** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **21357**

## Letzter Lauf

- bearbeitete Quelldateien: 11
- erzeugte Uebersetzungen: 5
- verworfen: 16

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
