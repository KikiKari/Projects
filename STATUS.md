# Script Abstractions — Status

**Letzter Lauf:** 2026-08-08 23:16 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 67 |
| perl5 | 71 |
| powershell | 59 |
| python | 62 |
| shell | 65 |
| tcl | 76 |
| **gesamt** | **400** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 575 | uebriger ausfuehrbarer Code |
| low | 57 | Markup und Stilvorlagen |
| **gesamt** | **749** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **3423**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 189
- verworfen: 11

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
