#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "3c2e9225ba195a769f8fe04b65bc43ad8254220531760449b1acbcafc8645228", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "javascript"}
// channel_status.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

/**
 * Channel Status Agent - Automatische Status-Updates
 */

const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Konfiguration
const WORKSPACE = "/home/openclaw/.openclaw/workspace";
const LOGS_DB = path.join(WORKSPACE, "db/logs.db");
const CONFIG_FILE = path.join(WORKSPACE, "config/channel-status.json");
const LOG_FILE = path.join(WORKSPACE, "logs/channel-status.log");

function log(message, level = "INFO") {
    /** Logging */
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const entry = `[${timestamp}] [${level}] ${message}`;
    console.log(entry);
    fs.appendFileSync(LOG_FILE, entry + '\n');
}

function getSystemStatus() {
    /** Sammelt System-Status */
    const status = {
        "timestamp": new Date().toISOString(),
        "nodes": {},
        "agents": {},
        "system": {}
    };
    
    // Node-Status (vereinfacht)
    const nodes = {
        "node1": {"name": "Gateway", "status": "online"},
        "node2": {"name": "Worker", "status": "online"},
        "node3": {"name": "Relay", "status": "offline", "reason": "disk full"},
        "node5": {"name": "Redmi", "status": "intermittent"},
        "node7": {"name": "Docker", "status": "planned"}
    };
    status["nodes"] = nodes;
    
    // Agent-Status aus Cron
    try {
        const result = execSync('crontab -l', { encoding: 'utf8' });
        const cronLines = result.split('\n').filter(line => line && !line.startsWith('#')).length;
        status["agents"]["active_crons"] = cronLines;
    } catch (error) {
        status["agents"]["active_crons"] = "unknown";
    }
    
    // System-Metriken
    try {
        // Disk usage
        const dfOutput = execSync('df -h /', { encoding: 'utf8' });
        const dfLines = dfOutput.split('\n');
        for (const line of dfLines) {
            if (line.includes('/') && line.includes('%')) {
                const parts = line.trim().split(/\s+/);
                status["system"]["disk_used"] = parts[4];
                break;
            }
        }
        
        // RAM usage
        const freeOutput = execSync('free -h', { encoding: 'utf8' });
        const freeLines = freeOutput.split('\n');
        for (const line of freeLines) {
            if (line.includes('Mem:')) {
                const parts = line.trim().split(/\s+/);
                status["system"]["ram_total"] = parts[1];
                status["system"]["ram_used"] = parts[2];
                break;
            }
        }
    } catch (error) {
        // Ignore errors
    }
    
    return status;
}

function formatDailyStatus(status) {
    /** Formatiert täglichen Status */
    const nodes = status["nodes"];
    const online = Object.values(nodes).filter(n => n["status"] === "online").length;
    
    let message = `📊 **Täglicher Status-Report**
🗓️ ${new Date().toLocaleString('de-DE', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })}

**🖥️ Nodes (${online}/5 online):**
`;
    
    for (const [nodeId, info] of Object.entries(nodes)) {
        const emoji = info["status"] === "online" ? "🟢" : info["status"] === "offline" ? "🔴" : "🟡";
        message += `${emoji} ${info['name']}: ${info['status']}`;
        if ("reason" in info) {
            message += ` (${info['reason']})`;
        }
        message += "\n";
    }
    
    message += `\n**🤖 Agents:**\n`;
    message += `Aktive Cron-Jobs: ${status['agents']['active_crons']}\n`;
    
    if ("disk_used" in status["system"]) {
        message += `\n**💾 System:**\n`;
        message += `Disk: ${status['system']['disk_used']} belegt\n`;
        message += `RAM: ${status['system']['ram_used']} / ${status['system']['ram_total']}\n`;
    }
    
    return message;
}

function formatWeeklyStatus(status) {
    /** Formatiert wöchentlichen Status */
    const now = new Date();
    const weekNumber = Math.ceil((((now - new Date(now.getFullYear(), 0, 1)) / 86400000) + now.getDay() + 1) / 7);
    
    const message = `📈 **Wöchentlicher Report**
📅 Woche ${weekNumber} - ${now.getFullYear()}

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
`;
    return message;
}

function sendToChannel(message, channelType = "telegram", channelId = "-1002381931352") {
    /** Sendet Nachricht an Channel */
    let cmd;
    if (channelType === "telegram") {
        // Nutze OpenClaw message tool
        cmd = `openclaw message send --target ${channelId} --message "${message.replace(/"/g, '\\"')}"`;
    } else {
        log(`Channel type ${channelType} not implemented`, "WARN");
        return false;
    }
    
    try {
        execSync(cmd, { stdio: 'pipe' });
        log(`Message sent to ${channelType} ${channelId}`);
        return true;
    } catch (error) {
        log(`Failed to send: ${error.message}`, "ERROR");
        return false;
    }
}

function main() {
    /** Hauptfunktion */
    const args = require('yargs')
        .usage('Usage: $0 --type [daily|weekly|alert] [options]')
        .option('type', {
            describe: 'Type of status update',
            choices: ['daily', 'weekly', 'alert'],
            demandOption: true
        })
        .option('message', {
            describe: 'Alert message',
            type: 'string'
        })
        .option('channel', {
            describe: 'Target channel ID',
            default: '-1002381931352'
        })
        .option('dry-run', {
            describe: 'Show message without sending',
            type: 'boolean'
        })
        .argv;
    
    log(`Starting ${args.type} status update`);
    
    // Status sammeln
    const status = getSystemStatus();
    
    // Message formatieren
    let message;
    if (args.type === 'daily') {
        message = formatDailyStatus(status);
    } else if (args.type === 'weekly') {
        message = formatWeeklyStatus(status);
    } else if (args.type === 'alert') {
        message = `🚨 **ALERT**\n${args.message || 'Manual alert'}`;
    }
    
    // Senden oder Dry-Run
    if (args.dryRun) {
        console.log("\n--- DRY RUN ---");
        console.log(message);
        console.log("--- END ---");
    } else {
        sendToChannel(message, "telegram", args.channel);
    }
    
    log("Status update completed");
}

// Ensure log directory exists
const logDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

main();
