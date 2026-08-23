# Script Abstractions — Status

**Letzter Lauf:** 2026-08-23 01:28 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 247 |
| perl5 | 263 |
| powershell | 233 |
| python | 204 |
| shell | 237 |
| tcl | 282 |
| **gesamt** | **1466** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1768 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1945** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **8806**

## Letzter Lauf

- bearbeitete Quelldateien: 37
- erzeugte Uebersetzungen: 47
- verworfen: 27

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
