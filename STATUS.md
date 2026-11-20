# Script Abstractions — Status

**Letzter Lauf:** 2026-11-20 06:03 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 912 |
| perl5 | 1044 |
| powershell | 999 |
| python | 983 |
| shell | 656 |
| tcl | 1081 |
| **gesamt** | **5675** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 152 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 6110 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **6334** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **30437**

## Letzter Lauf

- bearbeitete Quelldateien: 14
- erzeugte Uebersetzungen: 8
- verworfen: 14

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
