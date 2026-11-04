# Script Abstractions — Status

**Letzter Lauf:** 2026-11-04 05:48 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 632 |
| perl5 | 719 |
| powershell | 688 |
| python | 659 |
| shell | 541 |
| tcl | 741 |
| **gesamt** | **3980** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4412 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4635** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **21970**

## Letzter Lauf

- bearbeitete Quelldateien: 8
- erzeugte Uebersetzungen: 1
- verworfen: 15

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
