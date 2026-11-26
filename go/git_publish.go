// abstraction-provenance: {"artifact_sha256": "da386bae4a44849ee71ff33f6d15542abae12dcc3ab3f4f2b9b26f4705488631", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "go"}
// git_publish.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// Git Publish Agent - Automatisierte Skill-Veröffentlichung

package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

var SKILLS_DIR = filepath.Join(os.Getenv("HOME"), ".openclaw", "workspace", "skills")

func gitCommit(skillPath string, message string) bool {
	// Commit skill changes.
	if message == "" {
		now := time.Now().Format(time.RFC3339)
		message = fmt.Sprintf("[skill] Auto-update %s - %s", filepath.Base(skillPath), now)
	}

	cmd := exec.Command("git", "add", skillPath)
	cmd.Dir = filepath.Dir(SKILLS_DIR)
	err := cmd.Run()
	if err != nil {
		return false
	}

	cmd = exec.Command("git", "commit", "-m", message)
	cmd.Dir = filepath.Dir(SKILLS_DIR)
	err = cmd.Run()
	return err == nil
}

func clawhubPublish(skillName string) (bool, string) {
	// Publish to ClawHub.
	skillPath := filepath.Join(SKILLS_DIR, skillName)
	cmd := exec.Command("clawhub", "publish", skillPath,
		"--slug", skillName,
		"--version", "1.0.0")
	output, err := cmd.CombinedOutput()
	return err == nil, string(output)
}

func batchPublish() {
	// Publish all changed skills with rate limiting.
	cmd := exec.Command("git", "status", "--short", SKILLS_DIR)
	output, err := cmd.Output()
	if err != nil {
		fmt.Printf("Error getting git status: %v\n", err)
		return
	}

	lines := strings.Split(string(output), "\n")
	changed := make([]string, 0)
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && strings.Contains(line, "skills/") {
			parts := strings.Split(line, "skills/")
			if len(parts) > 1 {
				skill := strings.Split(parts[1], "/")[0]
				found := false
				for _, s := range changed {
					if s == skill {
						found = true
						break
					}
				}
				if !found {
					changed = append(changed, skill)
				}
			}
		}
	}

	fmt.Printf("Changed skills: %v\n", changed)

	// Publish with delay
	limit := len(changed)
	if limit > 5 {
		limit = 5 // Max 5 per batch
	}
	for i := 0; i < limit; i++ {
		skill := changed[i]
		if i > 0 {
			fmt.Println("Waiting 15min for rate limit...")
			// In real: time.Sleep(15 * time.Minute)
		}

		fmt.Printf("Publishing %s...\n", skill)
		commitOk := gitCommit(filepath.Join(SKILLS_DIR, skill), "")
		if commitOk {
			pubOk, output := clawhubPublish(skill)
			status := "✗"
			if pubOk {
				status = "✓"
			}
			fmt.Printf("  %s %s", status, output)
		}
	}
}

func main() {
	var skill string
	var all bool
	var noPublish bool
	var message string

	flag.StringVar(&skill, "skill", "", "Single skill to publish")
	flag.BoolVar(&all, "all", false, "Publish all changed")
	flag.BoolVar(&noPublish, "no-publish", false, "Commit only")
	flag.StringVar(&message, "message", "", "Custom commit message")
	flag.Parse()

	if skill != "" {
		skillPath := filepath.Join(SKILLS_DIR, skill)
		if noPublish {
			gitCommit(skillPath, message)
		} else {
			gitCommit(skillPath, message)
			clawhubPublish(skill)
		}
	} else if all {
		batchPublish()
	} else {
		fmt.Println("Use --skill <name> or --all")
	}
}
