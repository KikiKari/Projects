// abstraction-provenance: {"artifact_sha256": "6bd84994ba98ee6020f705524003a9974f538e59662968482693ab25a6d508a3", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "go"}
// node_health.py — portiert nach go
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Node Health Monitor - Multi-Node Gesundheitsüberwachung
*/

package main

import (
	"bufio"
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
	WORKSPACE = filepath.Join(os.Getenv("HOME"), ".openclaw", "workspace")
	HEALTH_DB = filepath.Join(WORKSPACE, "db", "health.db")
	LOG_FILE  = filepath.Join(WORKSPACE, "logs", "node-health.log")
)

// Node-Konfiguration
type NodeConfig struct {
	Name         string `json:"name"`
	Host         string `json:"host"`
	User         string `json:"user"`
	SSHOpts      string `json:"ssh_opts,omitempty"`
	Port         int    `json:"port,omitempty"`
	DiskWarning  int    `json:"disk_warning,omitempty"`
	Critical     bool   `json:"critical,omitempty"`
	Optional     bool   `json:"optional,omitempty"`
	SSHKey       string `json:"ssh_key,omitempty"`
}

// Metrikstruktur
type Metrics struct {
	Timestamp     string  `json:"timestamp"`
	Available     bool    `json:"available"`
	CPU           float64 `json:"cpu,omitempty"`
	RAM           float64 `json:"ram,omitempty"`
	Disk          int     `json:"disk,omitempty"`
	Load          float64 `json:"load,omitempty"`
	GatewayStatus string  `json:"gateway_status,omitempty"`
}

// Alert-Struktur
type Alert struct {
	Level   string `json:"level"`
	Message string `json:"message"`
}

var NODES = map[string]NodeConfig{
	"node1": {
		Name:     "Node 1",
		Host:     "localhost",
		User:     "openclaw",
		Critical: true,
	},
	"node2": {
		Name:    "Node 2",
		Host:    "10.10.0.2",
		User:    "root",
		SSHKey:  "~/.ssh/id_rsa",
		SSHOpts: "-o ConnectTimeout=10 -o BatchMode=yes",
	},
	"node3": {
		Name:        "Node 3",
		Host:        "localhost",
		User:        "root",
		Port:        18794,
		SSHOpts:     "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes",
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
	// Stelle sicher, dass das Log-Verzeichnis existiert
	logDir := filepath.Dir(LOG_FILE)
	if _, err := os.Stat(logDir); os.IsNotExist(err) {
		os.MkdirAll(logDir, 0755)
	}
	
	// Öffne Log-Datei
	logFile, err := os.OpenFile(LOG_FILE, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	
	// Setze Logger auf Log-Datei
	log.SetOutput(logFile)
	log.SetFlags(0) // Keine Standard-Flags, wir formatieren selbst
}

func logMessage(message string, level string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	entry := fmt.Sprintf("[%s] [%s] %s", timestamp, level, message)
	fmt.Println(entry)
	log.Println(entry)
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
	
	args := []string{}
	
	if nodeConfig.SSHOpts != "" {
		opts := strings.Split(nodeConfig.SSHOpts, " ")
		args = append(args, opts...)
	}
	
	if nodeConfig.Port != 0 {
		args = append(args, "-p", strconv.Itoa(nodeConfig.Port))
	}
	
	args = append(args, "-o", "ConnectTimeout=10", "-o", "BatchMode=yes")
	args = append(args, fmt.Sprintf("%s@%s", user, host), "echo", "\"OK\"")
	
	cmd := exec.Command("ssh", args...)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		return false
	}
	
	return strings.Contains(string(output), "OK")
}

func getNodeMetrics(nodeConfig NodeConfig) Metrics {
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
	cmdStr := fmt.Sprintf(`ssh -o ConnectTimeout=10 %s@%s '
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
	
	cmd := exec.Command("sh", "-c", cmdStr)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		logMessage(fmt.Sprintf("Error checking %s: %v", nodeConfig.Name, err), "ERROR")
		return metrics
	}
	
	metrics.Available = true
	
	scanner := bufio.NewScanner(strings.NewReader(string(output)))
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Contains(line, ":") {
			parts := strings.SplitN(line, ":", 2)
			key := parts[0]
			value := strings.TrimSpace(parts[1])
			
			switch key {
			case "CPU":
				if val, err := strconv.ParseFloat(value, 64); err == nil {
					metrics.CPU = val
				}
			case "RAM":
				if val, err := strconv.ParseFloat(value, 64); err == nil {
					metrics.RAM = val
				}
			case "DISK":
				if val, err := strconv.Atoi(value); err == nil {
					metrics.Disk = val
				}
			case "LOAD":
				if val, err := strconv.ParseFloat(value, 64); err == nil {
					metrics.Load = val
				}
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
		if metrics.CPU > 90 {
			alerts = append(alerts, Alert{
				Level:   "WARNING",
				Message: fmt.Sprintf("Node %s: CPU bei %.1f%%", nodeConfig.Name, metrics.CPU),
			})
		}
		
		// RAM
		if metrics.RAM > 90 {
			alerts = append(alerts, Alert{
				Level:   "WARNING",
				Message: fmt.Sprintf("Node %s: RAM bei %.1f%%", nodeConfig.Name, metrics.RAM),
			})
		}
		
		// Disk
		diskThreshold := nodeConfig.DiskWarning
		if diskThreshold == 0 {
			diskThreshold = 85
		}
		
		if metrics.Disk > diskThreshold {
			level := "WARNING"
			if metrics.Disk > 95 {
				level = "CRITICAL"
			}
			alerts = append(alerts, Alert{
				Level:   level,
				Message: fmt.Sprintf("Node %s: Disk bei %d%%", nodeConfig.Name, metrics.Disk),
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
	
	for i, arg := range os.Args {
		if arg == "--node" && i+1 < len(os.Args) {
			node = os.Args[i+1]
		}
		if arg == "--check" && i+1 < len(os.Args) {
			check = os.Args[i+1]
		}
		if arg == "--alert" {
			alert = true
		}
	}
	
	// Nodes bestimmen
	var nodesToCheck map[string]NodeConfig
	
	if node == "all" {
		nodesToCheck = NODES
	} else {
		if config, exists := NODES[node]; exists {
			nodesToCheck = make(map[string]NodeConfig)
			nodesToCheck[node] = config
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
				pingOk := checkPing(nodeConfig.Host, 10)
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
			metrics := getNodeMetrics(nodeConfig)
			
			if metrics.Available {
				if metrics.CPU != 0 {
					logMessage(fmt.Sprintf("  CPU: %.1f%%", metrics.CPU), "INFO")
				} else {
					logMessage("  CPU: N/A", "INFO")
				}
				
				if metrics.RAM != 0 {
					logMessage(fmt.Sprintf("  RAM: %.1f%%", metrics.RAM), "INFO")
				} else {
					logMessage("  RAM: N/A", "INFO")
				}
				
				if metrics.Disk != 0 {
					logMessage(fmt.Sprintf("  Disk: %d%%", metrics.Disk), "INFO")
				} else {
					logMessage("  Disk: N/A", "INFO")
				}
				
				if metrics.Load != 0 {
					logMessage(fmt.Sprintf("  Load: %.2f", metrics.Load), "INFO")
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
		for _, alertItem := range allAlerts {
			sendAlert(alertItem)
		}
	} else if len(allAlerts) > 0 {
		logMessage(fmt.Sprintf("\n%d alerts found (use --alert to send)", len(allAlerts)), "INFO")
	} else {
		logMessage("\nAll nodes healthy!", "INFO")
	}
}
