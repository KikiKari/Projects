// abstraction-provenance: {"artifact_sha256": "85e607657e61359b2b72be04be7a15cf0d72556a38c369ef2ecefc4a37448ae0", "source_sha256": "62685d1bad45f2dffb79d4424a8a668a222d4008e157a9d6b51a3e2a1d1d204d", "target_language": "java"}
// db_manager.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:scripts/db_manager.py
// auch in: OpenClaw@gateway2:scripts/db_manager.py
// auch in: Projects@abstractions:abstractions/db_manager.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Workspace Documentation Database Manager
 *
 * Erstellt und verwaltet docs.db und tree.db im Workspace-Datenbankverzeichnis.
 * Beide Datenbanken liegen unter $OPENCLAW_WORKSPACE/db/.
 *
 * Verwendung:
 *     java DbManager
 *
 * Konfiguration:
 *     OPENCLAW_WORKSPACE (Umgebungsvariable) — Standard: /home/openclaw/.openclaw/workspace
 */
public class DbManager {
    // ---------------------------------------------------------------------------
    // Konfiguration
    // ---------------------------------------------------------------------------
    
    private static final Path WORKSPACE = Paths.get(
        System.getenv().getOrDefault("OPENCLAW_WORKSPACE", 
        "/home/openclaw/.openclaw/workspace"));
    private static final Path DB_DIR = WORKSPACE.resolve("db");
    
    // Erlaubte Tabellennamen für Export-Methoden (verhindert SQL-Injection)
    private static final Set<String> DOCS_EXPORT_TABLES = Set.of("documents", "categories", "symlinks", "skills");
    private static final Set<String> TREE_EXPORT_TABLES = Set.of("tree_entries", "tree_scans");
    
    // ---------------------------------------------------------------------------
    // Logger
    // ---------------------------------------------------------------------------
    
    private static final Logger logger = Logger.getLogger(DbManager.class.getName());
    
    static {
        System.setProperty("java.util.logging.SimpleFormatter.format", 
            "%1$tF %1$tT | %-8s | %2$s | %4$s%n");
        logger.setLevel(Level.INFO);
    }
    
    // ---------------------------------------------------------------------------
    // DocsDatabase
    // ---------------------------------------------------------------------------
    
    public static class DocsDatabase {
        private final Path dbPath;
        
        public DocsDatabase() {
            this.dbPath = DB_DIR.resolve("docs.db");
        }
        
        private Connection getConnection() throws SQLException {
            Connection conn = DriverManager.getConnection("jdbc:sqlite:" + dbPath.toString());
            conn.createStatement().execute("PRAGMA foreign_keys = ON");
            return conn;
        }
        
        public DocsDatabase initSchema() throws SQLException {
            try (Connection conn = getConnection()) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute("""
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
                        """);
                    
                    stmt.execute("""
                        CREATE TABLE IF NOT EXISTS categories (
                            id          INTEGER PRIMARY KEY AUTOINCREMENT,
                            name        TEXT    UNIQUE NOT NULL,
                            description TEXT,
                            priority    INTEGER DEFAULT 0
                        )
                        """);
                    
                    stmt.execute("""
                        CREATE TABLE IF NOT EXISTS symlinks (
                            id          INTEGER PRIMARY KEY AUTOINCREMENT,
                            name        TEXT    NOT NULL,
                            target      TEXT    NOT NULL,
                            source_path TEXT    NOT NULL,
                            description TEXT,
                            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                        """);
                    
                    stmt.execute("""
                        CREATE TABLE IF NOT EXISTS skills (
                            id          INTEGER PRIMARY KEY AUTOINCREMENT,
                            name        TEXT    NOT NULL,
                            version     TEXT,
                            status      TEXT    CHECK(status IN ('installed', 'local', 'published')),
                            description TEXT,
                            path        TEXT
                        )
                        """);
                }
            }
            
            logger.info(String.format("docs.db Schema initialisiert: %s", dbPath));
            return this;
        }
        
        public DocsDatabase populateFromWorkspace() throws SQLException {
            Object[][] categories = {
                {"main",      "Hauptverzeichnis Dateien",        1},
                {"memory",    "Memory und Protokolle",           2},
                {"reports",   "Berichte und Analysen",           3},
                {"cluster",   "Cluster und Infrastruktur",       4},
                {"skills",    "Installierte Skills",             5},
                {"websearch", "WebSearch Dokumentationen",       6},
                {"mcp",       "MCP Integration",                 7},
                {"links",     "Symbolische Links",               8},
            };
            
            Object[][] docs = {
                {"AGENTS.md",             "/", "main", "Agent-Konfiguration, Memory-Regeln",      "config",  false, null,                          "2026-04-11"},
                {"SOUL.md",               "/", "main", "Agent-Persönlichkeit und Kernwahrheiten", "config",  false, null,                          "2026-04-11"},
                {"IDENTITY.md",           "/", "main", "Agent-Name und Eigenschaften",            "config",  false, null,                          "2026-04-11"},
                {"USER.md",               "/", "main", "Benutzerinformationen",                   "config",  false, null,                          "2026-04-11"},
                {"TOOLS.md",              "/", "main", "Tool-spezifische Konfigurationen",        "config",  false, null,                          "2026-04-18"},
                {"MEMORY.md",             "/", "main", "Langzeitspeicher, System-Konfiguration",  "config",  false, null,                          "2026-04-11"},
                {"DOCUMENTATION-INDEX.md","/", "main", "Übersicht aller Dokumentationen",         "doc",     false, null,                          "2026-04-18"},
                {"WORKSPACE-INDEX.md",    "/", "main", "Symlink zu DOCUMENTATION-INDEX.md",       "symlink", true,  "DOCUMENTATION-INDEX.md",      "2026-04-18"},
                {"WEBSEARCH_README.md",        "websearch/", "websearch", "Schnellstart Guide",                    "guide",  true, "websearch/WEBSEARCH_README.md",          "2026-04-18"},
                {"WEBSEARCH_MCP_GUIDE.md",     "websearch/", "websearch", "Vollständige technische Dokumentation", "guide",  true, "websearch/WEBSEARCH_MCP_GUIDE.md",       "2026-04-18"},
                {"WEBSEARCH_CONFIG.md",        "websearch/", "websearch", "Konfigurations-Referenz",               "config", true, "websearch/WEBSEARCH_CONFIG.md",          "2026-04-18"},
                {"WEBSEARCH_PRIORITY_CONFIG.md","websearch/","websearch", "Provider-Priorität",                    "config", true, "websearch/WEBSEARCH_PRIORITY_CONFIG.md", "2026-04-18"},
                {"WEBSEARCH_SCRIPTS.md",       "websearch/", "websearch", "Automation & Scripting",                "script", true, "websearch/WEBSEARCH_SCRIPTS.md",         "2026-04-18"},
                {"WEBSEARCH_OPS.md",           "websearch/", "websearch", "IT-Operations",                         "guide",  true, "websearch/WEBSEARCH_OPS.md",             "2026-04-18"},
                {"MCP_GUIDE.md",               "mcp/",       "mcp",       "Symlink zu websearch/WEBSEARCH_MCP_GUIDE.md","symlink",false,"websearch/WEBSEARCH_MCP_GUIDE.md",  "2026-04-18"},
            };
            
            Object[][] skills = {
                {"json-utils",          "1.0.0", "installed", "JSON parsing and validation",      "skills/json-utils/"},
                {"scripting-utils",     "1.0.0", "installed", "Multi-language scripting support", "skills/scripting-utils/"},
                {"tiktok-live-mon",     "1.0.0", "installed", "TikTok stream monitoring",         "skills/tiktok-live-mon/"},
                {"cluster-management",  "1.0.0", "installed", "Cluster topology management",      "skills/cluster-management/"},
                {"worker-node",         "-",     "local",     "Worker node configuration",        "skills/worker-node/"},
                {"resource-manager",    "-",     "local",     "Resource management",              "skills/resource-manager/"},
                {"git-publish-agent",   "1.0.0", "local",     "Git publishing automation",        "skills/git-publish-agent/"},
            };
            
            Object[][] symlinks = {
                {"openclaw.env",               "/home/openclaw/.config/openclaw/env",  "/",             "API-Keys Shortcut"},
                {"openclaw.json",              "/home/openclaw/.openclaw/openclaw.json","/",             "Konfig Shortcut"},
                {"links/config/openclaw-env",  "/home/openclaw/.config/openclaw/env",  "links/config/", "API-Keys"},
                {"links/dotfiles/.tavily",     "/home/openclaw/.tavily/",              "links/dotfiles/","Tavily Config"},
                {"links/dotfiles/.claude",     "/home/openclaw/.claude/",              "links/dotfiles/","Claude Config"},
                {"links/dotfiles/.mcporter",   "/home/openclaw/.mcporter/",            "links/dotfiles/","MCPorter Config"},
                {"links/dotfiles/.ssh",        "/home/openclaw/.ssh/",                 "links/dotfiles/","SSH Keys"},
            };
            
            try (Connection conn = getConnection()) {
                conn.setAutoCommit(false);
                
                try (PreparedStatement stmt = conn.prepareStatement(
                        "INSERT OR IGNORE INTO categories (name, description, priority) VALUES (?,?,?)")) {
                    for (Object[] cat : categories) {
                        stmt.setString(1, (String)cat[0]);
                        stmt.setString(2, (String)cat[1]);
                        stmt.setInt(3, (Integer)cat[2]);
                        stmt.executeUpdate();
                    }
                }
                
                try (PreparedStatement stmt = conn.prepareStatement(
                        """INSERT OR REPLACE INTO documents
                           (name, path, category, description, type, has_symlink, symlink_path, last_update)
                           VALUES (?,?,?,?,?,?,?,?)""")) {
                    for (Object[] doc : docs) {
                        for (int i = 0; i < doc.length; i++) {
                            stmt.setObject(i+1, doc[i]);
                        }
                        stmt.executeUpdate();
                    }
                }
                
                try (PreparedStatement stmt = conn.prepareStatement(
                        "INSERT OR REPLACE INTO skills (name, version, status, description, path) VALUES (?,?,?,?,?)")) {
                    for (Object[] skill : skills) {
                        for (int i = 0; i < skill.length; i++) {
                            stmt.setObject(i+1, skill[i]);
                        }
                        stmt.executeUpdate();
                    }
                }
                
                try (PreparedStatement stmt = conn.prepareStatement(
                        "INSERT OR REPLACE INTO symlinks (name, target, source_path, description) VALUES (?,?,?,?)")) {
                    for (Object[] link : symlinks) {
                        for (int i = 0; i < link.length; i++) {
                            stmt.setObject(i+1, link[i]);
                        }
                        stmt.executeUpdate();
                    }
                }
                
                conn.commit();
            }
            
            logger.info(String.format(
                "docs.db befüllt: %d Dokumente, %d Skills, %d Symlinks",
                docs.length, skills.length, symlinks.length));
            return this;
        }
        
        private void validateTableName(String table, Set<String> allowed) {
            if (!allowed.contains(table)) {
                throw new IllegalArgumentException(
                    String.format("Ungültiger Tabellenname: '%s'. Erlaubt: %s", 
                        table, new ArrayList<>(allowed)));
            }
        }
        
        public Optional<Path> exportCsv(String table) throws SQLException, IOException {
            validateTableName(table, DOCS_EXPORT_TABLES);
            
            List<Map<String, Object>> rows;
            List<String> columnNames;
            
            try (Connection conn = getConnection()) {
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT * FROM " + table);
                    rows = resultSetToList(rs);
                    columnNames = getColumnNames(rs.getMetaData());
                }
            }
            
            if (rows.isEmpty()) {
                logger.info(String.format("Tabelle '%s' ist leer — kein CSV erzeugt", table));
                return Optional.empty();
            }
            
            Path csvPath = WORKSPACE.resolve("export_" + table + ".csv");
            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(csvPath, 
                    java.nio.charset.StandardCharsets.UTF_8))) {
                
                writer.println(String.join(",", columnNames));
                
                for (Map<String, Object> row : rows) {
                    List<String> values = new ArrayList<>();
                    for (String col : columnNames) {
                        Object value = row.get(col);
                        values.add(value != null ? value.toString() : "");
                    }
                    writer.println(String.join(",", values));
                }
            }
            
            logger.info(String.format("CSV exportiert: %s (%d Zeilen)", csvPath, rows.size()));
            return Optional.of(csvPath);
        }
        
        public Optional<Path> exportJson(String table) throws SQLException, IOException {
            validateTableName(table, DOCS_EXPORT_TABLES);
            
            List<Map<String, Object>> rows;
            
            try (Connection conn = getConnection()) {
                try (Statement stmt = conn.createStatement()) {
                    ResultSet rs = stmt.executeQuery("SELECT * FROM " + table);
                    rows = resultSetToList(rs);
                }
            }
            
            if (rows.isEmpty()) {
                logger.info(String.format("Tabelle '%s' ist leer — kein JSON erzeugt", table));
                return Optional.empty();
            }
            
            Path jsonPath = WORKSPACE.resolve("export_" + table + ".json");
            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(jsonPath, 
                    java.nio.charset.StandardCharsets.UTF_8))) {
                
                writer.print("[");
                for (int i = 0; i < rows.size(); i++) {
                    if (i > 0) writer.print(",");
                    writer.print(mapToJson(rows.get(i)));
                }
                writer.print("]");
            }
            
            logger.info(String.format("JSON exportiert: %s (%d Einträge)", jsonPath, rows.size()));
            return Optional.of(jsonPath);
        }
        
        private List<Map<String, Object>> resultSetToList(ResultSet rs) throws SQLException {
            List<Map<String, Object>> list = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                for (int i = 1; i <= columnCount; i++) {
                    row.put(metaData.getColumnName(i), rs.getObject(i));
                }
                list.add(row);
            }
            return list;
        }
        
        private List<String> getColumnNames(ResultSetMetaData metaData) throws SQLException {
            List<String> columnNames = new ArrayList<>();
            int columnCount = metaData.getColumnCount();
            for (int i = 1; i <= columnCount; i++) {
                columnNames.add(metaData.getColumnName(i));
            }
            return columnNames;
        }
        
        private String mapToJson(Map<String, Object> map) {
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                if (!first) sb.append(",");
                sb.append("\"").append(entry.getKey()).append("\":");
                Object value = entry.getValue();
                if (value instanceof String) {
                    sb.append("\"").append(value.toString().replace("\"", "\\\"")).append("\"");
                } else {
                    sb.append(value != null ? value.toString() : "null");
                }
                first = false;
            }
            sb.append("}");
            return sb.toString();
        }
    }
    
    // ---------------------------------------------------------------------------
    // TreeDatabase
    // ---------------------------------------------------------------------------
    
    public static class TreeDatabase {
        private final Path dbPath;
        
        public TreeDatabase() {
            this.dbPath = DB_DIR.resolve("tree.db");
        }
        
        private Connection getConnection() throws SQLException {
            Connection conn = DriverManager.getConnection("jdbc:sqlite:" + dbPath.toString());
            conn.createStatement().execute("PRAGMA foreign_keys = ON");
            return conn;
        }
        
        public TreeDatabase initSchema() throws SQLException {
            try (Connection conn = getConnection()) {
                try (Statement stmt = conn.createStatement()) {
                    stmt.execute("""
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
                        """);
                    
                    stmt.execute("""
                        CREATE TABLE IF NOT EXISTS tree_scans (
                            id             INTEGER PRIMARY KEY AUTOINCREMENT,
                            root_path      TEXT    NOT NULL,
                            max_depth      INTEGER,
                            total_files    INTEGER,
                            total_dirs     INTEGER,
                            total_symlinks INTEGER,
                            scanned_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                        )
                        """);
                }
            }
            
            logger.info(String.format("tree.db Schema initialisiert: %s", dbPath));
            return this;
        }
        
        public void addEntry(
                String rootPath,
                String relativePath,
                String name,
                String entryType,
                int depth,
                String parentPath,
                int size) throws SQLException {
            
            try (Connection conn = getConnection()) {
                try (PreparedStatement stmt = conn.prepareStatement(
                        """INSERT INTO tree_entries
                           (root_path, relative_path, name, type, depth, parent_path, size)
                           VALUES (?,?,?,?,?,?,?)""")) {
                    
                    stmt.setString(1, rootPath);
                    stmt.setString(2, relativePath);
                    stmt.setString(3, name);
                    stmt.setString(4, entryType);
                    stmt.setInt(5, depth);
                    stmt.setString(6, parentPath);
                    stmt.setInt(7, size);
                    stmt.executeUpdate();
                }
            }
        }
        
        public Optional<Path> exportCsv(String rootPathFilter) throws SQLException, IOException {
            List<Map<String, Object>> rows;
            List<String> columnNames;
            
            try (Connection conn = getConnection()) {
                try (PreparedStatement stmt = conn.prepareStatement(
                        rootPathFilter != null ? 
                        "SELECT * FROM tree_entries WHERE root_path = ?" :
                        "SELECT * FROM tree_entries")) {
                    
                    if (rootPathFilter != null) {
                        stmt.setString(1, rootPathFilter);
                    }
                    
                    ResultSet rs = stmt.executeQuery();
                    rows = resultSetToList(rs);
                    columnNames = getColumnNames(rs.getMetaData());
                }
            }
            
            if (rows.isEmpty()) {
                logger.info("Keine Tree-Einträge vorhanden — kein CSV erzeugt");
                return Optional.empty();
            }
            
            String suffix = rootPathFilter != null ? 
                "_" + rootPathFilter.replace("/", "_") : "_all";
            Path csvPath = WORKSPACE.resolve("export_tree" + suffix + ".csv");
            
            try (PrintWriter writer = new PrintWriter(Files.newBufferedWriter(csvPath, 
                    java.nio.charset.StandardCharsets.UTF_8))) {
                
                writer.println(String.join(",", columnNames));
                
                for (Map<String, Object> row : rows) {
                    List<String> values = new ArrayList<>();
                    for (String col : columnNames) {
                        Object value = row.get(col);
                        values.add(value != null ? value.toString() : "");
                    }
                    writer.println(String.join(",", values));
                }
            }
            
            logger.info(String.format("Tree-CSV exportiert: %s (%d Einträge)", csvPath, rows.size()));
            return Optional.of(csvPath);
        }
        
        private List<Map<String, Object>> resultSetToList(ResultSet rs) throws SQLException {
            List<Map<String, Object>> list = new ArrayList<>();
            while (rs.next()) {
                Map<String, Object> row = new HashMap<>();
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                for (int i = 1; i <= columnCount; i++) {
                    row.put(metaData.getColumnName(i), rs.getObject(i));
                }
                list.add(row);
            }
            return list;
        }
        
        private List<String> getColumnNames(ResultSetMetaData metaData) throws SQLException {
            List<String> columnNames = new ArrayList<>();
            int columnCount = metaData.getColumnCount();
            for (int i = 1; i <= columnCount; i++) {
                columnNames.add(metaData.getColumnName(i));
            }
            return columnNames;
        }
    }
    
    // ---------------------------------------------------------------------------
    // Einstiegspunkt
    // ---------------------------------------------------------------------------
    
    public static void main(String[] args) {
        System.out.println("============================================================");
        System.out.println("WORKSPACE DATABASE MANAGER");
        System.out.println("============================================================");
        
        // DB-Verzeichnis hier (nicht auf Modulebene) anlegen
        try {
            Files.createDirectories(DB_DIR);
            logger.info(String.format("DB-Verzeichnis: %s", DB_DIR));
        } catch (IOException exc) {
            logger.severe(String.format("DB-Verzeichnis konnte nicht erstellt werden: %s", exc.getMessage()));
            System.exit(1);
        }
        
        try {
            // docs.db aufbauen
            DocsDatabase docsDb = new DocsDatabase();
            docsDb.initSchema();
            docsDb.populateFromWorkspace();
            
            // Exporte
            System.out.println("\n--- Exporte docs.db ---");
            for (String table : Arrays.asList("documents", "skills", "symlinks")) {
                docsDb.exportCsv(table);
            }
            docsDb.exportJson("documents");
            
            // tree.db aufbauen (Daten kommen via tree.py)
            System.out.println("\n--- tree.db Initialisierung ---");
            TreeDatabase treeDb = new TreeDatabase();
            treeDb.initSchema();
            logger.info("Tree-Daten werden via tree.py Script befüllt");
            
            System.out.println("\n============================================================");
            System.out.println("DATENBANKEN BEREIT");
            System.out.println("============================================================");
            System.out.println("\nDatenbanken: " + DB_DIR + "/");
            System.out.println("Exporte:     " + WORKSPACE + "/");
            
        } catch (Exception e) {
            logger.severe("Fehler bei der Datenbankinitialisierung: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
}
