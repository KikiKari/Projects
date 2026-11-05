# Script Abstractions — Status

**Letzter Lauf:** 2026-11-05 14:12 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 654 |
| perl5 | 743 |
| powershell | 715 |
| python | 684 |
| shell | 551 |
| tcl | 769 |
| **gesamt** | **4116** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4548 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4771** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **22648**

## Letzter Lauf

- bearbeitete Quelldateien: 15
- erzeugte Uebersetzungen: 1
- verworfen: 14

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
