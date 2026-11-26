// abstraction-provenance: {"artifact_sha256": "bf70cf1ef351d6260ebfcddde0e7950f5cde51d175f653299522f38d8cfa7daa", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "go"}
// openclaw-maintenance.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func main() {
	openclawBin := os.Getenv("OPENCLAW_BIN")
	if openclawBin == "" {
		openclawBin = os.Getenv("HOME") + "/.local/bin/openclaw"
	}

	if _, err := os.Stat(openclawBin); os.IsNotExist(err) || os.FileMode(os.Stat(openclawBin).Sys().(*struct{ Stat_t uint64 }).Stat_t)&0111 == 0 {
		fmt.Fprintf(os.Stderr, "ERROR: OpenClaw binary not found: %s\n", openclawBin)
		os.Exit(1)
	}

	cmd := exec.Command(openclawBin, "--version")
	output, err := cmd.Output()
	if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to get OpenClaw version: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Using OpenClaw: %s", string(output))

	// === 1. Service-/Config-Drift ===
	runCommand(openclawBin, "doctor")

	// === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
	runCommand(openclawBin, "plugins", "registry", "--refresh")
	
	if os.Getenv("RUN_PLUGIN_UPDATE") == "1" {
		runCommand(openclawBin, "plugins", "update", "--all")
	} else {
		fmt.Println("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.")
	}

	// === 3. Tasks ===
	runCommand(openclawBin, "tasks", "maintenance", "--apply")

	// === 4. Sessions – alle Agents auf einmal ===
	runCommand(openclawBin, "sessions", "cleanup", "--enforce", "--all-agents")

	// === 5. Memory – status/index decken alle Agents ab ===
	runCommand(openclawBin, "memory", "status", "--deep", "--fix")
	runCommand(openclawBin, "memory", "index", "--force")

	// === 6. Memory promote – MUSS pro Agent ===
	agents := []string{"main", "knecht", "docs", "ops-hub", "cron"}
	for _, agent := range agents {
		runCommand(openclawBin, "memory", "promote", "--apply", "--agent", agent)
	}

	// === 7. Secrets ===
	runCommand(openclawBin, "secrets", "reload")
}

func runCommand(name string, args ...string) {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Command failed: %s %s: %v\n", name, strings.Join(args, " "), err)
		os.Exit(1)
	}
}
