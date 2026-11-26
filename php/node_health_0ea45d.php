<?php
// abstraction-provenance: {"artifact_sha256": "afb7ef15bf72cd4346b4be23b1accef70f2d3160052a507e140dcc7dc94beb6f", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "php"}
// node_health.py — portiert nach php
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
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
        "name" => "Node 1",
        "host" => "localhost",
        "user" => "openclaw",
        "critical" => true
    ],
    "node2" => [
        "name" => "Node 2",
        "host" => "10.10.0.2",
        "user" => "root",
        "ssh_key" => "~/.ssh/id_rsa",
        "ssh_opts" => "-o ConnectTimeout=10 -o BatchMode=yes"
    ],
    "node3" => [
        "name" => "Node 3",
        "host" => "localhost",
        "user" => "root",
        "port" => 18794,
        "ssh_opts" => "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes",
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
    $entry = "[{$timestamp}] [{$level}] {$message}";
    echo $entry . "\n";
    
    $logDir = dirname(LOG_FILE);
    if (!is_dir($logDir)) {
        mkdir($logDir, 0755, true);
    }
    
    file_put_contents(LOG_FILE, $entry . "\n", FILE_APPEND);
}

function checkPing($host, $timeout = 10) {
    /** Prüft Erreichbarkeit (Timeout seconds) */
    try {
        $cmd = "ping -c 1 -W {$timeout} {$host} >/dev/null 2>&1";
        $result = shell_exec($cmd);
        $returnCode = 0;
        if (strpos($result, '1 received') !== false) {
            $returnCode = 0;
        } else {
            $returnCode = 1;
        }
        return $returnCode === 0;
    } catch (Exception $e) {
        return false;
    }
}

function checkSSH($nodeConfig) {
    /** Prüft SSH-Verbindung */
    $host = $nodeConfig["host"];
    $user = $nodeConfig["user"] ?? "root";
    $sshOpts = $nodeConfig["ssh_opts"] ?? "";
    $port = $nodeConfig["port"] ?? null;
    
    $cmd = "ssh ";
    if ($sshOpts) {
        $cmd .= $sshOpts . " ";
    }
    if ($port) {
        $cmd .= "-p {$port} ";
    }
    $cmd .= "-o ConnectTimeout=10 -o BatchMode=yes {$user}@{$host} echo 'OK' 2>/dev/null";
    
    try {
        $output = shell_exec($cmd);
        return strpos($output, 'OK') !== false;
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
        $output = shell_exec($cmd);
        if ($output !== null) {
            $metrics["available"] = true;
            
            $lines = explode("\n", trim($output));
            foreach ($lines as $line) {
                if (strpos($line, ':') !== false) {
                    list($key, $value) = explode(':', $line, 2);
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
                "message" => "Node {$nodeConfig['name']}: CPU bei " . number_format($metrics['cpu'], 1) . "%"
            ];
        }
        
        // RAM
        if ($metrics["ram"] && $metrics["ram"] > 90) {
            $alerts[] = [
                "level" => "WARNING", 
                "message" => "Node {$nodeConfig['name']}: RAM bei " . number_format($metrics['ram'], 1) . "%"
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
        $scriptPath = WORKSPACE . "/skills/channel-status-agent/scripts/channel_status.py";
        $cmd = "python3 " . escapeshellarg($scriptPath) . " --type alert --message " . escapeshellarg("{$alert['level']}: {$alert['message']}");
        shell_exec($cmd);
        logMessage("Alert sent: {$alert['message']}");
    } catch (Exception $e) {
        logMessage("Failed to send alert: " . $e->getMessage(), "ERROR");
    }
}

function main() {
    global $NODES;
    
    // Argumente parsen
    $options = getopt("", ["node:", "check:", "alert"]);
    $nodeArg = $options["node"] ?? "all";
    $checkArg = $options["check"] ?? "all";
    $sendAlerts = isset($options["alert"]);
    
    // Nodes bestimmen
    if ($nodeArg === 'all') {
        $nodesToCheck = $NODES;
    } else {
        if (array_key_exists($nodeArg, $NODES)) {
            $nodesToCheck = [$nodeArg => $NODES[$nodeArg]];
        } else {
            logMessage("Unknown node: {$nodeArg}", "ERROR");
            exit(1);
        }
    }
    
    // Health-Checks durchführen
    $allAlerts = [];
    
    foreach ($nodesToCheck as $nodeId => $nodeConfig) {
        logMessage("Checking {$nodeConfig['name']} ({$nodeId})");
        
        // Ping
        if (in_array($checkArg, ['ping', 'all'])) {
            if ($nodeConfig["host"] !== "localhost") {
                $pingOk = checkPing($nodeConfig["host"]);
                logMessage("  Ping: " . ($pingOk ? "OK" : "FAILED"));
            }
        }
        
        // SSH
        if (in_array($checkArg, ['ssh', 'all'])) {
            $sshOk = checkSSH($nodeConfig);
            logMessage("  SSH: " . ($sshOk ? "OK" : "FAILED"));
        }
        
        // Metriken
        if (in_array($checkArg, ['metrics', 'all'])) {
            $metrics = getNodeMetrics($nodeConfig);
            
            if ($metrics["available"]) {
                logMessage("  CPU: " . ($metrics['cpu'] ? number_format($metrics['cpu'], 1) . "%" : "N/A"));
                logMessage("  RAM: " . ($metrics['ram'] ? number_format($metrics['ram'], 1) . "%" : "N/A"));
                logMessage("  Disk: " . ($metrics['disk'] ? $metrics['disk'] . "%" : "N/A"));
                logMessage("  Load: " . ($metrics['load'] ? $metrics['load'] : "N/A"));
            } else {
                logMessage("  Metrics: UNAVAILABLE");
            }
            
            // Alerts prüfen
            $alerts = checkAlerts($nodeId, $nodeConfig, $metrics);
            $allAlerts = array_merge($allAlerts, $alerts);
        }
    }
    
    // Alerts senden
    if ($sendAlerts && count($allAlerts) > 0) {
        logMessage("\nSending " . count($allAlerts) . " alerts...");
        foreach ($allAlerts as $alert) {
            sendAlert($alert);
        }
    } elseif (count($allAlerts) > 0) {
        logMessage("\n" . count($allAlerts) . " alerts found (use --alert to send)");
    } else {
        logMessage("\nAll nodes healthy!");
    }
}

main();
?>
