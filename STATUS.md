# Script Abstractions — Status

**Letzter Lauf:** 2026-10-27 17:41 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 474 |
| perl5 | 516 |
| powershell | 483 |
| python | 453 |
| shell | 433 |
| tcl | 541 |
| **gesamt** | **2900** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 3327 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **3543** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **16574**

## Letzter Lauf

- bearbeitete Quelldateien: 18
- erzeugte Uebersetzungen: 1
- verworfen: 17

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
