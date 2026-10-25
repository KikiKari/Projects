# Script Abstractions — Status

**Letzter Lauf:** 2026-10-25 20:32 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 424 |
| perl5 | 464 |
| powershell | 437 |
| python | 400 |
| shell | 392 |
| tcl | 486 |
| **gesamt** | **2603** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3028 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3244** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **15078**

## Letzter Lauf

- bearbeitete Quelldateien: 21
- erzeugte Uebersetzungen: 2
- verworfen: 19

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
