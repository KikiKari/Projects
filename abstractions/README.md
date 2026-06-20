# OpenClaw Script Abstractions Manager

> Automatisierte Portierung von OpenClaw-Scripts in zehn Programmiersprachen —  
> sicher, nachvollziehbar und vollständig dokumentiert.

---

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [Architektur](#architektur)
- [Schnellstart](#schnellstart)
- [Dateistruktur](#dateistruktur)
- [Konfiguration](#konfiguration)
- [Verwendung](#verwendung)
- [Sicherheit](#sicherheit)
- [Tests](#tests)
- [Logging](#logging)
- [Deployment & Cron](#deployment--cron)
- [Troubleshooting](#troubleshooting)

---

## Überblick

Der **Script Abstractions Manager** portiert OpenClaw-Scripts automatisch in folgende Zielsprachen:

| Sprache | Extension | Besonderheit |
|---------|-----------|--------------|
| Python | `.py` | OpenClaw-Standard |
| Perl 5 | `.pl` | Klassisch, stabil |
| Perl 6 (Raku) | `.raku` | Modern, expressiv |
| JavaScript | `.js` | Node.js-Ecosystem |
| Bash | `.sh` | Unix-native |
| PowerShell | `.ps1` | Windows/Cross-platform |
| Tcl | `.tcl` | Eingebettbar, simpel |
| Ruby | `.rb` | Expressiv, lesbar |
| Lua | `.lua` | Lightweight |
| Go | `.go` | Kompiliert, schnell |

**Kernfunktionen:**
- Hash-basierte Änderungserkennung (80–95% weniger API-Aufrufe)
- Parallelisierte Portierungen via `ThreadPoolExecutor`
- Atomisches State-File-Management (Race-Condition-sicher)
- Vollständiger Security-Schutz (Shell-Injection, Path-Traversal)
- Strukturiertes JSON-Logging

---

## Architektur

```
.env                          ← Secrets & Konfiguration
│
├── logger.py                 ← Zentrales Logging (JSON + Text)
├── exceptions.py             ← Custom Exceptions
├── validators.py             ← Eingabevalidierung (Security)
│
├── create_abstraction.py     ← Einzelne Portierung (CLI + Library)
├── spawn_agent.py            ← Sub-Agenten-Starter (CLI + Library)
│
├── json_processor.js         ← JS-Utility: JSON-Verarbeitung
├── check-live.js             ← JS-Utility: TikTok-Live-Check
│
├── initialize_repo.sh        ← Bash: Repository-Setup
│
└── test_abstractions_manager.py  ← Unit-Tests (pytest)
```

### Datenfluß

```
Cron (0 */6 * * *)
  └── abstractions_manager.py
        ├── Lädt .env (API-Keys, Workspace-Pfad)
        ├── Liest abstractions_state.json (Hashes)
        ├── Vergleicht Datei-Hashes → nur geänderte Scripts
        └── ThreadPoolExecutor (max. 4 Worker)
              ├── create_abstraction.py (perl5)
              ├── create_abstraction.py (javascript)
              ├── create_abstraction.py (go)
              └── ... (weitere Sprachen parallel)
                    ├── KI-API-Aufruf (Anthropic/OpenRouter)
                    ├── Atomisches Schreiben der Ausgabedatei
                    └── Git-Commit: "Add perl5 version of db_maintainer"
```

---

## Schnellstart

### 1. Repository klonen und einrichten

```bash
# Repository initialisieren
chmod +x initialize_repo.sh
./initialize_repo.sh

# Oder mit eigenem Workspace-Pfad
./initialize_repo.sh --workspace /custom/path
```

### 2. Konfiguration

```bash
# .env aus Vorlage erstellen
cp .env.example .env

# API-Schlüssel eintragen
nano .env
# ANTHROPIC_API_KEY=sk-ant-api03-...
```

### 3. Einzelne Portierung

```bash
# db_maintainer.py → Perl 5
python3 create_abstraction.py \
    --source /home/openclaw/.openclaw/workspace/skills/scripts/db_maintainer.py \
    --target-lang perl5

# json_processor.py → JavaScript (ohne Commit)
python3 create_abstraction.py \
    --source /path/to/json_processor.py \
    --target-lang javascript \
    --dry-run
```

### 4. Sub-Agent für komplexe Portierung

```bash
python3 spawn_agent.py \
    --task "Port db_maintainer.py to Go with full error handling and tests" \
    --model openrouter/anthropic/claude-3-5-sonnet-20241022 \
    --timeout 1800
```

---

## Dateistruktur

```
script-abstractions/
├── .env.example              # Konfigurationsvorlage (kein Geheimnis)
├── .env                      # Aktive Konfiguration (NICHT in Git!)
├── .gitignore
├── README.md                 # Diese Datei
│
├── exceptions.py             # Custom Exception-Klassen
├── validators.py             # Eingabevalidierung & Sicherheit
├── logger.py                 # Logging-Konfiguration
│
├── create_abstraction.py     # Einzelne Portierung
├── spawn_agent.py            # Sub-Agenten-Starter
│
├── json_processor.js         # JS JSON-Utilities
├── check-live.js             # TikTok Live-Checker
│
├── initialize_repo.sh        # Repository-Initialisierung
│
├── test_abstractions_manager.py  # Unit-Tests
│
└── git/Abstraktionen/        # Ausgabe-Repository
    ├── perl5/
    ├── perl6/
    ├── javascript/
    ├── python/
    ├── bash/
    ├── powershell/
    ├── tcl/
    ├── ruby/
    ├── lua/
    └── go/
```

---

## Konfiguration

Alle Einstellungen werden über die `.env`-Datei gesteuert:

| Variable | Beschreibung | Standard |
|----------|--------------|---------|
| `ANTHROPIC_API_KEY` | Anthropic API-Schlüssel | — (Pflicht) |
| `OPENROUTER_API_KEY` | OpenRouter API-Schlüssel | — (optional) |
| `OPENCLAW_WORKSPACE` | Absoluter Workspace-Pfad | `/home/openclaw/.openclaw/workspace` |
| `ABSTRACTIONS_LOG_LEVEL` | Log-Level (DEBUG/INFO/WARNING/ERROR) | `INFO` |
| `ABSTRACTIONS_JSON_LOGGING` | JSON-Logging aktivieren (1/0) | `1` |
| `ABSTRACTIONS_DEFAULT_MODEL` | Standard-KI-Modell | `openrouter/anthropic/claude-3-5-sonnet-20241022` |
| `ABSTRACTIONS_MAX_WORKERS` | Parallele Portierungs-Worker | `4` |
| `ABSTRACTIONS_DRY_RUN` | Dry-Run-Modus (1/0) | `0` |
| `GIT_AUTHOR_NAME` | Git-Commit-Autor-Name | `Abstractions Manager` |
| `GIT_SIGN_COMMITS` | GPG-Signing für Commits (1/0) | `0` |

---

## Verwendung

### `create_abstraction.py`

```
Usage: python3 create_abstraction.py [OPTIONS]

Options:
  --source PATH          Pfad zum Original-Script (Pflicht)
  --target-lang LANG     Zielsprache (Pflicht)
                         Erlaubt: perl5, perl6, javascript, python,
                                  bash, powershell, tcl, ruby, lua, go
  --model MODEL          KI-Modell (Standard: aus .env)
  --dry-run              Erstellt .dryrun-Datei, kein Git-Commit
  --force                Portiert auch wenn keine Änderung erkannt

Beispiele:
  python3 create_abstraction.py --source ./db_maintainer.py --target-lang perl5
  python3 create_abstraction.py --source ./json_processor.py --target-lang go --dry-run
```

### `spawn_agent.py`

```
Usage: python3 spawn_agent.py [OPTIONS]

Options:
  --task TEXT            Task-Beschreibung (Pflicht, max. 500 Zeichen)
  --model MODEL          KI-Modell (Pflicht)
  --timeout SECONDS      Timeout in Sekunden (Standard: 1800, max: 7200)
  --dry-run              Zeigt Befehl ohne Ausführung
  --log-level LEVEL      Log-Level (DEBUG/INFO/WARNING/ERROR)

Beispiele:
  python3 spawn_agent.py \
      --task "Port json_processor.py to Perl 5 with error handling" \
      --model openrouter/anthropic/claude-3-5-sonnet-20241022 \
      --timeout 1800
```

### `check-live.js`

```
Usage: node check-live.js [OPTIONS]

Options:
  --username NAME        TikTok-Benutzername (Pflicht, mit oder ohne @)
  --interval SECONDS     Polling-Intervall in Sekunden (min. 10)
                         Wenn angegeben: kontinuierliches Polling

Beispiele:
  # Einmalige Prüfung
  node check-live.js --username alice_123

  # Kontinuierliches Polling alle 60 Sekunden
  node check-live.js --username alice_123 --interval 60
```

### `initialize_repo.sh`

```
Usage: ./initialize_repo.sh [OPTIONS]

Options:
  -w, --workspace PATH   Workspace-Basispfad
  -b, --branch NAME      Initialer Branch-Name (Standard: main)
  -n, --dry-run          Zeigt Aktionen ohne Ausführung
  -h, --help             Diese Hilfe

Beispiele:
  ./initialize_repo.sh
  ./initialize_repo.sh --workspace /custom/path --dry-run
```

---

## Sicherheit

### Implementierte Schutzmaßnahmen

| Bedrohung | Schutzmaßnahme | Implementiert in |
|-----------|---------------|-----------------|
| Shell-Injection | `subprocess` mit Liste, kein `shell=True` | `spawn_agent.py` |
| Path-Traversal | `Path.resolve()` + Allowlist-Check | `validators.py` |
| Modell-Injection | Allowlist für KI-Modell-Namen | `validators.py` |
| API-Key-Leak | Umgebungsvariablen, kein Hardcoding | `.env` + `validators.py` |
| Log-Injection | Strukturiertes JSON-Logging | `logger.py` |
| Race Conditions | Atomisches `os.replace()` | `create_abstraction.py` |

### Security-Checkliste (vor Produktivbetrieb)

- [ ] `.env` ist in `.gitignore` eingetragen
- [ ] Cron-Logs haben `chmod 640` (nicht world-readable)
- [ ] API-Schlüssel sind gesetzt und valide (`python3 -c "from validators import load_and_validate_api_key; load_and_validate_api_key('ANTHROPIC')"`)
- [ ] `OPENCLAW_WORKSPACE` zeigt auf korrekte Verzeichnis
- [ ] Git-Signierung aktiviert (`GIT_SIGN_COMMITS=1`)

---

## Tests

```bash
# Alle Tests ausführen
pytest test_abstractions_manager.py -v

# Mit Coverage-Report
pip install pytest-cov
pytest test_abstractions_manager.py -v --cov=validators --cov=create_abstraction --cov-report=term-missing

# Nur Security-Tests
pytest test_abstractions_manager.py -v -k "Security or Injection or Traversal or Allowlist"

# Nur einen Test-Block
pytest test_abstractions_manager.py::TestTaskDescriptionValidation -v
```

### Test-Coverage-Ziele

| Modul | Ziel |
|-------|------|
| `validators.py` | ≥ 95% |
| `create_abstraction.py` | ≥ 85% |
| `exceptions.py` | ≥ 90% |
| Gesamt | ≥ 85% |

---

## Logging

### JSON-Format (Produktion)

```json
{
  "timestamp": "2026-05-26T10:00:00+00:00",
  "level": "INFO",
  "logger": "create_abstraction",
  "message": "Portierung abgeschlossen: db_maintainer.py → perl5",
  "module": "create_abstraction",
  "function": "create_single_abstraction",
  "line": 142
}
```

### Text-Format (Entwicklung, `ABSTRACTIONS_JSON_LOGGING=0`)

```
2026-05-26 10:00:00 | INFO     | create_abstraction:142 | Portierung abgeschlossen: db_maintainer.py → perl5
```

### Log-Dateien

| Datei | Inhalt | Rotation |
|-------|--------|----------|
| `logs/abstractions-manager/abstractions_manager.log` | Alle Events | 10 MB / 7 Backups |
| `logs/abstractions-manager/cron.log` | Cron-Ausgaben | logrotate |

---

## Deployment & Cron

### Cron-Job einrichten

```bash
# Crontab bearbeiten
crontab -e

# Cron-Job (alle 6 Stunden, JSON-Logging, separates Error-Log)
0 */6 * * * cd /home/openclaw/.openclaw/workspace && \
    /usr/bin/python3 skills/script-abstractions-manager/scripts/abstractions_manager.py \
    >> logs/abstractions-manager/cron.log 2>&1
```

### Log-Permissions absichern

```bash
# Log-Verzeichnis anlegen mit korrekten Berechtigungen
mkdir -p /home/openclaw/.openclaw/workspace/logs/abstractions-manager
chmod 750 /home/openclaw/.openclaw/workspace/logs/abstractions-manager
chmod 640 /home/openclaw/.openclaw/workspace/logs/abstractions-manager/*.log 2>/dev/null || true
```

### Logrotate konfigurieren

```
# /etc/logrotate.d/abstractions-manager
/home/openclaw/.openclaw/workspace/logs/abstractions-manager/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    create 640 openclaw openclaw
}
```

---

## Troubleshooting

### `ApiKeyError: Umgebungsvariable nicht gesetzt`

```bash
# Prüfen ob .env geladen wird
python3 -c "from dotenv import load_dotenv; load_dotenv(); import os; print(os.environ.get('ANTHROPIC_API_KEY', 'NICHT GESETZT')[:8])"
```

### `ValidationError: Zugriff verweigert`

```bash
# OPENCLAW_WORKSPACE in .env prüfen
grep OPENCLAW_WORKSPACE .env

# Tatsächlichen Dateipfad prüfen
python3 -c "from pathlib import Path; print(Path('/dein/pfad').resolve())"
```

### `StateFileError: parse`

```bash
# State-Datei auf Korruption prüfen
python3 -m json.tool /home/openclaw/.openclaw/workspace/db/abstractions_state.json

# State zurücksetzen (Vorsicht: alle Hashes werden vergessen)
echo '{}' > /home/openclaw/.openclaw/workspace/db/abstractions_state.json
```

### Tests schlagen fehl

```bash
# Abhängigkeiten installieren
pip install pytest pytest-cov python-dotenv

# Einzelnen fehlgeschlagenen Test debuggen
pytest test_abstractions_manager.py::TestTaskDescriptionValidation::test_shell_metacharacters_are_rejected -v -s
```

---

## Changelog

| Version | Datum | Änderungen |
|---------|-------|-----------|
| 1.0.0 | 2026-05-26 | Initiales Release mit Security-Fixes, Logging, Tests |

---

*OpenClaw Script Abstractions Manager — Internal Use Only*
