# Script Abstractions — Status

**Letzter Lauf:** 2026-10-26 22:32 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 449 |
| perl5 | 490 |
| powershell | 462 |
| python | 426 |
| shell | 412 |
| tcl | 513 |
| **gesamt** | **2752** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3179 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3395** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **15835**

## Letzter Lauf

- bearbeitete Quelldateien: 19
- erzeugte Uebersetzungen: 1
- verworfen: 18

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
