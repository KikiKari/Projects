// abstraction-provenance: {"artifact_sha256": "4cda960b909ae01ec3b13b7f5422f4180ff02c733ac6f09fc959314176d1c14e", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "java"}
// log_collector.py — portiert nach java
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.*;

/**
 * Log Collector Sub-Agent
 * Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
 */
public class LogCollector {
    private static final Path WORKSPACE = Paths.get(System.getProperty("user.home"), ".openclaw", "workspace");
    private static final Path DB_PATH = WORKSPACE.resolve("db").resolve("logs.db");
    private static final Path LOG_DIR = WORKSPACE.resolve("logs").resolve("log-collector");
    
    static {
        try {
            Files.createDirectories(LOG_DIR);
        } catch (IOException e) {
            System.err.println("Failed to create log directory: " + e.getMessage());
        }
    }
    
    private Logger logger;
    private Connection conn;
    
    public LogCollector() {
        this.logger = new Logger();
    }
    
    private void connectDb() throws SQLException {
        this.conn = DriverManager.getConnection("jdbc:sqlite:" + DB_PATH.toString());
        // Schema initialisieren falls nicht existiert
        initSchema();
    }
    
    private void initSchema() throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement("SELECT name FROM sqlite_master WHERE type='table'")) {
            ResultSet rs = stmt.executeQuery();
            if (!rs.next()) {
                Path schemaPath = WORKSPACE.resolve("db").resolve("logs.db.schema.sql");
                if (Files.exists(schemaPath)) {
                    String schema = readFile(schemaPath);
                    try (Statement schemaStmt = conn.createStatement()) {
                        schemaStmt.execute(schema);
                    }
                }
            }
        } catch (IOException e) {
            logger.error("Failed to read schema: " + e.getMessage());
        }
    }
    
    private List<Map<String, Object>> getNodes() throws SQLException {
        List<Map<String, Object>> nodes = new ArrayList<>();
        try (PreparedStatement stmt = conn.prepareStatement("SELECT * FROM nodes");
             ResultSet rs = stmt.executeQuery()) {
            
            while (rs.next()) {
                Map<String, Object> node = new HashMap<>();
                ResultSetMetaData metaData = rs.getMetaData();
                int columnCount = metaData.getColumnCount();
                
                for (int i = 1; i <= columnCount; i++) {
                    node.put(metaData.getColumnName(i), rs.getObject(i));
                }
                nodes.add(node);
            }
        }
        return nodes;
    }
    
    private boolean checkVpn(String ip) {
        try {
            ProcessBuilder pb = new ProcessBuilder("ping", "-c", "1", "-W", "3", ip);
            Process process = pb.start();
            return process.waitFor(10, TimeUnit.SECONDS) && process.exitValue() == 0;
        } catch (Exception e) {
            return false;
        }
    }
    
    private Integer sshConnectAndCollect(Map<String, Object> node) {
        String nodeId = (String) node.get("node_id");
        String vpnIp = getVpnIp(node);
        
        if (vpnIp == null) {
            logger.error(nodeId + ": Keine VPN-IP konfiguriert");
            return null;
        }
        
        // 1. VPN-Check
        logger.info(nodeId + ": Prüfe VPN " + vpnIp + "...");
        if (!checkVpn(vpnIp)) {
            logger.error(nodeId + ": VPN nicht erreichbar");
            logSshConnection(nodeId, "tailscale", false, "VPN unreachable");
            return null;
        }
        
        // 2. SSH-Verbindung
        logger.info(nodeId + ": Verbinde via SSH...");
        try {
            // Logs abholen (ohne cd wegen exec-Beschränkungen)
            String[] logCommands = {
                "journalctl -n 500 --no-pager",
                "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
                "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
            };
            
            List<Map<String, String>> logsCollected = new ArrayList<>();
            for (String cmd : logCommands) {
                ProcessBuilder pb = new ProcessBuilder("ssh", "-o", "ConnectTimeout=10", 
                                                       "-o", "StrictHostKeyChecking=no",
                                                       "openclaw@" + vpnIp, cmd);
                Process process = pb.start();
                
                if (process.waitFor(30, TimeUnit.SECONDS) && process.exitValue() == 0) {
                    String output = readProcessOutput(process.getInputStream());
                    Map<String, String> logEntry = new HashMap<>();
                    logEntry.put("command", cmd);
                    logEntry.put("output", output);
                    logEntry.put("timestamp", LocalDateTime.now().toString());
                    logsCollected.add(logEntry);
                }
            }
            
            // Erfolg loggen
            logSshConnection(nodeId, "ssh", true, null);
            
            // In DB speichern
            insertLogs(nodeId, logsCollected);
            
            return logsCollected.size();
            
        } catch (InterruptedException | IOException e) {
            logger.error(nodeId + ": SSH Fehler: " + e.getMessage());
            logSshConnection(nodeId, "ssh", false, e.getMessage());
            return null;
        } catch (Exception e) {
            logger.error(nodeId + ": SSH Fehler: " + e.getMessage());
            logSshConnection(nodeId, "ssh", false, e.getMessage());
            return null;
        }
    }
    
    private String getVpnIp(Map<String, Object> node) {
        Object vpnIp = node.get("vpn_ip");
        if (vpnIp != null) return vpnIp.toString();
        
        vpnIp = node.get("tailscale_ip");
        if (vpnIp != null) return vpnIp.toString();
        
        vpnIp = node.get("wireguard_ip");
        if (vpnIp != null) return vpnIp.toString();
        
        return null;
    }
    
    private void logSshConnection(String nodeId, String connType, boolean success, String error) {
        try (PreparedStatement stmt = conn.prepareStatement(
                "INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES (?, ?, ?, ?)")) {
            stmt.setString(1, nodeId);
            stmt.setString(2, connType);
            stmt.setBoolean(3, success);
            stmt.setString(4, error);
            stmt.executeUpdate();
        } catch (SQLException e) {
            logger.error("Failed to log SSH connection: " + e.getMessage());
        }
    }
    
    private void insertLogs(String nodeId, List<Map<String, String>> logs) throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "INSERT INTO logs (node_id, log_type, source, content, severity, collected_by, collection_method, retention_until) " +
                "VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)")) {
            
            LocalDateTime retention = LocalDateTime.now().plusDays(30);
            
            for (Map<String, String> logEntry : logs) {
                stmt.setString(1, nodeId);
                stmt.setString(2, logEntry.get("command").substring(0, Math.min(50, logEntry.get("command").length())));
                stmt.setString(3, logEntry.get("output").substring(0, Math.min(10000, logEntry.get("output").length())));
                stmt.setString(4, "node1"); // collected_by
                stmt.setString(5, retention.toString());
                stmt.executeUpdate();
            }
            
            logger.info(nodeId + ": " + logs.size() + " Log-Einträge gespeichert");
        }
    }
    
    private int cleanupRetention() throws SQLException {
        try (PreparedStatement stmt = conn.prepareStatement(
                "DELETE FROM logs WHERE retention_until < datetime('now')")) {
            int deleted = stmt.executeUpdate();
            logger.info("Retention-Cleanup: " + deleted + " alte Logs gelöscht");
            return deleted;
        }
    }
    
    public void runCollectionCycle() throws SQLException {
        logger.info("=".repeat(60));
        logger.info("LOG COLLECTOR CYCLE START");
        logger.info("=".repeat(60));
        
        connectDb();
        
        // 1. Nodes holen
        List<Map<String, Object>> nodes = getNodes();
        logger.info("Gefunden: " + nodes.size() + " Nodes");
        
        // 2. Collection-Run starten
        try (PreparedStatement stmt = conn.prepareStatement(
                "INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ?)",
                Statement.RETURN_GENERATED_KEYS)) {
            stmt.setInt(1, nodes.size());
            stmt.executeUpdate();
            
            ResultSet rs = stmt.getGeneratedKeys();
            int runId = rs.next() ? rs.getInt(1) : -1;
            
            // 3. Für jeden Node sammeln
            int successCount = 0;
            int failedCount = 0;
            int totalLogs = 0;
            
            for (Map<String, Object> node : nodes) {
                if ("node1".equals(node.get("node_id"))) {
                    // Lokale Logs (Gateway selbst)
                    logger.info("node1: Lokale Collection (Gateway)");
                    successCount++;
                } else {
                    // Remote-Node abfragen
                    Integer result = sshConnectAndCollect(node);
                    if (result != null) {
                        successCount++;
                        totalLogs += result;
                    } else {
                        failedCount++;
                    }
                }
            }
            
            // 4. Run abschließen
            try (PreparedStatement updateStmt = conn.prepareStatement(
                    "UPDATE collection_runs SET finished_at = CURRENT_TIMESTAMP, nodes_success = ?, " +
                    "nodes_failed = ?, logs_collected = ? WHERE run_id = ?")) {
                updateStmt.setInt(1, successCount);
                updateStmt.setInt(2, failedCount);
                updateStmt.setInt(3, totalLogs);
                updateStmt.setInt(4, runId);
                updateStmt.executeUpdate();
            }
            
            // 5. Retention-Cleanup
            logger.info("Retention-Cleanup (30 Tage)...");
            cleanupRetention();
            
            logger.info("=".repeat(60));
            logger.info("SUMMARY: " + successCount + " OK, " + failedCount + " Failed, " + totalLogs + " Logs");
            logger.info("=".repeat(60));
        }
    }
    
    private String readFile(Path path) throws IOException {
        return new String(Files.readAllBytes(path));
    }
    
    private String readProcessOutput(InputStream inputStream) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream))) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
        }
        return sb.toString();
    }
    
    public static void main(String[] args) {
        System.out.println("=".repeat(60));
        System.out.println("LOG COLLECTOR");
        System.out.println("=".repeat(60));
        
        LogCollector collector = new LogCollector();
        
        try {
            collector.runCollectionCycle();
        } catch (Exception e) {
            System.err.println("CRITICAL ERROR: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }
    
    static class Logger {
        private Path logFile;
        
        public Logger() {
            String today = LocalDate.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd"));
            this.logFile = LOG_DIR.resolve(today + ".log");
        }
        
        public void log(String level, String msg) {
            String ts = LocalDateTime.now().toString();
            String line = "[" + ts + "] [" + level + "] " + msg;
            System.out.println(line);
            try {
                Files.write(logFile, (line + "\n").getBytes(), StandardOpenOption.CREATE, StandardOpenOption.APPEND);
            } catch (IOException e) {
                System.err.println("Failed to write to log file: " + e.getMessage());
            }
        }
        
        public void info(String msg) { log("INFO", msg); }
        public void error(String msg) { log("ERROR", msg); }
    }
}
