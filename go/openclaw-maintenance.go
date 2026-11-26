// abstraction-provenance: {"artifact_sha256": "413a26b983dc1fd8b915fe3df7f1d6d1178abdec6164b6d9aa59b6d5c446a451", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "go"}
// openclaw-maintenance.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"os/exec"
)

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	fmt.Printf("Running: %s %v\n", name, args)
	return cmd.Run()
}

func main() {
	// === 1. Service-/Config-Drift ===
	if err := runCommand("openclaw", "doctor"); err != nil {
		fmt.Fprintf(os.Stderr, "Error running openclaw doctor: %v\n", err)
		os.Exit(1)
	}

	// === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
	if err := runCommand("openclaw", "plugins", "registry", "--refresh"); err != nil {
		fmt.Fprintf(os.Stderr, "Error refreshing plugin registry: %v\n", err)
		os.Exit(1)
	}

	if err := runCommand("openclaw", "plugins", "update", "--all"); err != nil {
		fmt.Fprintf(os.Stderr, "Error updating plugins: %v\n", err)
		os.Exit(1)
	}

	// === 3. Tasks ===
	if err := runCommand("openclaw", "tasks", "maintenance", "--apply"); err != nil {
		fmt.Fprintf(os.Stderr, "Error running tasks maintenance: %v\n", err)
		os.Exit(1)
	}

	// === 4. Sessions – alle Agents auf einmal ===
	if err := runCommand("openclaw", "sessions", "cleanup", "--enforce", "--all-agents"); err != nil {
		fmt.Fprintf(os.Stderr, "Error cleaning up sessions: %v\n", err)
		os.Exit(1)
	}

	// === 5. Memory – status/index decken alle Agents ab ===
	if err := runCommand("openclaw", "memory", "status", "--deep", "--fix"); err != nil {
		fmt.Fprintf(os.Stderr, "Error checking memory status: %v\n", err)
		os.Exit(1)
	}

	if err := runCommand("openclaw", "memory", "index", "--force"); err != nil {
		fmt.Fprintf(os.Stderr, "Error indexing memory: %v\n", err)
		os.Exit(1)
	}

	// === 6. Memory promote – MUSS pro Agent ===
	agents := []string{"main", "knecht", "docs", "ops-hub", "cron"}
	for _, agent := range agents {
		if err := runCommand("openclaw", "memory", "promote", "--apply", "--agent", agent); err != nil {
			fmt.Fprintf(os.Stderr, "Error promoting memory for agent %s: %v\n", agent, err)
			os.Exit(1)
		}
	}

	// === 7. Secrets ===
	if err := runCommand("openclaw", "secrets", "reload"); err != nil {
		fmt.Fprintf(os.Stderr, "Error reloading secrets: %v\n", err)
		os.Exit(1)
	}
}
