# Script Abstractions — Status

**Letzter Lauf:** 2026-10-28 00:13 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 502 |
| perl5 | 544 |
| powershell | 509 |
| python | 479 |
| shell | 457 |
| tcl | 565 |
| **gesamt** | **3056** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3327 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3543** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **16378**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 196
- verworfen: 4

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
