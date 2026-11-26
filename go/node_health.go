// abstraction-provenance: {"artifact_sha256": "a1674cad2484101dd3dbbec9d31e91468208359e6d4bbd60a54c61da46b1c6dc", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "go"}
// node_health.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Konfiguration
var (
	WORKSPACE = "/home/openclaw/.openclaw/workspace"
	HEALTH_DB = filepath.Join(WORKSPACE, "db", "health.db")
	LOG_FILE  = filepath.Join(WORKSPACE, "logs", "node-health.log")
)

// NodeConfig repräsentiert die Konfiguration eines Knotens
type NodeConfig struct {
	Name          string `json:"name"`
	Host          string `json:"host"`
	User          string `json:"user"`
	Critical      bool   `json:"critical,omitempty"`
	SSHKey        string `json:"ssh_key,omitempty"`
	DiskWarning   int    `json:"disk_warning,omitempty"`
	Optional      bool   `json:"optional,omitempty"`
}

// Metrics enthält die Systemmetriken eines Knotens
type Metrics struct {
	Timestamp     string  `json:"timestamp"`
	Available     bool    `json:"available"`
	CPU           *float64 `json:"cpu,omitempty"`
	RAM           *float64 `json:"ram,omitempty"`
	Disk          *int    `json:"disk,omitempty"`
	Load          *float64 `json:"load,omitempty"`
	GatewayStatus string  `json:"gateway_status,omitempty"`
}

// Alert repräsentiert eine Warnung
type Alert struct {
	Level   string `json:"level"`
	Message string `json:"message"`
}

// Node-Definitionen
var NODES = map[string]NodeConfig{
	"node1": {
		Name:     "Gateway",
		Host:     "localhost",
		User:     "openclaw",
		Critical: true,
	},
	"node2": {
		Name:   "Worker",
		Host:   "100.92.155.34",
		User:   "root",
		SSHKey: "~/.ssh/id_rsa",
	},
	"node3": {
		Name:        "Relay",
		Host:        "185.242.xxx.xxx",
		User:        "root",
		DiskWarning: 85,
	},
	"node5": {
		Name:     "Redmi",
		Host:     "192.168.1.x",
		User:     "openclaw",
		Optional: true,
	},
}

func init() {
	// Setze Standardwerte für DiskWarning falls nicht gesetzt
	for id, node := range NODES {
		if node.DiskWarning == 0 {
			NODES[id] = NodeConfig{
				Name:          node.Name,
				Host:          node.Host,
				User:          node.User,
				Critical:      node.Critical,
				SSHKey:        node.SSHKey,
				DiskWarning:   85,
				Optional:      node.Optional,
			}
		}
	}
}

func logMessage(message, level string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	entry := fmt.Sprintf("[%s] [%s] %s", timestamp, level, message)
	fmt.Println(entry)

	// Stelle sicher, dass das Log-Verzeichnis existiert
	logDir := filepath.Dir(LOG_FILE)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Erstellen des Log-Verzeichnisses: %v\n", err)
		return
	}

	// Schreibe in die Log-Datei
	f, err := os.OpenFile(LOG_FILE, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Öffnen der Log-Datei: %v\n", err)
		return
	}
	defer f.Close()

	if _, err := f.WriteString(entry + "\n"); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Schreiben in die Log-Datei: %v\n", err)
	}
}

func checkPing(host string, timeout int) bool {
	cmd := exec.Command("ping", "-c", "1", "-W", strconv.Itoa(timeout), host)
	err := cmd.Run()
	return err == nil
}

func checkSSH(nodeConfig NodeConfig) bool {
	host := nodeConfig.Host
	user := nodeConfig.User
	if user == "" {
		user = "root"
	}

	args := []string{"-o", "ConnectTimeout=10", "-o", "BatchMode=yes"}
	if nodeConfig.SSHKey != "" {
		args = append(args, "-i", nodeConfig.SSHKey)
	}
	args = append(args, fmt.Sprintf("%s@%s", user, host), "echo \"OK\"")

	cmd := exec.Command("ssh", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		return false
	}
	return strings.Contains(string(output), "OK")
}

func getFloatPtr(s string) *float64 {
	if s == "" {
		return nil
	}
	f, err := strconv.ParseFloat(strings.TrimSpace(s), 64)
	if err != nil {
		return nil
	}
	return &f
}

func getIntPtr(s string) *int {
	if s == "" {
		return nil
	}
	i, err := strconv.Atoi(strings.TrimSpace(s))
	if err != nil {
		return nil
	}
	return &i
}

func getMetricsViaSSH(nodeConfig NodeConfig) Metrics {
	host := nodeConfig.Host
	user := nodeConfig.User
	if user == "" {
		user = "root"
	}

	metrics := Metrics{
		Timestamp: time.Now().Format(time.RFC3339),
		Available: false,
	}

	// SSH-Command für alle Metriken
	sshCmd := fmt.Sprintf(`ssh -o ConnectTimeout=10 %s@%s '
        # CPU
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    '`, user, host)

	cmd := exec.Command("sh", "-c", sshCmd)
	output, err := cmd.CombinedOutput()
	
	// Timeout handling
	done := make(chan error, 1)
	go func() {
		done <- cmd.Start()
	}()
	
	select {
	case <-time.After(15 * time.Second):
		logMessage(fmt.Sprintf("SSH timeout for %s", nodeConfig.Name), "WARN")
		return metrics
	case err := <-done:
		if err != nil {
			logMessage(fmt.Sprintf("Error checking %s: %v", nodeConfig.Name, err), "ERROR")
			return metrics
		}
	}

	if cmd.Wait() == nil {
		metrics.Available = true
		
		lines := strings.Split(strings.TrimSpace(string(output)), "\n")
		for _, line := range lines {
			if !strings.Contains(line, ":") {
				continue
			}
			
			parts := strings.SplitN(line, ":", 2)
			key := parts[0]
			value := ""
			if len(parts) > 1 {
				value = parts[1]
			}
			
			switch key {
			case "CPU":
				metrics.CPU = getFloatPtr(value)
			case "RAM":
				metrics.RAM = getFloatPtr(value)
			case "DISK":
				metrics.Disk = getIntPtr(value)
			case "LOAD":
				metrics.Load = getFloatPtr(value)
			case "GATEWAY":
				metrics.GatewayStatus = value
			}
		}
	}
	
	return metrics
}

func checkAlerts(nodeID string, nodeConfig NodeConfig, metrics Metrics) []Alert {
	var alerts []Alert
	
	// Verfügbarkeit
	if !metrics.Available {
		if !nodeConfig.Optional {
			alerts = append(alerts, Alert{
				Level:   "CRITICAL",
				Message: fmt.Sprintf("Node %s nicht erreichbar!", nodeConfig.Name),
			})
		}
	} else {
		// CPU
		if metrics.CPU != nil && *metrics.CPU > 90 {
			alerts = append(alerts, Alert{
				Level:   "WARNING",
				Message: fmt.Sprintf("Node %s: CPU bei %.1f%%", nodeConfig.Name, *metrics.CPU),
			})
		}
		
		// RAM
		if metrics.RAM != nil && *metrics.RAM > 90 {
			alerts = append(alerts, Alert{
				Level:   "WARNING",
				Message: fmt.Sprintf("Node %s: RAM bei %.1f%%", nodeConfig.Name, *metrics.RAM),
			})
		}
		
		// Disk
		diskThreshold := nodeConfig.DiskWarning
		if diskThreshold == 0 {
			diskThreshold = 85
		}
		if metrics.Disk != nil && *metrics.Disk > diskThreshold {
			level := "WARNING"
			if *metrics.Disk > 95 {
				level = "CRITICAL"
			}
			alerts = append(alerts, Alert{
				Level:   level,
				Message: fmt.Sprintf("Node %s: Disk bei %d%%", nodeConfig.Name, *metrics.Disk),
			})
		}
		
		// Gateway
		if nodeConfig.Critical && metrics.GatewayStatus == "inactive" {
			alerts = append(alerts, Alert{
				Level:   "CRITICAL",
				Message: fmt.Sprintf("Node %s: OpenClaw Gateway nicht aktiv!", nodeConfig.Name),
			})
		}
	}
	
	return alerts
}

func sendAlert(alert Alert) {
	defer func() {
		if r := recover(); r != nil {
			logMessage(fmt.Sprintf("Failed to send alert: %v", r), "ERROR")
		}
	}()
	
	scriptPath := filepath.Join(WORKSPACE, "skills", "channel-status-agent", "scripts", "channel_status.py")
	cmd := exec.Command("python3", scriptPath, "--type", "alert", "--message", fmt.Sprintf("%s: %s", alert.Level, alert.Message))
	err := cmd.Run()
	if err != nil {
		logMessage(fmt.Sprintf("Failed to send alert: %v", err), "ERROR")
		return
	}
	logMessage(fmt.Sprintf("Alert sent: %s", alert.Message), "INFO")
}

func main() {
	// Kommandozeilenargumente parsen
	node := "all"
	check := "all"
	alert := false
	
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		switch arg {
		case "--node":
			if i+1 < len(os.Args) {
				node = os.Args[i+1]
				i++
			}
		case "--check":
			if i+1 < len(os.Args) {
				check = os.Args[i+1]
				i++
			}
		case "--alert":
			alert = true
		case "-h", "--help":
			fmt.Println("Node Health Monitor")
			fmt.Println("Usage: node_health [options]")
			fmt.Println("Options:")
			fmt.Println("  --node NODE    Node ID oder \"all\"")
			fmt.Println("  --check CHECK  Check type: ping, ssh, metrics, all")
			fmt.Println("  --alert        Sende Alerts")
			os.Exit(0)
		}
	}
	
	// Nodes bestimmen
	var nodesToCheck map[string]NodeConfig
	if node == "all" {
		nodesToCheck = NODES
	} else {
		if config, exists := NODES[node]; exists {
			nodesToCheck = map[string]NodeConfig{node: config}
		} else {
			logMessage(fmt.Sprintf("Unknown node: %s", node), "ERROR")
			os.Exit(1)
		}
	}
	
	// Health-Checks durchführen
	var allAlerts []Alert
	
	for nodeID, nodeConfig := range nodesToCheck {
		logMessage(fmt.Sprintf("Checking %s (%s)", nodeConfig.Name, nodeID), "INFO")
		
		// Ping
		if check == "ping" || check == "all" {
			if nodeConfig.Host != "localhost" {
				pingOk := checkPing(nodeConfig.Host, 5)
				status := "FAILED"
				if pingOk {
					status = "OK"
				}
				logMessage(fmt.Sprintf("  Ping: %s", status), "INFO")
			}
		}
		
		// SSH
		if check == "ssh" || check == "all" {
			sshOk := checkSSH(nodeConfig)
			status := "FAILED"
			if sshOk {
				status = "OK"
			}
			logMessage(fmt.Sprintf("  SSH: %s", status), "INFO")
		}
		
		// Metriken
		if check == "metrics" || check == "all" {
			metrics := getMetricsViaSSH(nodeConfig)
			
			if metrics.Available {
				if metrics.CPU != nil {
					logMessage(fmt.Sprintf("  CPU: %.1f%%", *metrics.CPU), "INFO")
				} else {
					logMessage("  CPU: N/A", "INFO")
				}
				if metrics.RAM != nil {
					logMessage(fmt.Sprintf("  RAM: %.1f%%", *metrics.RAM), "INFO")
				} else {
					logMessage("  RAM: N/A", "INFO")
				}
				if metrics.Disk != nil {
					logMessage(fmt.Sprintf("  Disk: %d%%", *metrics.Disk), "INFO")
				} else {
					logMessage("  Disk: N/A", "INFO")
				}
				if metrics.Load != nil {
					logMessage(fmt.Sprintf("  Load: %.2f", *metrics.Load), "INFO")
				} else {
					logMessage("  Load: N/A", "INFO")
				}
			} else {
				logMessage("  Metrics: UNAVAILABLE", "INFO")
			}
			
			// Alerts prüfen
			alerts := checkAlerts(nodeID, nodeConfig, metrics)
			allAlerts = append(allAlerts, alerts...)
		}
	}
	
	// Alerts senden
	if alert && len(allAlerts) > 0 {
		logMessage(fmt.Sprintf("\nSending %d alerts...", len(allAlerts)), "INFO")
		for _, alert := range allAlerts {
			sendAlert(alert)
		}
	} else if len(allAlerts) > 0 {
		logMessage(fmt.Sprintf("\n%d alerts found (use --alert to send)", len(allAlerts)), "INFO")
	} else {
		logMessage("\nAll nodes healthy!", "INFO")
	}
}
