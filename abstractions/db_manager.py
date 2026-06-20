#!/usr/bin/env python3
"""
Workspace Documentation Database Manager

Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.

Verwendung:
    python3 db_manager.py

Konfiguration:
    OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
"""

import csv
import json
import logging
import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Dict, Generator, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

WORKSPACE: Path = Path(os.environ.get("OPENCLAW_WORKSPACE", "/home/openclaw/.openclaw/workspace"))
DB_DIR: Path = WORKSPACE / "db"

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
_DOCS_EXPORT_TABLES = frozenset({"documents", "categories", "symlinks", "skills"})
_TREE_EXPORT_TABLES = frozenset({"tree_entries", "tree_scans"})

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger("db_manager")

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

class DocsDatabase:
    """
    Verwaltet die docs.db: Dokumentationen, Kategorien, Symlinks und Skills.

    Jede öffentliche Methode öffnet und schließt ihre Datenbankverbindung
    eigenständig via Context-Manager, sodass keine Verbindungen offen bleiben.
    """

    def __init__(self) -> None:
        """Initialisiert DocsDatabase mit dem Standard-Datenbankpfad."""
        self.db_path: Path = DB_DIR / "docs.db"

    @contextmanager
    def _get_connection(self) -> Generator[sqlite3.Connection, None, None]:
        """
        Context-Manager der eine SQLite-Verbindung öffnet und sicher schließt.

        Yields:
            sqlite3.Connection: Offene Verbindung mit Row-Factory.

        Raises:
            sqlite3.Error: Bei Verbindungs- oder Datenbankfehlern.
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    def init_schema(self) -> "DocsDatabase":
        """
        Erstellt die Tabellenstruktur in docs.db falls noch nicht vorhanden.

        Tabellen: documents, categories, symlinks, skills.
        Bestehende Tabellen werden nicht verändert (CREATE TABLE IF NOT EXISTS).

        Returns:
            DocsDatabase: self für Method-Chaining.

        Raises:
            sqlite3.Error: Bei Fehlern in der Schema-Erstellung.
        """
        with self._get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS documents (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT    NOT NULL,
                    path        TEXT    NOT NULL,
                    category    TEXT,
                    description TEXT,
                    type        TEXT    CHECK(type IN ('config', 'doc', 'guide', 'script', 'symlink')),
                    has_symlink BOOLEAN DEFAULT FALSE,
                    symlink_path TEXT,
                    last_update TEXT,
                    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS categories (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT    UNIQUE NOT NULL,
                    description TEXT,
                    priority    INTEGER DEFAULT 0
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS symlinks (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT    NOT NULL,
                    target      TEXT    NOT NULL,
                    source_path TEXT    NOT NULL,
                    description TEXT,
                    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS skills (
                    id          INTEGER PRIMARY KEY AUTOINCREMENT,
                    name        TEXT    NOT NULL,
                    version     TEXT,
                    status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                    description TEXT,
                    path        TEXT
                )
            """)

            conn.commit()

        logger.info("docs.db Schema initialisiert: %s", self.db_path)
        return self

    def populate_from_workspace(self) -> "DocsDatabase":
        """
        Befüllt docs.db mit bekannten Workspace-Dokumenten, Skills und Symlinks.

        Verwendet INSERT OR IGNORE / INSERT OR REPLACE, sodass ein erneuter
        Aufruf idempotent ist.

        Returns:
            DocsDatabase: self für Method-Chaining.

        Raises:
            sqlite3.Error: Bei Datenbankfehlern während des Einfügens.
        """
        categories: List[Tuple] = [
            ("main",      "Hauptverzeichnis Dateien",        1),
            ("memory",    "Memory und Protokolle",           2),
            ("reports",   "Berichte und Analysen",           3),
            ("cluster",   "Cluster und Infrastruktur",       4),
            ("skills",    "Installierte Skills",             5),
            ("websearch", "WebSearch Dokumentationen",       6),
            ("mcp",       "MCP Integration",                 7),
            ("links",     "Symbolische Links",               8),
        ]

        # (name, path, category, description, type, has_symlink, symlink_path, last_update)
        docs: List[Tuple] = [
            ("AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  False, None,                          "2026-04-11"),
            ("SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  False, None,                          "2026-04-11"),
            ("IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  False, None,                          "2026-04-11"),
            ("USER.md",               "/", "main", "Benutzerinformationen",                   "config",  False, None,                          "2026-04-11"),
            ("TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  False, None,                          "2026-04-18"),
            ("MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  False, None,                          "2026-04-11"),
            ("DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     False, None,                          "2026-04-18"),
            ("WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", True,  "DOCUMENTATION-INDEX.md",      "2026-04-18"),
            ("WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  True, "websearch/WEBSEARCH_README.md",          "2026-04-18"),
            ("WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  True, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18"),
            ("WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", True, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18"),
            ("WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", True, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"),
            ("WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", True, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18"),
            ("WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  True, "websearch/WEBSEARCH_OPS.md",             "2026-04-18"),
            ("MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",False,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18"),
        ]

        skills: List[Tuple] = [
            ("json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"),
            ("scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"),
            ("tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"),
            ("cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"),
            ("worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"),
            ("resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"),
            ("git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"),
        ]

        symlinks: List[Tuple] = [
            ("openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"),
            ("openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"),
            ("links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"),
            ("links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"),
            ("links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"),
            ("links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"),
            ("links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"),
        ]

        with self._get_connection() as conn:
            cursor = conn.cursor()

            cursor.executemany(
                "INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)",
                categories,
            )
            cursor.executemany(
                """INSERT OR REPLACE INTO documents
                   (name, path, category, description, type, has_symlink, symlink_path, last_update)
                   VALUES (?,?,?,?,?,?,?,?)""",
                docs,
            )
            cursor.executemany(
                "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)",
                skills,
            )
            cursor.executemany(
                "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)",
                symlinks,
            )
            conn.commit()

        logger.info(
            "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks",
            len(docs), len(skills), len(symlinks),
        )
        return self

    def _validate_table_name(self, table: str, allowed: frozenset) -> None:
        """
        Prüft ob der Tabellenname in der Allowlist enthalten ist.

        Verhindert SQL-Injection durch direkte Tabellennamen-Interpolation.

        Args:
            table:   Zu prüfender Tabellenname.
            allowed: Menge erlaubter Tabellennamen.

        Raises:
            ValueError: Wenn der Tabellenname nicht erlaubt ist.
        """
        if table not in allowed:
            raise ValueError(
                f"Ungültiger Tabellenname: '{table}'. "
                f"Erlaubt: {sorted(allowed)}"
            )

    def export_csv(self, table: str) -> Optional[Path]:
        """
        Exportiert eine Tabelle aus docs.db als CSV-Datei in den Workspace-Root.

        Args:
            table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.

        Returns:
            Path zur erzeugten CSV-Datei, oder None wenn die Tabelle leer ist.

        Raises:
            ValueError: Bei ungültigem Tabellennamen.
            sqlite3.Error: Bei Datenbankfehlern.
            OSError: Bei Schreibfehlern.
        """
        self._validate_table_name(table, _DOCS_EXPORT_TABLES)

        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Tabellenname ist durch _validate_table_name gegen Injection gesichert
            cursor.execute(f"SELECT * FROM {table}")  # noqa: S608
            rows = cursor.fetchall()
            column_names = [col[0] for col in cursor.description]

        if not rows:
            logger.info("Tabelle '%s' ist leer — kein CSV erzeugt", table)
            return None

        csv_path = WORKSPACE / f"export_{table}.csv"
        with open(csv_path, "w", newline="", encoding="utf-8") as fh:
            writer = csv.writer(fh)
            writer.writerow(column_names)
            writer.writerows(rows)

        logger.info("CSV exportiert: %s (%d Zeilen)", csv_path, len(rows))
        return csv_path

    def export_json(self, table: str) -> Optional[Path]:
        """
        Exportiert eine Tabelle aus docs.db als JSON-Datei in den Workspace-Root.

        Args:
            table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.

        Returns:
            Path zur erzeugten JSON-Datei, oder None wenn die Tabelle leer ist.

        Raises:
            ValueError: Bei ungültigem Tabellennamen.
            sqlite3.Error: Bei Datenbankfehlern.
            OSError: Bei Schreibfehlern.
        """
        self._validate_table_name(table, _DOCS_EXPORT_TABLES)

        with self._get_connection() as conn:
            cursor = conn.cursor()
            # Tabellenname ist durch _validate_table_name gegen Injection gesichert
            cursor.execute(f"SELECT * FROM {table}")  # noqa: S608
            rows = cursor.fetchall()

        if not rows:
            logger.info("Tabelle '%s' ist leer — kein JSON erzeugt", table)
            return None

        data = [dict(row) for row in rows]
        json_path = WORKSPACE / f"export_{table}.json"

        with open(json_path, "w", encoding="utf-8") as fh:
            json.dump(data, fh, indent=2, default=str, ensure_ascii=False)

        logger.info("JSON exportiert: %s (%d Einträge)", json_path, len(data))
        return json_path


# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

class TreeDatabase:
    """
    Verwaltet die tree.db: Verzeichnisbaum-Strukturen und Scan-Metadaten.

    Wird durch ein separates tree.py Script befüllt. Dieses Modul stellt
    nur Schema-Initialisierung und Export bereit.
    """

    def __init__(self) -> None:
        """Initialisiert TreeDatabase mit dem Standard-Datenbankpfad."""
        self.db_path: Path = DB_DIR / "tree.db"

    @contextmanager
    def _get_connection(self) -> Generator[sqlite3.Connection, None, None]:
        """
        Context-Manager der eine SQLite-Verbindung öffnet und sicher schließt.

        Yields:
            sqlite3.Connection: Offene Verbindung mit Row-Factory.

        Raises:
            sqlite3.Error: Bei Verbindungs- oder Datenbankfehlern.
        """
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        try:
            yield conn
        finally:
            conn.close()

    def init_schema(self) -> "TreeDatabase":
        """
        Erstellt die Tabellenstruktur in tree.db falls noch nicht vorhanden.

        Tabellen: tree_entries, tree_scans.

        Returns:
            TreeDatabase: self für Method-Chaining.

        Raises:
            sqlite3.Error: Bei Fehlern in der Schema-Erstellung.
        """
        with self._get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tree_entries (
                    id            INTEGER PRIMARY KEY AUTOINCREMENT,
                    root_path     TEXT    NOT NULL,
                    relative_path TEXT    NOT NULL,
                    name          TEXT    NOT NULL,
                    type          TEXT    CHECK(type IN ('file', 'directory', 'symlink')),
                    depth         INTEGER,
                    parent_path   TEXT,
                    size          INTEGER,
                    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS tree_scans (
                    id             INTEGER PRIMARY KEY AUTOINCREMENT,
                    root_path      TEXT    NOT NULL,
                    max_depth      INTEGER,
                    total_files    INTEGER,
                    total_dirs     INTEGER,
                    total_symlinks INTEGER,
                    scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

            conn.commit()

        logger.info("tree.db Schema initialisiert: %s", self.db_path)
        return self

    def add_entry(
        self,
        root_path: str,
        relative_path: str,
        name: str,
        entry_type: str,
        depth: int,
        parent_path: str,
        size: int = 0,
    ) -> None:
        """
        Fügt einen einzelnen Verzeichnisbaum-Eintrag in tree_entries ein.

        Args:
            root_path:     Absoluter Pfad des Scan-Wurzelverzeichnisses.
            relative_path: Pfad relativ zu root_path.
            name:          Datei- oder Verzeichnisname.
            entry_type:    'file', 'directory' oder 'symlink'.
            depth:         Verschachtelungstiefe (0 = root).
            parent_path:   Relativer Pfad des Elternverzeichnisses.
            size:          Dateigröße in Bytes (0 für Verzeichnisse).

        Raises:
            sqlite3.Error: Bei Datenbankfehlern.
        """
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute(
                """INSERT INTO tree_entries
                   (root_path, relative_path, name, type, depth, parent_path, size)
                   VALUES (?,?,?,?,?,?,?)""",
                (root_path, relative_path, name, entry_type, depth, parent_path, size),
            )
            conn.commit()

    def export_csv(self, root_path_filter: Optional[str] = None) -> Optional[Path]:
        """
        Exportiert tree_entries als CSV-Datei, optional gefiltert nach root_path.

        Args:
            root_path_filter: Wenn angegeben, werden nur Einträge mit diesem
                              root_path exportiert. None exportiert alle Einträge.

        Returns:
            Path zur erzeugten CSV-Datei, oder None wenn keine Einträge vorhanden.

        Raises:
            sqlite3.Error: Bei Datenbankfehlern.
            OSError: Bei Schreibfehlern.
        """
        with self._get_connection() as conn:
            cursor = conn.cursor()

            if root_path_filter is not None:
                cursor.execute(
                    "SELECT * FROM tree_entries WHERE root_path = ?",
                    (root_path_filter,),
                )
            else:
                cursor.execute("SELECT * FROM tree_entries")

            rows = cursor.fetchall()
            column_names = [col[0] for col in cursor.description]

        if not rows:
            logger.info("Keine Tree-Einträge vorhanden — kein CSV erzeugt")
            return None

        suffix = (
            f"_{root_path_filter.replace('/', '_')}" if root_path_filter else "_all"
        )
        csv_path = WORKSPACE / f"export_tree{suffix}.csv"

        with open(csv_path, "w", newline="", encoding="utf-8") as fh:
            writer = csv.writer(fh)
            writer.writerow(column_names)
            writer.writerows(rows)

        logger.info("Tree-CSV exportiert: %s (%d Einträge)", csv_path, len(rows))
        return csv_path


# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

def main() -> None:
    """
    Initialisiert docs.db und tree.db, befüllt docs.db und erzeugt Exporte.

    Legt DB_DIR an falls nicht vorhanden. Wird als Standalone-Script
    oder einmalig zur Ersteinrichtung ausgeführt.
    """
    print("=" * 60)
    print("WORKSPACE DATABASE MANAGER")
    print("=" * 60)

    # DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    try:
        DB_DIR.mkdir(parents=True, exist_ok=True)
        logger.info("DB-Verzeichnis: %s", DB_DIR)
    except OSError as exc:
        logger.error("DB-Verzeichnis konnte nicht erstellt werden: %s", exc)
        raise SystemExit(1) from exc

    # docs.db aufbauen
    docs_db = DocsDatabase()
    docs_db.init_schema()
    docs_db.populate_from_workspace()

    # Exporte
    print("\n--- Exporte docs.db ---")
    for table in ("documents", "skills", "symlinks"):
        docs_db.export_csv(table)
    docs_db.export_json("documents")

    # tree.db aufbauen (Daten kommen via tree.py)
    print("\n--- tree.db Initialisierung ---")
    tree_db = TreeDatabase()
    tree_db.init_schema()
    logger.info("Tree-Daten werden via tree.py Script befüllt")

    print("\n" + "=" * 60)
    print("DATENBANKEN BEREIT")
    print("=" * 60)
    print(f"\nDatenbanken: {DB_DIR}/")
    print(f"Exporte:     {WORKSPACE}/")


if __name__ == "__main__":
    main()
