// abstraction-provenance: {"artifact_sha256": "0ba60085221358482d6bfe04820d15211ba962d7c55276b09615a872d9b77588", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "go"}
// check_nodes.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Node-Status Checker - Prüft Verfügbarkeit aller Nodes
*/

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"sort"
	"strings"
	"time"
)

// NodeConfig repräsentiert die Konfiguration eines Nodes
type NodeConfig struct {
	AlwaysAvailable bool   `json:"always_available"`
	Capacity        string `json:"capacity"`
	Priority        int    `json:"priority"`
	Device          string `json:"device,omitempty"`
	Description     string `json:"description"`
}

// NodeStatus repräsentiert den Status eines Nodes
type NodeStatus struct {
	ID       string `json:"id"`
	Online   bool   `json:"online"`
	Available bool  `json:"available"`
	Response string `json:"response"`
}

// OutputFormat definiert das Ausgabeformat
type OutputFormat string

const (
	TableFormat OutputFormat = "table"
	JSONFormat  OutputFormat = "json"
)

// Node-Konfiguration (sollte aus config file geladen werden)
var NODES = map[string]NodeConfig{
	"node1": {
		AlwaysAvailable: true,
		Capacity:        "medium",
		Priority:        2,
		Description:     "Gateway-Master",
	},
	"node2": {
		AlwaysAvailable: true,
		Capacity:        "medium",
		Priority:        3,
		Description:     "Stable Worker",
	},
	"node3": {
		AlwaysAvailable: false,
		Capacity:        "medium",
		Priority:        4,
		Description:     "Bald verfügbar (nach Reorganisation)",
	},
	"node5": {
		AlwaysAvailable: false,
		Capacity:        "low",
		Priority:        5,
		Device:          "Redmi Note 11S",
		Description:     "Mobile (bei Internet verfügbar)",
	},
	"node7": {
		AlwaysAvailable: true,
		Capacity:        "high",
		Priority:        1,
		Description:     "Docker Hauptarbeitspferd (bald verfügbar)",
	},
}

// checkNodeStatus prüft Status eines einzelnen Nodes
func checkNodeStatus(nodeID string) NodeStatus {
	cmd := exec.Command("openclaw", "nodes", "status", nodeID)
	
	// Setze Timeout
	done := make(chan error, 1)
	go func() {
		done <- cmd.Start()
	}()
	
	select {
	case <-time.After(5 * time.Second):
		return NodeStatus{
			ID:        nodeID,
			Online:    false,
			Available: NODES[nodeID].AlwaysAvailable,
			Response:  "Timeout",
		}
	case err := <-done:
		if err != nil {
			return NodeStatus{
				ID:        nodeID,
				Online:    false,
				Available: NODES[nodeID].AlwaysAvailable,
				Response:  fmt.Sprintf("Error: %v", err),
			}
		}
	}
	
	output, err := cmd.Output()
	if err != nil {
		return NodeStatus{
			ID:        nodeID,
			Online:    false,
			Available: NODES[nodeID].AlwaysAvailable,
			Response:  fmt.Sprintf("Error: %v", err),
		}
	}
	
	stdout := string(output)
	isOnline := cmd.ProcessState.ExitCode() == 0 && 
		(strings.Contains(strings.ToLower(stdout), "online") || 
		 strings.Contains(strings.ToLower(stdout), "active"))
	
	response := stdout
	if len(response) > 100 {
		response = response[:100]
	}
	if response == "" {
		response = "No response"
	}
	
	return NodeStatus{
		ID:        nodeID,
		Online:    isOnline,
		Available: NODES[nodeID].AlwaysAvailable,
		Response:  strings.TrimSpace(response),
	}
}

// printTable gibt Node-Status als Tabelle aus
func printTable(nodesStatus []NodeStatus) {
	fmt.Println("\n" + strings.Repeat("=", 90))
	fmt.Printf("%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung")
	fmt.Println(strings.Repeat("=", 90))
	
	for _, status := range nodesStatus {
		config := NODES[status.ID]
		
		statusIcon := "🔴 Offline"
		if status.Online {
			statusIcon = "🟢 Online"
		}
		
		availIcon := "📱 Bedingt"
		if status.Available {
			availIcon = "✅ Immer"
		}
		
		capacity := config.Capacity
		if capacity == "" {
			capacity = "unknown"
		}
		
		priority := fmt.Sprintf("%d", config.Priority)
		
		device := config.Device
		if device == "" {
			device = config.Description
		}
		
		fmt.Printf("%-8s %-12s %-12s %-10s %-10s %s\n", status.ID, statusIcon, availIcon, capacity, priority, device)
	}
	
	fmt.Println(strings.Repeat("=", 90))
	fmt.Printf("\nGeprüft am: %s\n", time.Now().Format("2006-01-02 15:04:05"))
}

// printJSON gibt Node-Status als JSON aus
func printJSON(nodesStatus []NodeStatus) {
	type NodeOutput struct {
		Status NodeStatus   `json:"status"`
		Config NodeConfig   `json:"config"`
	}
	
	output := struct {
		Timestamp string                `json:"timestamp"`
		Nodes     map[string]NodeOutput `json:"nodes"`
	}{
		Timestamp: time.Now().Format(time.RFC3339),
		Nodes:     make(map[string]NodeOutput),
	}
	
	for _, status := range nodesStatus {
		output.Nodes[status.ID] = NodeOutput{
			Status: status,
			Config: NODES[status.ID],
		}
	}
	
	jsonData, _ := json.MarshalIndent(output, "", "  ")
	fmt.Println(string(jsonData))
}

func main() {
	// Kommandozeilenargumente parsen
	format := TableFormat
	var saveFile string
	
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--format" || arg == "-f" {
			if i+1 < len(args) {
				if args[i+1] == "json" {
					format = JSONFormat
				}
				i++
			}
		} else if arg == "--save" || arg == "-s" {
			if i+1 < len(args) {
				saveFile = args[i+1]
				i++
			}
		}
	}
	
	fmt.Println("🔍 Prüfe Node-Status...")
	
	// Prüfe alle Nodes
	var nodesStatus []NodeStatus
	nodeIDs := make([]string, 0, len(NODES))
	for nodeID := range NODES {
		nodeIDs = append(nodeIDs, nodeID)
	}
	sort.Strings(nodeIDs)
	
	for _, nodeID := range nodeIDs {
		fmt.Printf("  → %s... ", nodeID)
		status := checkNodeStatus(nodeID)
		nodesStatus = append(nodesStatus, status)
		if status.Online {
			fmt.Println("✓")
		} else {
			fmt.Println("✗")
		}
	}
	
	// Ausgabe
	if format == JSONFormat {
		printJSON(nodesStatus)
	} else {
		printTable(nodesStatus)
	}
	
	// Speichern
	if saveFile != "" {
		type SaveOutput struct {
			Timestamp string                 `json:"timestamp"`
			Nodes     map[string]NodeStatus `json:"nodes"`
		}
		
		output := SaveOutput{
			Timestamp: time.Now().Format(time.RFC3339),
			Nodes:     make(map[string]NodeStatus),
		}
		
		for _, status := range nodesStatus {
			output.Nodes[status.ID] = status
		}
		
		file, err := os.Create(saveFile)
		if err != nil {
			fmt.Printf("Fehler beim Erstellen der Datei: %v\n", err)
			return
		}
		defer file.Close()
		
		encoder := json.NewEncoder(file)
		encoder.SetIndent("", "  ")
		err = encoder.Encode(output)
		if err != nil {
			fmt.Printf("Fehler beim Schreiben der Datei: %v\n", err)
			return
		}
		
		fmt.Printf("\n💾 Gespeichert: %s\n", saveFile)
	}
	
	// Zusammenfassung
	onlineCount := 0
	for _, status := range nodesStatus {
		if status.Online {
			onlineCount++
		}
	}
	fmt.Printf("\n📊 Zusammenfassung: %d/%d Nodes online\n", onlineCount, len(nodesStatus))
}
