# Script Abstractions — Status

**Letzter Lauf:** 2026-10-31 04:52 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 562 |
| perl5 | 616 |
| powershell | 585 |
| python | 556 |
| shell | 495 |
| tcl | 638 |
| **gesamt** | **3452** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3878 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **4094** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **19312**

## Letzter Lauf

- bearbeitete Quelldateien: 8
- erzeugte Uebersetzungen: 2
- verworfen: 17

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
