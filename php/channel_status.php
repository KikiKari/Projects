<?php
// abstraction-provenance: {"artifact_sha256": "67276e9011dcc3d591e5ec61e920aa84a0fe5cad10193fc4f0399fea7cd09fa7", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "php"}
// channel_status.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py
/**
 * Channel Status Agent - Automatische Status-Updates
 */

// Konfiguration
define('WORKSPACE', '/home/openclaw/.openclaw/workspace');
define('LOGS_DB', WORKSPACE . '/db/logs.db');
define('CONFIG_FILE', WORKSPACE . '/config/channel-status.json');
define('LOG_FILE', WORKSPACE . '/logs/channel-status.log');

function log_message($message, $level = "INFO") {
    /** Logging */
    $timestamp = date('Y-m-d H:i:s');
    $entry = "[{$timestamp}] [{$level}] {$message}" . PHP_EOL;
    echo $entry;
    file_put_contents(LOG_FILE, $entry, FILE_APPEND | LOCK_EX);
}

function get_system_status() {
    /** Sammelt System-Status */
    $status = [
        "timestamp" => date('c'),
        "nodes" => [],
        "agents" => [],
        "system" => []
    ];
    
    // Node-Status (vereinfacht)
    $nodes = [
        "node1" => ["name" => "Gateway", "status" => "online"],
        "node2" => ["name" => "Worker", "status" => "online"],
        "node3" => ["name" => "Relay", "status" => "offline", "reason" => "disk full"],
        "node5" => ["name" => "Redmi", "status" => "intermittent"],
        "node7" => ["name" => "Docker", "status" => "planned"]
    ];
    $status["nodes"] = $nodes;
    
    // Agent-Status aus Cron
    try {
        $cron_output = shell_exec('crontab -l 2>/dev/null');
        $cron_lines = substr_count($cron_output, "\n") - substr_count($cron_output, '#');
        $status["agents"]["active_crons"] = $cron_lines;
    } catch (Exception $e) {
        $status["agents"]["active_crons"] = "unknown";
    }
    
    // System-Metriken
    try {
        // Disk usage
        $df_output = shell_exec('df -h / 2>/dev/null');
        $df_lines = explode("\n", $df_output);
        foreach ($df_lines as $line) {
            if (strpos($line, '/') !== false && strpos($line, '%') !== false) {
                $parts = preg_split('/\s+/', trim($line));
                if (isset($parts[4])) {
                    $status["system"]["disk_used"] = $parts[4];
                    break;
                }
            }
        }
        
        // RAM usage
        $free_output = shell_exec('free -h 2>/dev/null');
        $free_lines = explode("\n", $free_output);
        foreach ($free_lines as $line) {
            if (strpos($line, 'Mem:') !== false) {
                $parts = preg_split('/\s+/', trim($line));
                if (isset($parts[1]) && isset($parts[2])) {
                    $status["system"]["ram_total"] = $parts[1];
                    $status["system"]["ram_used"] = $parts[2];
                    break;
                }
            }
        }
    } catch (Exception $e) {
        // ignore errors
    }
    
    return $status;
}

function format_daily_status($status) {
    /** Formatiert täglichen Status */
    $nodes = $status["nodes"];
    $online = 0;
    foreach ($nodes as $node) {
        if ($node["status"] == "online") {
            $online++;
        }
    }
    
    $message = "📊 **Täglicher Status-Report**\n";
    $message .= "🗓️ " . date('Y-m-d H:i') . "\n\n";
    $message .= "**🖥️ Nodes ({$online}/5 online):**\n";
    
    foreach ($nodes as $node_id => $info) {
        $emoji = "🟢";
        if ($info["status"] == "online") {
            $emoji = "🟢";
        } elseif ($info["status"] == "offline") {
            $emoji = "🔴";
        } else {
            $emoji = "🟡";
        }
        $message .= "{$emoji} {$info['name']}: {$info['status']}";
        if (isset($info["reason"])) {
            $message .= " ({$info['reason']})";
        }
        $message .= "\n";
    }
    
    $message .= "\n**🤖 Agents:**\n";
    $message .= "Aktive Cron-Jobs: " . ($status['agents']['active_crons'] ?? 'unknown') . "\n";
    
    if (isset($status["system"]["disk_used"])) {
        $message .= "\n**💾 System:**\n";
        $message .= "Disk: {$status['system']['disk_used']} belegt\n";
        $message .= "RAM: {$status['system']['ram_used']} / {$status['system']['ram_total']}\n";
    }
    
    return $message;
}

function format_weekly_status($status) {
    /** Formatiert wöchentlichen Status */
    $message = "📈 **Wöchentlicher Report**\n";
    $message .= "📅 Woche " . date('W') . " - " . date('Y') . "\n\n";
    $message .= "**Zusammenfassung:**\n";
    $message .= "- 5 aktive Sub-Agents\n";
    $message .= "- 11 Skills synchronisiert\n";
    $message .= "- 3 neue Features implementiert\n\n";
    $message .= "**Top-Ereignisse:**\n";
    $message .= "1. ClawHub-Git Sync implementiert ✅\n";
    $message .= "2. Node 3 Disk voll (95%) ⚠️\n";
    $message .= "3. Channel-Status-Agent aktiviert 🆕\n\n";
    $message .= "**Geplante Wartungen:**\n";
    $message .= "- Node 3: Disk-Cleanup erforderlich\n";
    $message .= "- Node 7: Docker-Setup ausstehend\n";
    
    return $message;
}

function send_to_channel($message, $channel_type = "telegram", $channel_id = "-1002381931352") {
    /** Sendet Nachricht an Channel */
    if ($channel_type == "telegram") {
        // Nutze OpenClaw message tool
        $cmd = "openclaw message send --target {$channel_id} --message " . escapeshellarg($message);
    } else {
        log_message("Channel type {$channel_type} not implemented", "WARN");
        return false;
    }
    
    try {
        $result = shell_exec("{$cmd} 2>&1");
        if (strpos($result, 'error') === false) {
            log_message("Message sent to {$channel_type} {$channel_id}");
            return true;
        } else {
            log_message("Failed to send: {$result}", "ERROR");
            return false;
        }
    } catch (Exception $e) {
        log_message("Send error: {$e->getMessage()}", "ERROR");
        return false;
    }
}

function main($argv) {
    /** Hauptfunktion */
    if (!file_exists(dirname(LOG_FILE))) {
        mkdir(dirname(LOG_FILE), 0755, true);
    }
    
    $options = getopt("", ["type:", "message::", "channel::", "dry-run"]);
    
    if (!isset($options["type"]) || !in_array($options["type"], ["daily", "weekly", "alert"])) {
        echo "Usage: php channel_status.php --type=daily|weekly|alert [--message=MESSAGE] [--channel=CHANNEL] [--dry-run]\n";
        exit(1);
    }
    
    $type = $options["type"];
    $message_text = $options["message"] ?? null;
    $channel = $options["channel"] ?? "-1002381931352";
    $dry_run = isset($options["dry-run"]);
    
    log_message("Starting {$type} status update");
    
    // Status sammeln
    $status = get_system_status();
    
    // Message formatieren
    if ($type == 'daily') {
        $message = format_daily_status($status);
    } elseif ($type == 'weekly') {
        $message = format_weekly_status($status);
    } elseif ($type == 'alert') {
        $message = "🚨 **ALERT**\n" . ($message_text ?: "Manual alert");
    }
    
    // Senden oder Dry-Run
    if ($dry_run) {
        echo "\n--- DRY RUN ---\n";
        echo $message;
        echo "\n--- END ---\n";
    } else {
        send_to_channel($message, "telegram", $channel);
    }
    
    log_message("Status update completed");
}

main($argv);
?>
