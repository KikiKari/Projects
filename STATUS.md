# Script Abstractions — Status

**Letzter Lauf:** 2026-11-05 02:22 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 654 |
| perl5 | 743 |
| powershell | 714 |
| python | 684 |
| shell | 551 |
| tcl | 769 |
| **gesamt** | **4115** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4419 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4642** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **21828**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 171
- verworfen: 29

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
