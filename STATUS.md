# Script Abstractions — Status

**Letzter Lauf:** 2026-08-24 07:39 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 296 |
| perl5 | 317 |
| powershell | 282 |
| python | 257 |
| shell | 286 |
| tcl | 335 |
| **gesamt** | **1773** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2118 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **2295** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **10555**

## Letzter Lauf

- bearbeitete Quelldateien: 8
- erzeugte Uebersetzungen: 1
- verworfen: 22

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
