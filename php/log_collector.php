<?php
// abstraction-provenance: {"artifact_sha256": "ee6f2a5762f967da94f4f13c9ee888e1e2fa3c8134b2d9ff47549388db8485df", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "php"}
// log_collector.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Log Collector Sub-Agent
 * Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
 */

$WORKSPACE = "/home/openclaw/.openclaw/workspace";
$DB_PATH = $WORKSPACE . "/db/logs.db";
$LOG_DIR = $WORKSPACE . "/logs/log-collector";

if (!file_exists($LOG_DIR)) {
    mkdir($LOG_DIR, 0777, true);
}

class Logger {
    private $logFile;
    
    public function __construct() {
        $today = date('Y-m-d');
        $this->logFile = $GLOBALS['LOG_DIR'] . "/{$today}.log";
    }
    
    public function log($level, $msg) {
        $ts = date('c');
        $line = "[{$ts}] [{$level}] {$msg}\n";
        echo $line;
        file_put_contents($this->logFile, $line, FILE_APPEND | LOCK_EX);
    }
    
    public function info($msg) { $this->log('INFO', $msg); }
    public function error($msg) { $this->log('ERROR', $msg); }
}

class LogCollector {
    private $logger;
    private $conn;
    
    public function __construct() {
        $this->logger = new Logger();
    }
    
    public function connectDb() {
        $this->conn = new SQLite3($GLOBALS['DB_PATH']);
        $this->conn->busyTimeout(5000);
        // Schema initialisieren falls nicht existiert
        $this->_initSchema();
        return $this->conn;
    }
    
    private function _initSchema() {
        $result = $this->conn->query("SELECT name FROM sqlite_master WHERE type='table'");
        if (!$result->fetchArray(SQLITE3_NUM)) {
            $schemaPath = $GLOBALS['WORKSPACE'] . "/db/logs.db.schema.sql";
            if (file_exists($schemaPath)) {
                $sql = file_get_contents($schemaPath);
                $this->conn->exec($sql);
            }
        }
    }
    
    public function getNodes() {
        $result = $this->conn->query("SELECT * FROM nodes");
        $nodes = [];
        while ($row = $result->fetchArray(SQLITE3_ASSOC)) {
            $nodes[] = $row;
        }
        return $nodes;
    }
    
    public function checkVpn($ip) {
        $command = "ping -c 1 -W 3 " . escapeshellarg($ip);
        $descriptorspec = [
            0 => ["pipe", "r"],
            1 => ["pipe", "w"],
            2 => ["pipe", "w"]
        ];
        
        $process = proc_open($command, $descriptorspec, $pipes);
        
        if (is_resource($process)) {
            $return_value = proc_close($process);
            return $return_value === 0;
        }
        return false;
    }
    
    public function sshConnectAndCollect($node) {
        $nodeId = $node['node_id'];
        $vpnIp = $node['vpn_ip'] ?? $node['tailscale_ip'] ?? $node['wireguard_ip'] ?? null;
        
        if (!$vpnIp) {
            $this->logger->error("{$nodeId}: Keine VPN-IP konfiguriert");
            return null;
        }
        
        // 1. VPN-Check
        $this->logger->info("{$nodeId}: Prüfe VPN {$vpnIp}...");
        if (!$this->checkVpn($vpnIp)) {
            $this->logger->error("{$nodeId}: VPN nicht erreichbar");
            $this->_logSshConnection($nodeId, 'tailscale', false, 'VPN unreachable');
            return null;
        }
        
        // 2. SSH-Verbindung
        $this->logger->info("{$nodeId}: Verbinde via SSH...");
        try {
            // Logs abholen (ohne cd wegen exec-Beschränkungen)
            $logCommands = [
                "journalctl -n 500 --no-pager",
                "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
                "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
            ];
            
            $logsCollected = [];
            foreach ($logCommands as $cmd) {
                $fullCommand = "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no " . 
                              escapeshellarg("openclaw@{$vpnIp}") . " " . escapeshellarg($cmd);
                
                $descriptorspec = [
                    0 => ["pipe", "r"],
                    1 => ["pipe", "w"],
                    2 => ["pipe", "w"]
                ];
                
                $process = proc_open($fullCommand, $descriptorspec, $pipes);
                
                if (is_resource($process)) {
                    $stdout = stream_get_contents($pipes[1]);
                    $stderr = stream_get_contents($pipes[2]);
                    fclose($pipes[1]);
                    fclose($pipes[2]);
                    
                    $return_value = proc_close($process);
                    
                    if ($return_value === 0) {
                        $logsCollected[] = [
                            'command' => $cmd,
                            'output' => $stdout,
                            'timestamp' => date('c')
                        ];
                    }
                }
            }
            
            // Erfolg loggen
            $this->_logSshConnection($nodeId, 'ssh', true, null);
            
            // In DB speichern
            $this->_insertLogs($nodeId, $logsCollected);
            
            return count($logsCollected);
            
        } catch (Exception $e) {
            $this->logger->error("{$nodeId}: SSH Fehler: " . $e->getMessage());
            $this->_logSshConnection($nodeId, 'ssh', false, $e->getMessage());
            return null;
        }
    }
    
    private function _logSshConnection($nodeId, $connType, $success, $error) {
        $stmt = $this->conn->prepare('
            INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
            VALUES (:node_id, :connection_type, :success, :error_message)
        ');
        $stmt->bindValue(':node_id', $nodeId);
        $stmt->bindValue(':connection_type', $connType);
        $stmt->bindValue(':success', $success ? 1 : 0, SQLITE3_INTEGER);
        $stmt->bindValue(':error_message', $error);
        $stmt->execute();
    }
    
    private function _insertLogs($nodeId, $logs) {
        $stmt = $this->conn->prepare('
            INSERT INTO logs (node_id, log_type, source, content, severity, 
                            collected_by, collection_method, retention_until)
            VALUES (:node_id, :log_type, :source, :content, :severity, 
                    :collected_by, :collection_method, :retention_until)
        ');
        
        $retention = date('c', strtotime('+30 days'));
        $insertedCount = 0;
        
        foreach ($logs as $logEntry) {
            $stmt->bindValue(':node_id', $nodeId);
            $stmt->bindValue(':log_type', 'system');
            $stmt->bindValue(':source', substr($logEntry['command'], 0, 50));
            $stmt->bindValue(':content', substr($logEntry['output'], 0, 10000));
            $stmt->bindValue(':severity', 'info');
            $stmt->bindValue(':collected_by', 'node1');
            $stmt->bindValue(':collection_method', 'ssh');
            $stmt->bindValue(':retention_until', $retention);
            
            if ($stmt->execute()) {
                $insertedCount++;
            }
        }
        
        $this->logger->info("{$nodeId}: {$insertedCount} Log-Einträge gespeichert");
    }
    
    public function cleanupRetention() {
        $stmt = $this->conn->prepare("
            DELETE FROM logs WHERE retention_until < datetime('now')
        ");
        $result = $stmt->execute();
        
        $deleted = $this->conn->changes();
        $this->logger->info("Retention-Cleanup: {$deleted} alte Logs gelöscht");
        return $deleted;
    }
    
    public function runCollectionCycle() {
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("LOG COLLECTOR CYCLE START");
        $this->logger->info(str_repeat("=", 60));
        
        $this->connectDb();
        
        // 1. Nodes holen
        $nodes = $this->getNodes();
        $this->logger->info("Gefunden: " . count($nodes) . " Nodes");
        
        // 2. Collection-Run starten
        $stmt = $this->conn->prepare('
            INSERT INTO collection_runs (started_at, nodes_total)
            VALUES (CURRENT_TIMESTAMP, :nodes_total)
        ');
        $stmt->bindValue(':nodes_total', count($nodes), SQLITE3_INTEGER);
        $stmt->execute();
        $runId = $this->conn->lastInsertRowID();
        
        // 3. Für jeden Node sammeln
        $successCount = 0;
        $failedCount = 0;
        $totalLogs = 0;
        
        foreach ($nodes as $node) {
            if ($node['node_id'] === 'node1') {
                // Lokale Logs (Gateway selbst)
                $this->logger->info("node1: Lokale Collection (Gateway)");
                $successCount++;
            } else {
                // Remote-Node abfragen
                $result = $this->sshConnectAndCollect($node);
                if ($result !== null) {
                    $successCount++;
                    $totalLogs += $result;
                } else {
                    $failedCount++;
                }
            }
        }
        
        // 4. Run abschließen
        $stmt = $this->conn->prepare('
            UPDATE collection_runs SET
                finished_at = CURRENT_TIMESTAMP,
                nodes_success = :nodes_success,
                nodes_failed = :nodes_failed,
                logs_collected = :logs_collected
            WHERE run_id = :run_id
        ');
        $stmt->bindValue(':nodes_success', $successCount, SQLITE3_INTEGER);
        $stmt->bindValue(':nodes_failed', $failedCount, SQLITE3_INTEGER);
        $stmt->bindValue(':logs_collected', $totalLogs, SQLITE3_INTEGER);
        $stmt->bindValue(':run_id', $runId, SQLITE3_INTEGER);
        $stmt->execute();
        
        // 5. Retention-Cleanup
        $this->logger->info("Retention-Cleanup (30 Tage)...");
        $this->cleanupRetention();
        
        $this->logger->info(str_repeat("=", 60));
        $this->logger->info("SUMMARY: {$successCount} OK, {$failedCount} Failed, {$totalLogs} Logs");
        $this->logger->info(str_repeat("=", 60));
    }
}

function main() {
    echo str_repeat("=", 60) . "\n";
    echo "LOG COLLECTOR\n";
    echo str_repeat("=", 60) . "\n";
    
    $collector = new LogCollector();
    
    try {
        $collector->runCollectionCycle();
    } catch (Exception $e) {
        echo "CRITICAL ERROR: " . $e->getMessage() . "\n";
        echo $e->getTraceAsString() . "\n";
        exit(1);
    }
}

main();
