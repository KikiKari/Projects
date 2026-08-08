#!/usr/bin/env node
// channel_status.pl — portiert nach javascript
// Quelle: perl5, Projects@abstractions:perl5/channel_status.pl
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// channel_status.js — portiert nach JavaScript für Node 20
// Quelle: perl5, channel_status.pl
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { Command } = require('commander');

// Konfiguration
const WORKSPACE = "/home/openclaw/.openclaw/workspace";
const LOGS_DB = `${WORKSPACE}/db/logs.db`;
const CONFIG_FILE = `${WORKSPACE}/config/channel-status.json`;
const LOG_FILE = `${WORKSPACE}/logs/channel-status.log`;

function logMessage(message, level = "INFO") {
    const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
    const entry = `[${timestamp}] [${level}] ${message}\n`;
    process.stdout.write(entry);
    fs.appendFileSync(LOG_FILE, entry);
}

function getSystemStatus() {
    const status = {
        timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
        nodes: {},
        agents: {},
        system: {}
    };
    
    // Node-Status (vereinfacht)
    const nodes = {
        node1: {name: "Gateway", status: "online"},
        node2: {name: "Worker", status: "online"},
        node3: {name: "Relay", status: "offline", reason: "disk full"},
        node5: {name: "Redmi", status: "intermittent"},
        node7: {name: "Docker", status: "planned"}
    };
    status.nodes = nodes;
    
    // Agent-Status aus Cron
    try {
        const stdout = execSync('crontab -l', { encoding: 'utf8' });
        const lines = stdout.split('\n');
        const cronLines = lines.filter(line => !/^\s*#/.test(line) && /\S/.test(line)).length;
        status.agents.active_crons = cronLines;
    } catch (error) {
        status.agents.active_crons = "unknown";
    }
    
    // System-Metriken
    try {
        // Disk usage
        const dfOutput = execSync('df -h /', { encoding: 'utf8' });
        const dfLines = dfOutput.split('\n');
        for (const line of dfLines) {
            if (line.includes('/') && line.includes('%')) {
                const parts = line.split(/\s+/);
                status.system.disk_used = parts[4];
                break;
            }
        }
        
        // RAM usage
        const freeOutput = execSync('free -h', { encoding: 'utf8' });
        const freeLines = freeOutput.split('\n');
        for (const line of freeLines) {
            if (line.includes('Mem:')) {
                const parts = line.split(/\s+/);
                status.system.ram_total = parts[1];
                status.system.ram_used = parts[2];
                break;
            }
        }
    } catch (error) {
        // Fehler werden ignoriert, status.system bleibt leer
    }
    
    return status;
}

function formatDailyStatus(status) {
    const nodes = status.nodes;
    let online = 0;
    for (const nodeId in nodes) {
        if (nodes[nodeId].status === "online") {
            online++;
        }
    }
    
    let message = "📊 **Täglicher Status-Report**\n";
    message += "🗓️ " + new Date().toISOString().replace('T', ' ').substring(0, 16) + "\n\n";
    message += `**🖥️ Nodes (${online}/5 online):**\n`;
    
    for (const nodeId of Object.keys(nodes).sort()) {
        const info = nodes[nodeId];
        const emoji = info.status === "online" ? "🟢" : 
                      (info.status === "offline" ? "🔴" : "🟡");
        message += `${emoji} ${info.name}: ${info.status}`;
        if (info.reason) {
            message += ` (${info.reason})`;
        }
        message += "\n";
    }
    
    message += "\n**🤖 Agents:**\n";
    message += `Aktive Cron-Jobs: ${status.agents.active_crons}\n`;
    
    if (status.system.disk_used) {
        message += "\n**💾 System:**\n";
        message += `Disk: ${status.system.disk_used} belegt\n`;
        message += `RAM: ${status.system.ram_used} / ${status.system.ram_total}\n`;
    }
    
    return message;
}

function formatWeeklyStatus(status) {
    const now = new Date();
    const weekNumber = Math.ceil((((now - new Date(now.getFullYear(), 0, 1)) / 86400000) + now.getDay() + 1) / 7);
    let message = "📈 **Wöchentlicher Report**\n";
    message += `📅 Woche ${weekNumber} - ${now.getFullYear()}\n\n`;
    message += "**Zusammenfassung:**\n";
    message += "- 5 aktive Sub-Agents\n";
    message += "- 11 Skills synchronisiert\n";
    message += "- 3 neue Features implementiert\n\n";
    message += "**Top-Ereignisse:**\n";
    message += "1. ClawHub-Git Sync implementiert ✅\n";
    message += "2. Node 3 Disk voll (95%) ⚠️\n";
    message += "3. Channel-Status-Agent aktiviert 🆕\n\n";
    message += "**Geplante Wartungen:**\n";
    message += "- Node 3: Disk-Cleanup erforderlich\n";
    message += "- Node 7: Docker-Setup ausstehend\n";
    return message;
}

function sendToChannel(message, channelType = "telegram", channelId = "-1002381931352") {
    if (channelType === "telegram") {
        // Nutze OpenClaw message tool
        const cmd = `openclaw message send --target ${channelId} --message "${message.replace(/"/g, '\\"')}"`;
        try {
            execSync(cmd, { stdio: 'pipe' });
            logMessage(`Message sent to ${channelType} ${channelId}`);
            return true;
        } catch (error) {
            logMessage(`Failed to send: ${error.message}`, "ERROR");
            return false;
        }
    } else {
        logMessage(`Channel type ${channelType} not implemented`, "WARN");
        return false;
    }
}

function main() {
    const program = new Command();
    
    program
        .option('--type <type>', 'Type of status update (daily|weekly|alert)')
        .option('--message <message>', 'Message content for alert type')
        .option('--channel <channel>', 'Channel ID', '-1002381931352')
        .option('--dry-run', 'Dry run mode')
        .parse();
    
    const options = program.opts();
    
    if (!options.type) {
        console.error("Type is required\n");
        process.exit(1);
    }
    
    if (!['daily', 'weekly', 'alert'].includes(options.type)) {
        console.error(`Invalid type: ${options.type}\n`);
        process.exit(1);
    }
    
    logMessage(`Starting ${options.type} status update`);
    
    // Status sammeln
    const status = getSystemStatus();
    
    // Message formatieren
    let formattedMessage;
    if (options.type === 'daily') {
        formattedMessage = formatDailyStatus(status);
    } else if (options.type === 'weekly') {
        formattedMessage = formatWeeklyStatus(status);
    } else if (options.type === 'alert') {
        formattedMessage = "🚨 **ALERT**\n" + (options.message || 'Manual alert');
    }
    
    // Senden oder Dry-Run
    if (options.dryRun) {
        process.stdout.write("\n--- DRY RUN ---\n");
        process.stdout.write(formattedMessage);
        process.stdout.write("\n--- END ---\n");
    } else {
        sendToChannel(formattedMessage, "telegram", options.channel);
    }
    
    logMessage("Status update completed");
}

// Ensure log directory exists
const logDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

main();
