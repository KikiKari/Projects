# Script Abstractions — Status

**Letzter Lauf:** 2026-11-04 01:54 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 632 |
| perl5 | 719 |
| powershell | 688 |
| python | 658 |
| shell | 541 |
| tcl | 741 |
| **gesamt** | **3979** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 150 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4291 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4514** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **21207**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 160
- verworfen: 36

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
