#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "bfae9ae8714186422482bd15db023ed56a209e4f3e17a05dd32800fb5cbfbf38", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "javascript"}
// node_health.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Node Health Monitor - Multi-Node Gesundheitsüberwachung
 */

const fs = require('fs');
const path = require('path');
const { spawn, exec } = require('child_process');

// Konfiguration
const WORKSPACE = path.join('/home/openclaw/.openclaw/workspace');
const HEALTH_DB = path.join(WORKSPACE, 'db/health.db');
const LOG_FILE = path.join(WORKSPACE, 'logs/node-health.log');

// Node-Definitionen
const NODES = {
    "node1": {
        "name": "Gateway",
        "host": "localhost",
        "user": "openclaw",
        "critical": true
    },
    "node2": {
        "name": "Worker", 
        "host": "100.92.155.34",
        "user": "root",
        "ssh_key": "~/.ssh/id_rsa"
    },
    "node3": {
        "name": "Relay",
        "host": "185.242.xxx.xxx",
        "user": "root",
        "disk_warning": 85
    },
    "node5": {
        "name": "Redmi",
        "host": "192.168.1.x",
        "user": "openclaw",
        "optional": true
    }
};

function log(message, level = "INFO") {
    /** Logging */
    const timestamp = new Date().toISOString().replace(/T/, ' ').replace(/\..+/, '');
    const entry = `[${timestamp}] [${level}] ${message}`;
    console.log(entry);
    
    const logDir = path.dirname(LOG_FILE);
    if (!fs.existsSync(logDir)) {
        fs.mkdirSync(logDir, { recursive: true });
    }
    
    fs.appendFileSync(LOG_FILE, entry + '\n');
}

function checkPing(host, timeout = 5) {
    /** Prüft Erreichbarkeit */
    return new Promise((resolve) => {
        const ping = spawn('ping', ['-c', '1', '-W', timeout.toString(), host]);
        
        ping.on('close', (code) => {
            resolve(code === 0);
        });
        
        ping.on('error', () => {
            resolve(false);
        });
    });
}

function checkSSH(nodeConfig) {
    /** Prüft SSH-Verbindung */
    const host = nodeConfig.host;
    const user = nodeConfig.user || 'root';
    
    return new Promise((resolve) => {
        const cmd = spawn('ssh', [
            '-o', 'ConnectTimeout=10',
            '-o', 'BatchMode=yes',
            `${user}@${host}`,
            'echo "OK"'
        ]);
        
        let stdout = '';
        
        cmd.stdout.on('data', (data) => {
            stdout += data.toString();
        });
        
        cmd.on('close', (code) => {
            resolve(code === 0 && stdout.includes('OK'));
        });
        
        cmd.on('error', () => {
            resolve(false);
        });
    });
}

function getNodeMetrics(nodeConfig) {
    /** Holt Metriken via SSH */
    const host = nodeConfig.host;
    const user = nodeConfig.user || 'root';
    
    const metrics = {
        timestamp: new Date().toISOString(),
        available: false,
        cpu: null,
        ram: null,
        disk: null,
        load: null
    };
    
    // SSH-Command für alle Metriken
    const cmd = `ssh -o ConnectTimeout=10 ${user}@${host} '
        # CPU
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    '`;
    
    return new Promise((resolve) => {
        exec(cmd, { timeout: 15000 }, (error, stdout, stderr) => {
            if (error || stderr) {
                if (error && error.killed) {
                    log(`SSH timeout for ${nodeConfig.name}`, "WARN");
                } else {
                    log(`Error checking ${nodeConfig.name}: ${error ? error.message : stderr}`, "ERROR");
                }
                resolve(metrics);
                return;
            }
            
            metrics.available = true;
            
            stdout.trim().split('\n').forEach(line => {
                if (line.includes(':')) {
                    const [key, value] = line.split(':', 2);
                    switch(key) {
                        case "CPU":
                            metrics.cpu = parseFloat(value);
                            break;
                        case "RAM":
                            metrics.ram = parseFloat(value);
                            break;
                        case "DISK":
                            metrics.disk = parseInt(value, 10);
                            break;
                        case "LOAD":
                            metrics.load = parseFloat(value);
                            break;
                        case "GATEWAY":
                            metrics.gateway_status = value;
                            break;
                    }
                }
            });
            
            resolve(metrics);
        });
    });
}

function checkAlerts(nodeId, nodeConfig, metrics) {
    /** Prüft Schwellwerte und generiert Alerts */
    const alerts = [];
    
    // Verfügbarkeit
    if (!metrics.available) {
        if (!nodeConfig.optional) {
            alerts.push({
                level: "CRITICAL",
                message: `Node ${nodeConfig.name} nicht erreichbar!`
            });
        }
    } else {
        // CPU
        if (metrics.cpu !== null && metrics.cpu > 90) {
            alerts.push({
                level: "WARNING",
                message: `Node ${nodeConfig.name}: CPU bei ${metrics.cpu.toFixed(1)}%`
            });
        }
        
        // RAM
        if (metrics.ram !== null && metrics.ram > 90) {
            alerts.push({
                level: "WARNING", 
                message: `Node ${nodeConfig.name}: RAM bei ${metrics.ram.toFixed(1)}%`
            });
        }
        
        // Disk
        const diskThreshold = nodeConfig.disk_warning || 85;
        if (metrics.disk !== null && metrics.disk > diskThreshold) {
            const level = metrics.disk > 95 ? "CRITICAL" : "WARNING";
            alerts.push({
                level: level,
                message: `Node ${nodeConfig.name}: Disk bei ${metrics.disk}%`
            });
        }
        
        // Gateway
        if (nodeConfig.critical && metrics.gateway_status === "inactive") {
            alerts.push({
                level: "CRITICAL",
                message: `Node ${nodeConfig.name}: OpenClaw Gateway nicht aktiv!`
            });
        }
    }
    
    return alerts;
}

function sendAlert(alert) {
    /** Sendet Alert via channel-status-agent */
    return new Promise((resolve) => {
        const scriptPath = path.join(WORKSPACE, 'skills/channel-status-agent/scripts/channel_status.py');
        const cmd = spawn('python3', [
            scriptPath,
            '--type', 'alert',
            '--message', `${alert.level}: ${alert.message}`
        ]);
        
        cmd.on('close', (code) => {
            if (code === 0) {
                log(`Alert sent: ${alert.message}`);
            } else {
                log(`Failed to send alert: exit code ${code}`, "ERROR");
            }
            resolve();
        });
        
        cmd.on('error', (err) => {
            log(`Failed to send alert: ${err.message}`, "ERROR");
            resolve();
        });
    });
}

async function main() {
    /** Hauptfunktion */
    const yargs = require('yargs');
    
    const argv = yargs
        .usage('Usage: $0 [options]')
        .option('node', {
            describe: 'Node ID oder "all"',
            default: 'all'
        })
        .option('check', {
            describe: 'Check type',
            choices: ['ping', 'ssh', 'metrics', 'all'],
            default: 'all'
        })
        .option('alert', {
            describe: 'Sende Alerts',
            boolean: true
        })
        .help()
        .argv;
    
    // Nodes bestimmen
    let nodesToCheck;
    if (argv.node === 'all') {
        nodesToCheck = Object.entries(NODES);
    } else {
        if (NODES[argv.node]) {
            nodesToCheck = [[argv.node, NODES[argv.node]]];
        } else {
            log(`Unknown node: ${argv.node}`, "ERROR");
            process.exit(1);
        }
    }
    
    // Health-Checks durchführen
    const allAlerts = [];
    
    for (const [nodeId, nodeConfig] of nodesToCheck) {
        log(`Checking ${nodeConfig.name} (${nodeId})`);
        
        // Ping
        if (argv.check === 'ping' || argv.check === 'all') {
            if (nodeConfig.host !== "localhost") {
                const pingOk = await checkPing(nodeConfig.host);
                log(`  Ping: ${pingOk ? 'OK' : 'FAILED'}`);
            }
        }
        
        // SSH
        if (argv.check === 'ssh' || argv.check === 'all') {
            const sshOk = await checkSSH(nodeConfig);
            log(`  SSH: ${sshOk ? 'OK' : 'FAILED'}`);
        }
        
        // Metriken
        if (argv.check === 'metrics' || argv.check === 'all') {
            const metrics = await getNodeMetrics(nodeConfig);
            
            if (metrics.available) {
                log(`  CPU: ${metrics.cpu !== null ? metrics.cpu.toFixed(1) + '%' : 'N/A'}`);
                log(`  RAM: ${metrics.ram !== null ? metrics.ram.toFixed(1) + '%' : 'N/A'}`);
                log(`  Disk: ${metrics.disk !== null ? metrics.disk + '%' : 'N/A'}`);
                log(`  Load: ${metrics.load !== null ? metrics.load : 'N/A'}`);
            } else {
                log("  Metrics: UNAVAILABLE");
            }
            
            // Alerts prüfen
            const alerts = checkAlerts(nodeId, nodeConfig, metrics);
            allAlerts.push(...alerts);
        }
    }
    
    // Alerts senden
    if (argv.alert && allAlerts.length > 0) {
        log(`\nSending ${allAlerts.length} alerts...`);
        for (const alert of allAlerts) {
            await sendAlert(alert);
        }
    } else if (allAlerts.length > 0) {
        log(`\n${allAlerts.length} alerts found (use --alert to send)`);
    } else {
        log("\nAll nodes healthy!");
    }
}

if (require.main === module) {
    main().catch(err => {
        console.error(err);
        process.exit(1);
    });
}
