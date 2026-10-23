# Script Abstractions — Status

**Letzter Lauf:** 2026-10-23 05:36 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 349 |
| perl5 | 388 |
| powershell | 355 |
| python | 325 |
| shell | 351 |
| tcl | 410 |
| **gesamt** | **2178** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2427 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **2643** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **11940**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 192
- verworfen: 8

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
