// abstraction-provenance: {"artifact_sha256": "e769bc85b694de4dd869fae2b67fc4c2b74344e285ef898aec838004f1fe9571", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "go"}
// fix_gateway_node_path.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"os/exec"
	"time"
	"strings"
)

func main() {
	// Backup der originalen Service-Datei
	backupFile := fmt.Sprintf("/etc/systemd/system/openclaw-gateway.service.backup-%s", 
		time.Now().Format("20060102_150405"))
	
	copyCmd := exec.Command("cp", "/etc/systemd/system/openclaw-gateway.service", backupFile)
	if err := copyCmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Erstellen des Backups: %v\n", err)
		os.Exit(1)
	}
	
	// Korrektur des Node.js Pfads in der Service-Datei
	// Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
	readFile, err := os.ReadFile("/etc/systemd/system/openclaw-gateway.service")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Lesen der Service-Datei: %v\n", err)
		os.Exit(1)
	}
	
	newContent := strings.ReplaceAll(string(readFile), 
		"/home/openclaw/.nvm/versions/node/v22.22.2/bin/node", 
		"/usr/bin/node")
	
	err = os.WriteFile("/etc/systemd/system/openclaw-gateway.service", []byte(newContent), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Schreiben der korrigierten Service-Datei: %v\n", err)
		os.Exit(1)
	}
	
	// Service neu laden und neu starten
	daemonReload := exec.Command("systemctl", "daemon-reload")
	if err := daemonReload.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Neuladen der Systemd-Konfiguration: %v\n", err)
		os.Exit(1)
	}
	
	restartCmd := exec.Command("systemctl", "restart", "openclaw-gateway")
	if err := restartCmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Neustarten des Services: %v\n", err)
		os.Exit(1)
	}
	
	// Status prüfen
	statusCmd := exec.Command("systemctl", "status", "openclaw-gateway", "--no-pager")
	statusCmd.Stdout = os.Stdout
	statusCmd.Stderr = os.Stderr
	statusCmd.Run()
}
