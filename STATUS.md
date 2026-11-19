# Script Abstractions — Status

**Letzter Lauf:** 2026-11-19 07:42 UTC

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
| medium | 5976 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **6200** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **29597**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 173
- verworfen: 27

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
