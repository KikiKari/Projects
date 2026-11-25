// abstraction-provenance: {"artifact_sha256": "684fb1f5e76f69fc5c856a145abc63d5eda138b564248a8341106cfd782ec83c", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "go"}
// abstractions-manager.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"os"
	"os/exec"
	"syscall"
)

func main() {
	// Execute the cron script with the same arguments
	scriptPath := "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh"
	
	// Get all command line arguments
	args := os.Args[1:]
	
	// Execute the script and replace current process
	err := syscall.Exec(scriptPath, append([]string{scriptPath}, args...), os.Environ())
	if err != nil {
		// If exec fails, try running it through shell as fallback
		cmd := exec.Command(scriptPath, args...)
		cmd.Stdin = os.Stdin
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		
		if err := cmd.Run(); err != nil {
			os.Exit(1)
		}
	}
}
