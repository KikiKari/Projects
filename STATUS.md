# Script Abstractions — Status

**Letzter Lauf:** 2026-10-23 11:54 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 352 |
| perl5 | 390 |
| powershell | 357 |
| python | 326 |
| shell | 353 |
| tcl | 412 |
| **gesamt** | **2190** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 147 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2578 | uebriger ausfuehrbarer Code |
| low | 69 | Markup und Stilvorlagen |
| **gesamt** | **2794** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **12851**

## Letzter Lauf

- bearbeitete Quelldateien: 15
- erzeugte Uebersetzungen: 36
- verworfen: 22

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
