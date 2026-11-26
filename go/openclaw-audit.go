// abstraction-provenance: {"artifact_sha256": "118e6f654dd486df978bb8b998ede2a067d0fb388dbfa739c00f5a7a196e691e", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "go"}
// openclaw-audit.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

func main() {
	scriptDir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		panic(err)
	}

	dateStamp := time.Now().Format("2006-01-02")
	out := filepath.Join(scriptDir, fmt.Sprintf("openclaw-audit-%s.log", dateStamp))

	oc := []string{"openclaw", "--no-color"}

	// Write header to log file
	logFile, err := os.Create(out)
	if err != nil {
		panic(err)
	}
	defer logFile.Close()

	writeLine(logFile, "================================================================")
	writeLine(logFile, "OpenClaw audit run")
	writeLine(logFile, fmt.Sprintf("Started:  %s", time.Now().Format(time.RFC3339)))
	writeLine(logFile, fmt.Sprintf("Host:     %s", getHostname()))
	writeLine(logFile, fmt.Sprintf("User:     %s", getCurrentUser()))
	
	version := getVersion()
	writeLine(logFile, fmt.Sprintf("Version:  %s", version))
	writeLine(logFile, fmt.Sprintf("Output:   %s", out))
	writeLine(logFile, "================================================================")

	// Run all commands
	runCmd(logFile, "tasks audit --severity error", append(oc, "tasks", "audit", "--severity", "error")...)
	runCmd(logFile, "secrets audit", append(oc, "secrets", "audit")...)
	runCmd(logFile, "security audit", append(oc, "security", "audit")...)
	runCmd(logFile, "plugins doctor", append(oc, "plugins", "doctor")...)
	runCmd(logFile, "plugins deps", append(oc, "plugins", "deps")...)
	runCmd(logFile, "plugins registry", append(oc, "plugins", "registry")...)
	runCmd(logFile, "skills check", append(oc, "skills", "check")...)
	runCmd(logFile, "hooks check", append(oc, "hooks", "check")...)
	runCmd(logFile, "gateway status --deep", append(oc, "gateway", "status", "--deep")...)
	runCmd(logFile, "channels status --probe", append(oc, "channels", "status", "--probe")...)
	runCmd(logFile, "memory status --deep", append(oc, "memory", "status", "--deep")...)
	runCmd(logFile, "sessions --all-agents", append(oc, "sessions", "--all-agents")...)
	runCmd(logFile, "tasks list", append(oc, "tasks", "list")...)
	runCmd(logFile, "cron list", append(oc, "cron", "list")...)

	// Write footer
	writeLine(logFile, "")
	writeLine(logFile, "================================================================")
	writeLine(logFile, fmt.Sprintf("Audit complete: %s", time.Now().Format(time.RFC3339)))
	writeLine(logFile, "================================================================")

	fmt.Printf("Audit complete. Output: %s\n", out)
}

func writeLine(file *os.File, line string) {
	file.WriteString(line + "\n")
}

func runCmd(logFile *os.File, title string, cmd ...string) {
	writeLine(logFile, "")
	writeLine(logFile, "----------------------------------------------------------------")
	writeLine(logFile, fmt.Sprintf("### %s", title))
	writeLine(logFile, fmt.Sprintf("### $ %s", strings.Join(cmd, " ")))
	writeLine(logFile, fmt.Sprintf("### %s", time.Now().Format(time.RFC3339)))
	writeLine(logFile, "----------------------------------------------------------------")
	
	command := exec.Command(cmd[0], cmd[1:]...)
	output, err := command.CombinedOutput()
	
	if len(output) > 0 {
		logFile.Write(output)
		if !strings.HasSuffix(string(output), "\n") {
			writeLine(logFile, "")
		}
	}
	
	rc := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			rc = exitError.ExitCode()
		} else {
			rc = 1
		}
	}
	writeLine(logFile, fmt.Sprintf("[exit: %d]", rc))
}

func getHostname() string {
	hostname, err := os.Hostname()
	if err != nil {
		return "unknown"
	}
	return hostname
}

func getCurrentUser() string {
	user := os.Getenv("USER")
	if user == "" {
		user = os.Getenv("USERNAME")
	}
	if user == "" {
		return "unknown"
	}
	return user
}

func getVersion() string {
	cmd := exec.Command("openclaw", "--version")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return "unknown"
	}
	return strings.TrimSpace(string(output))
}
