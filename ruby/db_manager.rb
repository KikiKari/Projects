#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "c8b78d07d19f9cdb8df8447e28e834e2772af1afb2640d1240338c280b4a72b1", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "ruby"}
# db_manager.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
# auch in: OpenClaw@gateway2:scripts/db_manager.py
# auch in: Projects@abstractions:abstractions/db_manager.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Workspace Documentation Database Manager
#
# Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
# Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
#
# Verwendung:
#     ruby db_manager.rb
#
# Konfiguration:
#     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace

require 'csv'
require 'json'
require 'logger'
require 'pathname'
require 'sqlite3'

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

WORKSPACE = Pathname.new(ENV.fetch('OPENCLAW_WORKSPACE', '/home/openclaw/.openclaw/workspace'))
DB_DIR = WORKSPACE / 'db'

# Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
DOCS_EXPORT_TABLES = Set.new(%w[documents categories symlinks skills]).freeze
TREE_EXPORT_TABLES = Set.new(%w[tree_entries tree_scans]).freeze

# ---------------------------------------------------------------------------
# Logger
# ---------------------------------------------------------------------------

logger = Logger.new($stdout)
logger.level = Logger::INFO
logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%Y-%m-%d %H:%M:%S')} | #{severity.ljust(8)} | #{progname} | #{msg}\n"
end
logger.progname = 'db_manager'

# ---------------------------------------------------------------------------
# DocsDatabase
# ---------------------------------------------------------------------------

class DocsDatabase
  # Verwaltet die docs.db: Dokumentationen, Kategorien, Symlinks und Skills.
  #
  # Jede öffentliche Methode öffnet und schließt ihre Datenbankverbindung
  # eigenständig via Context-Manager, sodass keine Verbindungen offen bleiben.

  def initialize
    # Initialisiert DocsDatabase mit dem Standard-Datenbankpfad.
    @db_path = DB_DIR / 'docs.db'
  end

  def init_schema
    # Erstellt die Tabellenstruktur in docs.db falls noch nicht vorhanden.
    #
    # Tabellen: documents, categories, symlinks, skills.
    # Bestehende Tabellen werden nicht verändert (CREATE TABLE IF NOT EXISTS).
    #
    # Returns:
    #     DocsDatabase: self für Method-Chaining.
    #
    # Raises:
    #     SQLite3::Exception: Bei Fehlern in der Schema-Erstellung.

    get_connection do |conn|
      conn.execute <<-SQL
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
      SQL

      conn.execute <<-SQL
        CREATE TABLE IF NOT EXISTS categories (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    UNIQUE NOT NULL,
            description TEXT,
            priority    INTEGER DEFAULT 0
        )
      SQL

      conn.execute <<-SQL
        CREATE TABLE IF NOT EXISTS symlinks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            target      TEXT    NOT NULL,
            source_path TEXT    NOT NULL,
            description TEXT,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      SQL

      conn.execute <<-SQL
        CREATE TABLE IF NOT EXISTS skills (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            version     TEXT,
            status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
            description TEXT,
            path        TEXT
        )
      SQL
    end

    logger.info("docs.db Schema initialisiert: #{@db_path}")
    self
  end

  def populate_from_workspace
    # Befüllt docs.db mit bekannten Workspace-Dokumenten, Skills und Symlinks.
    #
    # Verwendet INSERT OR IGNORE / INSERT OR REPLACE, sodass ein erneuter
    # Aufruf idempotent ist.
    #
    # Returns:
    #     DocsDatabase: self für Method-Chaining.
    #
    # Raises:
    #     SQLite3::Exception: Bei Datenbankfehlern während des Einfügens.

    categories = [
      ['main',      'Hauptverzeichnis Dateien',        1],
      ['memory',    'Memory und Protokolle',           2],
      ['reports',   'Berichte und Analysen',           3],
      ['cluster',   'Cluster und Infrastruktur',       4],
      ['skills',    'Installierte Skills',             5],
      ['websearch', 'WebSearch Dokumentationen',       6],
      ['mcp',       'MCP Integration',                 7],
      ['links',     'Symbolische Links',               8],
    ]

    # (name, path, category, description, type, has_symlink, symlink_path, last_update)
    docs = [
      ['AGENTS.md',             '/', 'main', 'Agent-Konfiguration, Memory-Regeln',      'config',  false, nil,                          '2026-04-11'],
      ['SOUL.md',               '/', 'main', 'Agent-Persönlichkeit und Kernwahrheiten', 'config',  false, nil,                          '2026-04-11'],
      ['IDENTITY.md',           '/', 'main', 'Agent-Name und Eigenschaften',            'config',  false, nil,                          '2026-04-11'],
      ['USER.md',               '/', 'main', 'Benutzerinformationen',                   'config',  false, nil,                          '2026-04-11'],
      ['TOOLS.md',              '/', 'main', 'Tool-spezifische Konfigurationen',        'config',  false, nil,                          '2026-04-18'],
      ['MEMORY.md',             '/', 'main', 'Langzeitspeicher, System-Konfiguration',  'config',  false, nil,                          '2026-04-11'],
      ['DOCUMENTATION-INDEX.md','/', 'main', 'Übersicht aller Dokumentationen',         'doc',     false, nil,                          '2026-04-18'],
      ['WORKSPACE-INDEX.md',    '/', 'main', 'Symlink zu DOCUMENTATION-INDEX.md',       'symlink', true,  'DOCUMENTATION-INDEX.md',      '2026-04-18'],
      ['WEBSEARCH_README.md',        'websearch/', 'websearch', 'Schnellstart Guide',                    'guide',  true, 'websearch/WEBSEARCH_README.md',          '2026-04-18'],
      ['WEBSEARCH_MCP_GUIDE.md',     'websearch/', 'websearch', 'Vollständige technische Dokumentation', 'guide',  true, 'websearch/WEBSEARCH_MCP_GUIDE.md',       '2026-04-18'],
      ['WEBSEARCH_CONFIG.md',        'websearch/', 'websearch', 'Konfigurations-Referenz',               'config', true, 'websearch/WEBSEARCH_CONFIG.md',          '2026-04-18'],
      ['WEBSEARCH_PRIORITY_CONFIG.md','websearch/','websearch', 'Provider-Priorität',                    'config', true, 'websearch/WEBSEARCH_PRIORITY_CONFIG.md', '2026-04-18'],
      ['WEBSEARCH_SCRIPTS.md',       'websearch/', 'websearch', 'Automation & Scripting',                'script', true, 'websearch/WEBSEARCH_SCRIPTS.md',         '2026-04-18'],
      ['WEBSEARCH_OPS.md',           'websearch/', 'websearch', 'IT-Operations',                         'guide',  true, 'websearch/WEBSEARCH_OPS.md',             '2026-04-18'],
      ['MCP_GUIDE.md',               'mcp/',       'mcp',       'Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md','symlink',false,'websearch/WEBSEARCH_MCP_GUIDE.md',  '2026-04-18'],
    ]

    skills = [
      ['json-utils',          '1.0.0', 'installed', 'JSON parsing and validation',      'skills/json-utils/'],
      ['scripting-utils',     '1.0.0', 'installed', 'Multi-language scripting support', 'skills/scripting-utils/'],
      ['tiktok-live-mon',     '1.0.0', 'installed', 'TikTok stream monitoring',         'skills/tiktok-live-mon/'],
      ['cluster-management',  '1.0.0', 'installed', 'Cluster topology management',      'skills/cluster-management/'],
      ['worker-node',         '-',     'local',     'Worker node configuration',        'skills/worker-node/'],
      ['resource-manager',    '-',     'local',     'Resource management',              'skills/resource-manager/'],
      ['git-publish-agent',   '1.0.0', 'local',     'Git publishing automation',        'skills/git-publish-agent/'],
    ]

    symlinks = [
      ['openclaw.env',               '/home/openclaw/.config/openclaw/env',  '/',             'API-Keys Shortcut'],
      ['openclaw.json',              '/home/openclaw/.openclaw/openclaw.json','/',             'Konfig Shortcut'],
      ['links/config/openclaw-env',  '/home/openclaw/.config/openclaw/env',  'links/config/', 'API-Keys'],
      ['links/dotfiles/.tavily',     '/home/openclaw/.tavily/',              'links/dotfiles/','Tavily Config'],
      ['links/dotfiles/.claude',     '/home/openclaw/.claude/',              'links/dotfiles/','Claude Config'],
      ['links/dotfiles/.mcporter',   '/home/openclaw/.mcporter/',            'links/dotfiles/','MCPorter Config'],
      ['links/dotfiles/.ssh',        '/home/openclaw/.ssh/',                 'links/dotfiles/','SSH Keys'],
    ]

    get_connection do |conn|
      categories.each do |category|
        conn.execute(
          'INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)',
          category
        )
      end

      docs.each do |doc|
        conn.execute(
          <<~SQL,
            INSERT OR REPLACE INTO documents
            (name, path, category, description, type, has_symlink, symlink_path, last_update)
            VALUES (?,?,?,?,?,?,?,?)
          SQL
          doc
        )
      end

      skills.each do |skill|
        conn.execute(
          'INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)',
          skill
        )
      end

      symlinks.each do |symlink|
        conn.execute(
          'INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)',
          symlink
        )
      end
    end

    logger.info(
      "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks",
      docs.length, skills.length, symlinks.length
    )
    self
  end

  def export_csv(table)
    # Exportiert eine Tabelle aus docs.db als CSV-Datei in den Workspace-Root.
    #
    # Args:
    #     table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
    #
    # Returns:
    #     Path zur erzeugten CSV-Datei, oder nil wenn die Tabelle leer ist.
    #
    # Raises:
    #     ArgumentError: Bei ungültigem Tabellennamen.
    #     SQLite3::Exception: Bei Datenbankfehlern.
    #     IOError: Bei Schreibfehlern.

    validate_table_name(table, DOCS_EXPORT_TABLES)

    rows = []
    column_names = []

    get_connection do |conn|
      result = conn.execute("SELECT * FROM #{table}")
      rows = result.to_a
      column_names = result.columns
    end

    if rows.empty?
      logger.info("Tabelle '#{table}' ist leer — kein CSV erzeugt")
      return nil
    end

    csv_path = WORKSPACE / "export_#{table}.csv"
    CSV.open(csv_path, 'w', write_headers: true, headers: column_names) do |csv|
      rows.each { |row| csv << row }
    end

    logger.info("CSV exportiert: #{csv_path} (#{rows.length} Zeilen)")
    csv_path
  end

  def export_json(table)
    # Exportiert eine Tabelle aus docs.db als JSON-Datei in den Workspace-Root.
    #
    # Args:
    #     table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
    #
    # Returns:
    #     Path zur erzeugten JSON-Datei, oder nil wenn die Tabelle leer ist.
    #
    # Raises:
    #     ArgumentError: Bei ungültigem Tabellennamen.
    #     SQLite3::Exception: Bei Datenbankfehlern.
    #     IOError: Bei Schreibfehlern.

    validate_table_name(table, DOCS_EXPORT_TABLES)

    data = []
    get_connection do |conn|
      conn.results_as_hash = true
      result = conn.execute("SELECT * FROM #{table}")
      data = result.to_a.map(&:to_h)
    end

    if data.empty?
      logger.info("Tabelle '#{table}' ist leer — kein JSON erzeugt")
      return nil
    end

    json_path = WORKSPACE / "export_#{table}.json"
    File.write(json_path, JSON.pretty_generate(data))

    logger.info("JSON exportiert: #{json_path} (#{data.length} Einträge)")
    json_path
  end

  private

  def get_connection(&block)
    # Context-Manager der eine SQLite-Verbindung öffnet und sicher schließt.
    #
    # Yields:
    #     SQLite3::Database: Offene Verbindung.
    #
    # Raises:
    #     SQLite3::Exception: Bei Verbindungs- oder Datenbankfehlern.

    db = SQLite3::Database.new(@db_path.to_s)
    begin
      yield db
    ensure
      db.close
    end
  end

  def validate_table_name(table, allowed)
    # Prüft ob der Tabellenname in der Allowlist enthalten ist.
    #
    # Verhindert SQL-Injection durch direkte Tabellennamen-Interpolation.
    #
    # Args:
    #     table:   Zu prüfender Tabellenname.
    #     allowed: Menge erlaubter Tabellennamen.
    #
    # Raises:
    #     ArgumentError: Wenn der Tabellenname nicht erlaubt ist.

    return if allowed.include?(table)

    raise ArgumentError,
          "Ungültiger Tabellenname: '#{table}'. Erlaubt: #{allowed.to_a.sort}"
  end
end

# ---------------------------------------------------------------------------
# TreeDatabase
# ---------------------------------------------------------------------------

class TreeDatabase
  # Verwaltet die tree.db: Verzeichnisbaum-Strukturen und Scan-Metadaten.
  #
  # Wird durch ein separates tree.py Script befüllt. Dieses Modul stellt
  # nur Schema-Initialisierung und Export bereit.

  def initialize
    # Initialisiert TreeDatabase mit dem Standard-Datenbankpfad.
    @db_path = DB_DIR / 'tree.db'
  end

  def init_schema
    # Erstellt die Tabellenstruktur in tree.db falls noch nicht vorhanden.
    #
    # Tabellen: tree_entries, tree_scans.
    #
    # Returns:
    #     TreeDatabase: self für Method-Chaining.
    #
    # Raises:
    #     SQLite3::Exception: Bei Fehlern in der Schema-Erstellung.

    get_connection do |conn|
      conn.execute <<-SQL
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
      SQL

      conn.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tree_scans (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            root_path      TEXT    NOT NULL,
            max_depth      INTEGER,
            total_files    INTEGER,
            total_dirs     INTEGER,
            total_symlinks INTEGER,
            scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      SQL
    end

    logger.info("tree.db Schema initialisiert: #{@db_path}")
    self
  end

  def add_entry(root_path:, relative_path:, name:, entry_type:, depth:, parent_path:, size: 0)
    # Fügt einen einzelnen Verzeichnisbaum-Eintrag in tree_entries ein.
    #
    # Args:
    #     root_path:     Absoluter Pfad des Scan-Wurzelverzeichnisses.
    #     relative_path: Pfad relativ zu root_path.
    #     name:          Datei- oder Verzeichnisname.
    #     entry_type:    'file', 'directory' oder 'symlink'.
    #     depth:         Verschachtelungstiefe (0 = root).
    #     parent_path:   Relativer Pfad des Elternverzeichnisses.
    #     size:          Dateigröße in Bytes (0 für Verzeichnisse).
    #
    # Raises:
    #     SQLite3::Exception: Bei Datenbankfehlern.

    get_connection do |conn|
      conn.execute(
        <<~SQL,
          INSERT INTO tree_entries
          (root_path, relative_path, name, type, depth, parent_path, size)
          VALUES (?,?,?,?,?,?,?)
        SQL
        [root_path, relative_path, name, entry_type, depth, parent_path, size]
      )
    end
  end

  def export_csv(root_path_filter = nil)
    # Exportiert tree_entries als CSV-Datei, optional gefiltert nach root_path.
    #
    # Args:
    #     root_path_filter: Wenn angegeben, werden nur Einträge mit diesem
    #                       root_path exportiert. nil exportiert alle Einträge.
    #
    # Returns:
    #     Path zur erzeugten CSV-Datei, oder nil wenn keine Einträge vorhanden.
    #
    # Raises:
    #     SQLite3::Exception: Bei Datenbankfehlern.
    #     IOError: Bei Schreibfehlern.

    rows = []
    column_names = []

    get_connection do |conn|
      if root_path_filter
        result = conn.execute(
          'SELECT * FROM tree_entries WHERE root_path = ?',
          [root_path_filter]
        )
      else
        result = conn.execute('SELECT * FROM tree_entries')
      end

      rows = result.to_a
      column_names = result.columns
    end

    if rows.empty?
      logger.info('Keine Tree-Einträge vorhanden — kein CSV erzeugt')
      return nil
    end

    suffix = root_path_filter ? "_#{root_path_filter.gsub('/', '_')}" : '_all'
    csv_path = WORKSPACE / "export_tree#{suffix}.csv"

    CSV.open(csv_path, 'w', write_headers: true, headers: column_names) do |csv|
      rows.each { |row| csv << row }
    end

    logger.info("Tree-CSV exportiert: #{csv_path} (#{rows.length} Einträge)")
    csv_path
  end

  private

  def get_connection(&block)
    # Context-Manager der eine SQLite-Verbindung öffnet und sicher schließt.
    #
    # Yields:
    #     SQLite3::Database: Offene Verbindung.
    #
    # Raises:
    #     SQLite3::Exception: Bei Verbindungs- oder Datenbankfehlern.

    db = SQLite3::Database.new(@db_path.to_s)
    begin
      yield db
    ensure
      db.close
    end
  end
end

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

def main
  # Initialisiert docs.db und tree.db, befüllt docs.db und erzeugt Exporte.
  #
  # Legt DB_DIR an falls nicht vorhanden. Wird als Standalone-Script
  # oder einmalig zur Ersteinrichtung ausgeführt.

  puts '=' * 60
  puts 'WORKSPACE DATABASE MANAGER'
  puts '=' * 60

  # DB-Verzeichnis hier (nicht auf Modulebene) anlegen
  begin
    DB_DIR.mkpath
    logger.info("DB-Verzeichnis: #{DB_DIR}")
  rescue => e
    logger.error("DB-Verzeichnis konnte nicht erstellt werden: #{e}")
    exit(1)
  end

  # docs.db aufbauen
  docs_db = DocsDatabase.new
  docs_db.init_schema
  docs_db.populate_from_workspace

  # Exporte
  puts "\n--- Exporte docs.db ---"
  %w[documents skills symlinks].each { |table| docs_db.export_csv(table) }
  docs_db.export_json('documents')

  # tree.db aufbauen (Daten kommen via tree.py)
  puts "\n--- tree.db Initialisierung ---"
  tree_db = TreeDatabase.new
  tree_db.init_schema
  logger.info('Tree-Daten werden via tree.py Script befüllt')

  puts "\n" + '=' * 60
  puts 'DATENBANKEN BEREIT'
  puts '=' * 60
  puts "\nDatenbanken: #{DB_DIR}/"
  puts "Exporte:     #{WORKSPACE}/"
end

main if __FILE__ == $0
