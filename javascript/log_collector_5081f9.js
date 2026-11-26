#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "d750f7a19fdb441c4642788d3e2f719a66e415c6c4557b655e386e7184da4d7e", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "javascript"}
// log_collector.py — portiert nach javascript
// Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
// auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/**
 * Log Collector Sub-Agent
 * Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');
const sqlite3 = require('sqlite3').verbose();

const WORKSPACE = path.join('/home/openclaw/.openclaw/workspace');
const DB_PATH = path.join(WORKSPACE, 'db', 'logs.db');
const LOG_DIR = path.join(WORKSPACE, 'logs', 'log-collector');

// Stelle sicher, dass das Log-Verzeichnis existiert
fs.mkdirSync(LOG_DIR, { recursive: true });


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
        this.conn = null;
    }
    
    connectDb() {
        this.conn = new sqlite3.Database(DB_PATH);
        // Schema initialisieren falls nicht existiert
        this._initSchema();
        return this.conn;
    }
    
    _initSchema() {
        /** Liest schema.sql falls DB leer */
        this.conn.get("SELECT name FROM sqlite_master WHERE type='table'", (err, row) => {
            if (!row) {
                const schemaPath = path.join(WORKSPACE, 'db', 'logs.db.schema.sql');
                if (fs.existsSync(schemaPath)) {
                    const schema = fs.readFileSync(schemaPath, 'utf8');
                    this.conn.exec(schema);
                }
            }
        });
    }
    
    getNodes() {
        /** Holt Liste aller Nodes aus DB */
        return new Promise((resolve, reject) => {
            this.conn.all("SELECT * FROM nodes", (err, rows) => {
                if (err) reject(err);
                else resolve(rows);
            });
        });
    }
    
    checkVpn(ip) {
        /** Prüft ob VPN-IP erreichbar ist */
        try {
            const result = spawnSync('ping', ['-c', '1', '-W', '3', ip], {
                timeout: 10000
            });
            return result.status === 0;
        } catch (error) {
            return false;
        }
    }
    
    async sshConnectAndCollect(node) {
        /** Verbindet via SSH und sammelt Logs */
        const nodeId = node.node_id;
        const vpnIp = node.vpn_ip || node.tailscale_ip || node.wireguard_ip;
        
        if (!vpnIp) {
            this.logger.error(`${nodeId}: Keine VPN-IP konfiguriert`);
            return null;
        }
        
        // 1. VPN-Check
        this.logger.info(`${nodeId}: Prüfe VPN ${vpnIp}...`);
        if (!this.checkVpn(vpnIp)) {
            this.logger.error(`${nodeId}: VPN nicht erreichbar`);
            await this._logSshConnection(nodeId, 'tailscale', false, 'VPN unreachable');
            return null;
        }
        
        // 2. SSH-Verbindung
        this.logger.info(`${nodeId}: Verbinde via SSH...`);
        try {
            // Logs abholen (ohne cd wegen exec-Beschränkungen)
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
                    encoding: 'utf8',
                    timeout: 30000
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
            await this._logSshConnection(nodeId, 'ssh', true, null);
            
            // In DB speichern
            await this._insertLogs(nodeId, logsCollected);
            
            return logsCollected.length;
            
        } catch (error) {
            if (error.code === 'ETIMEDOUT') {
                this.logger.error(`${nodeId}: SSH Timeout`);
                await this._logSshConnection(nodeId, 'ssh', false, 'Timeout');
            } else if (error.code === 'ENOENT') {
                this.logger.error(`${nodeId}: SSH nicht verfügbar`);
            } else {
                this.logger.error(`${nodeId}: SSH Fehler: ${error.message}`);
                await this._logSshConnection(nodeId, 'ssh', false, error.message);
            }
            return null;
        }
    }
    
    _logSshConnection(nodeId, connType, success, error) {
        /** Loggt SSH-Verbindungsversuch */
        return new Promise((resolve, reject) => {
            this.conn.run(`
                INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
                VALUES (?, ?, ?, ?)
            `, [nodeId, connType, success, error], (err) => {
                if (err) reject(err);
                else this.conn.run('COMMIT', resolve);
            });
        });
    }
    
    _insertLogs(nodeId, logs) {
        /** Speichert Logs in Datenbank */
        return new Promise((resolve, reject) => {
            const stmt = this.conn.prepare(`
                INSERT INTO logs (node_id, log_type, source, content, severity, 
                                collected_by, collection_method, retention_until)
                VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)
            `);
            
            const retention = new Date();
            retention.setDate(retention.getDate() + 30);
            
            let inserted = 0;
            for (const logEntry of logs) {
                stmt.run(
                    nodeId,
                    logEntry.command.substring(0, 50),
                    logEntry.output.substring(0, 10000), // Limit 10KB
                    'node1', // collected_by
                    retention.toISOString()
                );
                inserted++;
            }
            
            stmt.finalize((err) => {
                if (err) reject(err);
                else {
                    this.conn.run('COMMIT', () => {
                        this.logger.info(`${nodeId}: ${inserted} Log-Einträge gespeichert`);
                        resolve();
                    });
                }
            });
        });
    }
    
    cleanupRetention() {
        /** Löscht Logs älter 30 Tage */
        return new Promise((resolve, reject) => {
            this.conn.run(`
                DELETE FROM logs WHERE retention_until < datetime('now')
            `, function(err) {
                if (err) reject(err);
                else {
                    this.logger.info(`Retention-Cleanup: ${this.changes} alte Logs gelöscht`);
                    resolve(this.changes);
                }
            });
        });
    }
    
    async runCollectionCycle() {
        /** Ein kompletter Sammel-Durchlauf */
        this.logger.info("=".repeat(60));
        this.logger.info("LOG COLLECTOR CYCLE START");
        this.logger.info("=".repeat(60));
        
        this.connectDb();
        
        // 1. Nodes holen
        const nodes = await this.getNodes();
        this.logger.info(`Gefunden: ${nodes.length} Nodes`);
        
        // 2. Collection-Run starten
        return new Promise((resolve, reject) => {
            this.conn.run(`
                INSERT INTO collection_runs (started_at, nodes_total)
                VALUES (CURRENT_TIMESTAMP, ?)
            `, [nodes.length], function(err) {
                if (err) return reject(err);
                
                const runId = this.lastID;
                
                // 3. Für jeden Node sammeln
                let successCount = 0;
                let failedCount = 0;
                let totalLogs = 0;
                
                const processNodes = async () => {
                    for (const node of nodes) {
                        if (node.node_id === 'node1') {
                            // Lokale Logs (Gateway selbst)
                            this.logger.info("node1: Lokale Collection (Gateway)");
                            successCount++;
                        } else {
                            // Remote-Node abfragen
                            const result = await this.sshConnectAndCollect(node);
                            if (result !== null) {
                                successCount++;
                                totalLogs += result;
                            } else {
                                failedCount++;
                            }
                        }
                    }
                    
                    // 4. Run abschließen
                    this.conn.run(`
                        UPDATE collection_runs SET
                            finished_at = CURRENT_TIMESTAMP,
                            nodes_success = ?,
                            nodes_failed = ?,
                            logs_collected = ?
                        WHERE run_id = ?
                    `, [successCount, failedCount, totalLogs, runId], async (err) => {
                        if (err) return reject(err);
                        
                        // 5. Retention-Cleanup
                        this.logger.info("Retention-Cleanup (30 Tage)...");
                        await this.cleanupRetention();
                        
                        this.logger.info("=".repeat(60));
                        this.logger.info(`SUMMARY: ${successCount} OK, ${failedCount} Failed, ${totalLogs} Logs`);
                        this.logger.info("=".repeat(60));
                        
                        resolve();
                    });
                };
                
                processNodes().catch(reject);
            }.bind(this));
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
    } catch (error) {
        console.log(`CRITICAL ERROR: ${error.message}`);
        console.error(error.stack);
        process.exit(1);
    }
}


if (require.main === module) {
    main();
}

module.exports = { LogCollector, Logger };
