#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "fa238fcc2a517047f5a6ae10fc304fccf2b83770a5411e71fbaacf267b9fbfd4", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "javascript"}
// db_manager.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Workspace Documentation Database Manager
 *
 * Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
 * Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
 *
 * Verwendung:
 *     node db_manager.js
 *
 * Konfiguration:
 *     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
 */

const fs = require('fs');
const path = require('path');
const sqlite3 = require('sqlite3').verbose();
const { open } = require('sqlite');

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || '/home/openclaw/.openclaw/workspace';
const DB_DIR = path.join(WORKSPACE, 'db');

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
const _DOCS_EXPORT_TABLES = new Set(['documents', 'categories', 'symlinks', 'skills']);
const _TREE_EXPORT_TABLES = new Set(['tree_entries', 'tree_scans']);

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

class Logger {
  constructor(name) {
    this.name = name;
  }

  _log(level, message, ...args) {
    const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
    console.log(`${timestamp} | ${level.padEnd(8)} | ${this.name} | ${message}`, ...args);
  }

  info(message, ...args) {
    this._log('INFO', message, ...args);
  }

  error(message, ...args) {
    this._log('ERROR', message, ...args);
  }
}

const logger = new Logger('db_manager');

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

class DocsDatabase {
  /**
   * Verwaltet die docs.db: Dokumentationen, Kategorien, Symlinks und Skills.
   *
   * Jede öffentliche Methode öffnet und schließt ihre Datenbankverbindung
   * eigenständig, sodass keine Verbindungen offen bleiben.
   */
  constructor() {
    /** Initialisiert DocsDatabase mit dem Standard-Datenbankpfad. */
    this.dbPath = path.join(DB_DIR, 'docs.db');
  }

  async _get_connection() {
    /**
     * Erstellt eine SQLite-Verbindung.
     *
     * Returns:
     *     Promise<sqlite3.Database>: Offene Verbindung.
     */
    const db = new sqlite3.Database(this.dbPath);
    return db;
  }

  async init_schema() {
    /**
     * Erstellt die Tabellenstruktur in docs.db falls noch nicht vorhanden.
     *
     * Tabellen: documents, categories, symlinks, skills.
     * Bestehende Tabellen werden nicht verändert (CREATE TABLE IF NOT EXISTS).
     *
     * Returns:
     *     Promise<DocsDatabase>: this für Method-Chaining.
     */
    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.serialize(() => {
        db.run(`
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
        `);

        db.run(`
          CREATE TABLE IF NOT EXISTS categories (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    UNIQUE NOT NULL,
            description TEXT,
            priority    INTEGER DEFAULT 0
          )
        `);

        db.run(`
          CREATE TABLE IF NOT EXISTS symlinks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            target      TEXT    NOT NULL,
            source_path TEXT    NOT NULL,
            description TEXT,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);

        db.run(`
          CREATE TABLE IF NOT EXISTS skills (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            version     TEXT,
            status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
            description TEXT,
            path        TEXT
          )
        `);

        db.close((err) => {
          if (err) {
            reject(err);
          } else {
            logger.info(`docs.db Schema initialisiert: ${this.dbPath}`);
            resolve(this);
          }
        });
      });
    });
  }

  async populate_from_workspace() {
    /**
     * Befüllt docs.db mit bekannten Workspace-Dokumenten, Skills und Symlinks.
     *
     * Verwendet INSERT OR IGNORE / INSERT OR REPLACE, sodass ein erneuter
     * Aufruf idempotent ist.
     *
     * Returns:
     *     Promise<DocsDatabase>: self für Method-Chaining.
     */
    const categories = [
      ['main',      'Hauptverzeichnis Dateien',        1],
      ['memory',    'Memory und Protokolle',           2],
      ['reports',   'Berichte und Analysen',           3],
      ['cluster',   'Cluster und Infrastruktur',       4],
      ['skills',    'Installierte Skills',             5],
      ['websearch', 'WebSearch Dokumentationen',       6],
      ['mcp',       'MCP Integration',                 7],
      ['links',     'Symbolische Links',               8],
    ];

    // (name, path, category, description, type, has_symlink, symlink_path, last_update)
    const docs = [
      ['AGENTS.md',             '/', 'main', 'Agent-Konfiguration, Memory-Regeln',      'config',  false, null,                          '2026-04-11'],
      ['SOUL.md',               '/', 'main', 'Agent-Persönlichkeit und Kernwahrheiten', 'config',  false, null,                          '2026-04-11'],
      ['IDENTITY.md',           '/', 'main', 'Agent-Name und Eigenschaften',            'config',  false, null,                          '2026-04-11'],
      ['USER.md',               '/', 'main', 'Benutzerinformationen',                   'config',  false, null,                          '2026-04-11'],
      ['TOOLS.md',              '/', 'main', 'Tool-spezifische Konfigurationen',        'config',  false, null,                          '2026-04-18'],
      ['MEMORY.md',             '/', 'main', 'Langzeitspeicher, System-Konfiguration',  'config',  false, null,                          '2026-04-11'],
      ['DOCUMENTATION-INDEX.md','/', 'main', 'Übersicht aller Dokumentationen',         'doc',     false, null,                          '2026-04-18'],
      ['WORKSPACE-INDEX.md',    '/', 'main', 'Symlink zu DOCUMENTATION-INDEX.md',       'symlink', true,  'DOCUMENTATION-INDEX.md',      '2026-04-18'],
      ['WEBSEARCH_README.md',        'websearch/', 'websearch', 'Schnellstart Guide',                    'guide',  true, 'websearch/WEBSEARCH_README.md',          '2026-04-18'],
      ['WEBSEARCH_MCP_GUIDE.md',     'websearch/', 'websearch', 'Vollständige technische Dokumentation', 'guide',  true, 'websearch/WEBSEARCH_MCP_GUIDE.md',       '2026-04-18'],
      ['WEBSEARCH_CONFIG.md',        'websearch/', 'websearch', 'Konfigurations-Referenz',               'config', true, 'websearch/WEBSEARCH_CONFIG.md',          '2026-04-18'],
      ['WEBSEARCH_PRIORITY_CONFIG.md','websearch/','websearch', 'Provider-Priorität',                    'config', true, 'websearch/WEBSEARCH_PRIORITY_CONFIG.md', '2026-04-18'],
      ['WEBSEARCH_SCRIPTS.md',       'websearch/', 'websearch', 'Automation & Scripting',                'script', true, 'websearch/WEBSEARCH_SCRIPTS.md',         '2026-04-18'],
      ['WEBSEARCH_OPS.md',           'websearch/', 'websearch', 'IT-Operations',                         'guide',  true, 'websearch/WEBSEARCH_OPS.md',             '2026-04-18'],
      ['MCP_GUIDE.md',               'mcp/',       'mcp',       'Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md','symlink',false,'websearch/WEBSEARCH_MCP_GUIDE.md',  '2026-04-18'],
    ];

    const skills = [
      ['json-utils',          '1.0.0', 'installed', 'JSON parsing and validation',      'skills/json-utils/'],
      ['scripting-utils',     '1.0.0', 'installed', 'Multi-language scripting support', 'skills/scripting-utils/'],
      ['tiktok-live-mon',     '1.0.0', 'installed', 'TikTok stream monitoring',         'skills/tiktok-live-mon/'],
      ['cluster-management',  '1.0.0', 'installed', 'Cluster topology management',      'skills/cluster-management/'],
      ['worker-node',         '-',     'local',     'Worker node configuration',        'skills/worker-node/'],
      ['resource-manager',    '-',     'local',     'Resource management',              'skills/resource-manager/'],
      ['git-publish-agent',   '1.0.0', 'local',     'Git publishing automation',        'skills/git-publish-agent/'],
    ];

    const symlinks = [
      ['openclaw.env',               '/home/openclaw/.config/openclaw/env',  '/',             'API-Keys Shortcut'],
      ['openclaw.json',              '/home/openclaw/.openclaw/openclaw.json','/',             'Konfig Shortcut'],
      ['links/config/openclaw-env',  '/home/openclaw/.config/openclaw/env',  'links/config/', 'API-Keys'],
      ['links/dotfiles/.tavily',     '/home/openclaw/.tavily/',              'links/dotfiles/','Tavily Config'],
      ['links/dotfiles/.claude',     '/home/openclaw/.claude/',              'links/dotfiles/','Claude Config'],
      ['links/dotfiles/.mcporter',   '/home/openclaw/.mcporter/',            'links/dotfiles/','MCPorter Config'],
      ['links/dotfiles/.ssh',        '/home/openclaw/.ssh/',                 'links/dotfiles/','SSH Keys'],
    ];

    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.serialize(() => {
        // Insert categories
        const catStmt = db.prepare('INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)');
        for (const cat of categories) {
          catStmt.run(cat);
        }
        catStmt.finalize();

        // Insert documents
        const docStmt = db.prepare(`
          INSERT OR REPLACE INTO documents 
          (name, path, category, description, type, has_symlink, symlink_path, last_update) 
          VALUES (?,?,?,?,?,?,?,?)
        `);
        for (const doc of docs) {
          docStmt.run(doc);
        }
        docStmt.finalize();

        // Insert skills
        const skillStmt = db.prepare(`
          INSERT OR REPLACE INTO skills 
          (name, version, status, description, path) 
          VALUES (?,?,?,?,?)
        `);
        for (const skill of skills) {
          skillStmt.run(skill);
        }
        skillStmt.finalize();

        // Insert symlinks
        const symlinkStmt = db.prepare(`
          INSERT OR REPLACE INTO symlinks 
          (name, target, source_path, description) 
          VALUES (?,?,?,?)
        `);
        for (const link of symlinks) {
          symlinkStmt.run(link);
        }
        symlinkStmt.finalize();

        db.close((err) => {
          if (err) {
            reject(err);
          } else {
            logger.info(`docs.db befüllt: ${docs.length} Dokumente, ${skills.length} Skills, ${symlinks.length} Symlinks`);
            resolve(this);
          }
        });
      });
    });
  }

  _validate_table_name(table, allowed) {
    /**
     * Prüft ob der Tabellenname in der Allowlist enthalten ist.
     *
     * Verhindert SQL-Injection durch direkte Tabellennamen-Interpolation.
     *
     * Args:
     *     table:   Zu prüfender Tabellenname.
     *     allowed: Menge erlaubter Tabellennamen.
     *
     * Throws:
     *     Error: Wenn der Tabellenname nicht erlaubt ist.
     */
    if (!allowed.has(table)) {
      throw new Error(
        `Ungültiger Tabellenname: '${table}'. Erlaubt: [${Array.from(allowed).sort()}]`
      );
    }
  }

  async export_csv(table) {
    /**
     * Exportiert eine Tabelle aus docs.db als CSV-Datei in den Workspace-Root.
     *
     * Args:
     *     table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     *
     * Returns:
     *     Promise<string|null>: Pfad zur erzeugten CSV-Datei, oder null wenn die Tabelle leer ist.
     */
    this._validate_table_name(table, _DOCS_EXPORT_TABLES);

    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.all(`SELECT * FROM ${table}`, [], (err, rows) => {
        if (err) {
          db.close();
          reject(err);
          return;
        }

        if (rows.length === 0) {
          db.close();
          logger.info(`Tabelle '${table}' ist leer — kein CSV erzeugt`);
          resolve(null);
          return;
        }

        // Get column names
        const columns = Object.keys(rows[0]);

        // Create CSV content
        let csvContent = columns.join(',') + '\n';
        for (const row of rows) {
          const values = columns.map(col => `"${String(row[col]).replace(/"/g, '""')}"`);
          csvContent += values.join(',') + '\n';
        }

        const csvPath = path.join(WORKSPACE, `export_${table}.csv`);
        
        fs.writeFile(csvPath, csvContent, 'utf8', (err) => {
          db.close();
          if (err) {
            reject(err);
          } else {
            logger.info(`CSV exportiert: ${csvPath} (${rows.length} Zeilen)`);
            resolve(csvPath);
          }
        });
      });
    });
  }

  async export_json(table) {
    /**
     * Exportiert eine Tabelle aus docs.db als JSON-Datei in den Workspace-Root.
     *
     * Args:
     *     table: Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     *
     * Returns:
     *     Promise<string|null>: Pfad zur erzeugten JSON-Datei, oder null wenn die Tabelle leer ist.
     */
    this._validate_table_name(table, _DOCS_EXPORT_TABLES);

    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.all(`SELECT * FROM ${table}`, [], (err, rows) => {
        if (err) {
          db.close();
          reject(err);
          return;
        }

        if (rows.length === 0) {
          db.close();
          logger.info(`Tabelle '${table}' ist leer — kein JSON erzeugt`);
          resolve(null);
          return;
        }

        const data = rows.map(row => {
          const obj = {};
          for (const key in row) {
            obj[key] = row[key];
          }
          return obj;
        });

        const jsonPath = path.join(WORKSPACE, `export_${table}.json`);
        const jsonContent = JSON.stringify(data, null, 2);

        fs.writeFile(jsonPath, jsonContent, 'utf8', (err) => {
          db.close();
          if (err) {
            reject(err);
          } else {
            logger.info(`JSON exportiert: ${jsonPath} (${data.length} Einträge)`);
            resolve(jsonPath);
          }
        });
      });
    });
  }
}

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

class TreeDatabase {
  /**
   * Verwaltet die tree.db: Verzeichnisbaum-Strukturen und Scan-Metadaten.
   *
   * Wird durch ein separates tree.py Script befüllt. Dieses Modul stellt
   * nur Schema-Initialisierung und Export bereit.
   */
  constructor() {
    /** Initialisiert TreeDatabase mit dem Standard-Datenbankpfad. */
    this.dbPath = path.join(DB_DIR, 'tree.db');
  }

  async _get_connection() {
    /**
     * Erstellt eine SQLite-Verbindung.
     *
     * Returns:
     *     Promise<sqlite3.Database>: Offene Verbindung.
     */
    const db = new sqlite3.Database(this.dbPath);
    return db;
  }

  async init_schema() {
    /**
     * Erstellt die Tabellenstruktur in tree.db falls noch nicht vorhanden.
     *
     * Tabellen: tree_entries, tree_scans.
     *
     * Returns:
     *     Promise<TreeDatabase>: self für Method-Chaining.
     */
    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.serialize(() => {
        db.run(`
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
        `);

        db.run(`
          CREATE TABLE IF NOT EXISTS tree_scans (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            root_path      TEXT    NOT NULL,
            max_depth      INTEGER,
            total_files    INTEGER,
            total_dirs     INTEGER,
            total_symlinks INTEGER,
            scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);

        db.close((err) => {
          if (err) {
            reject(err);
          } else {
            logger.info(`tree.db Schema initialisiert: ${this.dbPath}`);
            resolve(this);
          }
        });
      });
    });
  }

  async add_entry(root_path, relative_path, name, entry_type, depth, parent_path, size = 0) {
    /**
     * Fügt einen einzelnen Verzeichnisbaum-Eintrag in tree_entries ein.
     *
     * Args:
     *     root_path:     Absoluter Pfad des Scan-Wurzelverzeichnisses.
     *     relative_path: Pfad relativ zu root_path.
     *     name:          Datei- oder Verzeichnisname.
     *     entry_type:    'file', 'directory' oder 'symlink'.
     *     depth:         Verschachtelungstiefe (0 = root).
     *     parent_path:   Relativer Pfad des Elternverzeichnisses.
     *     size:          Dateigröße in Bytes (0 für Verzeichnisse).
     */
    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      db.run(
        `INSERT INTO tree_entries 
         (root_path, relative_path, name, type, depth, parent_path, size) 
         VALUES (?,?,?,?,?,?,?)`,
        [root_path, relative_path, name, entry_type, depth, parent_path, size],
        (err) => {
          db.close();
          if (err) {
            reject(err);
          } else {
            resolve();
          }
        }
      );
    });
  }

  async export_csv(root_path_filter = null) {
    /**
     * Exportiert tree_entries als CSV-Datei, optional gefiltert nach root_path.
     *
     * Args:
     *     root_path_filter: Wenn angegeben, werden nur Einträge mit diesem
     *                       root_path exportiert. null exportiert alle Einträge.
     *
     * Returns:
     *     Promise<string|null>: Pfad zur erzeugten CSV-Datei, oder null wenn keine Einträge vorhanden.
     */
    const db = await this._get_connection();
    
    return new Promise((resolve, reject) => {
      let query, params;
      if (root_path_filter !== null) {
        query = 'SELECT * FROM tree_entries WHERE root_path = ?';
        params = [root_path_filter];
      } else {
        query = 'SELECT * FROM tree_entries';
        params = [];
      }

      db.all(query, params, (err, rows) => {
        if (err) {
          db.close();
          reject(err);
          return;
        }

        if (rows.length === 0) {
          db.close();
          logger.info('Keine Tree-Einträge vorhanden — kein CSV erzeugt');
          resolve(null);
          return;
        }

        // Get column names
        const columns = Object.keys(rows[0]);

        // Create CSV content
        let csvContent = columns.join(',') + '\n';
        for (const row of rows) {
          const values = columns.map(col => `"${String(row[col]).replace(/"/g, '""')}"`);
          csvContent += values.join(',') + '\n';
        }

        const suffix = root_path_filter !== null ? 
          `_${root_path_filter.replace(/\//g, '_')}` : '_all';
        const csvPath = path.join(WORKSPACE, `export_tree${suffix}.csv`);

        fs.writeFile(csvPath, csvContent, 'utf8', (err) => {
          db.close();
          if (err) {
            reject(err);
          } else {
            logger.info(`Tree-CSV exportiert: ${csvPath} (${rows.length} Einträge)`);
            resolve(csvPath);
          }
        });
      });
    });
  }
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

async function main() {
  /**
   * Initialisiert docs.db und tree.db, befüllt docs.db und erzeugt Exporte.
   *
   * Legt DB_DIR an falls nicht vorhanden. Wird als Standalone-Script
   * oder einmalig zur Ersteinrichtung ausgeführt.
   */
  console.log('='.repeat(60));
  console.log('WORKSPACE DATABASE MANAGER');
  console.log('='.repeat(60));

  // DB-Verzeichnis hier (nicht auf Modulebene) anlegen
  try {
    fs.mkdirSync(DB_DIR, { recursive: true });
    logger.info(`DB-Verzeichnis: ${DB_DIR}`);
  } catch (exc) {
    logger.error(`DB-Verzeichnis konnte nicht erstellt werden: ${exc.message}`);
    process.exit(1);
  }

  // docs.db aufbauen
  const docs_db = new DocsDatabase();
  await docs_db.init_schema();
  await docs_db.populate_from_workspace();

  // Exporte
  console.log('\n--- Exporte docs.db ---');
  for (const table of ['documents', 'skills', 'symlinks']) {
    await docs_db.export_csv(table);
  }
  await docs_db.export_json('documents');

  // tree.db aufbauen (Daten kommen via tree.py)
  console.log('\n--- tree.db Initialisierung ---');
  const tree_db = new TreeDatabase();
  await tree_db.init_schema();
  logger.info('Tree-Daten werden via tree.py Script befüllt');

  console.log('\n' + '='.repeat(60));
  console.log('DATENBANKEN BEREIT');
  console.log('='.repeat(60));
  console.log(`\nDatenbanken: ${DB_DIR}/`);
  console.log(`Exporte:     ${WORKSPACE}/`);
}

if (require.main === module) {
  main().catch(console.error);
}

module.exports = { DocsDatabase, TreeDatabase };
