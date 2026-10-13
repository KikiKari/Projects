# Script Abstractions — Status

**Letzter Lauf:** 2026-10-13 00:22 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 322 |
| perl5 | 357 |
| powershell | 324 |
| python | 297 |
| shell | 326 |
| tcl | 378 |
| **gesamt** | **2004** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 128 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2361 | uebriger ausfuehrbarer Code |
| low | 63 | Markup und Stilvorlagen |
| **gesamt** | **2552** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **11757**

## Letzter Lauf

- bearbeitete Quelldateien: 29
- erzeugte Uebersetzungen: 12
- verworfen: 22

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
