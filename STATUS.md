# Script Abstractions — Status

**Letzter Lauf:** 2026-10-23 17:01 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 353 |
| perl5 | 390 |
| powershell | 358 |
| python | 326 |
| shell | 354 |
| tcl | 412 |
| **gesamt** | **2193** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2614 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **2830** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **13021**

## Letzter Lauf

- bearbeitete Quelldateien: 30
- erzeugte Uebersetzungen: 10
- verworfen: 21

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
