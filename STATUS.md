# Script Abstractions — Status

**Letzter Lauf:** 2026-08-23 08:19 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 268 |
| perl5 | 288 |
| powershell | 256 |
| python | 233 |
| shell | 261 |
| tcl | 309 |
| **gesamt** | **1615** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1812 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1989** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **8835**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 191
- verworfen: 9

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
