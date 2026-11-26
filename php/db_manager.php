<?php
// abstraction-provenance: {"artifact_sha256": "58bd297968f836a0e13edc92f696a91adbb8e09a5609879e4d1a8086ac3e28ff", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "php"}
// db_manager.py — portiert nach php
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
 *     php db_manager.php
 *
 * Konfiguration:
 *     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
 */

// ---------------------------------------------------------------------------
// Konfiguration
// ---------------------------------------------------------------------------

$WORKSPACE = getenv("OPENCLAW_WORKSPACE") ?: "/home/openclaw/.openclaw/workspace";
$DB_DIR = $WORKSPACE . "/db";

// Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
$_DOCS_EXPORT_TABLES = ["documents", "categories", "symlinks", "skills"];
$_TREE_EXPORT_TABLES = ["tree_entries", "tree_scans"];

// ---------------------------------------------------------------------------
// Logger
// ---------------------------------------------------------------------------

class Logger {
    private $name;
    
    public function __construct($name) {
        $this->name = $name;
    }
    
    private function log($level, $message, $context = []) {
        $timestamp = date("Y-m-d H:i:s");
        $formatted_message = vsprintf($message, $context);
        echo sprintf("%s | %-8s | %s | %s\n", $timestamp, strtoupper($level), $this->name, $formatted_message);
    }
    
    public function info($message, $context = []) {
        $this->log("info", $message, $context);
    }
    
    public function error($message, $context = []) {
        $this->log("error", $message, $context);
    }
}

$logger = new Logger("db_manager");

// ---------------------------------------------------------------------------
// DocsDatabase
// ---------------------------------------------------------------------------

class DocsDatabase {
    private $db_path;
    private $logger;
    
    /**
     * Initialisiert DocsDatabase mit dem Standard-Datenbankpfad.
     */
    public function __construct() {
        global $DB_DIR, $logger;
        $this->db_path = $DB_DIR . "/docs.db";
        $this->logger = $logger;
    }
    
    /**
     * Erstellt die Tabellenstruktur in docs.db falls noch nicht vorhanden.
     *
     * Tabellen: documents, categories, symlinks, skills.
     * Bestehende Tabellen werden nicht verändert (CREATE TABLE IF NOT EXISTS).
     *
     * @return DocsDatabase self für Method-Chaining.
     */
    public function initSchema() {
        $conn = new SQLite3($this->db_path);
        $conn->exec("PRAGMA foreign_keys = ON;");
        
        $conn->exec("
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
        ");
        
        $conn->exec("
            CREATE TABLE IF NOT EXISTS categories (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    UNIQUE NOT NULL,
                description TEXT,
                priority    INTEGER DEFAULT 0
            )
        ");
        
        $conn->exec("
            CREATE TABLE IF NOT EXISTS symlinks (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                target      TEXT    NOT NULL,
                source_path TEXT    NOT NULL,
                description TEXT,
                created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ");
        
        $conn->exec("
            CREATE TABLE IF NOT EXISTS skills (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                name        TEXT    NOT NULL,
                version     TEXT,
                status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                description TEXT,
                path        TEXT
            )
        ");
        
        $conn->close();
        
        $this->logger->info("docs.db Schema initialisiert: %s", [$this->db_path]);
        return $this;
    }
    
    /**
     * Befüllt docs.db mit bekannten Workspace-Dokumenten, Skills und Symlinks.
     *
     * Verwendet INSERT OR IGNORE / INSERT OR REPLACE, sodass ein erneuter
     * Aufruf idempotent ist.
     *
     * @return DocsDatabase self für Method-Chaining.
     */
    public function populateFromWorkspace() {
        $categories = [
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
        $docs = [
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
        
        $skills = [
            ["json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"],
            ["scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"],
            ["tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"],
            ["cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"],
            ["worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"],
            ["resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"],
            ["git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"],
        ];
        
        $symlinks = [
            ["openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"],
            ["openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"],
            ["links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"],
            ["links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"],
            ["links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"],
            ["links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"],
            ["links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"],
        ];
        
        $conn = new SQLite3($this->db_path);
        
        foreach ($categories as $category) {
            $stmt = $conn->prepare("INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)");
            $stmt->bindValue(1, $category[0], SQLITE3_TEXT);
            $stmt->bindValue(2, $category[1], SQLITE3_TEXT);
            $stmt->bindValue(3, $category[2], SQLITE3_INTEGER);
            $stmt->execute();
        }
        
        foreach ($docs as $doc) {
            $stmt = $conn->prepare("
                INSERT OR REPLACE INTO documents
                (name, path, category, description, type, has_symlink, symlink_path, last_update)
                VALUES (?,?,?,?,?,?,?,?)
            ");
            $stmt->bindValue(1, $doc[0], SQLITE3_TEXT);
            $stmt->bindValue(2, $doc[1], SQLITE3_TEXT);
            $stmt->bindValue(3, $doc[2], SQLITE3_TEXT);
            $stmt->bindValue(4, $doc[3], SQLITE3_TEXT);
            $stmt->bindValue(5, $doc[4], SQLITE3_TEXT);
            $stmt->bindValue(6, $doc[5], SQLITE3_BOOLEAN);
            $stmt->bindValue(7, $doc[6], SQLITE3_TEXT);
            $stmt->bindValue(8, $doc[7], SQLITE3_TEXT);
            $stmt->execute();
        }
        
        foreach ($skills as $skill) {
            $stmt = $conn->prepare("
                INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)
            ");
            $stmt->bindValue(1, $skill[0], SQLITE3_TEXT);
            $stmt->bindValue(2, $skill[1], SQLITE3_TEXT);
            $stmt->bindValue(3, $skill[2], SQLITE3_TEXT);
            $stmt->bindValue(4, $skill[3], SQLITE3_TEXT);
            $stmt->bindValue(5, $skill[4], SQLITE3_TEXT);
            $stmt->execute();
        }
        
        foreach ($symlinks as $symlink) {
            $stmt = $conn->prepare("
                INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)
            ");
            $stmt->bindValue(1, $symlink[0], SQLITE3_TEXT);
            $stmt->bindValue(2, $symlink[1], SQLITE3_TEXT);
            $stmt->bindValue(3, $symlink[2], SQLITE3_TEXT);
            $stmt->bindValue(4, $symlink[3], SQLITE3_TEXT);
            $stmt->execute();
        }
        
        $conn->close();
        
        $this->logger->info(
            "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks",
            [count($docs), count($skills), count($symlinks)]
        );
        return $this;
    }
    
    /**
     * Prüft ob der Tabellenname in der Allowlist enthalten ist.
     *
     * Verhindert SQL-Injection durch direkte Tabellennamen-Interpolation.
     *
     * @param string $table   Zu prüfender Tabellenname.
     * @param array  $allowed Menge erlaubter Tabellennamen.
     *
     * @throws Exception Wenn der Tabellenname nicht erlaubt ist.
     */
    private function validateTableName($table, $allowed) {
        if (!in_array($table, $allowed)) {
            throw new Exception(
                "Ungültiger Tabellenname: '$table'. " .
                "Erlaubt: [" . implode(", ", $allowed) . "]"
            );
        }
    }
    
    /**
     * Exportiert eine Tabelle aus docs.db als CSV-Datei in den Workspace-Root.
     *
     * @param string $table Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     *
     * @return string|null Path zur erzeugten CSV-Datei, oder null wenn die Tabelle leer ist.
     */
    public function exportCsv($table) {
        global $_DOCS_EXPORT_TABLES, $WORKSPACE;
        
        $this->validateTableName($table, $_DOCS_EXPORT_TABLES);
        
        $conn = new SQLite3($this->db_path);
        $result = $conn->query("SELECT * FROM " . $table);
        
        $rows = [];
        $column_names = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            if (empty($column_names)) {
                $column_names = array_keys($row);
            }
            $rows[] = $row;
        }
        
        $conn->close();
        
        if (empty($rows)) {
            $this->logger->info("Tabelle '%s' ist leer — kein CSV erzeugt", [$table]);
            return null;
        }
        
        $csv_path = $WORKSPACE . "/export_" . $table . ".csv";
        $fh = fopen($csv_path, "w");
        fputcsv($fh, $column_names);
        
        foreach ($rows as $row) {
            fputcsv($fh, array_values($row));
        }
        
        fclose($fh);
        
        $this->logger->info("CSV exportiert: %s (%d Zeilen)", [$csv_path, count($rows)]);
        return $csv_path;
    }
    
    /**
     * Exportiert eine Tabelle aus docs.db als JSON-Datei in den Workspace-Root.
     *
     * @param string $table Tabellenname — muss in {'documents', 'categories', 'symlinks', 'skills'} sein.
     *
     * @return string|null Path zur erzeugten JSON-Datei, oder null wenn die Tabelle leer ist.
     */
    public function exportJson($table) {
        global $_DOCS_EXPORT_TABLES, $WORKSPACE;
        
        $this->validateTableName($table, $_DOCS_EXPORT_TABLES);
        
        $conn = new SQLite3($this->db_path);
        $result = $conn->query("SELECT * FROM " . $table);
        
        $rows = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            $rows[] = $row;
        }
        
        $conn->close();
        
        if (empty($rows)) {
            $this->logger->info("Tabelle '%s' ist leer — kein JSON erzeugt", [$table]);
            return null;
        }
        
        $data = [];
        foreach ($rows as $row) {
            $data[] = $row;
        }
        
        $json_path = $WORKSPACE . "/export_" . $table . ".json";
        file_put_contents($json_path, json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
        
        $this->logger->info("JSON exportiert: %s (%d Einträge)", [$json_path, count($data)]);
        return $json_path;
    }
}

// ---------------------------------------------------------------------------
// TreeDatabase
// ---------------------------------------------------------------------------

class TreeDatabase {
    private $db_path;
    private $logger;
    
    /**
     * Initialisiert TreeDatabase mit dem Standard-Datenbankpfad.
     */
    public function __construct() {
        global $DB_DIR, $logger;
        $this->db_path = $DB_DIR . "/tree.db";
        $this->logger = $logger;
    }
    
    /**
     * Erstellt die Tabellenstruktur in tree.db falls noch nicht vorhanden.
     *
     * Tabellen: tree_entries, tree_scans.
     *
     * @return TreeDatabase self für Method-Chaining.
     */
    public function initSchema() {
        $conn = new SQLite3($this->db_path);
        $conn->exec("PRAGMA foreign_keys = ON;");
        
        $conn->exec("
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
        ");
        
        $conn->exec("
            CREATE TABLE IF NOT EXISTS tree_scans (
                id             INTEGER PRIMARY KEY AUTOINCREMENT,
                root_path      TEXT    NOT NULL,
                max_depth      INTEGER,
                total_files    INTEGER,
                total_dirs     INTEGER,
                total_symlinks INTEGER,
                scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ");
        
        $conn->close();
        
        $this->logger->info("tree.db Schema initialisiert: %s", [$this->db_path]);
        return $this;
    }
    
    /**
     * Fügt einen einzelnen Verzeichnisbaum-Eintrag in tree_entries ein.
     *
     * @param string $root_path     Absoluter Pfad des Scan-Wurzelverzeichnisses.
     * @param string $relative_path Pfad relativ zu root_path.
     * @param string $name          Datei- oder Verzeichnisname.
     * @param string $entry_type    'file', 'directory' oder 'symlink'.
     * @param int    $depth         Verschachtelungstiefe (0 = root).
     * @param string $parent_path   Relativer Pfad des Elternverzeichnisses.
     * @param int    $size          Dateigröße in Bytes (0 für Verzeichnisse).
     */
    public function addEntry($root_path, $relative_path, $name, $entry_type, $depth, $parent_path, $size = 0) {
        $conn = new SQLite3($this->db_path);
        $stmt = $conn->prepare("
            INSERT INTO tree_entries
            (root_path, relative_path, name, type, depth, parent_path, size)
            VALUES (?,?,?,?,?,?,?)
        ");
        $stmt->bindValue(1, $root_path, SQLITE3_TEXT);
        $stmt->bindValue(2, $relative_path, SQLITE3_TEXT);
        $stmt->bindValue(3, $name, SQLITE3_TEXT);
        $stmt->bindValue(4, $entry_type, SQLITE3_TEXT);
        $stmt->bindValue(5, $depth, SQLITE3_INTEGER);
        $stmt->bindValue(6, $parent_path, SQLITE3_TEXT);
        $stmt->bindValue(7, $size, SQLITE3_INTEGER);
        $stmt->execute();
        $conn->close();
    }
    
    /**
     * Exportiert tree_entries als CSV-Datei, optional gefiltert nach root_path.
     *
     * @param string|null $root_path_filter Wenn angegeben, werden nur Einträge mit diesem
     *                                       root_path exportiert. null exportiert alle Einträge.
     *
     * @return string|null Path zur erzeugten CSV-Datei, oder null wenn keine Einträge vorhanden.
     */
    public function exportCsv($root_path_filter = null) {
        global $WORKSPACE;
        
        $conn = new SQLite3($this->db_path);
        
        if ($root_path_filter !== null) {
            $stmt = $conn->prepare("SELECT * FROM tree_entries WHERE root_path = ?");
            $stmt->bindValue(1, $root_path_filter, SQLITE3_TEXT);
            $result = $stmt->execute();
        } else {
            $result = $conn->query("SELECT * FROM tree_entries");
        }
        
        $rows = [];
        $column_names = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            if (empty($column_names)) {
                $column_names = array_keys($row);
            }
            $rows[] = $row;
        }
        
        $conn->close();
        
        if (empty($rows)) {
            $this->logger->info("Keine Tree-Einträge vorhanden — kein CSV erzeugt");
            return null;
        }
        
        $suffix = $root_path_filter !== null ? "_" . str_replace("/", "_", $root_path_filter) : "_all";
        $csv_path = $WORKSPACE . "/export_tree" . $suffix . ".csv";
        
        $fh = fopen($csv_path, "w");
        fputcsv($fh, $column_names);
        
        foreach ($rows as $row) {
            fputcsv($fh, array_values($row));
        }
        
        fclose($fh);
        
        $this->logger->info("Tree-CSV exportiert: %s (%d Einträge)", [$csv_path, count($rows)]);
        return $csv_path;
    }
}

// ---------------------------------------------------------------------------
// Einstiegspunkt
// ---------------------------------------------------------------------------

function main() {
    global $DB_DIR, $logger;
    
    echo str_repeat("=", 60) . "\n";
    echo "WORKSPACE DATABASE MANAGER\n";
    echo str_repeat("=", 60) . "\n";
    
    // DB-Verzeichnis hier (nicht auf Modulebene) anlegen
    try {
        if (!is_dir($DB_DIR)) {
            mkdir($DB_DIR, 0777, true);
        }
        $logger->info("DB-Verzeichnis: %s", [$DB_DIR]);
    } catch (Exception $exc) {
        $logger->error("DB-Verzeichnis konnte nicht erstellt werden: %s", [$exc->getMessage()]);
        exit(1);
    }
    
    // docs.db aufbauen
    $docs_db = new DocsDatabase();
    $docs_db->initSchema();
    $docs_db->populateFromWorkspace();
    
    // Exporte
    echo "\n--- Exporte docs.db ---\n";
    foreach (["documents", "skills", "symlinks"] as $table) {
        $docs_db->exportCsv($table);
    }
    $docs_db->exportJson("documents");
    
    // tree.db aufbauen (Daten kommen via tree.py)
    echo "\n--- tree.db Initialisierung ---\n";
    $tree_db = new TreeDatabase();
    $tree_db->initSchema();
    $logger->info("Tree-Daten werden via tree.py Script befüllt");
    
    echo "\n" . str_repeat("=", 60) . "\n";
    echo "DATENBANKEN BEREIT\n";
    echo str_repeat("=", 60) . "\n";
    echo "\nDatenbanken: " . $DB_DIR . "/\n";
    echo "Exporte:     " . dirname($DB_DIR) . "/\n";
}

main();
?>
