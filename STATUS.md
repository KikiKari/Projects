# Script Abstractions — Status

**Letzter Lauf:** 2026-11-02 04:55 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 598 |
| perl5 | 671 |
| powershell | 639 |
| python | 608 |
| shell | 519 |
| tcl | 694 |
| **gesamt** | **3729** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 149 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4152 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4374** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **20676**

## Letzter Lauf

- bearbeitete Quelldateien: 18
- erzeugte Uebersetzungen: 10
- verworfen: 16

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
