#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "847635aa1b92befdaa2cdfd790b05c224d406b82f46d82a63c1b6b0d43586649", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "lua"}
-- db_manager.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
-- auch in: OpenClaw@gateway2:scripts/db_manager.py
-- auch in: Projects@abstractions:abstractions/db_manager.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Workspace Documentation Database Manager

Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.

Verwendung:
    lua db_manager.lua

Konfiguration:
    OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
]]

local sqlite3 = require("lsqlite3")
local json = require("cjson")
local lfs = require("lfs")

-- ---------------------------------------------------------------------------
-- Konfiguration
-- ---------------------------------------------------------------------------

local function get_env_var(var, default)
    local value = os.getenv(var)
    return value or default
end

local WORKSPACE = get_env_var("OPENCLAW_WORKSPACE", "/home/openclaw/.openclaw/workspace")
local DB_DIR = WORKSPACE .. "/db"

-- Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
local _DOCS_EXPORT_TABLES = {
    documents = true,
    categories = true,
    symlinks = true,
    skills = true
}
local _TREE_EXPORT_TABLES = {
    tree_entries = true,
    tree_scans = true
}

-- ---------------------------------------------------------------------------
-- Logger
-- ---------------------------------------------------------------------------

local logger = {}
function logger.log(level, message, ...)
    local fmt_message = string.format(message, ...)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    print(string.format("%s | %-8s | db_manager | %s", timestamp, level:upper(), fmt_message))
end
logger.info = function(...) logger.log("INFO", ...) end
logger.error = function(...) logger.log("ERROR", ...) end

-- ---------------------------------------------------------------------------
-- Hilfsfunktionen
-- ---------------------------------------------------------------------------

local function mkdir_p(path)
    local dirs = {}
    local current = ""
    
    for dir in string.gmatch(path, "[^/]+") do
        current = current .. "/" .. dir
        table.insert(dirs, current)
    end
    
    for _, dir in ipairs(dirs) do
        local mode = lfs.attributes(dir, "mode")
        if mode == nil then
            local success, err = lfs.mkdir(dir)
            if not success and err ~= "File exists" then
                return false, err
            end
        elseif mode ~= "directory" then
            return false, "Path exists but is not a directory: " .. dir
        end
    end
    
    return true
end

local function write_file(path, content)
    local file, err = io.open(path, "w")
    if not file then
        return false, err
    end
    file:write(content)
    file:close()
    return true
end

-- ---------------------------------------------------------------------------
-- DocsDatabase
-- ---------------------------------------------------------------------------

local DocsDatabase = {}
DocsDatabase.__index = DocsDatabase

function DocsDatabase:new()
    local obj = {
        db_path = DB_DIR .. "/docs.db"
    }
    setmetatable(obj, DocsDatabase)
    return obj
end

function DocsDatabase:_get_connection()
    local conn = sqlite3.open(self.db_path)
    if not conn then
        error("Failed to open database connection")
    end
    return conn
end

function DocsDatabase:init_schema()
    local conn = self:_get_connection()
    
    conn:exec([[
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
    ]])
    
    conn:exec([[
        CREATE TABLE IF NOT EXISTS categories (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    UNIQUE NOT NULL,
            description TEXT,
            priority    INTEGER DEFAULT 0
        )
    ]])
    
    conn:exec([[
        CREATE TABLE IF NOT EXISTS symlinks (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            target      TEXT    NOT NULL,
            source_path TEXT    NOT NULL,
            description TEXT,
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    conn:exec([[
        CREATE TABLE IF NOT EXISTS skills (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL,
            version     TEXT,
            status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
            description TEXT,
            path        TEXT
        )
    ]])
    
    conn:close()
    logger.info("docs.db Schema initialisiert: %s", self.db_path)
    return self
end

function DocsDatabase:populate_from_workspace()
    local categories = {
        {"main",      "Hauptverzeichnis Dateien",        1},
        {"memory",    "Memory und Protokolle",           2},
        {"reports",   "Berichte und Analysen",           3},
        {"cluster",   "Cluster und Infrastruktur",       4},
        {"skills",    "Installierte Skills",             5},
        {"websearch", "WebSearch Dokumentationen",       6},
        {"mcp",       "MCP Integration",                 7},
        {"links",     "Symbolische Links",               8},
    }
    
    local docs = {
        {"AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  false, nil,                          "2026-04-11"},
        {"SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  false, nil,                          "2026-04-11"},
        {"IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  false, nil,                          "2026-04-11"},
        {"USER.md",               "/", "main", "Benutzerinformationen",                   "config",  false, nil,                          "2026-04-11"},
        {"TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  false, nil,                          "2026-04-18"},
        {"MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  false, nil,                          "2026-04-11"},
        {"DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     false, nil,                          "2026-04-18"},
        {"WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", true,  "DOCUMENTATION-INDEX.md",      "2026-04-18"},
        {"WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  true, "websearch/WEBSEARCH_README.md",          "2026-04-18"},
        {"WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  true, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18"},
        {"WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", true, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18"},
        {"WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"},
        {"WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", true, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18"},
        {"WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  true, "websearch/WEBSEARCH_OPS.md",             "2026-04-18"},
        {"MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",false,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18"},
    }
    
    local skills = {
        {"json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"},
        {"scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"},
        {"tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"},
        {"cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"},
        {"worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"},
        {"resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"},
        {"git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"},
    }
    
    local symlinks = {
        {"openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"},
        {"openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"},
        {"links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"},
        {"links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"},
        {"links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"},
        {"links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"},
        {"links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"},
    }
    
    local conn = self:_get_connection()
    
    -- Insert categories
    for _, cat in ipairs(categories) do
        conn:exec(string.format(
            "INSERT OR IGNORE INTO categories (name, description, priority) VALUES ('%s','%s',%d)",
            cat[1], cat[2], cat[3]
        ))
    end
    
    -- Insert documents
    for _, doc in ipairs(docs) do
        local symlink_path = doc[7] and "'" .. doc[7] .. "'" or "NULL"
        conn:exec(string.format(
            "INSERT OR REPLACE INTO documents (name, path, category, description, type, has_symlink, symlink_path, last_update) VALUES ('%s','%s','%s','%s','%s',%s,%s,'%s')",
            doc[1], doc[2], doc[3], doc[4], doc[5], tostring(doc[6]):upper(), symlink_path, doc[8]
        ))
    end
    
    -- Insert skills
    for _, skill in ipairs(skills) do
        conn:exec(string.format(
            "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES ('%s','%s','%s','%s','%s')",
            skill[1], skill[2], skill[3], skill[4], skill[5]
        ))
    end
    
    -- Insert symlinks
    for _, link in ipairs(symlinks) do
        conn:exec(string.format(
            "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES ('%s','%s','%s','%s')",
            link[1], link[2], link[3], link[4]
        ))
    end
    
    conn:close()
    logger.info(
        "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks",
        #docs, #skills, #symlinks
    )
    return self
end

function DocsDatabase:_validate_table_name(table, allowed)
    if not allowed[table] then
        error(string.format(
            "Ungültiger Tabellenname: '%s'. Erlaubt: {%s}",
            table, table.concat({}, ", ")
        ))
    end
end

function DocsDatabase:export_csv(table)
    self:_validate_table_name(table, _DOCS_EXPORT_TABLES)
    
    local conn = self:_get_connection()
    local stmt = conn:prepare(string.format("SELECT * FROM %s", table))
    local rows = {}
    local column_names = {}
    
    for row in stmt:nrows() do
        if #column_names == 0 then
            for k, _ in pairs(row) do
                table.insert(column_names, k)
            end
        end
        table.insert(rows, row)
    end
    
    stmt:finalize()
    conn:close()
    
    if #rows == 0 then
        logger.info("Tabelle '%s' ist leer — kein CSV erzeugt", table)
        return nil
    end
    
    local csv_content = table.concat(column_names, ",") .. "\n"
    for _, row in ipairs(rows) do
        local values = {}
        for _, col in ipairs(column_names) do
            table.insert(values, tostring(row[col] or ""))
        end
        csv_content = csv_content .. table.concat(values, ",") .. "\n"
    end
    
    local csv_path = WORKSPACE .. "/export_" .. table .. ".csv"
    local success, err = write_file(csv_path, csv_content)
    if not success then
        error("Fehler beim Schreiben der CSV-Datei: " .. err)
    end
    
    logger.info("CSV exportiert: %s (%d Zeilen)", csv_path, #rows)
    return csv_path
end

function DocsDatabase:export_json(table)
    self:_validate_table_name(table, _DOCS_EXPORT_TABLES)
    
    local conn = self:_get_connection()
    local stmt = conn:prepare(string.format("SELECT * FROM %s", table))
    local rows = {}
    
    for row in stmt:nrows() do
        table.insert(rows, row)
    end
    
    stmt:finalize()
    conn:close()
    
    if #rows == 0 then
        logger.info("Tabelle '%s' ist leer — kein JSON erzeugt", table)
        return nil
    end
    
    local json_data = json.encode(rows)
    local json_path = WORKSPACE .. "/export_" .. table .. ".json"
    
    local success, err = write_file(json_path, json_data)
    if not success then
        error("Fehler beim Schreiben der JSON-Datei: " .. err)
    end
    
    logger.info("JSON exportiert: %s (%d Einträge)", json_path, #rows)
    return json_path
end

-- ---------------------------------------------------------------------------
-- TreeDatabase
-- ---------------------------------------------------------------------------

local TreeDatabase = {}
TreeDatabase.__index = TreeDatabase

function TreeDatabase:new()
    local obj = {
        db_path = DB_DIR .. "/tree.db"
    }
    setmetatable(obj, TreeDatabase)
    return obj
end

function TreeDatabase:_get_connection()
    local conn = sqlite3.open(self.db_path)
    if not conn then
        error("Failed to open database connection")
    end
    return conn
end

function TreeDatabase:init_schema()
    local conn = self:_get_connection()
    
    conn:exec([[
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
    ]])
    
    conn:exec([[
        CREATE TABLE IF NOT EXISTS tree_scans (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            root_path      TEXT    NOT NULL,
            max_depth      INTEGER,
            total_files    INTEGER,
            total_dirs     INTEGER,
            total_symlinks INTEGER,
            scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ]])
    
    conn:close()
    logger.info("tree.db Schema initialisiert: %s", self.db_path)
    return self
end

function TreeDatabase:add_entry(root_path, relative_path, name, entry_type, depth, parent_path, size)
    size = size or 0
    
    local conn = self:_get_connection()
    local stmt = conn:prepare([[
        INSERT INTO tree_entries
        (root_path, relative_path, name, type, depth, parent_path, size)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ]])
    
    stmt:bind_values(root_path, relative_path, name, entry_type, depth, parent_path, size)
    stmt:step()
    stmt:finalize()
    conn:close()
end

function TreeDatabase:export_csv(root_path_filter)
    local conn = self:_get_connection()
    local stmt
    
    if root_path_filter then
        stmt = conn:prepare("SELECT * FROM tree_entries WHERE root_path = ?")
        stmt:bind_values(root_path_filter)
    else
        stmt = conn:prepare("SELECT * FROM tree_entries")
    end
    
    local rows = {}
    local column_names = {}
    
    for row in stmt:nrows() do
        if #column_names == 0 then
            for k, _ in pairs(row) do
                table.insert(column_names, k)
            end
        end
        table.insert(rows, row)
    end
    
    stmt:finalize()
    conn:close()
    
    if #rows == 0 then
        logger.info("Keine Tree-Einträge vorhanden — kein CSV erzeugt")
        return nil
    end
    
    local csv_content = table.concat(column_names, ",") .. "\n"
    for _, row in ipairs(rows) do
        local values = {}
        for _, col in ipairs(column_names) do
            table.insert(values, tostring(row[col] or ""))
        end
        csv_content = csv_content .. table.concat(values, ",") .. "\n"
    end
    
    local suffix = root_path_filter and "_" .. string.gsub(root_path_filter, "/", "_") or "_all"
    local csv_path = WORKSPACE .. "/export_tree" .. suffix .. ".csv"
    
    local success, err = write_file(csv_path, csv_content)
    if not success then
        error("Fehler beim Schreiben der CSV-Datei: " .. err)
    end
    
    logger.info("Tree-CSV exportiert: %s (%d Einträge)", csv_path, #rows)
    return csv_path
end

-- ---------------------------------------------------------------------------
-- Einstiegspunkt
-- ---------------------------------------------------------------------------

local function main()
    print("=" .. string.rep("-", 59))
    print("WORKSPACE DATABASE MANAGER")
    print("=" .. string.rep("-", 59))
    
    -- DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    local success, err = mkdir_p(DB_DIR)
    if not success then
        logger.error("DB-Verzeichnis konnte nicht erstellt werden: %s", err)
        os.exit(1)
    end
    logger.info("DB-Verzeichnis: %s", DB_DIR)
    
    -- docs.db aufbauen
    local docs_db = DocsDatabase:new()
    docs_db:init_schema()
    docs_db:populate_from_workspace()
    
    -- Exporte
    print("\n--- Exporte docs.db ---")
    for _, table in ipairs({"documents", "skills", "symlinks"}) do
        docs_db:export_csv(table)
    end
    docs_db:export_json("documents")
    
    -- tree.db aufbauen (Daten kommen via tree.py Script)
    print("\n--- tree.db Initialisierung ---")
    local tree_db = TreeDatabase:new()
    tree_db:init_schema()
    logger.info("Tree-Daten werden via tree.py Script befüllt")
    
    print("\n" .. "=" .. string.rep("-", 59))
    print("DATENBANKEN BEREIT")
    print("=" .. string.rep("-", 59))
    print("\nDatenbanken: " .. DB_DIR .. "/")
    print("Exporte:     " .. WORKSPACE .. "/")
end

main()
