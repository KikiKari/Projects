# Script Abstractions — Status

**Letzter Lauf:** 2026-08-19 12:52 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 190 |
| perl5 | 193 |
| powershell | 172 |
| python | 158 |
| shell | 173 |
| tcl | 214 |
| **gesamt** | **1100** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 115 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1444 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1619** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **7418**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 7
- verworfen: 193

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
