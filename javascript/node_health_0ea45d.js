#!/usr/bin/env node
// node_health.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Node Health Monitor - Multi-Node Gesundheitsüberwachung
 */

const fs = require('fs');
const { exec, execSync } = require('child_process');
const path = require('path');
const os = require('os');

// Konfiguration
const WORKSPACE = path.join(os.homedir(), '.openclaw/workspace');
const HEALTH_DB = path.join(WORKSPACE, 'db/health.db');
const LOG_FILE = path.join(WORKSPACE, 'logs/node-health.log');

// Node-Definitionen
const NODES = {
  node1: {
    name: "Node 1",
    host: "localhost",
    user: "openclaw",
    critical: true
  },
  node2: {
    name: "Node 2",
    host: "10.10.0.2",
    user: "root",
    ssh_key: "~/.ssh/id_rsa",
    ssh_opts: "-o ConnectTimeout=10 -o BatchMode=yes"
  },
  node3: {
    name: "Node 3",
    host: "localhost",
    user: "root",
    port: 18794,
    ssh_opts: "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes",
    disk_warning: 85
  },
  node5: {
    name: "Redmi",
    host: "192.168.1.x",
    user: "openclaw",
    optional: true
  }
};

function log(message, level = "INFO") {
  /** Logging */
  const timestamp = new Date().toISOString().replace('T', ' ').substring(0, 19);
  const entry = `[${timestamp}] [${level}] ${message}`;
  console.log(entry);
  
  // Stelle sicher, dass das Verzeichnis existiert
  const logDir = path.dirname(LOG_FILE);
  if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
  }
  
  fs.appendFileSync(LOG_FILE, entry + '\n');
}

function checkPing(host, timeout = 10) {
  /** Prüft Erreichbarkeit (Timeout seconds) */
  return new Promise((resolve) => {
    const platform = os.platform();
    let cmd;
    
    if (platform === 'win32') {
      cmd = `ping -n 1 -w ${timeout * 1000} ${host}`;
    } else {
      cmd = `ping -c 1 -W ${timeout} ${host}`;
    }
    
    exec(cmd, (error, stdout, stderr) => {
      resolve(!error);
    });
  });
}

function checkSSH(nodeConfig) {
  /** Prüft SSH-Verbindung */
  return new Promise((resolve) => {
    const host = nodeConfig.host;
    const user = nodeConfig.user || "root";
    const sshOpts = nodeConfig.ssh_opts || "";
    const port = nodeConfig.port;
    
    let cmd = "ssh";
    if (sshOpts) {
      cmd += " " + sshOpts;
    }
    if (port) {
      cmd += ` -p ${port}`;
    }
    cmd += ` -o ConnectTimeout=10 -o BatchMode=yes ${user}@${host} echo "OK"`;
    
    exec(cmd, (error, stdout, stderr) => {
      resolve(!error && stdout.includes("OK"));
    });
  });
}

function getNodeMetrics(nodeConfig) {
  /** Holt Metriken via SSH */
  return new Promise((resolve) => {
    const host = nodeConfig.host;
    const user = nodeConfig.user || "root";
    
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
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \\$2}" | cut -d"%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\\$3/\\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \\$5}" | tr -d "%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \\$2}" | awk "{print \\$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    '`;
    
    exec(cmd, { timeout: 15000 }, (error, stdout, stderr) => {
      if (error) {
        if (error.killed) {
          log(`SSH timeout for ${nodeConfig.name}`, "WARN");
        } else {
          log(`Error checking ${nodeConfig.name}: ${error.message}`, "ERROR");
        }
        resolve(metrics);
        return;
      }
      
      metrics.available = true;
      
      const lines = stdout.trim().split('\n');
      for (const line of lines) {
        if (line.includes(':')) {
          const [key, value] = line.split(':', 2);
          switch (key) {
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
      }
      
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
    if (metrics.cpu && metrics.cpu > 90) {
      alerts.push({
        level: "WARNING",
        message: `Node ${nodeConfig.name}: CPU bei ${metrics.cpu.toFixed(1)}%`
      });
    }
    
    // RAM
    if (metrics.ram && metrics.ram > 90) {
      alerts.push({
        level: "WARNING", 
        message: `Node ${nodeConfig.name}: RAM bei ${metrics.ram.toFixed(1)}%`
      });
    }
    
    // Disk
    const diskThreshold = nodeConfig.disk_warning || 85;
    if (metrics.disk && metrics.disk > diskThreshold) {
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
    const cmd = `python3 "${scriptPath}" --type alert --message "${alert.level}: ${alert.message}"`;
    
    exec(cmd, (error, stdout, stderr) => {
      if (error) {
        log(`Failed to send alert: ${error.message}`, "ERROR");
      } else {
        log(`Alert sent: ${alert.message}`);
      }
      resolve();
    });
  });
}

async function main() {
  /** Hauptfunktion */
  const args = require('yargs')
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
      type: 'boolean'
    })
    .help()
    .argv;
  
  // Nodes bestimmen
  let nodesToCheck;
  if (args.node === 'all') {
    nodesToCheck = Object.entries(NODES);
  } else {
    if (NODES[args.node]) {
      nodesToCheck = [[args.node, NODES[args.node]]];
    } else {
      log(`Unknown node: ${args.node}`, "ERROR");
      process.exit(1);
    }
  }
  
  // Health-Checks durchführen
  const allAlerts = [];
  
  for (const [nodeId, nodeConfig] of nodesToCheck) {
    log(`Checking ${nodeConfig.name} (${nodeId})`);
    
    // Ping
    if (args.check === 'ping' || args.check === 'all') {
      if (nodeConfig.host !== "localhost") {
        const pingOk = await checkPing(nodeConfig.host);
        log(`  Ping: ${pingOk ? 'OK' : 'FAILED'}`);
      }
    }
    
    // SSH
    if (args.check === 'ssh' || args.check === 'all') {
      const sshOk = await checkSSH(nodeConfig);
      log(`  SSH: ${sshOk ? 'OK' : 'FAILED'}`);
    }
    
    // Metriken
    if (args.check === 'metrics' || args.check === 'all') {
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
  if (args.alert && allAlerts.length > 0) {
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
