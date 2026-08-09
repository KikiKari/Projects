#!/usr/bin/env node
// log_collector.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

/**
 * Log Collector Sub-Agent
 * Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
 */

const fs = require('fs');
const path = require('path');
const { spawnSync, execSync } = require('child_process');

const WORKSPACE = path.join('/home/openclaw/.openclaw/workspace');
const DB_PATH = path.join(WORKSPACE, 'db', 'logs.db');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'log-collector');

// Stelle sicher, dass das Log-Verzeichnis existiert
if (!fs.existsSync(LOG_DIR)) {
    fs.mkdirSync(LOG_DIR, { recursive: true });
}

class Logger {
    constructor() {
        const today = new Date().toISOString().split('T')[0];
        this.logFile = path.join(LOG_DIR, `${today}.log`);
    }

    log(level, msg) {
        const ts = new Date().toISOString();
        const line = `[${ts}] [${level}] ${msg}`;
        console.log(line);
        fs.appendFileSync(this.logFile, line + '\n');
    }

    info(msg) { this.log('INFO', msg); }
    error(msg) { this.log('ERROR', msg); }
}

class LogCollector {
    constructor() {
        this.logger = new Logger();
        this.db = null;
    }

    connectDB() {
        // In Node.js verwenden wir eine SQLite-Bibliothek wie 'better-sqlite3'
        // Da diese nicht standardmäßig verfügbar ist, verwenden wir sqlite3
        const sqlite3 = require('sqlite3').verbose();
        this.db = new sqlite3.Database(DB_PATH);
        
        // Schema initialisieren falls nicht existiert
        this._initSchema();
        return this.db;
    }

    _initSchema() {
        // Prüfen ob Tabellen existieren
        this.db.serialize(() => {
            this.db.get("SELECT name FROM sqlite_master WHERE type='table'", (err, row) => {
                if (err || !row) {
                    const schemaPath = path.join(WORKSPACE, 'db', 'logs.db.schema.sql');
                    if (fs.existsSync(schemaPath)) {
                        const schema = fs.readFileSync(schemaPath, 'utf8');
                        this.db.exec(schema);
                    }
                }
            });
        });
    }

    getNodes() {
        return new Promise((resolve, reject) => {
            this.db.all("SELECT * FROM nodes", (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }

    checkVPN(ip) {
        try {
            const result = spawnSync('ping', ['-c', '1', '-W', '3', ip], {
                timeout: 10000,
                stdio: 'pipe'
            });
            return result.status === 0;
        } catch (e) {
            return false;
        }
    }

    async sshConnectAndCollect(node) {
        const nodeId = node.node_id;
        const vpnIp = node.vpn_ip || node.tailscale_ip || node.wireguard_ip;

        if (!vpnIp) {
            this.logger.error(`${nodeId}: Keine VPN-IP konfiguriert`);
            return null;
        }

        // 1. VPN-Check
        this.logger.info(`${nodeId}: Prüfe VPN ${vpnIp}...`);
        if (!this.checkVPN(vpnIp)) {
            this.logger.error(`${nodeId}: VPN nicht erreichbar`);
            this._logSSHConnection(nodeId, 'tailscale', false, 'VPN unreachable');
            return null;
        }

        // 2. SSH-Verbindung
        this.logger.info(`${nodeId}: Verbinde via SSH...`);
        try {
            // Logs abholen
            const logCommands = [
                "journalctl -n 500 --no-pager",
                "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
                "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
            ];

            const logsCollected = [];
            for (const cmd of logCommands) {
                const result = spawnSync('ssh', [
                    '-o', 'ConnectTimeout=10',
                    '-o', 'StrictHostKeyChecking=no',
                    `openclaw@${vpnIp}`,
                    cmd
                ], {
                    timeout: 30000,
                    encoding: 'utf8',
                    stdio: 'pipe'
                });

                if (result.status === 0) {
                    logsCollected.push({
                        command: cmd,
                        output: result.stdout,
                        timestamp: new Date().toISOString()
                    });
                }
            }

            // Erfolg loggen
            this._logSSHConnection(nodeId, 'ssh', true, null);

            // In DB speichern
            this._insertLogs(nodeId, logsCollected);

            return logsCollected.length;

        } catch (error) {
            if (error.code === 'ETIMEDOUT') {
                this.logger.error(`${nodeId}: SSH Timeout`);
                this._logSSHConnection(nodeId, 'ssh', false, 'Timeout');
            } else {
                this.logger.error(`${nodeId}: SSH Fehler: ${error.message}`);
                this._logSSHConnection(nodeId, 'ssh', false, error.message);
            }
            return null;
        }
    }

    _logSSHConnection(nodeId, connType, success, error) {
        this.db.run(
            'INSERT INTO ssh_connections (node_id, connection_type, success, error_message) VALUES (?, ?, ?, ?)',
            [nodeId, connType, success, error],
            (err) => {
                if (err) this.logger.error(`Fehler beim Loggen der SSH-Verbindung: ${err.message}`);
            }
        );
    }

    _insertLogs(nodeId, logs) {
        const retention = new Date();
        retention.setDate(retention.getDate() + 30);
        const retentionStr = retention.toISOString();

        let insertedCount = 0;
        logs.forEach(logEntry => {
            this.db.run(
                `INSERT INTO logs (node_id, log_type, source, content, severity, 
                                   collected_by, collection_method, retention_until)
                 VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)`,
                [
                    nodeId,
                    logEntry.command.substring(0, 50),
                    logEntry.output.substring(0, 10000), // Limit 10KB
                    'node1', // collected_by
                    retentionStr
                ],
                (err) => {
                    if (err) {
                        this.logger.error(`Fehler beim Einfügen von Logs: ${err.message}`);
                    } else {
                        insertedCount++;
                        if (insertedCount === logs.length) {
                            this.logger.info(`${nodeId}: ${logs.length} Log-Einträge gespeichert`);
                        }
                    }
                }
            );
        });
    }

    cleanupRetention() {
        return new Promise((resolve, reject) => {
            this.db.run(
                "DELETE FROM logs WHERE retention_until < datetime('now')",
                function(err) {
                    if (err) reject(err);
                    else {
                        this.logger.info(`Retention-Cleanup: ${this.changes} alte Logs gelöscht`);
                        resolve(this.changes);
                    }
                }.bind(this)
            );
        });
    }

    async runCollectionCycle() {
        this.logger.info("=".repeat(60));
        this.logger.info("LOG COLLECTOR CYCLE START");
        this.logger.info("=".repeat(60));

        this.connectDB();

        // 1. Nodes holen
        const nodes = await this.getNodes();
        this.logger.info(`Gefunden: ${nodes.length} Nodes`);

        // 2. Collection-Run starten
        return new Promise((resolve, reject) => {
            this.db.run(
                'INSERT INTO collection_runs (started_at, nodes_total) VALUES (CURRENT_TIMESTAMP, ?)',
                [nodes.length],
                function(err) {
                    if (err) return reject(err);
                    const runId = this.lastID;
                    
                    // 3. Für jeden Node sammeln
                    let successCount = 0;
                    let failedCount = 0;
                    let totalLogs = 0;
                    let processed = 0;

                    const processNode = (index) => {
                        if (index >= nodes.length) {
                            // 4. Run abschließen
                            this.db.run(
                                `UPDATE collection_runs SET
                                 finished_at = CURRENT_TIMESTAMP,
                                 nodes_success = ?,
                                 nodes_failed = ?,
                                 logs_collected = ?
                                 WHERE run_id = ?`,
                                [successCount, failedCount, totalLogs, runId],
                                (err) => {
                                    if (err) return reject(err);
                                    
                                    // 5. Retention-Cleanup
                                    this.logger.info("Retention-Cleanup (30 Tage)...");
                                    this.cleanupRetention().then(() => {
                                        this.logger.info("=".repeat(60));
                                        this.logger.info(`SUMMARY: ${successCount} OK, ${failedCount} Failed, ${totalLogs} Logs`);
                                        this.logger.info("=".repeat(60));
                                        resolve();
                                    }).catch(reject);
                                }
                            );
                            return;
                        }

                        const node = nodes[index];
                        if (node.node_id === 'node1') {
                            // Lokale Logs (Gateway selbst)
                            this.logger.info("node1: Lokale Collection (Gateway)");
                            successCount++;
                            processNode(index + 1);
                        } else {
                            // Remote-Node abfragen
                            this.sshConnectAndCollect(node).then(result => {
                                if (result !== null) {
                                    successCount++;
                                    totalLogs += result;
                                } else {
                                    failedCount++;
                                }
                                processNode(index + 1);
                            }).catch(() => {
                                failedCount++;
                                processNode(index + 1);
                            });
                        }
                    };

                    processNode(0);
                }.bind(this)
            );
        });
    }
}

async function main() {
    console.log("=".repeat(60));
    console.log("LOG COLLECTOR");
    console.log("=".repeat(60));

    const collector = new LogCollector();

    try {
        await collector.runCollectionCycle();
    } catch (e) {
        console.log(`CRITICAL ERROR: ${e.message}`);
        console.error(e.stack);
        process.exit(1);
    }
}

if (require.main === module) {
    main().catch(console.error);
}
