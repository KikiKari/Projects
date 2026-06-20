# abstractions-utils Skill

**Name:** abstractions-utils
**Beschreibung:** Automatisierter Multi-Node Abstraction Manager — portiert OpenClaw-Scripts alle 6 Stunden per Cron in 10 Zielsprachen. Unterstützt manuelle Ausführung, Status-Abfrage und State-Reset.
**Version:** 1.0.0
**Emoji:** 🤖

---

## Verwendung

### Cron (automatisch)

Der Manager läuft automatisch alle 6 Stunden:

```
0 */6 * * * /usr/bin/python3 /home/openclaw/.openclaw/workspace/skills/abstractions-utils/scripts/ABSTRACTIONS_MANAGER.py
```

### Manuell ausführen

```bash
python3 /home/openclaw/.openclaw/workspace/skills/abstractions-utils/scripts/ABSTRACTIONS_MANAGER.py
```

### Status-Report lesen

```bash
cat /home/openclaw/.openclaw/workspace/git/Abstraktionen/STATUS.md
```

### Letzten Lauf im Log prüfen

```bash
tail -50 /home/openclaw/.openclaw/workspace/logs/abstractions-manager/$(date +%Y-%m-%d).log
```

### Verarbeitungs-State zurücksetzen

```bash
rm /home/openclaw/.openclaw/workspace/db/abstractions_state.json
```

---

## Verfügbare Scripts

| Script | Funktion |
|--------|----------|
| `ABSTRACTIONS_MANAGER.py` | Haupt-Orchestrator: findet Scripts, verteilt Jobs auf Nodes, erstellt Stubs, committet ins Abstraktionen-Repo |

---

## Node-Übersicht

| Node | Gerät | Kapazität | Priorität |
|------|-------|-----------|-----------|
| node7 | Server (Docker-Hauptarbeitspferd) | high | 1 |
| node1 | Server (Gateway-Master) | medium | 2 |
| node2 | Server (Stable Worker) | medium | 3 |
| node3 | Server (bald verfügbar) | medium | 4 |
| node5 | Redmi Note 11S | low | 5 |

---

## Unterstützte Zielsprachen

- perl5, perl6
- javascript
- python
- shell
- powershell
- tcl
- ruby
- lua
- go

---

Workspace: `/home/openclaw/.openclaw/workspace`
Ausgabe-Repository: `/home/openclaw/.openclaw/workspace/git/Abstraktionen`
State-Datei: `/home/openclaw/.openclaw/workspace/db/abstractions_state.json`
Logs: `/home/openclaw/.openclaw/workspace/logs/abstractions-manager/YYYY-MM-DD.log`
