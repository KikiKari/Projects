# Script Abstractions — Status

**Letzter Lauf:** 2026-08-09 13:37 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 135 |
| perl5 | 132 |
| powershell | 115 |
| python | 111 |
| shell | 124 |
| tcl | 151 |
| **gesamt** | **768** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 120 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 932 | uebriger ausfuehrbarer Code |
| low | 61 | Markup und Stilvorlagen |
| **gesamt** | **1113** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **5065**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 178
- verworfen: 18

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
