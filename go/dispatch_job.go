// abstraction-provenance: {"artifact_sha256": "f9d927d60f8f9bbcf631b175fa4928f0b3ba575301a9efaad06588319307b47f", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "go"}
// dispatch_job.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Job Dispatcher - Verteilt Jobs auf passende Nodes
*/

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

// NodeConfig represents node configuration
type NodeConfig struct {
	AlwaysAvailable bool   `json:"always_available"`
	Capacity       string `json:"capacity,omitempty"`
	Priority       int    `json:"priority,omitempty"`
	Description    string `json:"description,omitempty"`
	Device         string `json:"device,omitempty"`
}

// NodeStatus represents the connection status of nodes
type NodeStatus map[string]bool

// Job represents a translation job
type Job struct {
	JobID          string `json:"job_id"`
	Source         string `json:"source"`
	TargetLanguage string `json:"target_language"`
	SelectedNode   string `json:"selected_node"`
	SourceText     string `json:"source_text,omitempty"`
	SourceLanguage string `json:"source_language,omitempty"`
}

// DispatchResult represents the result of job dispatching
type DispatchResult struct {
	Job             string            `json:"job"`
	Weight          string            `json:"weight"`
	SelectedNode    string            `json:"selected_node"`
	TargetLangs     []string          `json:"target_langs"`
	TranslationJobs []Job             `json:"translation_jobs"`
	Status          string            `json:"status"`
}

// TransportFunc defines the function signature for transport
type TransportFunc func(Job) map[string]interface{}

var (
	// Node configuration
	NODES = map[string]NodeConfig{
		"node1": {"true", "medium", 3, "Gateway", ""},
		"node2": {"false", "high", 1, "ARM Server", ""},
		"node3": {"false", "medium", 4, "AMD Server", ""},
		"node4": {"false", "low", 5, "", "Redmi Note 11S"},
		"node5": {"false", "high", 2, "", "Lenovo"},
		"node6": {"false", "", 0, "", "Lenovo (Docker)"},
	}

	// Node names mapping
	NODE_NAMES = map[string][]string{
		"node2": {"openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"},
		"node3": {"openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"},
		"node4": {"openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"},
		"node5": {"openclaw-node5", "windows node (lenovo-7)"},
		"node6": {"openclaw-node6"},
	}
)

// jobWeightBytes calculates Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen
func jobWeightBytes(scriptPath string, targetLangsCount int) int {
	info, err := os.Stat(scriptPath)
	if err != nil {
		return 0
	}
	return int(info.Size()) * targetLangsCount
}

// fetchNodeStatus returns mapped OpenClaw connection states; nil indicates lookup failure
func fetchNodeStatus() NodeStatus {
	cmd := exec.Command("openclaw", "nodes", "status", "--json")
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	
	// Set timeout
	done := make(chan error, 1)
	go func() {
		done <- cmd.Run()
	}()
	
	select {
	case <-time.After(10 * time.Second):
		return nil
	case err := <-done:
		if err != nil {
			return nil
		}
	}
	
	var payload map[string]interface{}
	if err := json.Unmarshal(stdout.Bytes(), &payload); err != nil {
		return nil
	}
	
	nodes, ok := payload["nodes"].([]interface{})
	if !ok {
		return nil
	}
	
	states := make(NodeStatus)
	for node := range NODE_NAMES {
		states[node] = false
	}
	
	for _, item := range nodes {
		nodeMap, ok := item.(map[string]interface{})
		if !ok {
			continue
		}
		
		names := make(map[string]bool)
		for _, key := range []string{"displayName", "nodeId", "remoteIp"} {
			if val, exists := nodeMap[key]; exists {
				names[strings.ToLower(fmt.Sprintf("%v", val))] = true
			}
		}
		
		for node, aliases := range NODE_NAMES {
			for _, alias := range aliases {
				if names[strings.ToLower(alias)] {
					if connected, ok := nodeMap["connected"].(bool); ok && connected {
						states[node] = true
					}
					break
				}
			}
		}
	}
	
	states["node1"] = true // successful Gateway status request
	return states
}

// JobDispatcher handles job dispatching
type JobDispatcher struct{}

// GetJobWeight bewertet Job-Gewicht
func (jd *JobDispatcher) GetJobWeight(scriptPath string, targetLangsCount int) string {
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		return "medium"
	}
	
	totalWork := jobWeightBytes(scriptPath, targetLangsCount)
	
	if totalWork > 50000 { // > 50KB
		return "heavy"
	} else if totalWork > 10000 { // > 10KB
		return "medium"
	} else {
		return "light"
	}
}

// SelectNode wählt besten Node basierend auf Job-Gewicht
func (jd *JobDispatcher) SelectNode(jobWeight string) string {
	var preferred []string
	
	switch jobWeight {
	case "heavy":
		preferred = []string{"node1", "node2", "node5", "node6"}
	case "medium":
		preferred = []string{"node1", "node2", "node3", "node6"}
	case "light":
		preferred = []string{"node2", "node1", "node3", "node4"}
	default:
		return ""
	}
	
	states := fetchNodeStatus()
	for _, nodeID := range preferred {
		if states != nil && states[nodeID] {
			return nodeID
		}
	}
	return "" // no verified reachable node
}

// CheckNodeAvailable uses the live connection state rather than static availability
func (jd *JobDispatcher) CheckNodeAvailable(nodeID string) bool {
	states := fetchNodeStatus()
	return states != nil && states[nodeID]
}

// ExecuteTranslation executes via a supplied transport and verify its result belongs to the job
func (jd *JobDispatcher) ExecuteTranslation(job Job, transport TransportFunc) (string, error) {
	if job.SelectedNode == "" || transport == nil {
		return "", fmt.Errorf("no verified node or authorized translation transport")
	}
	
	response := transport(job)
	
	jobID, ok1 := response["job_id"].(string)
	selectedNode, ok2 := response["selected_node"].(string)
	targetLanguage, ok3 := response["target_language"].(string)
	
	if !ok1 || !ok2 || !ok3 ||
		jobID != job.JobID ||
		selectedNode != job.SelectedNode ||
		targetLanguage != job.TargetLanguage {
		return "", fmt.Errorf("transport response does not match job")
	}
	
	code, ok := response["code"].(string)
	status, statusOk := response["status"].(string)
	
	if !statusOk || status != "ok" || !ok || strings.TrimSpace(code) == "" {
		return "", fmt.Errorf("translation did not complete with code")
	}
	
	return code, nil
}

// CheckMobileOnline checks Node4 (Redmi)
func (jd *JobDispatcher) CheckMobileOnline() bool {
	return jd.CheckNodeAvailable("node4")
}

// Dispatch dispatched Job und gibt Info zurück
func (jd *JobDispatcher) Dispatch(jobScript string, targetLangs []string, sourceText, sourceLanguage *string) DispatchResult {
	if targetLangs == nil {
		targetLangs = []string{"perl5"}
	}
	
	weight := jd.GetJobWeight(jobScript, len(targetLangs))
	selectedNode := jd.SelectNode(weight)
	
	var translationJobs []Job
	for _, language := range targetLangs {
		job := Job{
			JobID:          generateUUID(),
			Source:         jobScript,
			TargetLanguage: language,
			SelectedNode:   selectedNode,
		}
		
		if sourceText != nil {
			job.SourceText = *sourceText
		}
		if sourceLanguage != nil {
			job.SourceLanguage = *sourceLanguage
		}
		
		translationJobs = append(translationJobs, job)
	}
	
	status := "selected"
	if selectedNode == "" {
		status = "unavailable"
	}
	
	return DispatchResult{
		Job:             jobScript,
		Weight:          weight,
		SelectedNode:    selectedNode,
		TargetLangs:     targetLangs,
		TranslationJobs: translationJobs,
		Status:          status,
	}
}

// generateUUID generates a UUID string
func generateUUID() string {
	// Simple UUID generation - in production use proper UUID library
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		randomString(8), randomString(4), randomString(4), randomString(4), randomString(12))
}

// randomString generates a random hex string of given length
func randomString(length int) string {
	const charset = "0123456789abcdef"
	result := make([]byte, length)
	for i := range result {
		result[i] = charset[int(time.Now().UnixNano())%len(charset)]
	}
	return string(result)
}

// dispatchAbstractionJob erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag
func dispatchAbstractionJob(jobScript string, targetLangs []string) DispatchResult {
	dispatcher := &JobDispatcher{}
	return dispatcher.Dispatch(jobScript, targetLangs, nil, nil)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: dispatch_job.go [options]")
		os.Exit(1)
	}
	
	// Parse arguments manually since we don't have argparse in Go
	var jobPath string
	var langs string
	var weight string
	var execute bool
	
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "--job", "-j":
			if i+1 < len(args) {
				jobPath = args[i+1]
				i++
			}
		case "--langs", "-l":
			if i+1 < len(args) {
				langs = args[i+1]
				i++
			}
		case "--weight", "-w":
			if i+1 < len(args) {
				weight = args[i+1]
				i++
			}
		case "--execute", "-x":
			execute = true
		}
	}
	
	if jobPath == "" {
		jobPath = args[0] // fallback to first argument
	}
	
	if jobPath == "" {
		fmt.Println("❌ Job path is required")
		os.Exit(1)
	}
	
	jobPathAbs, err := filepath.Abs(jobPath)
	if err != nil {
		fmt.Printf("❌ Invalid job path: %s\n", jobPath)
		os.Exit(1)
	}
	
	if _, err := os.Stat(jobPathAbs); os.IsNotExist(err) {
		fmt.Printf("❌ Job not found: %s\n", jobPathAbs)
		os.Exit(1)
	}
	
	dispatcher := &JobDispatcher{}
	var targetLangs []string
	
	if langs != "" {
		targetLangs = strings.Split(langs, ",")
		for i := range targetLangs {
			targetLangs[i] = strings.TrimSpace(targetLangs[i])
		}
	} else {
		targetLangs = []string{"perl5"}
	}
	
	// Determine weight
	var jobWeight string
	if weight != "" {
		jobWeight = weight
	} else {
		jobWeight = dispatcher.GetJobWeight(jobPathAbs, len(targetLangs))
	}
	
	// Select node
	selectedNode := dispatcher.SelectNode(jobWeight)
	
	// Get file size
	fileInfo, _ := os.Stat(jobPathAbs)
	fileSize := fileInfo.Size()
	
	// Output
	fmt.Println("📦 Job Dispatch Information")
	fmt.Println("==================================================")
	fmt.Printf("Job: %s\n", jobPathAbs)
	fmt.Printf("Size: %d bytes\n", fileSize)
	fmt.Printf("Target langs: %s\n", strings.Join(targetLangs, ", "))
	fmt.Printf("Job weight: %s\n", jobWeight)
	fmt.Printf("Selected node: %s\n", selectedNode)
	fmt.Println("==================================================")
	
	if execute {
		fmt.Fprintf(os.Stderr, "\nTranslation dispatch on %s is not implemented.\n", selectedNode)
		os.Exit(1)
	} else {
		fmt.Printf("\n💡 To execute: %s --job %s --execute\n", os.Args[0], jobPath)
	}
	
	os.Exit(0)
}
