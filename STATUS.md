# Script Abstractions — Status

**Letzter Lauf:** 2026-11-17 15:55 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 870 |
| perl5 | 995 |
| powershell | 951 |
| python | 931 |
| shell | 640 |
| tcl | 1026 |
| **gesamt** | **5413** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 152 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 5846 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **6070** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **29116**

## Letzter Lauf

- bearbeitete Quelldateien: 14
- erzeugte Uebersetzungen: 2
- verworfen: 13

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
