# Script Abstractions — Status

**Letzter Lauf:** 2026-08-22 02:37 UTC

Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.
Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige
Syntax oder mit Platzhaltern werden verworfen.

## Bestand

| Zielsprache | Dateien |
|---|---:|
| javascript | 231 |
| perl5 | 237 |
| powershell | 209 |
| python | 187 |
| shell | 214 |
| tcl | 256 |
| **gesamt** | **1334** |

## Quellen

| Prioritaet | Quelldateien | Bedeutung |
|---|---:|---|
| high | 115 | Betriebsscripte aus scripts-Verzeichnissen |
| medium | 1672 | uebriger ausfuehrbarer Code |
| low | 60 | Markup und Stilvorlagen |
| **gesamt** | **1847** | nach Inhalt dedupliziert |

Noch offene Sprachpaare: **8451**

## Letzter Lauf

- bearbeitete Quelldateien: 15
- erzeugte Uebersetzungen: 11
- verworfen: 23

## Herkunft

- `KikiKari/OpenClaw` — main, gateway1, gateway2
- `KikiKari/Projects` — alle Branches
- `KikiKari/Onboarding` — main

Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.
