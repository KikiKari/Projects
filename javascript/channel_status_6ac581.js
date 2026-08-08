#!/usr/bin/env node
// channel_status.sh — portiert nach javascript
// Quelle: shell, Projects@abstractions:shell/channel_status.sh
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

// channel_status.py — portiert nach JavaScript
// Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
// auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
// Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

'use strict';

const fs = require('fs');
const { execSync } = require('child_process');
const path = require('path');

// Konfiguration
const WORKSPACE = '/home/openclaw/.openclaw/workspace';
const LOGS_DB = `${WORKSPACE}/db/logs.db`;
const CONFIG_FILE = `${WORKSPACE}/config/channel-status.json`;
const LOG_FILE = `${WORKSPACE}/logs/channel-status.log`;

// Logging
function log(message, level = 'INFO') {
    const timestamp = new Date().toISOString().replace('T', ' ').slice(0, 19);
    const entry = `[${timestamp}] [${level}] ${message}`;
    console.log(entry);
    fs.appendFileSync(LOG_FILE, entry + '\n');
}

// Sammelt System-Status
function getSystemStatus() {
    let status = {
        timestamp: new Date().toISOString(),
        nodes: {
            node1: { name: 'Gateway', status: 'online' },
            node2: { name: 'Worker', status: 'online' },
            node3: { name: 'Relay', status: 'offline', reason: 'disk full' },
            node5: { name: 'Redmi', status: 'intermittent' },
            node7: { name: 'Docker', status: 'planned' }
        },
        agents: {},
        system: {}
    };

    // Agent-Status aus Cron
    try {
        const cronOutput = execSync('crontab -l 2>/dev/null | grep -v "^#" | wc -l', { encoding: 'utf8' });
        status.agents.active_crons = cronOutput.trim() || 'unknown';
    } catch (error) {
        status.agents.active_crons = 'unknown';
    }

    // System-Metriken
    try {
        const diskOutput = execSync('df -h / | awk \'NR==2 {print $5}\'', { encoding: 'utf8' });
        status.system.disk_used = diskOutput.trim();
    } catch (error) {
        status.system.disk_used = 'unknown';
    }

    try {
        const ramOutput = execSync('free -h | awk \'NR==2 {print $2" "$3}\'', { encoding: 'utf8' });
        const [ramTotal, ramUsed] = ramOutput.trim().split(' ');
        status.system.ram_total = ramTotal;
        status.system.ram_used = ramUsed;
    } catch (error) {
        status.system.ram_total = 'unknown';
        status.system.ram_used = 'unknown';
    }

    return status;
}

// Formatiert täglichen Status
function formatDailyStatus(status) {
    let message = '📊 **Täglicher Status-Report**\n';
    message += new Date().toLocaleString('de-DE', { 
        year: 'numeric', month: '2-digit', day: '2-digit',
        hour: '2-digit', minute: '2-digit'
    }) + '\n\n';

    message += '**🖥️ Nodes (';
    const onlineNodes = Object.values(status.nodes).filter(node => node.status === 'online').length;
    message += `${onlineNodes}/5 online):\n`;

    for (const [nodeId, node] of Object.entries(status.nodes)) {
        let emoji;
        switch (node.status) {
            case 'online': emoji = '🟢'; break;
            case 'offline': emoji = '🔴'; break;
            default: emoji = '🟡'; break;
        }
        message += `${emoji} ${node.name}: ${node.status}`;
        if (node.reason && node.reason !== 'null') {
            message += ` (${node.reason})`;
        }
        message += '\n';
    }

    message += '\n**🤖 Agents:**\n';
    message += `Aktive Cron-Jobs: ${status.agents.active_crons}\n`;

    if (status.system.disk_used) {
        message += '\n**💾 System:**\n';
        message += `Disk: ${status.system.disk_used} belegt\n`;
        message += `RAM: ${status.system.ram_used} / ${status.system.ram_total}\n`;
    }

    return message;
}

// Formatiert wöchentlichen Status
function formatWeeklyStatus() {
    let message = '📈 **Wöchentlicher Report**\n';
    const now = new Date();
    const weekNumber = Math.ceil((((now - new Date(now.getFullYear(), 0, 1)) / 86400000) + now.getDay() + 1) / 7);
    message += `📅 Woche ${weekNumber} - ${now.getFullYear()}\n\n`;

    message += '**Zusammenfassung:**\n';
    message += '- 5 aktive Sub-Agents\n';
    message += '- 11 Skills synchronisiert\n';
    message += '- 3 neue Features implementiert\n\n';

    message += '**Top-Ereignisse:**\n';
    message += '1. ClawHub-Git Sync implementiert ✅\n';
    message += '2. Node 3 Disk voll (95%) ⚠️\n';
    message += '3. Channel-Status-Agent aktiviert 🆕\n\n';

    message += '**Geplante Wartungen:**\n';
    message += '- Node 3: Disk-Cleanup erforderlich\n';
    message += '- Node 7: Docker-Setup ausstehend\n';

    return message;
}

// Sendet Nachricht an Channel
function sendToChannel(message, channelType = 'telegram', channelId = '-1002381931352') {
    if (channelType === 'telegram') {
        const cmd = `openclaw message send --target "${channelId}" --message "${message.replace(/"/g, '\\"')}"`;
        try {
            execSync(cmd, { stdio: 'inherit' });
            log(`Message sent to ${channelType} ${channelId}`);
            return true;
        } catch (error) {
            log('Failed to send message', 'ERROR');
            return false;
        }
    } else {
        log(`Channel type ${channelType} not implemented`, 'WARN');
        return false;
    }
}

// Hauptfunktion
function main() {
    let type = '';
    let message = '';
    let channel = '-1002381931352';
    let dryRun = false;

    // Argumente parsen
    const args = process.argv.slice(2);
    for (let i = 0; i < args.length; i++) {
        switch (args[i]) {
            case '--type':
                type = args[++i];
                break;
            case '--message':
                message = args[++i];
                break;
            case '--channel':
                channel = args[++i];
                break;
            case '--dry-run':
                dryRun = true;
                break;
            default:
                console.error(`Unbekannte Option: ${args[i]}`);
                process.exit(1);
        }
    }

    if (!type) {
        console.error('Fehler: --type ist erforderlich');
        process.exit(1);
    }

    log(`Starting ${type} status update`);

    // Status sammeln
    const status = getSystemStatus();

    // Message formatieren
    let formattedMessage = '';
    switch (type) {
        case 'daily':
            formattedMessage = formatDailyStatus(status);
            break;
        case 'weekly':
            formattedMessage = formatWeeklyStatus();
            break;
        case 'alert':
            formattedMessage = '🚨 **ALERT**\n' + (message || 'Manual alert');
            break;
        default:
            console.error(`Unbekannter Typ: ${type}`);
            process.exit(1);
    }

    // Senden oder Dry-Run
    if (dryRun) {
        console.log('\n--- DRY RUN ---');
        console.log(formattedMessage);
        console.log('--- END ---\n');
    } else {
        sendToChannel(formattedMessage, 'telegram', channel);
    }

    log('Status update completed');
}

// Sicherstellen, dass das Log-Verzeichnis existiert
const logDir = path.dirname(LOG_FILE);
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

// Hauptfunktion aufrufen
main();
