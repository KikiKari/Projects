# Script Abstractions — Status

**Letzter Lauf:** 2026-11-11 07:19 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 786 |
| perl5 | 893 |
| powershell | 852 |
| python | 828 |
| shell | 598 |
| tcl | 918 |
| **gesamt** | **4875** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 148 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 5178 | uebriger ausfuehrbarer Code |
| low | 72 | Markup und Stilvorlagen |
| **gesamt** | **5398** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **25608**

## Letzter Lauf

- bearbeitete Quelldateien: 40
- erzeugte Uebersetzungen: 168
- verworfen: 32

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
