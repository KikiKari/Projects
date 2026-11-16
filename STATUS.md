# Script Abstractions — Status

**Letzter Lauf:** 2026-11-16 05:10 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 852 |
| perl5 | 972 |
| powershell | 926 |
| python | 906 |
| shell | 628 |
| tcl | 1000 |
| **gesamt** | **5284** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 152 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 5704 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **5928** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **28404**

## Letzter Lauf

- bearbeitete Quelldateien: 17
- erzeugte Uebersetzungen: 18
- verworfen: 15

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
