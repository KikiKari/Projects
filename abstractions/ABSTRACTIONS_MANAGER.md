# ABSTRACTIONS_MANAGER & DB_MANAGER — Technische Dokumentation

## Inhaltsverzeichnis

- [Überblick](#überblick)
- [ABSTRACTIONS_MANAGER.py](#abstractions_managerpy)
  - [Architektur](#architektur)
  - [Konfiguration](#konfiguration)
  - [Logging](#logging)
  - [State-Management](#state-management)
  - [Node-Management](#node-management)
  - [Script-Verarbeitung](#script-verarbeitung)
  - [Git-Integration](#git-integration)
  - [Cron-Deployment](#cron-deployment)
- [db_manager.py](#db_managerpy)
  - [DocsDatabase](#docsdatabase)
  - [TreeDatabase](#treedatabase)
- [Sicherheit](#sicherheit)
- [Fehlerbehandlung](#fehlerbehandlung)

---

## Überblick

Zwei eigenständige Scripts für den OpenClaw-Workspace:

| Script | Zweck |
|--------|-------|
| `ABSTRACTIONS_MANAGER.py` | Portiert OpenClaw-Scripts automatisch in 10 Zielsprachen. Läuft per Cron alle 6 Stunden. |
| `db_manager.py` | Erstellt und befüllt `docs.db` (Dokumentenindex) und `tree.db` (Verzeichnisbaum) im Workspace. |

Beide Scripts lesen ihre Basiskonfiguration aus der zentralen `.env` über Umgebungsvariablen. Keine hardcodierten Secrets, keine `.env.example`.

---

## ABSTRACTIONS_MANAGER.py

### Architektur

```
ABSTRACTIONS_MANAGER.py
│
├── Konfiguration       — WORKSPACE, NODES, AVAILABLE_MODELS, TARGET_LANGUAGES
├── _setup_logger()     — RotatingFileHandler + Console, einmalig konfiguriert
│
├── load_state()        — JSON-State lesen, Fehler werden geloggt
├── save_state()        — Atomisches Schreiben via tempfile + os.replace()
│
├── check_node_status() — subprocess 'openclaw nodes status', Timeout 5s
├── get_job_weight()    — Gewicht nach script_size × target_langs_count
├── get_node_by_priority() — Node-Auswahl nach Job-Gewicht
│
├── find_scripts_in_dir()  — Rekursive Suche nach .py/.js/.sh/.pl/.rb
├── _build_stub_content()  — Sprachspezifischer Stub-Text (korrekte Syntax pro Sprache)
├── create_abstraction()   — Stub-Datei atomar schreiben, überspringt vorhandene
├── process_on_node()      — Lokale oder (zukünftig) Remote-Verarbeitung
│
├── process_priority_high()   — Top 5 Skills, Langs: perl5 js python shell tcl
├── process_priority_medium() — Workspace-Scripts, Langs: perl5 js powershell python
│
├── git_commit()           — git -C <repo>, kein os.chdir()
├── create_status_report() — STATUS.md im Abstractions-Repo
│
└── main()  — Zyklus high → medium → high, State speichern, Report erstellen
```

### Konfiguration

Alle Werte werden aus Umgebungsvariablen bezogen:

| Variable | Beschreibung | Standard |
|----------|--------------|---------|

| `ABSTRACTIONS_LOG_LEVEL` | Log-Level (DEBUG/INFO/WARNING/ERROR) | `INFO` |

Abgeleitete Pfade (hardcoded, Basis: `/home/openclaw/.openclaw/workspace`):

| Pfad | Verwendung |
|------|-----------|
| `$WORKSPACE/git/Abstraktionen` | Ausgabe-Repository für portierte Scripts |
| `$WORKSPACE/logs/abstractions-manager/` | Log-Dateien |
| `$WORKSPACE/db/abstractions_state.json` | Verarbeitungs-State |

### Logging

Der Logger wird einmalig beim Modulstart über `_setup_logger()` konfiguriert. Pro Aufruf wird **keine** neue Datei geöffnet.

```
Format:  YYYY-MM-DD HH:MM:SS | LEVEL    | funcName:line | Nachricht
Datei:   $WORKSPACE/logs/abstractions-manager/YYYY-MM-DD.log
Rotation: 10 MB / 7 Backups
Console: stdout, gleiches Format
```

Log-Level per Umgebungsvariable `ABSTRACTIONS_LOG_LEVEL` steuerbar. Ungültige Werte fallen auf `INFO` zurück.

### State-Management

`abstractions_state.json` speichert:

```json
{
  "processed": {},
  "queue": [],
  "current_priority": "high",
  "stats": {
    "total_scripts": 0,
    "abstractions_created": 0,
    "last_run": "2026-05-26T10:00:00"
  }
}
```

**Atomisches Schreiben:** `save_state()` schreibt zuerst in eine temporäre `.tmp`-Datei im selben Verzeichnis und ersetzt die Zieldatei dann via `os.replace()`. Bei Schreibfehler wird die temporäre Datei bereinigt.

**Fehlertoleranz:** `load_state()` gibt einen leeren Standardzustand zurück wenn die Datei fehlt oder korrupt ist. Der Fehler wird mit Traceback geloggt.

### Node-Management

Fünf Nodes, konfiguriert in `NODES`:

| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |
|------|--------------|-----------|-----------|-------|
| node1 | Immer | medium | 2 | Server (Gateway-Master) |
| node2 | Immer | medium | 3 | Server (Stable Worker) |
| node3 | Bedingt | medium | 4 | Server (bald verfügbar) |
| node5 | Bedingt | low | 5 | Redmi Note 11S |
| node7 | Immer | high | 1 | Server (Docker-Hauptarbeitspferd) |

**Job-Gewicht → Node-Auswahl:**

| Gewicht | Bedingung | Bevorzugte Reihenfolge |
|---------|-----------|----------------------|
| heavy | `size × langs > 50.000` | node7 → node2 → node1 |
| medium | `size × langs > 10.000` | node2 → node1 → node7 |
| light | sonst | node5 → node1 → node2 |

`check_node_status()` ruft `openclaw nodes status <node_id>` mit 5s Timeout auf. Bei `TimeoutExpired`, `FileNotFoundError` oder `OSError` wird auf `always_available` zurückgefallen und der Grund geloggt.

### Script-Verarbeitung

`find_scripts_in_dir()` sucht rekursiv nach `.py`, `.js`, `.sh`, `.pl`, `.rb`. Standard-Ausschlüsse: `node_modules`, `.git`, `__pycache__`, `dist`, `build`.

`create_abstraction()` erstellt einen Stub für jede Zielsprache:

1. Prüft ob Ausgabedatei bereits existiert → überspringt
2. Liest erste 15 Zeilen der Quelldatei für Kommentar-Referenz
3. Generiert sprachkorrekten `main()`-Block (kein Python-Syntax für Perl/Tcl/Shell)
4. Schreibt atomar via `tempfile` + `os.replace()`

**Unterstützte Zielsprachen und Einstiegspunkte:**

| Sprache | Extension | Einstiegspunkt |
|---------|-----------|---------------|
| perl5 | `.pl` | `sub main { ... } main();` |
| perl6 | `.raku` | `sub MAIN() { ... }` |
| javascript | `.js` | `function main() { ... } main();` |
| python | `.py` | `def main(): ... if __name__ == '__main__': main()` |
| shell | `.sh` | `main() { ... } main "$@"` |
| powershell | `.ps1` | `function Main { ... } Main` |
| tcl | `.tcl` | `proc main {} { ... } main` |
| ruby | `.rb` | `def main ... end main if __FILE__ == $PROGRAM_NAME` |
| lua | `.lua` | `local function main() ... end main()` |
| go | `.go` | `func main() { ... }` |

**Verfügbare Modelle** (für zukünftige KI-gestützte Portierung via OpenRouter):

```
openrouter/moonshotai/kimi-k2.5
openrouter/openai/gpt-4o
openrouter/anthropic/claude-3-5-sonnet-20241022
openrouter/google/gemini-2.0-flash-001
openrouter/nvidia/llama-3.3-nemotron-super-49b-v1
openrouter/qwen/qwen-2.5-coder-32b-instruct
```

### Git-Integration

`git_commit()` verwendet `git -C <repo-pfad>` — der Prozess-CWD wird **nicht** verändert. Fehler werden differenziert geloggt:

- `CalledProcessError`: Exit-Code und stderr werden geloggt
- `FileNotFoundError`: git-Binary fehlt
- `OSError`: Systemfehler

### Cron-Deployment

```bash
# Crontab-Eintrag (alle 6 Stunden)
0 */6 * * * /usr/bin/python3 /home/openclaw/.openclaw/workspace/skills/ \
    script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py \
    >> /home/openclaw/.openclaw/workspace/logs/abstractions-manager/cron.log 2>&1
```

Log-Verzeichnis absichern:

```bash
mkdir -p /home/openclaw/.openclaw/workspace/logs/abstractions-manager
chmod 750 /home/openclaw/.openclaw/workspace/logs/abstractions-manager
```

---

## db_manager.py

Erstellt und befüllt zwei SQLite-Datenbanken unter `/home/openclaw/.openclaw/workspace/db/`.

Das DB-Verzeichnis wird in `main()` angelegt — nicht auf Modulebene.

### DocsDatabase

Datei: `$WORKSPACE/db/docs.db`

Alle Methoden verwalten ihre Verbindung via `_get_connection()` Context-Manager. Verbindungen werden immer im `finally`-Block geschlossen.

#### Schema

**documents**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| name | TEXT NOT NULL | Dateiname |
| path | TEXT NOT NULL | Verzeichnispfad |
| category | TEXT | Kategorie-Schlüssel |
| description | TEXT | Kurzbeschreibung |
| type | TEXT | config / doc / guide / script / symlink |
| has_symlink | BOOLEAN | Symlink vorhanden |
| symlink_path | TEXT | Symlink-Ziel |
| last_update | TEXT | Datum letzter Änderung |
| created_at | TIMESTAMP | Einfügezeitpunkt |

**categories**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| name | TEXT UNIQUE | Kategorie-Schlüssel |
| description | TEXT | Beschreibung |
| priority | INTEGER | Sortierreihenfolge |

**symlinks**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| name | TEXT | Symlink-Name |
| target | TEXT | Ziel-Pfad |
| source_path | TEXT | Verzeichnis des Symlinks |
| description | TEXT | Zweck |
| created_at | TIMESTAMP | Einfügezeitpunkt |

**skills**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| name | TEXT | Skill-Name |
| version | TEXT | Version oder `-` |
| status | TEXT | installed / local / published |
| description | TEXT | Kurzbeschreibung |
| path | TEXT | Relativer Workspace-Pfad |

#### Methoden

**`init_schema()`** — Erstellt alle vier Tabellen (`CREATE TABLE IF NOT EXISTS`). Idempotent.

**`populate_from_workspace()`** — Befüllt mit bekannten Workspace-Dokumenten, Skills und Symlinks. Verwendet `INSERT OR REPLACE` / `INSERT OR IGNORE` — idempotent.

**`export_csv(table)`** — Exportiert eine Tabelle als `export_{table}.csv` in den Workspace-Root. Erlaubte Tabellen: `documents`, `categories`, `symlinks`, `skills`. Gibt `None` zurück wenn die Tabelle leer ist.

**`export_json(table)`** — Exportiert eine Tabelle als `export_{table}.json`. Gleiche Restriktionen wie `export_csv()`.

### TreeDatabase

Datei: `$WORKSPACE/db/tree.db`

Wird durch `tree.py` (separates Script) befüllt. `db_manager.py` stellt nur Schema-Initialisierung und CSV-Export bereit.

#### Schema

**tree_entries**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| root_path | TEXT | Scan-Wurzelverzeichnis (absolut) |
| relative_path | TEXT | Pfad relativ zu root_path |
| name | TEXT | Datei-/Verzeichnisname |
| type | TEXT | file / directory / symlink |
| depth | INTEGER | Verschachtelungstiefe (0 = root) |
| parent_path | TEXT | Relativer Elternpfad |
| size | INTEGER | Größe in Bytes |
| created_at | TIMESTAMP | Einfügezeitpunkt |

**tree_scans**

| Spalte | Typ | Beschreibung |
|--------|-----|-------------|
| id | INTEGER PK | Autoincrement |
| root_path | TEXT | Scan-Wurzelverzeichnis |
| max_depth | INTEGER | Maximale Scan-Tiefe |
| total_files | INTEGER | Anzahl Dateien |
| total_dirs | INTEGER | Anzahl Verzeichnisse |
| total_symlinks | INTEGER | Anzahl Symlinks |
| scanned_at | TIMESTAMP | Zeitpunkt des Scans |

#### Methoden

**`init_schema()`** — Erstellt beide Tabellen. Idempotent.

**`add_entry(...)`** — Fügt einen einzelnen Verzeichnisbaum-Eintrag ein.

**`export_csv(root_path_filter)`** — Exportiert `tree_entries` als CSV. Optional gefiltert nach `root_path`. Dateiname: `export_tree_all.csv` oder `export_tree_{sanitized_path}.csv`.

---

## Sicherheit

| Bedrohung | Schutzmaßnahme | Datei |
|-----------|---------------|-------|
| SQL-Injection via Tabellenname | `_validate_table_name()` prüft gegen `frozenset` vor jeder Abfrage | `db_manager.py` |
| Prozess-CWD-Mutation | `git -C <pfad>` statt `os.chdir()` | `ABSTRACTIONS_MANAGER.py` |
| Path-Traversal in Stub-Generierung | Zielverzeichnis wird aus `ABSTRACTIONS_REPO / target_lang` gebildet — kein User-Input im Pfad | `ABSTRACTIONS_MANAGER.py` |
| Race-Condition beim State-Schreiben | Atomisches `tempfile` + `os.replace()` | `ABSTRACTIONS_MANAGER.py` |
| Race-Condition beim Stub-Schreiben | Atomisches `tempfile` + `os.replace()` | `ABSTRACTIONS_MANAGER.py` |
| Shell-Injection via subprocess | Alle subprocess-Aufrufe verwenden Listen-Form, kein `shell=True` | beide |
| Modul-Level-Seiteneffekte | `DB_DIR.mkdir()` nur in `main()` | `db_manager.py` |

---

## Fehlerbehandlung

Alle `except:`-Blöcke fangen spezifische Exception-Typen und loggen den Fehler:

| Funktion | Abgefangene Exceptions | Verhalten bei Fehler |
|----------|----------------------|----------------------|
| `load_state()` | `json.JSONDecodeError`, `OSError` | Fehler loggen, Standardzustand zurückgeben |
| `save_state()` | `OSError` | Fehler loggen, temp-Datei bereinigen |
| `check_node_status()` | `subprocess.TimeoutExpired`, `FileNotFoundError`, `OSError` | Warnung loggen, `always_available`-Wert zurückgeben |
| `git_commit()` | `subprocess.CalledProcessError`, `FileNotFoundError`, `OSError` | Fehler/Warnung loggen, weiter ausführen |
| `create_abstraction()` | `OSError` | Fehler loggen, `False` zurückgeben |
| `create_status_report()` | `OSError` | Fehler loggen, kein Abbruch |
| `DocsDatabase._get_connection()` | — (propagiert) | sqlite3.Error schlägt durch zur aufrufenden Methode |
| `TreeDatabase._get_connection()` | — (propagiert) | sqlite3.Error schlägt durch zur aufrufenden Methode |
