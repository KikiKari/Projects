#!/usr/bin/env tclsh8.6
# log_collector.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
# auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Log Collector Sub-Agent
# Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden

package require sqlite3
package require json

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_PATH "$WORKSPACE/db/logs.db"
set LOG_DIR "$WORKSPACE/logs/log-collector"

# Log-Verzeichnis erstellen
file mkdir $LOG_DIR

# Logger-Klasse
proc Logger {} {
    variable log_file
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set log_file "$::LOG_DIR/$today.log"
}

proc Logger::log {level msg} {
    variable log_file
    set ts [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    set line "\[$ts\] \[$level\] $msg"
    puts $line
    set f [open $log_file a]
    puts $f $line
    close $f
}

proc Logger::info {msg} {
    Logger::log "INFO" $msg
}

proc Logger::error {msg} {
    Logger::log "ERROR" $msg
}

# LogCollector-Klasse
namespace eval LogCollector {
    variable logger
    variable conn
}

proc LogCollector::init {} {
    variable logger
    set logger [Logger]
}

proc LogCollector::connect_db {} {
    variable conn
    sqlite3 conn $::DB_PATH
    conn eval {PRAGMA row_factory = sqlite3_row}
    # Schema initialisieren falls nicht existiert
    _init_schema
    return $conn
}

proc LogCollector::_init_schema {} {
    variable conn
    set tables [conn eval {SELECT name FROM sqlite_master WHERE type='table'}]
    if {[llength $tables] == 0} {
        set schema_path "$::WORKSPACE/db/logs.db.schema.sql"
        if {[file exists $schema_path]} {
            set f [open $schema_path r]
            set schema [read $f]
            close $f
            conn eval $schema
            conn eval {COMMIT}
        }
    }
}

proc LogCollector::get_nodes {} {
    variable conn
    set nodes [list]
    conn eval {SELECT * FROM nodes} row {
        lappend nodes [array get row]
    }
    return $nodes
}

proc LogCollector::check_vpn {ip} {
    # Prüft ob VPN-IP erreichbar ist
    if {[catch {exec ping -c 1 -W 3 $ip} result]} {
        return 0
    } else {
        return [expr {[lindex [split $result] end] eq "0"}]
    }
}

proc LogCollector::ssh_connect_and_collect {node} {
    variable conn
    array set node_array $node
    set node_id $node_array(node_id)
    
    # VPN-IP bestimmen
    set vpn_ip ""
    if {[info exists node_array(vpn_ip)] && $node_array(vpn_ip) ne ""} {
        set vpn_ip $node_array(vpn_ip)
    } elseif {[info exists node_array(tailscale_ip)] && $node_array(tailscale_ip) ne ""} {
        set vpn_ip $node_array(tailscale_ip)
    } elseif {[info exists node_array(wireguard_ip)] && $node_array(wireguard_ip) ne ""} {
        set vpn_ip $node_array(wireguard_ip)
    }
    
    if {$vpn_ip eq ""} {
        Logger::error "$node_id: Keine VPN-IP konfiguriert"
        return
    }
    
    # 1. VPN-Check
    Logger::info "$node_id: Prüfe VPN $vpn_ip..."
    if {![check_vpn $vpn_ip]} {
        Logger::error "$node_id: VPN nicht erreichbar"
        _log_ssh_connection $node_id "tailscale" 0 "VPN unreachable"
        return
    }
    
    # 2. SSH-Verbindung
    Logger::info "$node_id: Verbinde via SSH..."
    set logs_collected [list]
    
    # Log-Kommandos
    set log_commands [list \
        "journalctl -n 500 --no-pager" \
        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'" \
        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"]
    
    foreach cmd $log_commands {
        if {[catch {
            set result [exec ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw@$vpn_ip $cmd]
            lappend logs_collected [dict create \
                command $cmd \
                output $result \
                timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]]
        } error]} {
            # Timeout oder andere Fehler behandeln
            if {[string match "*timeout*" $error]} {
                Logger::error "$node_id: SSH Timeout"
                _log_ssh_connection $node_id "ssh" 0 "Timeout"
                return
            } else {
                Logger::error "$node_id: SSH Fehler: $error"
                _log_ssh_connection $node_id "ssh" 0 $error
                return
            }
        }
    }
    
    # Erfolg loggen
    _log_ssh_connection $node_id "ssh" 1 ""
    
    # In DB speichern
    _insert_logs $node_id $logs_collected
    
    return [llength $logs_collected]
}

proc LogCollector::_log_ssh_connection {node_id conn_type success error} {
    variable conn
    conn eval {
        INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
        VALUES ($node_id, $conn_type, $success, $error)
    }
}

proc LogCollector::_insert_logs {node_id logs} {
    variable conn
    set retention [clock add [clock seconds] 30 days]
    set retention_iso [clock format $retention -format "%Y-%m-%dT%H:%M:%S"]
    
    set log_count 0
    foreach log_entry $logs {
        set cmd [dict get $log_entry command]
        set output [dict get $log_entry output]
        # Begrenze Länge der Felder
        if {[string length $cmd] > 50} {
            set cmd [string range $cmd 0 49]
        }
        if {[string length $output] > 10000} {
            set output [string range $output 0 9999]
        }
        
        conn eval {
            INSERT INTO logs (node_id, log_type, source, content, severity, 
                            collected_by, collection_method, retention_until)
            VALUES ($node_id, 'system', $cmd, $output, 'info', 
                    'node1', 'ssh', $retention_iso)
        }
        incr log_count
    }
    
    Logger::info "$node_id: $log_count Log-Einträge gespeichert"
}

proc LogCollector::cleanup_retention {} {
    variable conn
    set deleted [conn eval {
        DELETE FROM logs WHERE retention_until < datetime('now');
        SELECT changes();
    }]
    Logger::info "Retention-Cleanup: $deleted alte Logs gelöscht"
    return $deleted
}

proc LogCollector::run_collection_cycle {} {
    Logger::info [string repeat "=" 60]
    Logger::info "LOG COLLECTOR CYCLE START"
    Logger::info [string repeat "=" 60]
    
    connect_db
    
    # 1. Nodes holen
    set nodes [get_nodes]
    Logger::info "Gefunden: [llength $nodes] Nodes"
    
    # 2. Collection-Run starten
    variable conn
    conn eval {
        INSERT INTO collection_runs (started_at, nodes_total)
        VALUES (CURRENT_TIMESTAMP, [llength $nodes])
    }
    set run_id [conn last_insert_rowid]
    
    # 3. Für jeden Node sammeln
    set success_count 0
    set failed_count 0
    set total_logs 0
    
    foreach node $nodes {
        array set node_array $node
        if {$node_array(node_id) eq "node1"} {
            # Lokale Logs (Gateway selbst)
            Logger::info "node1: Lokale Collection (Gateway)"
            incr success_count
        } else {
            # Remote-Node abfragen
            set result [ssh_connect_and_collect $node]
            if {$result ne ""} {
                incr success_count
                incr total_logs $result
            } else {
                incr failed_count
            }
        }
    }
    
    # 4. Run abschließen
    conn eval {
        UPDATE collection_runs SET
            finished_at = CURRENT_TIMESTAMP,
            nodes_success = $success_count,
            nodes_failed = $failed_count,
            logs_collected = $total_logs
        WHERE run_id = $run_id
    }
    
    # 5. Retention-Cleanup
    Logger::info "Retention-Cleanup (30 Tage)..."
    cleanup_retention
    
    Logger::info [string repeat "=" 60]
    Logger::info "SUMMARY: $success_count OK, $failed_count Failed, $total_logs Logs"
    Logger::info [string repeat "=" 60]
}

# Hauptprogramm
proc main {} {
    puts [string repeat "=" 60]
    puts "LOG COLLECTOR"
    puts [string repeat "=" 60]
    
    LogCollector::init
    
    if {[catch {
        LogCollector::run_collection_cycle
    } error]} {
        puts "CRITICAL ERROR: $error"
        puts $::errorInfo
        exit 1
    }
}

# Programm starten
main
