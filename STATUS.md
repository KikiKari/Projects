# Script Abstractions — Status

**Letzter Lauf:** 2026-11-01 22:19 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 598 |
| perl5 | 669 |
| powershell | 637 |
| python | 606 |
| shell | 517 |
| tcl | 692 |
| **gesamt** | **3719** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 149 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4136 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4358** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **20606**

## Letzter Lauf

- bearbeitete Quelldateien: 12
- erzeugte Uebersetzungen: 20
- verworfen: 21

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
