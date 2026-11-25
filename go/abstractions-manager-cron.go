// abstraction-provenance: {"artifact_sha256": "dcc55c975fe612ba2c61619365723415304a830da3d2f23cd088cbd7d4a763c2", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "go"}
// abstractions-manager-cron.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"

	"github.com/joho/godotenv"
)

func main() {
	// Set the PATH environment variable
	os.Setenv("PATH", "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin")

	// Load environment variables from .env file
	envPath := "/home/openclaw/.openclaw/.env"
	err := godotenv.Load(envPath)
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// Check if OPENROUTER_API_KEY is set
	openrouterAPIKey, exists := os.LookupEnv("OPENROUTER_API_KEY")
	if !exists {
		log.Fatal("OPENROUTER_API_KEY fehlt")
	}
	_ = openrouterAPIKey // Use the variable to suppress unused warning

	// Set GITHUB_TOKEN with fallbacks
	githubToken := os.Getenv("GITHUB_TOKEN")
	if githubToken == "" {
		githubToken = os.Getenv("GH_TOKEN")
		if githubToken == "" {
			githubToken = os.Getenv("GH_ACCESS_TOKEN")
		}
	}
	os.Setenv("GITHUB_TOKEN", githubToken)

	// Define the lock file and script path
	lockFile := "/home/openclaw/.openclaw/locks/abstractions-manager.lock"
	scriptPath := "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py"

	// Attempt to acquire a non-blocking lock
	fd, err := syscall.Open(lockFile, syscall.O_CREAT|syscall.O_RDWR, 0666)
	if err != nil {
		log.Fatalf("Failed to open lock file: %v", err)
	}
	defer syscall.Close(fd)

	err = syscall.Flock(fd, syscall.LOCK_EX|syscall.LOCK_NB)
	if err != nil {
		fmt.Println("Another instance is already running.")
		return
	}
	defer syscall.Flock(fd, syscall.LOCK_UN)

	// Execute the Python script with arguments
	cmd := exec.Command("/usr/bin/python3", scriptPath, os.Args[1:]...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		log.Fatalf("Failed to execute script: %v", err)
	}
}
