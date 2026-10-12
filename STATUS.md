# Script Abstractions — Status

**Letzter Lauf:** 2026-10-12 06:14 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 320 |
| perl5 | 353 |
| powershell | 318 |
| python | 294 |
| shell | 322 |
| tcl | 375 |
| **gesamt** | **1982** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 128 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 2196 | uebriger ausfuehrbarer Code |
| low | 63 | Markup und Stilvorlagen |
| **gesamt** | **2387** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **10779**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 195
- verworfen: 5

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
