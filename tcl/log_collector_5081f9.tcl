#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "c031a7ad61dbd1c277b0ce159f51fdb7272e04011f789c358d2672ac80348673", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "tcl"}
# log_collector.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
# auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Log Collector Sub-Agent
# Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden

package require sqlite3
package require json

set WORKSPACE "/home/openclaw/.openclaw/workspace"
set DB_PATH "$WORKSPACE/db/logs.db"
set LOG_DIR "$WORKSPACE/logs/log-collector"

# Create log directory if it doesn't exist
file mkdir $LOG_DIR

proc init_logger {} {
    global LOG_DIR
    set today [clock format [clock seconds] -format "%Y-%m-%d"]
    set log_file "$LOG_DIR/$today.log"
    return $log_file
}

proc log_msg {level msg} {
    global logger_fd
    set ts [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    set line "\[$ts\] \[$level\] $msg"
    puts $line
    if {[info exists logger_fd]} {
        puts $logger_fd $line
        flush $logger_fd
    }
}

proc log_info {msg} {
    log_msg "INFO" $msg
}

proc log_error {msg} {
    log_msg "ERROR" $msg
}

proc connect_db {} {
    global DB_PATH conn
    sqlite3 conn $DB_PATH
    conn eval {PRAGMA foreign_keys = ON}
    
    # Initialize schema if needed
    init_schema
    return conn
}

proc init_schema {} {
    global conn WORKSPACE
    set tables [conn eval {SELECT name FROM sqlite_master WHERE type='table'}]
    if {[llength $tables] == 0} {
        set schema_path "$WORKSPACE/db/logs.db.schema.sql"
        if {[file exists $schema_path]} {
            set fd [open $schema_path r]
            set schema_sql [read $fd]
            close $fd
            conn eval $schema_sql
        }
    }
}

proc get_nodes {} {
    global conn
    set nodes {}
    conn eval {SELECT * FROM nodes} row {
        lappend nodes [array get row]
    }
    return $nodes
}

proc check_vpn {ip} {
    if {[catch {exec ping -c 1 -W 3 $ip} result]} {
        return 0
    } else {
        return [expr {[lindex [split $result "\n"] end] eq "0"}]
    }
}

proc ssh_connect_and_collect {node_dict} {
    global conn
    array set node $node_dict
    
    set node_id $node(node_id)
    set vpn_ip ""
    
    if {[info exists node(vpn_ip)] && $node(vpn_ip) ne ""} {
        set vpn_ip $node(vpn_ip)
    } elseif {[info exists node(tailscale_ip)] && $node(tailscale_ip) ne ""} {
        set vpn_ip $node(tailscale_ip)
    } elseif {[info exists node(wireguard_ip)] && $node(wireguard_ip) ne ""} {
        set vpn_ip $node(wireguard_ip)
    }
    
    if {$vpn_ip eq ""} {
        log_error "$node_id: Keine VPN-IP konfiguriert"
        return
    }
    
    # 1. VPN-Check
    log_info "$node_id: Prüfe VPN $vpn_ip..."
    if {![check_vpn $vpn_ip]} {
        log_error "$node_id: VPN nicht erreichbar"
        log_ssh_connection $node_id "tailscale" 0 "VPN unreachable"
        return
    }
    
    # 2. SSH-Verbindung
    log_info "$node_id: Verbinde via SSH..."
    set logs_collected {}
    
    set log_commands {
        "journalctl -n 500 --no-pager"
        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'"
        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
    }
    
    foreach cmd $log_commands {
        if {[catch {
            exec ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no \
                 openclaw@$vpn_ip $cmd
        } output]} {
            log_error "$node_id: SSH Fehler bei Kommando '$cmd': $output"
        } else {
            lappend logs_collected [dict create \
                command $cmd \
                output $output \
                timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]]
        }
    }
    
    # Erfolg loggen
    log_ssh_connection $node_id "ssh" 1 ""
    
    # In DB speichern
    insert_logs $node_id $logs_collected
    
    return [llength $logs_collected]
}

proc log_ssh_connection {node_id conn_type success error} {
    global conn
    conn eval {
        INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
        VALUES ($node_id, $conn_type, $success, $error)
    }
}

proc insert_logs {node_id logs} {
    global conn
    set retention [expr {[clock seconds] + 30*24*60*60}]
    set retention_iso [clock format $retention -format "%Y-%m-%dT%H:%M:%S"]
    
    foreach log_entry $logs {
        set cmd [dict get $log_entry command]
        set output [dict get $log_entry output]
        
        # Truncate to reasonable sizes
        if {[string length $cmd] > 50} {
            set cmd [string range $cmd 0 49]
        }
        if {[string length $output] > 10000} {
            set output [string range $output 0 9999]
        }
        
        conn eval {
            INSERT INTO logs (node_id, log_type, source, content, severity, 
                            collected_by, collection_method, retention_until)
            VALUES ($node_id, 'system', $cmd, $output, 'info', 'node1', 'ssh', $retention_iso)
        }
    }
    
    log_info "$node_id: [llength $logs] Log-Einträge gespeichert"
}

proc cleanup_retention {} {
    global conn
    set deleted [conn eval {
        DELETE FROM logs WHERE retention_until < datetime('now');
        SELECT changes();
    }]
    log_info "Retention-Cleanup: $deleted alte Logs gelöscht"
    return $deleted
}

proc run_collection_cycle {} {
    log_info [string repeat "=" 60]
    log_info "LOG COLLECTOR CYCLE START"
    log_info [string repeat "=" 60]
    
    connect_db
    
    # 1. Nodes holen
    set nodes [get_nodes]
    log_info "Gefunden: [llength $nodes] Nodes"
    
    # 2. Collection-Run starten
    global conn
    conn eval {
        INSERT INTO collection_runs (started_at, nodes_total)
        VALUES (CURRENT_TIMESTAMP, $nodes_total)
    } "" [list nodes_total [llength $nodes]]
    set run_id [conn last_insert_rowid]
    
    # 3. Für jeden Node sammeln
    set success_count 0
    set failed_count 0
    set total_logs 0
    
    foreach node $nodes {
        array set node_array $node
        set node_id $node_array(node_id)
        
        if {$node_id eq "node1"} {
            # Lokale Logs (Gateway selbst)
            log_info "node1: Lokale Collection (Gateway)"
            incr success_count
        } else {
            # Remote-Node abfragen
            if {[catch {ssh_connect_and_collect $node} result]} {
                incr failed_count
                log_error "$node_id: Fehler bei Collection: $result"
            } else {
                incr success_count
                incr total_logs $result
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
    log_info "Retention-Cleanup (30 Tage)..."
    cleanup_retention
    
    log_info [string repeat "=" 60]
    log_info "SUMMARY: $success_count OK, $failed_count Failed, $total_logs Logs"
    log_info [string repeat "=" 60]
}

proc main {} {
    global logger_fd
    set logger_fd [open [init_logger] a]
    
    puts [string repeat "=" 60]
    puts "LOG COLLECTOR"
    puts [string repeat "=" 60]
    
    if {[catch {run_collection_cycle} error]} {
        puts "CRITICAL ERROR: $error"
        puts $::errorInfo
        exit 1
    }
    
    close $logger_fd
    unset logger_fd
}

# Start the program
main
