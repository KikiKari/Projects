# Script Abstractions — Status

**Letzter Lauf:** 2026-11-02 18:47 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 611 |
| perl5 | 695 |
| powershell | 663 |
| python | 634 |
| shell | 534 |
| tcl | 719 |
| **gesamt** | **3856** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 149 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 4162 | uebriger ausfuehrbarer Code |
| low | 73 | Markup und Stilvorlagen |
| **gesamt** | **4384** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **20558**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 168
- verworfen: 32

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
