<?php
// abstraction-provenance: {"artifact_sha256": "b6a7f9373d0a58904a97e436a374602c435c5a136b18e861e0734446001ba5f8", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "php"}
// node_health.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Node Health Monitor - Multi-Node Gesundheitsüberwachung
 */

// Konfiguration
define('WORKSPACE', '/home/openclaw/.openclaw/workspace');
define('HEALTH_DB', WORKSPACE . '/db/health.db');
define('LOG_FILE', WORKSPACE . '/logs/node-health.log');

// Node-Definitionen
$NODES = [
    "node1" => [
        "name" => "Gateway",
        "host" => "localhost",
        "user" => "openclaw",
        "critical" => true
    ],
    "node2" => [
        "name" => "Worker", 
        "host" => "100.92.155.34",
        "user" => "root",
        "ssh_key" => "~/.ssh/id_rsa"
    ],
    "node3" => [
        "name" => "Relay",
        "host" => "185.242.xxx.xxx",
        "user" => "root",
        "disk_warning" => 85
    ],
    "node5" => [
        "name" => "Redmi",
        "host" => "192.168.1.x",
        "user" => "openclaw",
        "optional" => true
    ]
];

function logMessage($message, $level = "INFO") {
    /** Logging */
    $timestamp = date('Y-m-d H:i:s');
    $entry = "[{$timestamp}] [{$level}] {$message}\n";
    echo $entry;
    
    $logDir = dirname(LOG_FILE);
    if (!file_exists($logDir)) {
        mkdir($logDir, 0777, true);
    }
    
    file_put_contents(LOG_FILE, $entry, FILE_APPEND);
}

function checkPing($host, $timeout = 5) {
    /** Prüft Erreichbarkeit */
    try {
        $cmd = "ping -c 1 -W {$timeout} {$host} >/dev/null 2>&1";
        $result = exec($cmd, $output, $returnCode);
        return $returnCode === 0;
    } catch (Exception $e) {
        return false;
    }
}

function checkSSH($nodeConfig) {
    /** Prüft SSH-Verbindung */
    $host = $nodeConfig["host"];
    $user = $nodeConfig["user"] ?? "root";
    
    $cmd = "ssh -o ConnectTimeout=10 -o BatchMode=yes {$user}@{$host} 'echo \"OK\"' 2>/dev/null";
    
    try {
        $result = shell_exec($cmd);
        return trim($result) === "OK";
    } catch (Exception $e) {
        return false;
    }
}

function getNodeMetrics($nodeConfig) {
    /** Holt Metriken via SSH */
    $host = $nodeConfig["host"];
    $user = $nodeConfig["user"] ?? "root";
    
    $metrics = [
        "timestamp" => date('c'),
        "available" => false,
        "cpu" => null,
        "ram" => null,
        "disk" => null,
        "load" => null
    ];
    
    // SSH-Command für alle Metriken
    $cmd = "ssh -o ConnectTimeout=10 {$user}@{$host} '
        # CPU
        echo \"CPU:\$(top -bn1 | grep \"Cpu(s)\" | awk \"{print \\\$2}\" | cut -d\"%\" -f1)\"
        
        # RAM
        echo \"RAM:\$(free | grep Mem | awk \"{print (\\\$3/\\\$2) * 100.0}\")\"
        
        # Disk
        echo \"DISK:\$(df -h / | tail -1 | awk \"{print \\\$5}\" | tr -d \"%\")\"
        
        # Load
        echo \"LOAD:\$(uptime | awk -F\"load average:\" \"{print \\\$2}\" | awk \"{print \\\$1}\" | tr -d \",\")\"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo \"GATEWAY:inactive\"
        fi
    ' 2>/dev/null";
    
    try {
        $start = time();
        $result = shell_exec($cmd);
        $duration = time() - $start;
        
        if ($duration > 15) {
            logMessage("SSH timeout for {$nodeConfig['name']}", "WARN");
            return $metrics;
        }
        
        if ($result !== null) {
            $metrics["available"] = true;
            
            $lines = explode("\n", trim($result));
            foreach ($lines as $line) {
                if (strpos($line, ':') !== false) {
                    list($key, $value) = explode(':', $line, 2);
                    $value = trim($value);
                    
                    switch ($key) {
                        case "CPU":
                            $metrics["cpu"] = floatval($value);
                            break;
                        case "RAM":
                            $metrics["ram"] = floatval($value);
                            break;
                        case "DISK":
                            $metrics["disk"] = intval($value);
                            break;
                        case "LOAD":
                            $metrics["load"] = floatval($value);
                            break;
                        case "GATEWAY":
                            $metrics["gateway_status"] = $value;
                            break;
                    }
                }
            }
        }
    } catch (Exception $e) {
        logMessage("Error checking {$nodeConfig['name']}: " . $e->getMessage(), "ERROR");
    }
    
    return $metrics;
}

function checkAlerts($nodeId, $nodeConfig, $metrics) {
    /** Prüft Schwellwerte und generiert Alerts */
    $alerts = [];
    
    // Verfügbarkeit
    if (!$metrics["available"]) {
        if (!($nodeConfig["optional"] ?? false)) {
            $alerts[] = [
                "level" => "CRITICAL",
                "message" => "Node {$nodeConfig['name']} nicht erreichbar!"
            ];
        }
    } else {
        // CPU
        if ($metrics["cpu"] && $metrics["cpu"] > 90) {
            $alerts[] = [
                "level" => "WARNING",
                "message" => "Node {$nodeConfig['name']}: CPU bei {$metrics['cpu']}%"
            ];
        }
        
        // RAM
        if ($metrics["ram"] && $metrics["ram"] > 90) {
            $alerts[] = [
                "level" => "WARNING", 
                "message" => "Node {$nodeConfig['name']}: RAM bei {$metrics['ram']}%"
            ];
        }
        
        // Disk
        $diskThreshold = $nodeConfig["disk_warning"] ?? 85;
        if ($metrics["disk"] && $metrics["disk"] > $diskThreshold) {
            $level = $metrics["disk"] > 95 ? "CRITICAL" : "WARNING";
            $alerts[] = [
                "level" => $level,
                "message" => "Node {$nodeConfig['name']}: Disk bei {$metrics['disk']}%"
            ];
        }
        
        // Gateway
        if (($nodeConfig["critical"] ?? false) && ($metrics["gateway_status"] ?? "") === "inactive") {
            $alerts[] = [
                "level" => "CRITICAL",
                "message" => "Node {$nodeConfig['name']}: OpenClaw Gateway nicht aktiv!"
            ];
        }
    }
    
    return $alerts;
}

function sendAlert($alert) {
    /** Sendet Alert via channel-status-agent */
    try {
        $cmd = "python3 " . WORKSPACE . "/skills/channel-status-agent/scripts/channel_status.py --type alert --message '{$alert['level']}: {$alert['message']}' 2>/dev/null";
        exec($cmd, $output, $returnCode);
        logMessage("Alert sent: {$alert['message']}");
    } catch (Exception $e) {
        logMessage("Failed to send alert: " . $e->getMessage(), "ERROR");
    }
}

function main($argv) {
    /** Hauptfunktion */
    global $NODES;
    
    $node = 'all';
    $check = 'all';
    $alert = false;
    
    // Argumente parsen
    for ($i = 1; $i < count($argv); $i++) {
        switch ($argv[$i]) {
            case '--node':
                $node = $argv[++$i] ?? 'all';
                break;
            case '--check':
                $check = $argv[++$i] ?? 'all';
                break;
            case '--alert':
                $alert = true;
                break;
        }
    }
    
    // Nodes bestimmen
    if ($node === 'all') {
        $nodesToCheck = $NODES;
    } else {
        if (isset($NODES[$node])) {
            $nodesToCheck = [$node => $NODES[$node]];
        } else {
            logMessage("Unknown node: {$node}", "ERROR");
            exit(1);
        }
    }
    
    // Health-Checks durchführen
    $allAlerts = [];
    
    foreach ($nodesToCheck as $nodeId => $nodeConfig) {
        logMessage("Checking {$nodeConfig['name']} ({$nodeId})");
        
        // Ping
        if (in_array($check, ['ping', 'all'])) {
            if ($nodeConfig["host"] !== "localhost") {
                $pingOk = checkPing($nodeConfig["host"]);
                logMessage("  Ping: " . ($pingOk ? "OK" : "FAILED"));
            }
        }
        
        // SSH
        if (in_array($check, ['ssh', 'all'])) {
            $sshOk = checkSSH($nodeConfig);
            logMessage("  SSH: " . ($sshOk ? "OK" : "FAILED"));
        }
        
        // Metriken
        if (in_array($check, ['metrics', 'all'])) {
            $metrics = getNodeMetrics($nodeConfig);
            
            if ($metrics["available"]) {
                logMessage("  CPU: " . ($metrics['cpu'] ? sprintf("%.1f%%", $metrics['cpu']) : "N/A"));
                logMessage("  RAM: " . ($metrics['ram'] ? sprintf("%.1f%%", $metrics['ram']) : "N/A"));
                logMessage("  Disk: " . ($metrics['disk'] ? "{$metrics['disk']}%" : "N/A"));
                logMessage("  Load: " . ($metrics['load'] ?? "N/A"));
            } else {
                logMessage("  Metrics: UNAVAILABLE");
            }
            
            // Alerts prüfen
            $alerts = checkAlerts($nodeId, $nodeConfig, $metrics);
            $allAlerts = array_merge($allAlerts, $alerts);
        }
    }
    
    // Alerts senden
    if ($alert && count($allAlerts) > 0) {
        logMessage("\nSending " . count($allAlerts) . " alerts...");
        foreach ($allAlerts as $alertItem) {
            sendAlert($alertItem);
        }
    } elseif (count($allAlerts) > 0) {
        logMessage("\n" . count($allAlerts) . " alerts found (use --alert to send)");
    } else {
        logMessage("\nAll nodes healthy!");
    }
}

main($argv);
?>
