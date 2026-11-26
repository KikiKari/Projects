#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "0fb0bf3a6baec0543fc9ea1591852828c00bcf38f86b23dff745fc067c511dcc", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "tcl"}
# node_health.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set HEALTH_DB "$WORKSPACE/db/health.db"
set LOG_FILE "$WORKSPACE/logs/node-health.log"

# Node-Definitionen
array set NODES {
    node1 {name "Node 1" host "localhost" user "openclaw" critical true}
    node2 {name "Node 2" host "10.10.0.2" user "root" ssh_key "~/.ssh/id_rsa" ssh_opts "-o ConnectTimeout=10 -o BatchMode=yes"}
    node3 {name "Node 3" host "localhost" user "root" port 18794 ssh_opts "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes" disk_warning 85}
    node5 {name "Redmi" host "192.168.1.x" user "openclaw" optional true}
}

proc log {message {level "INFO"}} {
    # Logging
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    
    global LOG_FILE
    set log_dir [file dirname $LOG_FILE]
    file mkdir $log_dir
    set f [open $LOG_FILE a]
    puts $f $entry
    close $f
}

proc check_ping {host {timeout 10}} {
    # Prüft Erreichbarkeit (Timeout seconds)
    if {[catch {exec ping -c 1 -W $timeout $host}]} {
        return 0
    } else {
        return 1
    }
}

proc check_ssh {node_config} {
    # Prüft SSH-Verbindung
    array set config $node_config
    set host $config(host)
    set user [expr {[info exists config(user)] ? $config(user) : "root"}]
    set ssh_opts [expr {[info exists config(ssh_opts)] ? $config(ssh_opts) : ""}]
    set port [expr {[info exists config(port)] ? $config(port) : ""}]
    
    set cmd "ssh"
    if {$ssh_opts ne ""} {
        append cmd " $ssh_opts"
    }
    if {$port ne ""} {
        append cmd " -p $port"
    }
    append cmd " -o ConnectTimeout=10 -o BatchMode=yes ${user}@${host} echo \"OK\""
    
    if {[catch {exec {*}$cmd} result]} {
        return 0
    } else {
        return [expr {[string match "*OK*" $result]}]
    }
}

proc get_node_metrics {node_config} {
    # Holt Metriken via SSH
    array set config $node_config
    set host $config(host)
    set user [expr {[info exists config(user)] ? $config(user) : "root"}]
    
    array set metrics {
        timestamp ""
        available false
        cpu ""
        ram ""
        disk ""
        load ""
    }
    set metrics(timestamp) [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}]
    
    # SSH-Command für alle Metriken
    set cmd "ssh -o ConnectTimeout=10 ${user}@${host} '
        # CPU
        echo \"CPU:\$(top -bn1 | grep \\\"Cpu(s)\\\" | awk \\\"{print \\\\\\$2}\\\" | cut -d\\\"%\\\" -f1)\"
        
        # RAM
        echo \"RAM:\$(free | grep Mem | awk \\\"{print (\\\\\$3/\\\\\$2) * 100.0}\\\")\"
        
        # Disk
        echo \"DISK:\$(df -h / | tail -1 | awk \\\"{print \\\\\$5}\\\" | tr -d \\\"%\\\")\"
        
        # Load
        echo \"LOAD:\$(uptime | awk -F\\\"load average:\\\" \\\"{print \\\\\$2}\\\" | awk \\\"{print \\\\\$1}\\\" | tr -d \\\",\\\")\"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo \"GATEWAY:inactive\"
        fi
    '"
    
    if {[catch {exec /bin/sh -c $cmd} result]} {
        log "Error checking node: $result" "ERROR"
        return [array get metrics]
    } else {
        set metrics(available) true
        foreach line [split $result "\n"] {
            if {[string first ":" $line] != -1} {
                lassign [split $line ":"] key value
                switch $key {
                    "CPU" {
                        if {$value ne ""} {
                            set metrics(cpu) [expr double($value)]
                        }
                    }
                    "RAM" {
                        if {$value ne ""} {
                            set metrics(ram) [expr double($value)]
                        }
                    }
                    "DISK" {
                        if {$value ne ""} {
                            set metrics(disk) [expr int($value)]
                        }
                    }
                    "LOAD" {
                        if {$value ne ""} {
                            set metrics(load) [expr double($value)]
                        }
                    }
                    "GATEWAY" {
                        set metrics(gateway_status) $value
                    }
                }
            }
        }
    }
    
    return [array get metrics]
}

proc check_alerts {node_id node_config metrics} {
    # Prüft Schwellwerte und generiert Alerts
    array set config $node_config
    array set metric_data $metrics
    set alerts {}
    
    # Verfügbarkeit
    if {!$metric_data(available)} {
        set optional [expr {[info exists config(optional)] ? $config(optional) : false}]
        if {!$optional} {
            lappend alerts [list level "CRITICAL" message "Node $config(name) nicht erreichbar!"]
        }
    } else {
        # CPU
        if {$metric_data(cpu) ne "" && $metric_data(cpu) > 90} {
            lappend alerts [list level "WARNING" message "Node $config(name): CPU bei $metric_data(cpu)%"]
        }
        
        # RAM
        if {$metric_data(ram) ne "" && $metric_data(ram) > 90} {
            lappend alerts [list level "WARNING" message "Node $config(name): RAM bei $metric_data(ram)%"]
        }
        
        # Disk
        set disk_threshold [expr {[info exists config(disk_warning)] ? $config(disk_warning) : 85}]
        if {$metric_data(disk) ne "" && $metric_data(disk) > $disk_threshold} {
            set level [expr {$metric_data(disk) > 95 ? "CRITICAL" : "WARNING"}]
            lappend alerts [list level $level message "Node $config(name): Disk bei $metric_data(disk)%"]
        }
        
        # Gateway
        set critical [expr {[info exists config(critical)] ? $config(critical) : false}]
        if {$critical && [info exists metric_data(gateway_status)] && $metric_data(gateway_status) eq "inactive"} {
            lappend alerts [list level "CRITICAL" message "Node $config(name): OpenClaw Gateway nicht aktiv!"]
        }
    }
    
    return $alerts
}

proc send_alert {alert} {
    # Sendet Alert via channel-status-agent
    global WORKSPACE
    array set alert_data $alert
    set cmd "python3 $WORKSPACE/skills/channel-status-agent/scripts/channel_status.py --type alert --message \"$alert_data(level): $alert_data(message)\""
    
    if {[catch {exec {*}$cmd}]} {
        log "Failed to send alert: $::errorInfo" "ERROR"
    } else {
        log "Alert sent: $alert_data(message)"
    }
}

proc main {} {
    # Hauptfunktion
    global argc argv NODES WORKSPACE
    
    # Default Werte
    set node "all"
    set check "all"
    set alert 0
    
    # Argumente parsen
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch $arg {
            "--node" {
                incr i
                set node [lindex $argv $i]
            }
            "--check" {
                incr i
                set check [lindex $argv $i]
            }
            "--alert" {
                set alert 1
            }
            default {
                if {[string match "-*" $arg]} {
                    puts "Unbekanntes Argument: $arg"
                    exit 1
                }
            }
        }
    }
    
    # Nodes bestimmen
    if {$node eq "all"} {
        set nodes_to_check [array get NODES]
    } else {
        if {[info exists NODES($node)]} {
            set nodes_to_check [list $node $NODES($node)]
        } else {
            log "Unknown node: $node" "ERROR"
            exit 1
        }
    }
    
    # Health-Checks durchführen
    set all_alerts {}
    
    foreach {node_id node_config} $nodes_to_check {
        array set config $node_config
        log "Checking $config(name) ($node_id)"
        
        # Ping
        if {$check in {ping all}} {
            if {$config(host) ne "localhost"} {
                set ping_ok [check_ping $config(host)]
                log "  Ping: [expr {$ping_ok ? "OK" : "FAILED"}]"
            }
        }
        
        # SSH
        if {$check in {ssh all}} {
            set ssh_ok [check_ssh $node_config]
            log "  SSH: [expr {$ssh_ok ? "OK" : "FAILED"}]"
        }
        
        # Metriken
        if {$check in {metrics all}} {
            set metrics [get_node_metrics $node_config]
            array set metric_data $metrics
            
            if {$metric_data(available)} {
                log [format "  CPU: %.1f%%" [expr {$metric_data(cpu) ne "" ? $metric_data(cpu) : "N/A"}]]
                log [format "  RAM: %.1f%%" [expr {$metric_data(ram) ne "" ? $metric_data(ram) : "N/A"}]]
                log [format "  Disk: %s%%" [expr {$metric_data(disk) ne "" ? $metric_data(disk) : "N/A"}]]
                log [format "  Load: %s" [expr {$metric_data(load) ne "" ? $metric_data(load) : "N/A"}]]
            } else {
                log "  Metrics: UNAVAILABLE"
            }
            
            # Alerts prüfen
            set alerts [check_alerts $node_id $node_config $metrics]
            set all_alerts [concat $all_alerts $alerts]
        }
    }
    
    # Alerts senden
    if {$alert && [llength $all_alerts] > 0} {
        log "\nSending [llength $all_alerts] alerts..."
        foreach alert $all_alerts {
            send_alert $alert
        }
    } elseif {[llength $all_alerts] > 0} {
        log "\n[llength $all_alerts] alerts found (use --alert to send)"
    } else {
        log "\nAll nodes healthy!"
    }
}

# Skript starten
if {[info script] eq $argv0} {
    main
}
