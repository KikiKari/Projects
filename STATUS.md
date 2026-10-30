# Script Abstractions — Status

**Letzter Lauf:** 2026-10-30 12:39 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 540 |
| perl5 | 593 |
| powershell | 561 |
| python | 532 |
| shell | 487 |
| tcl | 613 |
| **gesamt** | **3326** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3752 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3968** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **18693**

## Letzter Lauf

- bearbeitete Quelldateien: 17
- erzeugte Uebersetzungen: 1
- verworfen: 16

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
