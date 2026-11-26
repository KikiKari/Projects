// abstraction-provenance: {"artifact_sha256": "593c9efe9dd7e49e339122a9b7f842cfc56611fc28f69a4b33f99e75920d5cde", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "go"}
// dispatch_job.py — portiert nach go
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// Node-Konfiguration
var NODES = map[string]map[string]interface{}{
	"node1": {"always_available": true, "capacity": "medium", "priority": 2},
	"node2": {"always_available": true, "capacity": "medium", "priority": 3},
	"node3": {"always_available": false, "capacity": "medium", "priority": 4},
	"node5": {"always_available": false, "capacity": "low", "priority": 5, "device": "Redmi Note 11S"},
	"node7": {"always_available": true, "capacity": "high", "priority": 1},
}

type JobDispatcher struct{}

// Bewertet Job-Gewicht
func (jd *JobDispatcher) GetJobWeight(scriptPath string, targetLangsCount int) string {
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		return "medium"
	}

	fileInfo, err := os.Stat(scriptPath)
	if err != nil {
		return "medium"
	}

	scriptSize := fileInfo.Size()
	totalWork := scriptSize * int64(targetLangsCount)

	if totalWork > 50000 { // > 50KB
		return "heavy"
	} else if totalWork > 10000 { // > 10KB
		return "medium"
	} else {
		return "light"
	}
}

// Wählt besten Node basierend auf Job-Gewicht
func (jd *JobDispatcher) SelectNode(jobWeight string) string {
	var preferred []string

	if jobWeight == "heavy" {
		// Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
		preferred = []string{"node7", "node2", "node1"}
	} else if jobWeight == "medium" {
		// Mittlere Jobs → Stable Nodes
		preferred = []string{"node2", "node1", "node7"}
	} else { // light
		// Leichte Jobs → Mobile/verfügbare Nodes
		preferred = []string{"node5", "node1", "node2"}
	}

	// Prüfe Verfügbarkeit
	for _, nodeId := range preferred {
		if jd.CheckNodeAvailable(nodeId) {
			return nodeId
		}
	}

	// Fallback
	return "node1"
}

// Prüft ob Node erreichbar ist
func (jd *JobDispatcher) CheckNodeAvailable(nodeId string) bool {
	node, exists := NODES[nodeId]
	if !exists {
		return false
	}

	// Nicht immer-verfügbare Nodes nur wenn explizit requested
	if alwaysAvailable, ok := node["always_available"].(bool); !ok || !alwaysAvailable {
		// Für light-jobs prüfen wir ob online
		if nodeId == "node5" { // Redmi
			return jd.checkMobileOnline()
		}
		return false
	}

	// Für immer-verfügbare Nodes: prüfe ob wirklich online
	cmd := exec.Command("openclaw", "nodes", "status", nodeId)
	cmd.Stdout = nil
	cmd.Stderr = nil
	
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	
	cmd = exec.CommandContext(ctx, "openclaw", "nodes", "status", nodeId)
	err := cmd.Run()
	
	if err != nil {
		// Fallback to config value if command fails
		alwaysAvailable, _ := node["always_available"].(bool)
		return alwaysAvailable
	}
	
	return true
}

// Prüft ob Redmi (Node 5) Internet hat
func (jd *JobDispatcher) checkMobileOnline() bool {
	cmd := exec.Command("openclaw", "nodes", "status", "node5")
	var out bytes.Buffer
	cmd.Stdout = &out
	
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	
	cmd = exec.CommandContext(ctx, "openclaw", "nodes", "status", "node5")
	err := cmd.Run()
	
	if err != nil {
		return false
	}
	
	output := strings.ToLower(out.String())
	return strings.Contains(output, "online")
}

// Dispatched Job und gibt Info zurück
func (jd *JobDispatcher) Dispatch(jobScript string, targetLangs []string) map[string]interface{} {
	if targetLangs == nil {
		targetLangs = []string{"perl5"}
	}

	weight := jd.GetJobWeight(jobScript, len(targetLangs))
	selectedNode := jd.SelectNode(weight)

	return map[string]interface{}{
		"job":          jobScript,
		"weight":       weight,
		"selected_node": selectedNode,
		"target_langs":  targetLangs,
		"status":       "dispatched",
	}
}

func main() {
	jobPath := ""
	langs := "perl5"
	weight := ""
	execute := false

	// Simple argument parsing
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--job" || arg == "-j" {
			if i+1 < len(args) {
				jobPath = args[i+1]
				i++
			}
		} else if arg == "--langs" || arg == "-l" {
			if i+1 < len(args) {
				langs = args[i+1]
				i++
			}
		} else if arg == "--weight" || arg == "-w" {
			if i+1 < len(args) {
				weight = args[i+1]
				i++
			}
		} else if arg == "--execute" || arg == "-x" {
			execute = true
		}
	}

	if jobPath == "" {
		fmt.Println("❌ Job path is required")
		os.Exit(1)
	}

	if _, err := os.Stat(jobPath); os.IsNotExist(err) {
		fmt.Printf("❌ Job not found: %s\n", jobPath)
		os.Exit(1)
	}

	dispatcher := JobDispatcher{}
	targetLangs := strings.Split(langs, ",")

	// Determine weight
	var jobWeight string
	if weight != "" {
		jobWeight = weight
	} else {
		jobWeight = dispatcher.GetJobWeight(jobPath, len(targetLangs))
	}

	// Select node
	selectedNode := dispatcher.SelectNode(jobWeight)

	// Get file size
	fileInfo, _ := os.Stat(jobPath)
	fileSize := fileInfo.Size()

	// Output
	fmt.Println("📦 Job Dispatch Information")
	fmt.Println("==================================================")
	fmt.Printf("Job: %s\n", jobPath)
	fmt.Printf("Size: %d bytes\n", fileSize)
	fmt.Printf("Target langs: %s\n", strings.Join(targetLangs, ", "))
	fmt.Printf("Job weight: %s\n", jobWeight)
	fmt.Printf("Selected node: %s\n", selectedNode)
	fmt.Println("==================================================")

	if execute {
		fmt.Printf("\n🚀 Executing on %s...\n", selectedNode)
		// TODO: Implement remote execution
		fmt.Println("(Remote execution not yet implemented)")
	} else {
		executable, _ := os.Executable()
		fmt.Printf("\n💡 To execute: %s --job %s --execute\n", filepath.Base(executable), jobPath)
	}
}
