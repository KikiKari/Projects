#!/usr/bin/env node
// channel_status.ps1 — portiert nach javascript
// Quelle: powershell, Projects@abstractions:powershell/channel_status.ps1
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// channel_status.js — portiert von powershell
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

/*
Channel Status Agent - Automatische Status-Updates
*/

import { writeFileSync, appendFileSync, existsSync, mkdirSync } from 'fs';
import { join } from 'path';
import { execSync } from 'child_process';

// Konfiguration
const HOME = process.env.HOME || process.env.USERPROFILE;
const WORKSPACE = join(HOME, ".openclaw", "workspace");
const LOGS_DB = join(WORKSPACE, "db", "logs.db");
const CONFIG_FILE = join(WORKSPACE, "config", "channel-status.json");
const LOG_FILE = join(WORKSPACE, "logs", "channel-status.log");

function writeLog(message, level = "INFO") {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const entry = `[${timestamp}] [${level}] ${message}`;
    console.log(entry);
    appendFileSync(LOG_FILE, entry + '\n');
}

function getSystemStatus() {
    const status = {
        timestamp: new Date().toISOString(),
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
        const cronResult = execSync('crontab -l', { encoding: 'utf8', stdio: ['pipe', 'pipe', 'ignore'] });
        const cronLines = cronResult.split('\n').filter(line => !line.startsWith('#') && line.trim() !== '').length;
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
                const parts = line.trim().split(/\s+/);
                status.system.disk_used = parts[4];
                break;
            }
        }

        // RAM usage
        const freeOutput = execSync('free -h', { encoding: 'utf8' });
        const freeLines = freeOutput.split('\n');
        for (const line of freeLines) {
            if (line.startsWith('Mem:')) {
                const parts = line.trim().split(/\s+/);
                status.system.ram_total = parts[1];
                status.system.ram_used = parts[2];
                break;
            }
        }
    } catch (error) {
        // Ignoriere Fehler
    }

    return status;
}

function formatDailyStatus(status) {
    const nodes = status.nodes;
    const online = Object.values(nodes).filter(node => node.status === "online").length;

    let message = `📊 **Täglicher Status-Report**
🗓️ ${new Date().toLocaleString('de-DE', { year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit' })}

**🖥️ Nodes (${online}/5 online):**
`;

    for (const [key, node] of Object.entries(nodes)) {
        let emoji;
        switch (node.status) {
            case "online": emoji = "🟢"; break;
            case "offline": emoji = "🔴"; break;
            default: emoji = "🟡";
        }
        message += `${emoji} ${node.name}: ${node.status}`;
        if (node.reason) {
            message += ` (${node.reason})`;
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
    const message = `📈 **Wöchentlicher Report**
📅 Woche ${new Date().getFullYear()}-KW${getWeekNumber(new Date())} - ${new Date().getFullYear()}

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

function getWeekNumber(d) {
    d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
    return weekNo;
}

function sendToChannel(message, channelType = "telegram", channelId = "-1002381931352") {
    let cmd;
    if (channelType === "telegram") {
        cmd = ["openclaw", "message", "send", "--target", channelId, "--message", message];
    } else {
        writeLog(`Channel type ${channelType} not implemented`, "WARN");
        return false;
    }

    try {
        const result = execSync(cmd.join(' '), { encoding: 'utf8' });
        writeLog(`Message sent to ${channelType} ${channelId}`);
        return true;
    } catch (error) {
        writeLog(`Failed to send: ${error.message}`, "ERROR");
        return false;
    }
}

function main(type, message, channel, dryRun) {
    writeLog(`Starting ${type} status update`);

    // Status sammeln
    const status = getSystemStatus();

    // Message formatieren
    let formattedMessage;
    switch (type) {
        case "daily": formattedMessage = formatDailyStatus(status); break;
        case "weekly": formattedMessage = formatWeeklyStatus(status); break;
        case "alert": formattedMessage = `🚨 **ALERT**\n${message || 'Manual alert'}`; break;
    }

    // Senden oder Dry-Run
    if (dryRun) {
        console.log("\n--- DRY RUN ---");
        console.log(formattedMessage);
        console.log("--- END ---");
    } else {
        sendToChannel(formattedMessage, "telegram", channel);
    }

    writeLog("Status update completed");
}

// Hauptprogramm
process.on('uncaughtException', (err) => {
    console.error('Uncaught Exception:', err);
    process.exit(1);
});

// Erstelle Log-Verzeichnis falls nicht vorhanden
const logfileDir = LOG_FILE.split('/').slice(0, -1).join('/');
if (!existsSync(logfileDir)) {
    mkdirSync(logfileDir, { recursive: true });
}

// Parameter parsen
let paramType = null;
let paramMessage = null;
let paramChannel = "-1002381931352";
let dryRun = false;

for (let i = 0; i < process.argv.length; i++) {
    switch (process.argv[i]) {
        case "--type": paramType = process.argv[++i]; break;
        case "--message": paramMessage = process.argv[++i]; break;
        case "--channel": paramChannel = process.argv[++i]; break;
        case "--dry-run": dryRun = true; break;
    }
}

if (!paramType) {
    console.error("Parameter --type ist erforderlich");
    process.exit(1);
}

main(paramType, paramMessage, paramChannel, dryRun);
