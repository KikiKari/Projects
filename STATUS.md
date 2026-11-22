# Script Abstractions — Status

**Letzter Lauf:** 2026-11-22 17:34 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 954 |
| perl5 | 1092 |
| powershell | 1048 |
| python | 1036 |
| shell | 679 |
| tcl | 1132 |
| **gesamt** | **5941** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 152 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 6243 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **6467** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **30926**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 176
- verworfen: 24

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
