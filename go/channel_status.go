// abstraction-provenance: {"artifact_sha256": "fca9a42b084d21514dccde455f8ca0d0b2354f9ce69bf7df2212d55f8a183863", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "go"}
// channel_status.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

/*
Channel Status Agent - Automatische Status-Updates
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

// Konfiguration
var (
	WORKSPACE  = "/home/openclaw/.openclaw/workspace"
	LOGS_DB    = filepath.Join(WORKSPACE, "db/logs.db")
	CONFIG_FILE = filepath.Join(WORKSPACE, "config/channel-status.json")
	LOG_FILE   = filepath.Join(WORKSPACE, "logs/channel-status.log")
)

type Status struct {
	Timestamp string            `json:"timestamp"`
	Nodes     map[string]Node   `json:"nodes"`
	Agents    map[string]interface{} `json:"agents"`
	System    map[string]string `json:"system"`
}

type Node struct {
	Name   string `json:"name"`
	Status string `json:"status"`
	Reason string `json:"reason,omitempty"`
}

func init() {
	// Create logs directory if it doesn't exist
	logDir := filepath.Dir(LOG_FILE)
	if _, err := os.Stat(logDir); os.IsNotExist(err) {
		os.MkdirAll(logDir, 0755)
	}
}

func logMessage(message, level string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	entry := fmt.Sprintf("[%s] [%s] %s", timestamp, level, message)
	fmt.Println(entry)
	
	f, err := os.OpenFile(LOG_FILE, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return
	}
	defer f.Close()
	
	f.WriteString(entry + "\n")
}

func getSystemStatus() Status {
	status := Status{
		Timestamp: time.Now().Format(time.RFC3339),
		Nodes:     make(map[string]Node),
		Agents:    make(map[string]interface{}),
		System:    make(map[string]string),
	}
	
	// Node-Status (vereinfacht)
	nodes := map[string]Node{
		"node1": {"Gateway", "online", ""},
		"node2": {"Worker", "online", ""},
		"node3": {"Relay", "offline", "disk full"},
		"node5": {"Redmi", "intermittent", ""},
		"node7": {"Docker", "planned", ""},
	}
	status.Nodes = nodes
	
	// Agent-Status aus Cron
	cmd := exec.Command("crontab", "-l")
	var out bytes.Buffer
	cmd.Stdout = &out
	err := cmd.Run()
	if err != nil {
		status.Agents["active_crons"] = "unknown"
	} else {
		lines := strings.Split(out.String(), "\n")
		count := 0
		for _, line := range lines {
			if !strings.HasPrefix(line, "#") && strings.TrimSpace(line) != "" {
				count++
			}
		}
		status.Agents["active_crons"] = count
	}
	
	// System-Metriken
	// Disk usage
	cmd = exec.Command("df", "-h", "/")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err == nil {
		lines := strings.Split(out.String(), "\n")
		for _, line := range lines {
			if strings.Contains(line, "/") && strings.Contains(line, "%") {
				parts := strings.Fields(line)
				if len(parts) >= 5 {
					status.System["disk_used"] = parts[4]
				}
				break
			}
		}
	}
	
	// RAM usage
	cmd = exec.Command("free", "-h")
	out.Reset()
	cmd.Stdout = &out
	err = cmd.Run()
	if err == nil {
		lines := strings.Split(out.String(), "\n")
		for _, line := range lines {
			if strings.Contains(line, "Mem:") {
				parts := strings.Fields(line)
				if len(parts) >= 2 {
					status.System["ram_total"] = parts[1]
					if len(parts) >= 3 {
						status.System["ram_used"] = parts[2]
					}
				}
				break
			}
		}
	}
	
	return status
}

func formatDailyStatus(status Status) string {
	online := 0
	for _, node := range status.Nodes {
		if node.Status == "online" {
			online++
		}
	}
	
	message := fmt.Sprintf("📊 **Täglicher Status-Report**\n🗓️ %s\n\n**🖥️ Nodes (%d/5 online):**\n",
		time.Now().Format("2006-01-02 15:04"),
		online)
	
	for nodeID, info := range status.Nodes {
		emoji := "🔴"
		if info.Status == "online" {
			emoji = "🟢"
		} else if info.Status == "intermittent" {
			emoji = "🟡"
		}
		
		line := fmt.Sprintf("%s %s: %s", emoji, info.Name, info.Status)
		if info.Reason != "" {
			line += fmt.Sprintf(" (%s)", info.Reason)
		}
		message += line + "\n"
	}
	
	message += fmt.Sprintf("\n**🤖 Agents:**\nAktive Cron-Jobs: %v\n", status.Agents["active_crons"])
	
	if diskUsed, exists := status.System["disk_used"]; exists {
		message += "\n**💾 System:**\n"
		message += fmt.Sprintf("Disk: %s belegt\n", diskUsed)
		if ramUsed, exists := status.System["ram_used"]; exists {
			if ramTotal, exists := status.System["ram_total"]; exists {
				message += fmt.Sprintf("RAM: %s / %s\n", ramUsed, ramTotal)
			}
		}
	}
	
	return message
}

func formatWeeklyStatus(status Status) string {
	_, week := time.Now().ISOWeek()
	message := fmt.Sprintf(`📈 **Wöchentlicher Report**
📅 Woche %d - %d

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
`, week, time.Now().Year())
	
	return message
}

func sendToChannel(message, channelType, channelID string) bool {
	if channelType != "telegram" {
		logMessage(fmt.Sprintf("Channel type %s not implemented", channelType), "WARN")
		return false
	}
	
	// Nutze OpenClaw message tool
	cmd := exec.Command("openclaw", "message", "send", "--target", channelID, "--message", message)
	
	output, err := cmd.CombinedOutput()
	if err != nil {
		logMessage(fmt.Sprintf("Failed to send: %s", string(output)), "ERROR")
		return false
	}
	
	logMessage(fmt.Sprintf("Message sent to %s %s", channelType, channelID), "INFO")
	return true
}

func main() {
	var rootCmd = &cobra.Command{
		Use:   "channel-status",
		Short: "Channel Status Agent",
		Run: func(cmd *cobra.Command, args []string) {
			daily, _ := cmd.Flags().GetBool("daily")
			weekly, _ := cmd.Flags().GetBool("weekly")
			alert, _ := cmd.Flags().GetBool("alert")
			message, _ := cmd.Flags().GetString("message")
			channel, _ := cmd.Flags().GetString("channel")
			dryRun, _ := cmd.Flags().GetBool("dry-run")
			
			var updateType string
			if daily {
				updateType = "daily"
			} else if weekly {
				updateType = "weekly"
			} else if alert {
				updateType = "alert"
			} else {
				fmt.Println("Please specify --daily, --weekly, or --alert")
				return
			}
			
			logMessage(fmt.Sprintf("Starting %s status update", updateType), "INFO")
			
			// Status sammeln
			status := getSystemStatus()
			
			// Message formatieren
			var formattedMessage string
			switch updateType {
			case "daily":
				formattedMessage = formatDailyStatus(status)
			case "weekly":
				formattedMessage = formatWeeklyStatus(status)
			case "alert":
				if message == "" {
					message = "Manual alert"
				}
				formattedMessage = fmt.Sprintf("🚨 **ALERT**\n%s", message)
			}
			
			// Senden oder Dry-Run
			if dryRun {
				fmt.Println("\n--- DRY RUN ---")
				fmt.Println(formattedMessage)
				fmt.Println("--- END ---")
			} else {
				sendToChannel(formattedMessage, "telegram", channel)
			}
			
			logMessage("Status update completed", "INFO")
		},
	}
	
	rootCmd.Flags().Bool("daily", false, "Send daily status report")
	rootCmd.Flags().Bool("weekly", false, "Send weekly status report")
	rootCmd.Flags().Bool("alert", false, "Send alert message")
	rootCmd.Flags().String("message", "", "Alert message content")
	rootCmd.Flags().String("channel", "-1002381931352", "Target channel ID")
	rootCmd.Flags().Bool("dry-run", false, "Show message without sending")
	
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
