<?php
// abstraction-provenance: {"artifact_sha256": "3f5bbb707fdde31831c3897ec039276861a53b398cfd877489d976f766093d74", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "php"}
// dispatch_job.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Job Dispatcher - Verteilt Jobs auf passende Nodes
 */

class JobDispatcher {
    // Node-Konfiguration
    private const NODES = [
        "node1" => ["always_available" => true, "capacity" => "medium", "priority" => 3, "description" => "Gateway"],
        "node2" => ["always_available" => false, "capacity" => "high", "priority" => 1, "description" => "ARM Server"],
        "node3" => ["always_available" => false, "capacity" => "medium", "priority" => 4, "description" => "AMD Server"],
        "node4" => ["always_available" => false, "capacity" => "low", "priority" => 5, "device" => "Redmi Note 11S"],
        "node5" => ["always_available" => false, "capacity" => "high", "priority" => 2, "device" => "Lenovo"],
        "node6" => ["always_available" => false, "device" => "Lenovo (Docker)"],
    ];

    private const NODE_NAMES = [
        "node2" => ["openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"],
        "node3" => ["openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"],
        "node4" => ["openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"],
        "node5" => ["openclaw-node5", "windows node (lenovo-7)"],
        "node6" => ["openclaw-node6"],
    ];

    /**
     * Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen.
     */
    private function _job_weight_bytes(string $script_path, int $target_langs_count): int {
        if (!file_exists($script_path)) {
            return 0;
        }
        return filesize($script_path) * $target_langs_count;
    }

    /**
     * Return mapped OpenClaw connection states; null indicates lookup failure.
     */
    public function fetch_node_status(): ?array {
        try {
            $descriptorspec = [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ];
            
            $process = proc_open("openclaw nodes status --json", $descriptorspec, $pipes);
            
            if (is_resource($process)) {
                fclose($pipes[0]);
                
                $stdout = stream_get_contents($pipes[1]);
                fclose($pipes[1]);
                
                $stderr = stream_get_contents($pipes[2]);
                fclose($pipes[2]);
                
                $return_value = proc_close($process);
                
                if ($return_value !== 0) {
                    return null;
                }
                
                $payload = json_decode($stdout, true);
                
                if (!is_array($payload) || !isset($payload["nodes"]) || !is_array($payload["nodes"])) {
                    return null;
                }
                
                $states = [];
                foreach (self::NODE_NAMES as $node => $aliases) {
                    $states[$node] = false;
                }
                
                foreach ($payload["nodes"] as $item) {
                    if (!is_array($item)) {
                        continue;
                    }
                    
                    $names = [];
                    foreach (["displayName", "nodeId", "remoteIp"] as $key) {
                        if (isset($item[$key])) {
                            $names[] = strtolower((string)$item[$key]);
                        }
                    }
                    
                    foreach (self::NODE_NAMES as $node => $aliases) {
                        $intersection = array_intersect($names, $aliases);
                        if (!empty($intersection) && isset($item["connected"]) && $item["connected"] === true) {
                            $states[$node] = true;
                        }
                    }
                }
                
                $states["node1"] = true; // successful Gateway status request
                return $states;
            }
            return null;
        } catch (Exception $e) {
            return null;
        }
    }

    /**
     * Bewertet Job-Gewicht
     */
    public function get_job_weight(string $script_path, int $target_langs_count = 1): string {
        if (!file_exists($script_path)) {
            return "medium";
        }
        
        $total_work = $this->_job_weight_bytes($script_path, $target_langs_count);
        
        if ($total_work > 50000) {  // > 50KB
            return "heavy";
        } elseif ($total_work > 10000) {  // > 10KB
            return "medium";
        } else {
            return "light";
        }
    }

    /**
     * Wählt besten Node basierend auf Job-Gewicht
     */
    public function select_node(string $job_weight): ?string {
        switch ($job_weight) {
            case "heavy":
                $preferred = ["node1", "node2", "node5", "node6"];
                break;
            case "medium":
                $preferred = ["node1", "node2", "node3", "node6"];
                break;
            case "light":
                $preferred = ["node2", "node1", "node3", "node4"];
                break;
            default:
                throw new InvalidArgumentException("Unknown job weight: " . $job_weight);
        }

        $states = $this->fetch_node_status();
        foreach ($preferred as $node_id) {
            if ($states && isset($states[$node_id]) && $states[$node_id]) {
                return $node_id;
            }
        }
        return null; // no verified reachable node
    }

    /**
     * Use the live connection state rather than static availability.
     */
    public function check_node_available(string $node_id): bool {
        $states = $this->fetch_node_status();
        return $states && isset($states[$node_id]) && $states[$node_id];
    }

    public function execute_translation(array $job, callable $transport): string {
        return $this->execute_translation_internal($job, $transport);
    }

    /**
     * Check Node4 (Redmi).
     */
    private function _check_mobile_online(): bool {
        return $this->check_node_available("node4");
    }

    /**
     * Dispatched Job und gibt Info zurück
     */
    public function dispatch(string $job_script, array $target_langs = null, ?string $source_text = null, ?string $source_language = null): array {
        if ($target_langs === null) {
            $target_langs = ["perl5"];
        }
        
        $weight = $this->get_job_weight($job_script, count($target_langs));
        $selected_node = $this->select_node($weight);
        $translation_jobs = [];
        
        foreach ($target_langs as $language) {
            $job = [
                "job_id" => uniqid(),
                "source" => $job_script,
                "target_language" => $language,
                "selected_node" => $selected_node,
            ];
            
            if ($source_text !== null) {
                $job["source_text"] = $source_text;
            }
            
            if ($source_language !== null) {
                $job["source_language"] = $source_language;
            }
            
            $translation_jobs[] = $job;
        }
        
        return [
            "job" => $job_script,
            "weight" => $weight,
            "selected_node" => $selected_node,
            "target_langs" => $target_langs,
            "translation_jobs" => $translation_jobs,
            "status" => $selected_node ? "selected" : "unavailable"
        ];
    }

    /**
     * Execute via a supplied transport and verify its result belongs to the job.
     */
    private function execute_translation_internal(array $job, callable $transport): string {
        if (!isset($job["selected_node"]) || $transport === null) {
            throw new RuntimeException("no verified node or authorized translation transport");
        }
        
        $response = $transport($job);
        
        if (!is_array($response)) {
            throw new InvalidArgumentException("invalid transport response");
        }
        
        foreach (["job_id", "selected_node", "target_language"] as $key) {
            if (!isset($response[$key]) || $response[$key] !== $job[$key]) {
                throw new InvalidArgumentException("transport response does not match job");
            }
        }
        
        $code = $response["code"] ?? null;
        
        if (($response["status"] ?? null) !== "ok" || !is_string($code) || trim($code) === "") {
            throw new InvalidArgumentException("translation did not complete with code");
        }
        
        return $code;
    }
}

/**
 * Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag.
 */
function dispatch_abstraction_job(string $job_script, array $target_langs): array {
    $dispatcher = new JobDispatcher();
    return $dispatcher->dispatch($job_script, $target_langs);
}

function main(): int {
    global $argv;
    
    // Simple argument parsing
    $args = [];
    for ($i = 1; $i < count($argv); $i++) {
        if ($argv[$i] === "--job" || $argv[$i] === "-j") {
            $args["job"] = $argv[++$i] ?? null;
        } elseif ($argv[$i] === "--langs" || $argv[$i] === "-l") {
            $args["langs"] = $argv[++$i] ?? null;
        } elseif ($argv[$i] === "--weight" || $argv[$i] === "-w") {
            $args["weight"] = $argv[++$i] ?? null;
        } elseif ($argv[$i] === "--execute" || $argv[$i] === "-x") {
            $args["execute"] = true;
        }
    }
    
    if (!isset($args["job"])) {
        echo "Usage: php dispatch_job.php --job JOB_FILE [options]\n";
        return 1;
    }
    
    $job_path = $args["job"];
    if (!file_exists($job_path)) {
        echo "❌ Job not found: " . $job_path . "\n";
        return 1;
    }
    
    $dispatcher = new JobDispatcher();
    $target_langs = isset($args["langs"]) ? explode(",", $args["langs"]) : ["perl5"];
    
    // Determine weight
    if (isset($args["weight"])) {
        $weight = $args["weight"];
    } else {
        $weight = $dispatcher->get_job_weight($job_path, count($target_langs));
    }
    
    // Select node
    $selected_node = $dispatcher->select_node($weight);
    
    // Output
    echo "📦 Job Dispatch Information\n";
    echo str_repeat("=", 50) . "\n";
    echo "Job: " . $job_path . "\n";
    echo "Size: " . filesize($job_path) . " bytes\n";
    echo "Target langs: " . implode(", ", $target_langs) . "\n";
    echo "Job weight: " . $weight . "\n";
    echo "Selected node: " . ($selected_node ?? "none") . "\n";
    echo str_repeat("=", 50) . "\n";
    
    if (isset($args["execute"])) {
        echo "\nTranslation dispatch on " . ($selected_node ?? "none") . " is not implemented.\n";
        return 1;
    } else {
        echo "\n💡 To execute: php " . $argv[0] . " --job " . $args["job"] . " --execute\n";
    }
    
    return 0;
}

exit(main());
