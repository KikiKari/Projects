// abstraction-provenance: {"artifact_sha256": "81a7b9cacc38416495b2f4bb0d3ede7e433d0d7b4a9f1c18cd7cf8dbfbce710b", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "go"}
// openclaw-node-autostart-termux.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

const (
	SESSION  = "openclaw-node"
	GATEWAY  = "10.10.0.1"
	PORT     = "18789"
)

func main() {
	homeDir := os.Getenv("HOME")
	if homeDir == "" {
		log.Fatal("HOME environment variable not set")
	}

	logDir := filepath.Join(homeDir, ".openclaw")
	err := os.MkdirAll(logDir, 0755)
	if err != nil {
		log.Fatalf("Failed to create log directory: %v", err)
	}

	logFile := filepath.Join(logDir, "node.log")
	logFd, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		log.Fatalf("Failed to open log file: %v", err)
	}
	defer logFd.Close()

	// Prüfen ob tmux Session bereits läuft
	if sessionExists(SESSION) {
		msg := fmt.Sprintf("[%s] OpenClaw Node läuft bereits in tmux Session '%s'\n", time.Now().Format(time.RFC3339), SESSION)
		logFd.WriteString(msg)
		return
	}

	// Neue tmux Session erstellen und OpenClaw starten
	cmd := exec.Command("tmux", "new-session", "-d", "-s", SESSION, "-n", "node")
	script := `
while true; do
	echo "[` + time.Now().Format(time.RFC3339) + `] Starting OpenClaw Node Mode..." | tee -a '` + logFile + `'
	
	# Prüfe WireGuard Verbindung
	if ! ping -c 1 -W 3 ` + GATEWAY + ` >/dev/null 2>&1; then
		echo "[` + time.Now().Format(time.RFC3339) + `] FEHLER: WireGuard Gateway ` + GATEWAY + ` nicht erreichbar!" | tee -a '` + logFile + `'
		echo "[` + time.Now().Format(time.RFC3339) + `] Warte 10 Sekunden..." | tee -a '` + logFile + `'
		sleep 10
		continue
	fi
	
	# OpenClaw Node Mode starten
	openclaw node run --host ` + GATEWAY + ` --port ` + PORT + ` 2>&1 | tee -a '` + logFile + `'
	
	# Wenn der Prozess endet, warte und neustarten
	echo "[` + time.Now().Format(time.RFC3339) + `] OpenClaw beendet. Neustart in 5 Sekunden..." | tee -a '` + logFile + `'
	sleep 5
done
`
	cmd.Stdin = strings.NewReader(script)
	err = cmd.Run()
	if err != nil {
		log.Fatalf("Failed to create tmux session: %v", err)
	}

	msg := fmt.Sprintf("[%s] OpenClaw Node Autostart aktiviert (tmux Session: %s)\n", time.Now().Format(time.RFC3339), SESSION)
	logFd.WriteString(msg)

	// Optional: tmux attach Hinweis falls interaktiv gestartet
	if isTerminal() {
		fmt.Printf("OpenClaw Node Mode gestartet in tmux Session '%s'\n", SESSION)
		fmt.Printf("Zum Anschauen: tmux attach -t %s\n", SESSION)
		fmt.Printf("Log-Datei: %s\n", logFile)
	}
}

func sessionExists(session string) bool {
	cmd := exec.Command("tmux", "has-session", "-t", session)
	err := cmd.Run()
	return err == nil
}

func isTerminal() bool {
	fileInfo, _ := os.Stdout.Stat()
	return (fileInfo.Mode() & os.ModeCharDevice) != 0
}
