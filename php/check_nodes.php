<?php
// abstraction-provenance: {"artifact_sha256": "c84a9feb0cd8cc971657ce86e8028b1a0e3a5661d2b77fd3bcab734a06cfcbb5", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "php"}
// check_nodes.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
// auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Node-Status Checker - Prüft Verfügbarkeit aller Nodes
 */

// Node-Konfiguration (sollte aus config file geladen werden)
$NODES = [
    "node1" => [
        "always_available" => true,
        "capacity" => "medium",
        "priority" => 2,
        "description" => "Gateway-Master"
    ],
    "node2" => [
        "always_available" => true,
        "capacity" => "medium",
        "priority" => 3,
        "description" => "Stable Worker"
    ],
    "node3" => [
        "always_available" => false,
        "capacity" => "medium",
        "priority" => 4,
        "description" => "Bald verfügbar (nach Reorganisation)"
    ],
    "node5" => [
        "always_available" => false,
        "capacity" => "low",
        "priority" => 5,
        "device" => "Redmi Note 11S",
        "description" => "Mobile (bei Internet verfügbar)"
    ],
    "node7" => [
        "always_available" => true,
        "capacity" => "high",
        "priority" => 1,
        "description" => "Docker Hauptarbeitspferd (bald verfügbar)"
    ],
];

function check_node_status($node_id) {
    global $NODES;
    
    /**Prüft Status eines einzelnen Nodes*/
    try {
        $descriptorspec = [
            0 => ["pipe", "r"],
            1 => ["pipe", "w"],
            2 => ["pipe", "w"]
        ];
        
        $process = proc_open(
            "openclaw nodes status " . escapeshellarg($node_id),
            $descriptorspec,
            $pipes
        );
        
        if (is_resource($process)) {
            $status = stream_get_contents($pipes[1]);
            $stderr = stream_get_contents($pipes[2]);
            
            fclose($pipes[0]);
            fclose($pipes[1]);
            fclose($pipes[2]);
            
            $return_code = proc_close($process);
            
            $is_online = $return_code === 0 && (
                stripos($status, "online") !== false || 
                stripos($status, "active") !== false
            );
            
            return [
                "id" => $node_id,
                "online" => $is_online,
                "available" => $NODES[$node_id]["always_available"] ?? false,
                "response" => !empty($status) ? substr(trim($status), 0, 100) : "No response"
            ];
        } else {
            throw new Exception("Failed to start process");
        }
    } catch (Exception $e) {
        return [
            "id" => $node_id,
            "online" => false,
            "available" => $NODES[$node_id]["always_available"] ?? false,
            "response" => "Error: " . $e->getMessage()
        ];
    }
}

function print_table($nodes_status) {
    global $NODES;
    
    /**Gibt Node-Status als Tabelle aus*/
    echo "\n" . str_repeat("=", 90) . "\n";
    echo sprintf("%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung");
    echo str_repeat("=", 90) . "\n";
    
    foreach ($nodes_status as $status) {
        $node_id = $status["id"];
        $config = $NODES[$node_id];
        
        $status_icon = $status["online"] ? "🟢 Online" : "🔴 Offline";
        $avail_icon = $status["available"] ? "✅ Immer" : "📱 Bedingt";
        $capacity = $config["capacity"] ?? "unknown";
        $priority = $config["priority"] ?? "-";
        $device = $config["device"] ?? ($config["description"] ?? "");
        
        echo sprintf("%-8s %-12s %-12s %-10s %-10s %s\n", 
            $node_id, $status_icon, $avail_icon, $capacity, $priority, $device);
    }
    
    echo str_repeat("=", 90) . "\n";
    echo "\nGeprüft am: " . date('Y-m-d H:i:s') . "\n";
}

function print_json($nodes_status) {
    global $NODES;
    
    /**Gibt Node-Status als JSON aus*/
    $output = [
        "timestamp" => date('c'),
        "nodes" => []
    ];
    
    foreach ($nodes_status as $status) {
        $node_id = $status["id"];
        $output["nodes"][$node_id] = [
            "status" => $status,
            "config" => $NODES[$node_id]
        ];
    }
    
    echo json_encode($output, JSON_PRETTY_PRINT) . "\n";
}

function main() {
    global $argv, $NODES;
    
    // Simple argument parsing
    $format = "table";
    $save_file = null;
    
    for ($i = 1; $i < count($argv); $i++) {
        if (in_array($argv[$i], ["--format", "-f"]) && isset($argv[$i+1])) {
            if (in_array($argv[$i+1], ["table", "json"])) {
                $format = $argv[$i+1];
                $i++;
            }
        } elseif (in_array($argv[$i], ["--save", "-s"]) && isset($argv[$i+1])) {
            $save_file = $argv[$i+1];
            $i++;
        }
    }
    
    echo "🔍 Prüfe Node-Status...\n";
    
    // Prüfe alle Nodes
    $nodes_status = [];
    $sorted_keys = array_keys($NODES);
    sort($sorted_keys);
    
    foreach ($sorted_keys as $node_id) {
        echo "  → $node_id... ";
        $status = check_node_status($node_id);
        $nodes_status[] = $status;
        echo ($status["online"] ? "✓" : "✗") . "\n";
    }
    
    // Ausgabe
    if ($format === "table") {
        print_table($nodes_status);
    } else {
        print_json($nodes_status);
    }
    
    // Speichern
    if ($save_file) {
        $output = [
            "timestamp" => date('c'),
            "nodes" => []
        ];
        
        foreach ($nodes_status as $status) {
            $output["nodes"][$status["id"]] = $status;
        }
        
        file_put_contents($save_file, json_encode($output, JSON_PRETTY_PRINT));
        echo "\n💾 Gespeichert: $save_file\n";
    }
    
    // Zusammenfassung
    $online_count = 0;
    foreach ($nodes_status as $status) {
        if ($status["online"]) {
            $online_count++;
        }
    }
    
    echo "\n📊 Zusammenfassung: $online_count/" . count($nodes_status) . " Nodes online\n";
}

main();
?>
