---
name: git-publish-agent
description: Automated git publishing agent for OpenClaw skill management. Handles git commits, documentation updates, version bumps, and ClawHub publishing workflows. Monitors skill changes and publishes automatically when configured.
---

# Git Publish Agent

Sub-Agent für automatisierte Veröffentlichung von OpenClaw Skills.

## Aufgaben

| Aufgabe | Beschreibung |
|---------|-------------|
| **Git Commit** | Automatische Commits bei Skill-Änderungen |
| **Doc Update** | Dokumentation synchronisieren |
| **Version Bump** | Semantische Versionierung |
| **ClawHub Publish** | Automatische Veröffentlichung |
| **Changelog** | CHANGELOG.md automatisch pflegen |

## Workflows

### Workflow 1: Skill-Änderung erkannt

```
Skill-Datei geändert
    ↓
Git Status prüfen
    ↓
Änderungen commiten (auto-message)
    ↓
Dokumentation aktualisieren
    ↓
Optional: Version bump
    ↓
ClawHub publish (wenn konfiguriert)
```

### Workflow 2: Batch-Publishing

```
Mehrere Skills geändert
    ↓
Änderungen gruppieren
    ↓
Geordnet commiten
    ↓
Rate-Limit beachten (max 5/h)
    ↓
Nacheinander veröffentlichen
```

## Konfiguration

```json
{
  "git-publish-agent": {
    "enabled": true,
    "auto_commit": true,
    "auto_publish": true,
    "commit_prefix": "[skill]",
    "batch_delay_minutes": 15
  }
}
```

## CLI-Nutzung

```bash
# Einzelnen Skill veröffentlichen
openclaw git-publish --skill json-utils

# Alle geänderten Skills
openclaw git-publish --all

# Nur commit, nicht veröffentlichen
openclaw git-publish --skill scripting-utils --no-publish

# Mit spezifischer Message
openclaw git-publish --skill cluster-management --message "Fix: Topology template"
```

## Scripts

| Script | Zweck |
|--------|-------|
| `git_commit.py` | Automatische Git-Commits |
| `version_bump.py` | SemVersion erhöhen |
| `clawhub_batch.py` | Batch-Publishing mit Rate-Limit |
| `changelog_gen.py` | CHANGELOG.md generieren |

## Integration

Wird automatisch aktiv bei:
- Änderungen in `skills/` Verzeichnis
- `SKILL.md` Modifikationen
- Neue `package.json` Dateien
