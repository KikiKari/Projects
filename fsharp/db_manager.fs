// abstraction-provenance: {"artifact_sha256": "422065daa76dd0c7ae525c1171822224d0a02a80f2d14defcb49b85bad58908c", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "fsharp"}
// db_manager.py — portiert nach fsharp
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Workspace Documentation Database Manager
//
// Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
// Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
//
// Verwendung:
//     dotnet run
//
// Konfiguration:
//     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace

open System
open System.Data.SQLite
open System.IO
open System.Collections.Generic
open Newtonsoft.Json

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

let WORKSPACE = 
    match Environment.GetEnvironmentVariable("OPENCLAW_WORKSPACE") with
    | null -> Path.Combine("/home/openclaw/.openclaw/workspace")
    | path -> path
    |> Path.GetFullPath

let DB_DIR = Path.Combine(WORKSPACE, "db")

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
let _DOCS_EXPORT_TABLES = set ["documents"; "categories"; "symlinks"; "skills"]
let _TREE_EXPORT_TABLES = set ["tree_entries"; "tree_scans"]

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

type LogLevel = 
    | Info 
    | Warning 
    | Error

module Logger =
    let private formatTime () = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss")
    
    let log level (name: string) (message: string) =
        let levelStr = 
            match level with
            | Info -> "INFO    "
            | Warning -> "WARNING "
            | Error -> "ERROR   "
        
        printfn "%s | %s | %s | %s" (formatTime()) levelStr name message
    
    let info name message = log Info name message
    let warning name message = log Warning name message
    let error name message = log Error name message

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

let private executeNonQuery (connection: SQLiteConnection) (sql: string) (parameters: obj array) =
    use cmd = new SQLiteCommand(sql, connection)
    if parameters <> null then
        cmd.Parameters.AddRange(parameters)
    cmd.ExecuteNonQuery() |> ignore

let private executeQuery (connection: SQLiteConnection) (sql: string) (parameters: obj array) =
    use cmd = new SQLiteCommand(sql, connection)
    if parameters <> null then
        cmd.Parameters.AddRange(parameters)
    use reader = cmd.ExecuteReader()
    let mutable results = []
    while reader.Read() do
        let row = dict []
        for i in 0 .. reader.FieldCount - 1 do
            row.[reader.GetName(i)] <- reader.GetValue(i)
        results <- row :: results
    List.rev results

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

type DocsDatabase() =
    let dbPath = Path.Combine(DB_DIR, "docs.db")
    
    member private this.GetConnection() =
        let conn = new SQLiteConnection(sprintf "Data Source=%s;Version=3;" dbPath)
        conn.Open()
        conn
    
    member this.InitSchema() =
        use conn = this.GetConnection()
        
        let createDocuments = """
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
        """
        
        let createCategories = """
            CREATE TABLE IF NOT EXISTS categories (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    UNIQUE NOT NULL,
                description TEXT,
                priority    INTEGER DEFAULT 0
            )
        """
        
        let createSymlinks = """
            CREATE TABLE IF NOT EXISTS symlinks (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                target      TEXT    NOT NULL,
                source_path TEXT    NOT NULL,
                description TEXT,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        
        let createSkills = """
            CREATE TABLE IF NOT EXISTS skills (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                version     TEXT,
                status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                description TEXT,
                path        TEXT
            )
        """
        
        executeNonQuery conn createDocuments null
        executeNonQuery conn createCategories null
        executeNonQuery conn createSymlinks null
        executeNonQuery conn createSkills null
        
        Logger.info "db_manager" (sprintf "docs.db Schema initialisiert: %s" dbPath)
        this
    
    member this.PopulateFromWorkspace() =
        let categories = [
            ("main",      "Hauptverzeichnis Dateien",        1)
            ("memory",    "Memory und Protokolle",           2)
            ("reports",   "Berichte und Analysen",           3)
            ("cluster",   "Cluster und Infrastruktur",       4)
            ("skills",    "Installierte Skills",             5)
            ("websearch", "WebSearch Dokumentationen",       6)
            ("mcp",       "MCP Integration",                 7)
            ("links",     "Symbolische Links",               8)
        ]
        
        let docs = [
            ("AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  false, null,                          "2026-04-11")
            ("SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  false, null,                          "2026-04-11")
            ("IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  false, null,                          "2026-04-11")
            ("USER.md",               "/", "main", "Benutzerinformationen",                   "config",  false, null,                          "2026-04-11")
            ("TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  false, null,                          "2026-04-18")
            ("MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  false, null,                          "2026-04-11")
            ("DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     false, null,                          "2026-04-18")
            ("WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", true,  "DOCUMENTATION-INDEX.md",      "2026-04-18")
            ("WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  true, "websearch/WEBSEARCH_README.md",          "2026-04-18")
            ("WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  true, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18")
            ("WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", true, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18")
            ("WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18")
            ("WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", true, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18")
            ("WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  true, "websearch/WEBSEARCH_OPS.md",             "2026-04-18")
            ("MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",false,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18")
        ]
        
        let skills = [
            ("json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/")
            ("scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/")
            ("tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/")
            ("cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/")
            ("worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/")
            ("resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/")
            ("git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/")
        ]
        
        let symlinks = [
            ("openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut")
            ("openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut")
            ("links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys")
            ("links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config")
            ("links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config")
            ("links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config")
            ("links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys")
        ]
        
        use conn = this.GetConnection()
        
        // Insert categories
        for (name, description, priority) in categories do
            executeNonQuery conn 
                "INSERT OR IGNORE INTO categories (name, description, priority) VALUES (@name, @description, @priority)" 
                [| box name; box description; box priority |]
        
        // Insert documents
        for (name, path, category, description, ``type``, has_symlink, symlink_path, last_update) in docs do
            executeNonQuery conn """
                INSERT OR REPLACE INTO documents 
                (name, path, category, description, type, has_symlink, symlink_path, last_update) 
                VALUES (@name, @path, @category, @description, @type, @has_symlink, @symlink_path, @last_update)""" 
                [| box name; box path; box category; box description; box ``type``; box has_symlink; 
                   (if symlink_path = null then box DBNull.Value else box symlink_path); box last_update |]
        
        // Insert skills
        for (name, version, status, description, path) in skills do
            executeNonQuery conn 
                "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (@name, @version, @status, @description, @path)" 
                [| box name; box version; box status; box description; box path |]
        
        // Insert symlinks
        for (name, target, source_path, description) in symlinks do
            executeNonQuery conn 
                "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (@name, @target, @source_path, @description)" 
                [| box name; box target; box source_path; box description |]
        
        Logger.info "db_manager" 
            (sprintf "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks" 
                docs.Length skills.Length symlinks.Length)
        this
    
    member private this.ValidateTableName(table: string, allowed: Set<string>) =
        if not (allowed.Contains(table)) then
            failwithf "Ungültiger Tabellenname: '%s'. Erlaubt: %A" table (Set.toArray allowed)
    
    member this.ExportCsv(table: string) =
        this.ValidateTableName(table, _DOCS_EXPORT_TABLES)
        
        use conn = this.GetConnection()
        let sql = sprintf "SELECT * FROM %s" table
        let results = executeQuery conn sql null
        
        if List.isEmpty results then
            Logger.info "db_manager" (sprintf "Tabelle '%s' ist leer — kein CSV erzeugt" table)
            None
        else
            let csvPath = Path.Combine(WORKSPACE, sprintf "export_%s.csv" table)
            use writer = new StreamWriter(csvPath, false, Text.Encoding.UTF8)
            
            // Write header
            let headers = results.Head.Keys |> Seq.toArray
            writer.WriteLine(String.concat "," headers)
            
            // Write data
            for row in results do
                let values = headers |> Array.map (fun key -> 
                    match row.TryGetValue(key) with
                    | (true, value) -> 
                        if value = null || value = box DBNull.Value then ""
                        else value.ToString().Replace(",", "\\,") // Simple escaping
                    | _ -> "")
                writer.WriteLine(String.concat "," values)
            
            Logger.info "db_manager" (sprintf "CSV exportiert: %s (%d Zeilen)" csvPath results.Length)
            Some csvPath
    
    member this.ExportJson(table: string) =
        this.ValidateTableName(table, _DOCS_EXPORT_TABLES)
        
        use conn = this.GetConnection()
        let sql = sprintf "SELECT * FROM %s" table
        let results = executeQuery conn sql null
        
        if List.isEmpty results then
            Logger.info "db_manager" (sprintf "Tabelle '%s' ist leer — kein JSON erzeugt" table)
            None
        else
            let jsonPath = Path.Combine(WORKSPACE, sprintf "export_%s.json" table)
            let json = JsonConvert.SerializeObject(results, Formatting.Indented)
            File.WriteAllText(jsonPath, json, Text.Encoding.UTF8)
            
            Logger.info "db_manager" (sprintf "JSON exportiert: %s (%d Einträge)" jsonPath results.Length)
            Some jsonPath

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

type TreeDatabase() =
    let dbPath = Path.Combine(DB_DIR, "tree.db")
    
    member private this.GetConnection() =
        let conn = new SQLiteConnection(sprintf "Data Source=%s;Version=3;" dbPath)
        conn.Open()
        conn
    
    member this.InitSchema() =
        use conn = this.GetConnection()
        
        let createTreeEntries = """
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
        """
        
        let createTreeScans = """
            CREATE TABLE IF NOT EXISTS tree_scans (
                id             INTEGER PRIMARY KEY AUTOINCREMENT,
                root_path      TEXT    NOT NULL,
                max_depth      INTEGER,
                total_files    INTEGER,
                total_dirs     INTEGER,
                total_symlinks INTEGER,
                scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """
        
        executeNonQuery conn createTreeEntries null
        executeNonQuery conn createTreeScans null
        
        Logger.info "db_manager" (sprintf "tree.db Schema initialisiert: %s" dbPath)
        this
    
    member this.AddEntry(root_path: string, relative_path: string, name: string, 
                         entry_type: string, depth: int, parent_path: string, size: int) =
        use conn = this.GetConnection()
        executeNonQuery conn """
            INSERT INTO tree_entries 
            (root_path, relative_path, name, type, depth, parent_path, size) 
            VALUES (@root_path, @relative_path, @name, @type, @depth, @parent_path, @size)""" 
            [| box root_path; box relative_path; box name; box entry_type; box depth; box parent_path; box size |]
    
    member this.ExportCsv(rootPathFilter: string option) =
        use conn = this.GetConnection()
        
        let results = 
            match rootPathFilter with
            | Some filter -> executeQuery conn "SELECT * FROM tree_entries WHERE root_path = @filter" [| box filter |]
            | None -> executeQuery conn "SELECT * FROM tree_entries" null
        
        if List.isEmpty results then
            Logger.info "db_manager" "Keine Tree-Einträge vorhanden — kein CSV erzeugt"
            None
        else
            let suffix = 
                match rootPathFilter with
                | Some path -> sprintf "_%s" (path.Replace("/", "_"))
                | None -> "_all"
            
            let csvPath = Path.Combine(WORKSPACE, sprintf "export_tree%s.csv" suffix)
            use writer = new StreamWriter(csvPath, false, Text.Encoding.UTF8)
            
            // Write header
            let headers = results.Head.Keys |> Seq.toArray
            writer.WriteLine(String.concat "," headers)
            
            // Write data
            for row in results do
                let values = headers |> Array.map (fun key -> 
                    match row.TryGetValue(key) with
                    | (true, value) -> 
                        if value = null || value = box DBNull.Value then ""
                        else value.ToString().Replace(",", "\\,") // Simple escaping
                    | _ -> "")
                writer.WriteLine(String.concat "," values)
            
            Logger.info "db_manager" (sprintf "Tree-CSV exportiert: %s (%d Einträge)" csvPath results.Length)
            Some csvPath

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

let main() =
    printfn "%s" (String.replicate 60 "=")
    printfn "WORKSPACE DATABASE MANAGER"
    printfn "%s" (String.replicate 60 "=")
    
    // DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    try
        Directory.CreateDirectory(DB_DIR) |> ignore
        Logger.info "db_manager" (sprintf "DB-Verzeichnis: %s" DB_DIR)
    with
    | ex ->
        Logger.error "db_manager" (sprintf "DB-Verzeichnis konnte nicht erstellt werden: %s" ex.Message)
        exit 1
    
    // docs.db aufbauen
    let docsDb = DocsDatabase()
    docsDb.InitSchema() |> ignore
    docsDb.PopulateFromWorkspace() |> ignore
    
    // Exporte
    printfn "\n--- Exporte docs.db ---"
    for table in ["documents"; "skills"; "symlinks"] do
        docsDb.ExportCsv(table) |> ignore
    docsDb.ExportJson("documents") |> ignore
    
    // tree.db aufbauen (Daten kommen via tree.py)
    printfn "\n--- tree.db Initialisierung ---"
    let treeDb = TreeDatabase()
    treeDb.InitSchema() |> ignore
    Logger.info "db_manager" "Tree-Daten werden via tree.py Script befüllt"
    
    printfn "\n%s" (String.replicate 60 "=")
    printfn "DATENBANKEN BEREIT"
    printfn "%s" (String.replicate 60 "=")
    printfn "\nDatenbanken: %s/" DB_DIR
    printfn "Exporte:     %s/" WORKSPACE

[<EntryPoint>]
let entryPoint argv =
    main()
    0
