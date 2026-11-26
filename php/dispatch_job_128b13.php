<?php
// abstraction-provenance: {"artifact_sha256": "808d9084da2c27196910dbf5f2e401ea39bedc9c282f4185eddfeceaa187c39b", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "php"}
// dispatch_job.py — portiert nach php
// Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

// Node-Konfiguration
const NODES = [
    "node1" => ["always_available" => true, "capacity" => "medium", "priority" => 2],
    "node2" => ["always_available" => true, "capacity" => "medium", "priority" => 3],
    "node3" => ["always_available" => false, "capacity" => "medium", "priority" => 4],
    "node5" => ["always_available" => false, "capacity" => "low", "priority" => 5, "device" => "Redmi Note 11S"],
    "node7" => ["always_available" => true, "capacity" => "high", "priority" => 1],
];

class JobDispatcher {
    /** Bewertet Job-Gewicht */
    public function getJobWeight($scriptPath, $targetLangsCount = 1) {
        if (!file_exists($scriptPath)) {
            return "medium";
        }
        
        $scriptSize = filesize($scriptPath);
        $totalWork = $scriptSize * $targetLangsCount;
        
        if ($totalWork > 50000) {  // > 50KB
            return "heavy";
        } elseif ($totalWork > 10000) {  // > 10KB
            return "medium";
        } else {
            return "light";
        }
    }
    
    /** Wählt besten Node basierend auf Job-Gewicht */
    public function selectNode($jobWeight) {
        if ($jobWeight == "heavy") {
            // Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            $preferred = ["node7", "node2", "node1"];
        } elseif ($jobWeight == "medium") {
            // Mittlere Jobs → Stable Nodes
            $preferred = ["node2", "node1", "node7"];
        } else {  // light
            // Leichte Jobs → Mobile/verfügbare Nodes
            $preferred = ["node5", "node1", "node2"];
        }
        
        // Prüfe Verfügbarkeit
        foreach ($preferred as $nodeId) {
            if ($this->checkNodeAvailable($nodeId)) {
                return $nodeId;
            }
        }
        
        // Fallback
        return "node1";
    }
    
    /** Prüft ob Node erreichbar ist */
    public function checkNodeAvailable($nodeId) {
        if (!isset(NODES[$nodeId])) {
            return false;
        }
        
        $node = NODES[$nodeId];
        
        // Nicht immer-verfügbare Nodes nur wenn explizit requested
        if (!($node["always_available"] ?? false)) {
            // Für light-jobs prüfen wir ob online
            if ($nodeId == "node5") {  // Redmi
                return $this->_checkMobileOnline();
            }
            return false;
        }
        
        // Für immer-verfügbare Nodes: prüfe ob wirklich online
        try {
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ];
            
            $process = proc_open("openclaw nodes status " . escapeshellarg($nodeId), $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                $output = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                
                $return_value = proc_close($process);
                return $return_value === 0;
            }
            return $node["always_available"] ?? false;
        } catch (Exception $e) {
            return $node["always_available"] ?? false;
        }
    }
    
    /** Prüft ob Redmi (Node 5) Internet hat */
    private function _checkMobileOnline() {
        try {
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ];
            
            $process = proc_open("openclaw nodes status node5", $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                $output = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                
                $return_value = proc_close($process);
                return $return_value === 0 && stripos($output, "online") !== false;
            }
            return false;
        } catch (Exception $e) {
            return false;
        }
    }
    
    /** Dispatched Job und gibt Info zurück */
    public function dispatch($jobScript, $targetLangs = null) {
        if ($targetLangs === null) {
            $targetLangs = ["perl5"];
        }
        
        $weight = $this->getJobWeight($jobScript, count($targetLangs));
        $selectedNode = $this->selectNode($weight);
        
        return [
            "job" => $jobScript,
            "weight" => $weight,
            "selected_node" => $selectedNode,
            "target_langs" => $targetLangs,
            "status" => "dispatched"
        ];
    }
}

function main() {
    global $argv, $argc;
    
    // Simple argument parsing
    $options = getopt("j:l:w:x", ["job:", "langs:", "weight:", "execute"]);
    
    $job = $options["job"] ?? $options["j"] ?? null;
    $langs = $options["langs"] ?? $options["l"] ?? "perl5";
    $weight = $options["weight"] ?? $options["w"] ?? null;
    $execute = isset($options["execute"]) || isset($options["x"]);
    
    if (!$job) {
        echo "❌ Job parameter is required\n";
        exit(1);
    }
    
    $jobPath = $job;
    if (!file_exists($jobPath)) {
        echo "❌ Job not found: " . $jobPath . "\n";
        exit(1);
    }
    
    $dispatcher = new JobDispatcher();
    $targetLangs = explode(",", $langs);
    
    // Determine weight
    if ($weight) {
        $jobWeight = $weight;
    } else {
        $jobWeight = $dispatcher->getJobWeight($jobPath, count($targetLangs));
    }
    
    // Select node
    $selectedNode = $dispatcher->selectNode($jobWeight);
    
    // Output
    echo "📦 Job Dispatch Information\n";
    echo str_repeat("=", 50) . "\n";
    echo "Job: " . $jobPath . "\n";
    echo "Size: " . filesize($jobPath) . " bytes\n";
    echo "Target langs: " . implode(", ", $targetLangs) . "\n";
    echo "Job weight: " . $jobWeight . "\n";
    echo "Selected node: " . $selectedNode . "\n";
    echo str_repeat("=", 50) . "\n";
    
    if ($execute) {
        echo "\n🚀 Executing on " . $selectedNode . "...\n";
        // TODO: Implement remote execution
        echo "(Remote execution not yet implemented)\n";
    } else {
        echo "\n💡 To execute: php " . basename(__FILE__) . " --job " . $job . " --execute\n";
    }
}

if (basename(__FILE__) == basename($_SERVER["SCRIPT_NAME"])) {
    main();
}
?>
