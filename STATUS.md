# Script Abstractions — Status

**Letzter Lauf:** 2026-08-22 07:03 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 240 |
| perl5 | 254 |
| powershell | 225 |
| python | 197 |
| shell | 232 |
| tcl | 274 |
| **gesamt** | **1422** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 115 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1680 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1855** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **8403**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 88
- verworfen: 29

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
