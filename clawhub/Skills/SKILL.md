# clawhub-git-sync-agent Skill

**Name:** clawhub-git-sync-agent  
**Beschreibung:** Bidirektionaler Sync-Agent für ClawHub ↔ Git  
**Version:** 1.0.0  
**Emoji:** 🔄  

## Zweck

Alle 12 Stunden bidirektionale Synchronisation zwischen:
- **ClawHub**: `/workspace/skills/*/`
- **Git**: `/workspace/git/skills/*/`

## Features

- Automatische Erkennung von Änderungen
- Zeitstempel- und Hash-basierter Vergleich
- Backup vor jeder Änderung
- Dry-Run mit manueller Freigabe
- Konfliktbehandlung

## Verwendung

### Manueller Sync
```bash
python3 /workspace/scripts/sync_clawhub_git.py --skill db-maintainer --direction to-git --dry-run
```

### Automatischer Agent (alle 12 Stunden)
Via Cron-Job (`0 */12 * * *`) mit Dry-Run und Benachrichtigung bei Änderungen. Modell: kimi-k2.5.

## Logs

- Sync-Log: `/workspace/logs/sync.log`
- Agent-Log: `/workspace/logs/sync-agent.log`