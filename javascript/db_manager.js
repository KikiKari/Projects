#!/usr/bin/env node
// db_manager.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway1:abstraction-manager/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: OpenClaw@gateway2:abstraction-manager/db_manager.py
// auch in: 1 weiteren Fundstellen
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

const WORKSPACE = process.env.OPENCLAW_WORKSPACE || "/home/openclaw/.openclaw/workspace";
const DB_DIR = path.join(WORKSPACE, "db");

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
const _DOCS_EXPORT_TABLES = new Set(["documents", "categories", "symlinks", "skills"]);
const _TREE_EXPORT_TABLES = new Set(["tree_entries", "tree_scans"]);

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

function createLogger(name) {
    const levels = {
        INFO: 'INFO',
        ERROR: 'ERROR',
        WARN: 'WARN'
    };

    function log(level, message, ...args) {
        const timestamp = new Date().toISOString().slice(0, 19).replace('T', ' ');
        console.log(`${timestamp} | ${level.padEnd(8)} | ${name} | ${message}`, ...args);
    }

    return {
        info: (message, ...args) => log(levels.INFO, message, ...args),
        error: (message, ...args) => log(levels.ERROR, message, ...args),
        warn: (message, ...args) => log(levels.WARN, message, ...args)
    };
}

const logger = createLogger("db_manager");

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

function mkdirSyncRecursive(directory) {
    const parts = directory.split(path.sep);
    let currentPath = '';

    for (const part of parts) {
        currentPath = path.join(currentPath, part);
        if (!fs.existsSync(currentPath)) {
            fs.mkdirSync(currentPath);
        }
    }
}

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
        this.dbPath = path.join(DB_DIR, "docs.db");
    }

    /**
     * Erstellt die Tabellenstruktur in docs.db falls noch nicht vorhanden.
     *
     * Tabellen: documents, categories, symlinks, skills.
     * Bestehende Tabellen werden nicht verändert (CREATE TABLE IF NOT EXISTS).
     *
     * @returns {DocsDatabase} self für Method-Chaining.
     */
    initSchema() {
        const db = new sqlite3.Database(this.dbPath);
        
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
        });

        db.close();
        logger.info(`docs.db Schema initialisiert: ${this.dbPath}`);
        return this;
    }

    /**
     * Befüllt docs.db mit bekannten Workspace-Dokumenten, Skills und Symlinks.
     *
     * Verwendet INSERT OR IGNORE / INSERT OR REPLACE, sodass ein erneuter
     * Aufruf idempotent ist.
     *
     * @returns {DocsDatabase} self für Method-Chaining.
     */
    populateFromWorkspace() {
        const categories = [
            ["main",      "Hauptverzeichnis Dateien",        1],
            ["memory",    "Memory und Protokolle",           2],
            ["reports",   "Berichte und Analysen",           3],
            ["cluster",   "Cluster und Infrastruktur",       4],
            ["skills",    "Installierte Skills",             5],
            ["websearch", "WebSearch Dokumentationen",       6],
            ["mcp",       "MCP Integration",                 7],
            ["links",     "Symbolische Links",               8],
        ];

        // (name, path, category, description, type, has_symlink, symlink_path, last_update)
        const docs = [
            ["AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  false, null,                          "2026-04-11"],
            ["SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  false, null,                          "2026-04-11"],
            ["IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  false, null,                          "2026-04-11"],
            ["USER.md",               "/", "main", "Benutzerinformationen",                   "config",  false, null,                          "2026-04-11"],
            ["TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  false, null,                          "2026-04-18"],
            ["MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  false, null,                          "2026-04-11"],
            ["DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     false, null,                          "2026-04-18"],
            ["WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", true,  "DOCUMENTATION-INDEX.md",      "2026-04-18"],
            ["WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  true, "websearch/WEBSEARCH_README.md",          "2026-04-18"],
            ["WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  true, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18"],
            ["WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", true, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18"],
            ["WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"],
            ["WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", true, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18"],
            ["WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  true, "websearch/WEBSEARCH_OPS.md",             "2026-04-18"],
            ["MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",false,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18"],
        ];

        const skills = [
            ["json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"],
            ["scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"],
            ["tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"],
            ["cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"],
            ["worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"],
            ["resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"],
            ["git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"],
        ];

        const symlinks = [
            ["openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"],
            ["openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"],
            ["links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"],
            ["links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"],
            ["links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"],
            ["links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"],
            ["links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"],
        ];

        const db = new sqlite3.Database(this.dbPath);
        
        db.serialize(() => {
            for (const category of categories) {
                db.run(
                    "INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)",
                    category
                );
            }

            for (const doc of docs) {
                db.run(
                    `INSERT OR REPLACE INTO documents
                     (name, path, category, description, type, has_symlink, symlink_path, last_update)
                     VALUES (?,?,?,?,?,?,?,?)`,
                    doc
                );
            }

            for (const skill of skills) {
                db.run(
                    "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)",
                    skill
                );
            }

            for (const symlink of symlinks) {
                db.run(
                    "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)",
                    symlink
                );
            }
        });

        db.close();

        logger.info(
            `docs.db befüllt: ${docs.length} Dokumente, ${skills.length} Skills, ${symlinks.length} Symlinks`
        );
        return this;
    }

    /**
     * Prüft ob der Tabellenname in der Allowlist enthalten ist.
     *
     * Verhindert SQL-Injection durch direkte Tabellennamen-Interpolation.
     *
     * @param {string} table Zu prüfender Tabellenname.
     * @param {Set} allowed Menge erlaubter Tabellennamen.
     * @throws {Error} Wenn der Tabellenname nicht erlaubt ist.
     */
    _validateTableName(table, allowed) {
        if (!allowed.has(table)) {
            throw new Error(
                `Ungültiger Tabellenname: '${table}'. ` +
                `Erlaubt: [${Array.from(allowed).sort().join(', ')}]`
            );
        }
    }

    /**
     * Exportiert eine Tabelle aus docs.db als CSV-Datei in den Workspace-Root.
     *
     * @param {string} table Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     * @returns {string|null} Pfad zur erzeugten CSV-Datei, oder null wenn die Tabelle leer ist.
     */
    exportCsv(table) {
        this._validateTableName(table, _DOCS_EXPORT_TABLES);

        const db = new sqlite3.Database(this.dbPath);
        let rows = [];
        let columnNames = [];

        const selectAll = db.prepare(`SELECT * FROM ${table}`);
        selectAll.all((err, result) => {
            if (err) {
                db.close();
                throw err;
            }
            
            if (result.length === 0) {
                logger.info(`Tabelle '${table}' ist leer — kein CSV erzeugt`);
                db.close();
                return null;
            }

            rows = result;
            columnNames = Object.keys(result[0]);

            const csvPath = path.join(WORKSPACE, `export_${table}.csv`);
            
            // Erstelle CSV-Header
            let csvContent = columnNames.join(',') + '\n';
            
            // Füge Datenzeilen hinzu
            for (const row of rows) {
                const values = columnNames.map(col => {
                    const value = row[col];
                    // Escape und quote falls nötig
                    if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
                        return `"${value.replace(/"/g, '""')}"`;
                    }
                    return value;
                });
                csvContent += values.join(',') + '\n';
            }

            fs.writeFileSync(csvPath, csvContent, 'utf8');
            logger.info(`CSV exportiert: ${csvPath} (${rows.length} Zeilen)`);
            db.close();
            return csvPath;
        });
    }

    /**
     * Exportiert eine Tabelle aus docs.db als JSON-Datei in den Workspace-Root.
     *
     * @param {string} table Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     * @returns {string|null} Pfad zur erzeugten JSON-Datei, oder null wenn die Tabelle leer ist.
     */
    exportJson(table) {
        this._validateTableName(table, _DOCS_EXPORT_TABLES);

        const db = new sqlite3.Database(this.dbPath);
        let rows = [];

        const selectAll = db.prepare(`SELECT * FROM ${table}`);
        selectAll.all((err, result) => {
            if (err) {
                db.close();
                throw err;
            }
            
            if (result.length === 0) {
                logger.info(`Tabelle '${table}' ist leer — kein JSON erzeugt`);
                db.close();
                return null;
            }

            rows = result;

            const jsonPath = path.join(WORKSPACE, `export_${table}.json`);
            const data = rows.map(row => {
                const obj = {};
                for (const key in row) {
                    obj[key] = row[key];
                }
                return obj;
            });

            fs.writeFileSync(jsonPath, JSON.stringify(data, null, 2), 'utf8');
            logger.info(`JSON exportiert: ${jsonPath} (${data.length} Einträge)`);
            db.close();
            return jsonPath;
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
        this.dbPath = path.join(DB_DIR, "tree.db");
    }

    /**
     * Erstellt die Tabellenstruktur in tree.db falls noch nicht vorhanden.
     *
     * Tabellen: tree_entries, tree_scans.
     *
     * @returns {TreeDatabase} self für Method-Chaining.
     */
    initSchema() {
        const db = new sqlite3.Database(this.dbPath);
        
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
        });

        db.close();
        logger.info(`tree.db Schema initialisiert: ${this.dbPath}`);
        return this;
    }

    /**
     * Fügt einen einzelnen Verzeichnisbaum-Eintrag in tree_entries ein.
     *
     * @param {string} rootPath Absoluter Pfad des Scan-Wurzelverzeichnisses.
     * @param {string} relativePath Pfad relativ zu root_path.
     * @param {string} name Datei- oder Verzeichnisname.
     * @param {string} entryType 'file', 'directory' oder 'symlink'.
     * @param {number} depth Verschachtelungstiefe (0 = root).
     * @param {string} parentPath Relativer Pfad des Elternverzeichnisses.
     * @param {number} size Dateigröße in Bytes (0 für Verzeichnisse).
     */
    addEntry(rootPath, relativePath, name, entryType, depth, parentPath, size = 0) {
        const db = new sqlite3.Database(this.dbPath);
        
        db.run(
            `INSERT INTO tree_entries
             (root_path, relative_path, name, type, depth, parent_path, size)
             VALUES (?,?,?,?,?,?,?)`,
            [rootPath, relativePath, name, entryType, depth, parentPath, size],
            (err) => {
                if (err) {
                    db.close();
                    throw err;
                }
                db.close();
            }
        );
    }

    /**
     * Exportiert tree_entries als CSV-Datei, optional gefiltert nach root_path.
     *
     * @param {string|null} rootPathFilter Wenn angegeben, werden nur Einträge mit diesem
     *                                     root_path exportiert. null exportiert alle Einträge.
     * @returns {string|null} Pfad zur erzeugten CSV-Datei, oder null wenn keine Einträge vorhanden.
     */
    exportCsv(rootPathFilter = null) {
        const db = new sqlite3.Database(this.dbPath);
        let rows = [];
        let columnNames = [];

        let query;
        let params = [];
        
        if (rootPathFilter !== null) {
            query = "SELECT * FROM tree_entries WHERE root_path = ?";
            params = [rootPathFilter];
        } else {
            query = "SELECT * FROM tree_entries";
        }

        db.all(query, params, (err, result) => {
            if (err) {
                db.close();
                throw err;
            }
            
            if (result.length === 0) {
                logger.info("Keine Tree-Einträge vorhanden — kein CSV erzeugt");
                db.close();
                return null;
            }

            rows = result;
            columnNames = Object.keys(result[0]);

            const suffix = rootPathFilter !== null ? 
                `_${rootPathFilter.replace(/\//g, '_')}` : "_all";
            const csvPath = path.join(WORKSPACE, `export_tree${suffix}.csv`);
            
            // Erstelle CSV-Header
            let csvContent = columnNames.join(',') + '\n';
            
            // Füge Datenzeilen hinzu
            for (const row of rows) {
                const values = columnNames.map(col => {
                    const value = row[col];
                    // Escape und quote falls nötig
                    if (typeof value === 'string' && (value.includes(',') || value.includes('"') || value.includes('\n'))) {
                        return `"${value.replace(/"/g, '""')}"`;
                    }
                    return value;
                });
                csvContent += values.join(',') + '\n';
            }

            fs.writeFileSync(csvPath, csvContent, 'utf8');
            logger.info(`Tree-CSV exportiert: ${csvPath} (${rows.length} Einträge)`);
            db.close();
            return csvPath;
        });
    }
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

function main() {
    /**
     * Initialisiert docs.db und tree.db, befüllt docs.db und erzeugt Exporte.
     *
     * Legt DB_DIR an falls nicht vorhanden. Wird als Standalone-Script
     * oder einmalig zur Ersteinrichtung ausgeführt.
     */
    console.log("=".repeat(60));
    console.log("WORKSPACE DATABASE MANAGER");
    console.log("=".repeat(60));

    // DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    try {
        mkdirSyncRecursive(DB_DIR);
        logger.info(`DB-Verzeichnis: ${DB_DIR}`);
    } catch (exc) {
        logger.error(`DB-Verzeichnis konnte nicht erstellt werden: ${exc}`);
        process.exit(1);
    }

    // docs.db aufbauen
    const docsDb = new DocsDatabase();
    docsDb.initSchema();
    docsDb.populateFromWorkspace();

    // Exporte
    console.log("\n--- Exporte docs.db ---");
    for (const table of ["documents", "skills", "symlinks"]) {
        docsDb.exportCsv(table);
    }
    docsDb.exportJson("documents");

    // tree.db aufbauen (Daten kommen via tree.py)
    console.log("\n--- tree.db Initialisierung ---");
    const treeDb = new TreeDatabase();
    treeDb.initSchema();
    logger.info("Tree-Daten werden via tree.py Script befüllt");

    console.log("\n" + "=".repeat(60));
    console.log("DATENBANKEN BEREIT");
    console.log("=".repeat(60));
    console.log(`\nDatenbanken: ${DB_DIR}/`);
    console.log(`Exporte:     ${WORKSPACE}/`);
}

if (require.main === module) {
    main();
}

module.exports = {
    DocsDatabase,
    TreeDatabase,
    WORKSPACE,
    DB_DIR
};
