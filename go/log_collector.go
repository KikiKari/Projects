// abstraction-provenance: {"artifact_sha256": "1d514e549d3b39be7883df7a54b7719da3dd831d2ab4c901c0086c39e05027fe", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "go"}
// log_collector.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Log Collector Sub-Agent
Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
*/

package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

var (
	WORKSPACE = filepath.Join(os.Getenv("HOME"), ".openclaw", "workspace")
	DB_PATH   = filepath.Join(WORKSPACE, "db", "logs.db")
	LOG_DIR   = filepath.Join(WORKSPACE, "logs", "log-collector")
)

func init() {
	os.MkdirAll(LOG_DIR, 0755)
}

type Logger struct {
	logFile *os.File
}

func NewLogger() *Logger {
	today := time.Now().Format("2006-01-02")
	logFilePath := filepath.Join(LOG_DIR, today+".log")
	
	file, err := os.OpenFile(logFilePath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	
	return &Logger{logFile: file}
}

func (l *Logger) log(level string, msg string) {
	ts := time.Now().Format(time.RFC3339)
	line := fmt.Sprintf("[%s] [%s] %s\n", ts, level, msg)
	fmt.Print(line)
	l.logFile.WriteString(line)
}

func (l *Logger) Info(msg string)    { l.log("INFO", msg) }
func (l *Logger) Error(msg string)   { l.log("ERROR", msg) }

type LogCollector struct {
	logger *Logger
	conn   *sql.DB
}

func NewLogCollector() *LogCollector {
	return &LogCollector{
		logger: NewLogger(),
	}
}

func (lc *LogCollector) connectDB() error {
	db, err := sql.Open("sqlite3", DB_PATH)
	if err != nil {
		return err
	}
	lc.conn = db
	
	// Schema initialisieren falls nicht existiert
	err = lc.initSchema()
	return err
}

func (lc *LogCollector) initSchema() error {
	rows, err := lc.conn.Query("SELECT name FROM sqlite_master WHERE type='table'")
	if err != nil {
		return err
	}
	defer rows.Close()
	
	if !rows.Next() {
		schemaPath := filepath.Join(WORKSPACE, "db", "logs.db.schema.sql")
		if _, err := os.Stat(schemaPath); err == nil {
			content, err := os.ReadFile(schemaPath)
			if err != nil {
				return err
			}
			
			_, err = lc.conn.Exec(string(content))
			if err != nil {
				return err
			}
		}
	}
	
	return nil
}

func (lc *LogCollector) getNodes() ([]map[string]interface{}, error) {
	rows, err := lc.conn.Query("SELECT * FROM nodes")
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	
	columns, _ := rows.Columns()
	nodes := make([]map[string]interface{}, 0)
	
	for rows.Next() {
		values := make([]interface{}, len(columns))
		valuePtrs := make([]interface{}, len(columns))
		
		for i := range values {
			valuePtrs[i] = &values[i]
		}
		
		err = rows.Scan(valuePtrs...)
		if err != nil {
			return nil, err
		}
		
		node := make(map[string]interface{})
		for i, col := range columns {
			val := *(valuePtrs[i].(*interface{}))
			node[col] = val
		}
		
		nodes = append(nodes, node)
	}
	
	return nodes, nil
}

func (lc *LogCollector) checkVPN(ip string) bool {
	cmd := exec.Command("ping", "-c", "1", "-W", "3", ip)
	err := cmd.Run()
	return err == nil
}

func (lc *LogCollector) sshConnectAndCollect(node map[string]interface{}) *int {
	nodeID := node["node_id"].(string)
	var vpnIP string
	
	if val, ok := node["vpn_ip"]; ok && val != nil {
		vpnIP = val.(string)
	} else if val, ok := node["tailscale_ip"]; ok && val != nil {
		vpnIP = val.(string)
	} else if val, ok := node["wireguard_ip"]; ok && val != nil {
		vpnIP = val.(string)
	}
	
	if vpnIP == "" {
		lc.logger.Error(fmt.Sprintf("%s: Keine VPN-IP konfiguriert", nodeID))
		return nil
	}
	
	// 1. VPN-Check
	lc.logger.Info(fmt.Sprintf("%s: Prüfe VPN %s...", nodeID, vpnIP))
	if !lc.checkVPN(vpnIP) {
		lc.logger.Error(fmt.Sprintf("%s: VPN nicht erreichbar", nodeID))
		lc.logSSHConnection(nodeID, "tailscale", false, "VPN unreachable")
		return nil
	}
	
	// 2. SSH-Verbindung
	lc.logger.Info(fmt.Sprintf("%s: Verbinde via SSH...", nodeID))
	
	logCommands := []string{
		"journalctl -n 500 --no-pager",
		"tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
		"tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'",
	}
	
	logsCollected := make([]map[string]interface{}, 0)
	
	for _, cmd := range logCommands {
		context, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		
		command := exec.CommandContext(context, "ssh", "-o", "ConnectTimeout=10", "-o", "StrictHostKeyChecking=no", fmt.Sprintf("openclaw@%s", vpnIP), cmd)
		output, err := command.Output()
		
		if err == nil {
			logEntry := map[string]interface{}{
				"command":   cmd,
				"output":    string(output),
				"timestamp": time.Now().Format(time.RFC3339),
			}
			logsCollected = append(logsCollected, logEntry)
		}
	}
	
	// Erfolg loggen
	lc.logSSHConnection(nodeID, "ssh", true, "")
	
	// In DB speichern
	lc.insertLogs(nodeID, logsCollected)
	
	count := len(logsCollected)
	return &count
}

func (lc *LogCollector) logSSHConnection(nodeID string, connType string, success bool, errorMsg string) {
	stmt, err := lc.conn.Prepare("INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES (?, ?, ?, ?)")
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Vorbereiten der SQL-Anweisung: %v", err))
		return
	}
	defer stmt.Close()
	
	_, err = stmt.Exec(nodeID, connType, success, errorMsg)
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Einfügen der SSH-Verbindung: %v", err))
	}
}

func (lc *LogCollector) insertLogs(nodeID string, logs []map[string]interface{}) {
	stmt, err := lc.conn.Prepare(`INSERT INTO logs (node_id, log_type, source, content, severity, collected_by, collection_method, retention_until) VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)`)
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Vorbereiten der SQL-Anweisung: %v", err))
		return
	}
	defer stmt.Close()
	
	retention := time.Now().Add(30 * 24 * time.Hour).Format(time.RFC3339)
	
	for _, logEntry := range logs {
		source := logEntry["command"].(string)
		if len(source) > 50 {
			source = source[:50]
		}
		
		content := logEntry["output"].(string)
		if len(content) > 10000 {
			content = content[:10000]
		}
		
		_, err := stmt.Exec(nodeID, source, content, "node1", retention)
		if err != nil {
			lc.logger.Error(fmt.Sprintf("Fehler beim Einfügen des Logs: %v", err))
		}
	}
	
	lc.logger.Info(fmt.Sprintf("%s: %d Log-Einträge gespeichert", nodeID, len(logs)))
}

func (lc *LogCollector) cleanupRetention() int {
	stmt, err := lc.conn.Prepare("DELETE FROM logs WHERE retention_until < datetime('now')")
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Vorbereiten der SQL-Anweisung: %v", err))
		return 0
	}
	defer stmt.Close()
	
	result, err := stmt.Exec()
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Löschen alter Logs: %v", err))
		return 0
	}
	
	deleted, _ := result.RowsAffected()
	lc.logger.Info(fmt.Sprintf("Retention-Cleanup: %d alte Logs gelöscht", deleted))
	return int(deleted)
}

func (lc *LogCollector) runCollectionCycle() {
	lc.logger.Info(strings.Repeat("=", 60))
	lc.logger.Info("LOG COLLECTOR CYCLE START")
	lc.logger.Info(strings.Repeat("=", 60))
	
	err := lc.connectDB()
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Datenbankverbindung fehlgeschlagen: %v", err))
		return
	}
	defer lc.conn.Close()
	
	// 1. Nodes holen
	nodes, err := lc.getNodes()
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Abrufen der Nodes: %v", err))
		return
	}
	lc.logger.Info(fmt.Sprintf("Gefunden: %d Nodes", len(nodes)))
	
	// 2. Collection-Run starten
	stmt, err := lc.conn.Prepare("INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ?)")
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Vorbereiten der SQL-Anweisung: %v", err))
		return
	}
	
	result, err := stmt.Exec(len(nodes))
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Starten des Collection-Runs: %v", err))
		return
	}
	
	runID, _ := result.LastInsertId()
	stmt.Close()
	
	// 3. Für jeden Node sammeln
	successCount := 0
	failedCount := 0
	totalLogs := 0
	
	for _, node := range nodes {
		nodeID := node["node_id"].(string)
		if nodeID == "node1" {
			// Lokale Logs (Gateway selbst)
			lc.logger.Info("node1: Lokale Collection (Gateway)")
			successCount++
		} else {
			// Remote-Node abfragen
			result := lc.sshConnectAndCollect(node)
			if result != nil {
				successCount++
				totalLogs += *result
			} else {
				failedCount++
			}
		}
	}
	
	// 4. Run abschließen
	updateStmt, err := lc.conn.Prepare(`UPDATE collection_runs SET finished_at = CURRENT_TIMESTAMP, nodes_success = ?, nodes_failed = ?, logs_collected = ? WHERE run_id = ?`)
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Vorbereiten der Update-Anweisung: %v", err))
		return
	}
	
	_, err = updateStmt.Exec(successCount, failedCount, totalLogs, runID)
	if err != nil {
		lc.logger.Error(fmt.Sprintf("Fehler beim Aktualisieren des Collection-Runs: %v", err))
		return
	}
	updateStmt.Close()
	
	// 5. Retention-Cleanup
	lc.logger.Info("Retention-Cleanup (30 Tage)...")
	lc.cleanupRetention()
	
	lc.logger.Info(strings.Repeat("=", 60))
	lc.logger.Info(fmt.Sprintf("SUMMARY: %d OK, %d Failed, %d Logs", successCount, failedCount, totalLogs))
	lc.logger.Info(strings.Repeat("=", 60))
}

func main() {
	fmt.Println(strings.Repeat("=", 60))
	fmt.Println("LOG COLLECTOR")
	fmt.Println(strings.Repeat("=", 60))
	
	collector := NewLogCollector()
	
	defer func() {
		if r := recover(); r != nil {
			fmt.Printf("CRITICAL ERROR: %v\n", r)
			panic(r)
		}
	}()
	
	collector.runCollectionCycle()
}
