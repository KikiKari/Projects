# Script Abstractions — Status

**Letzter Lauf:** 2026-11-18 02:34 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 892 |
| perl5 | 1020 |
| powershell | 975 |
| python | 957 |
| shell | 645 |
| tcl | 1053 |
| **gesamt** | **5542** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 152 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 5847 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **6071** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **28950**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 171
- verworfen: 29

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
