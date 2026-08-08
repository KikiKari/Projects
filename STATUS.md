# Script Abstractions — Status

**Letzter Lauf:** 2026-08-08 03:11 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 30 |
| perl5 | 33 |
| powershell | 24 |
| python | 24 |
| shell | 32 |
| tcl | 37 |
| **gesamt** | **180** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 117 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 351 | uebriger ausfuehrbarer Code |
| low | 57 | Markup und Stilvorlagen |
| **gesamt** | **525** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **2483**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 170
- verworfen: 30

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
