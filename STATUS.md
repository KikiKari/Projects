# Script Abstractions — Status

**Letzter Lauf:** 2026-10-12 15:16 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 321 |
| perl5 | 355 |
| powershell | 321 |
| python | 296 |
| shell | 324 |
| tcl | 377 |
| **gesamt** | **1994** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 128 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2349 | uebriger ausfuehrbarer Code |
| low | 63 | Markup und Stilvorlagen |
| **gesamt** | **2540** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **11709**

## Letzter Lauf

- bearbeitete Quelldateien: 13
- erzeugte Uebersetzungen: 30
- verworfen: 22

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
