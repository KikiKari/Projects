#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "d0be55c29379f541be1ad41c3683095f1bb76099602ae54e1aef46bcf50a20ef", "source_sha256": "8cb73cb9ea3a2ccee09205fcea5d8d2e1f29c369b21a3dfcf948b8029436a339", "target_language": "tcl"}
# node_health.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Node Health Monitor - Multi-Node Gesundheitsüberwachung

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set HEALTH_DB "$WORKSPACE/db/health.db"
set LOG_FILE "$WORKSPACE/logs/node-health.log"

# Node-Definitionen
array set NODES {
    node1 {name "Gateway" host "localhost" user "openclaw" critical true}
    node2 {name "Worker" host "100.92.155.34" user "root" ssh_key "~/.ssh/id_rsa"}
    node3 {name "Relay" host "185.242.xxx.xxx" user "root" disk_warning 85}
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

proc check_ping {host {timeout 5}} {
    # Prüft Erreichbarkeit
    if {[catch {exec ping -c 1 -W $timeout $host} result]} {
        return 0
    } else {
        return [expr {[lindex [split $result "\n"] end] eq "" ? 0 : 1}]
    }
}

proc check_ssh {node_config} {
    # Prüft SSH-Verbindung
    array set config $node_config
    set host $config(host)
    set user [expr {[info exists config(user)] ? $config(user) : "root"}]
    
    set cmd [list ssh -o ConnectTimeout=10 -o BatchMode=yes "$user@$host" echo "OK"]
    
    if {[catch {exec {*}$cmd} result]} {
        return 0
    } else {
        return [expr {"OK" in [split $result " "]}]
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
    
    set metrics(timestamp) [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    
    # SSH-Command für alle Metriken
    set cmd "ssh -o ConnectTimeout=10 $user@$host '
        # CPU
        echo \"CPU:\$(top -bn1 | grep \"Cpu(s)\" | awk \"{print \\\\\\$2}\" | cut -d\"%\" -f1)\"
        
        # RAM
        echo \"RAM:\$(free | grep Mem | awk \"{print (\\\\\$3/\\\\\$2) * 100.0}\")\"
        
        # Disk
        echo \"DISK:\$(df -h / | tail -1 | awk \"{print \\\\\\$5}\" | tr -d \"%\")\"
        
        # Load
        echo \"LOAD:\$(uptime | awk -F\"load average:\" \"{print \\\\\\$2}\" | awk \"{print \\\\\\$1}\" | tr -d \",\")\"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo \"GATEWAY:inactive\"
        fi
    '"
    
    if {[catch {exec /bin/sh -c $cmd} result]} {
        log "Error checking metrics: $result" ERROR
        return [array get metrics]
    } else {
        set metrics(available) true
        
        foreach line [split $result "\n"] {
            if {[string first ":" $line] != -1} {
                lassign [split $line ":"] key value
                switch $key {
                    "CPU" {
                        if {$value ne ""} {set metrics(cpu) [expr double($value)]}
                    }
                    "RAM" {
                        if {$value ne ""} {set metrics(ram) [expr double($value)]}
                    }
                    "DISK" {
                        if {$value ne ""} {set metrics(disk) [expr int($value)]}
                    }
                    "LOAD" {
                        if {$value ne ""} {set metrics(load) [expr double($value)]}
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
            lappend alerts [list level CRITICAL message "Node $config(name) nicht erreichbar!"]
        }
    } else {
        # CPU
        if {$metric_data(cpu) ne "" && $metric_data(cpu) > 90} {
            lappend alerts [list level WARNING message "Node $config(name): CPU bei $metric_data(cpu)%"]
        }
        
        # RAM
        if {$metric_data(ram) ne "" && $metric_data(ram) > 90} {
            lappend alerts [list level WARNING message "Node $config(name): RAM bei $metric_data(ram)%"]
        }
        
        # Disk
        set disk_warning [expr {[info exists config(disk_warning)] ? $config(disk_warning) : 85}]
        if {$metric_data(disk) ne "" && $metric_data(disk) > $disk_warning} {
            set level [expr {$metric_data(disk) > 95 ? "CRITICAL" : "WARNING"}]
            lappend alerts [list level $level message "Node $config(name): Disk bei $metric_data(disk)%"]
        }
        
        # Gateway
        set critical [expr {[info exists config(critical)] ? $config(critical) : false}]
        if {$critical && [info exists metric_data(gateway_status)] && $metric_data(gateway_status) eq "inactive"} {
            lappend alerts [list level CRITICAL message "Node $config(name): OpenClaw Gateway nicht aktiv!"]
        }
    }
    
    return $alerts
}

proc send_alert {alert} {
    # Sendet Alert via channel-status-agent
    global WORKSPACE
    array set alert_data $alert
    
    set cmd [list python3 "$WORKSPACE/skills/channel-status-agent/scripts/channel_status.py" \
             --type alert \
             --message "$alert_data(level): $alert_data(message)"]
    
    if {[catch {exec {*}$cmd} result]} {
        log "Failed to send alert: $result" ERROR
    } else {
        log "Alert sent: $alert_data(message)"
    }
}

proc main {} {
    global argv argc NODES WORKSPACE
    
    # Argumente parsen
    set node "all"
    set check "all"
    set alert 0
    
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
                    puts stderr "Unbekanntes Argument: $arg"
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
            log "Unknown node: $node" ERROR
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
                log "  CPU: [expr {$metric_data(cpu) ne "" ? format "%.1f%%" $metric_data(cpu) : "N/A"}]"
                log "  RAM: [expr {$metric_data(ram) ne "" ? format "%.1f%%" $metric_data(ram) : "N/A"}]"
                log "  Disk: [expr {$metric_data(disk) ne "" ? format "%d%%" $metric_data(disk) : "N/A"}]"
                log "  Load: [expr {$metric_data(load) ne "" ? $metric_data(load) : "N/A"}]"
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

if {[info script] eq $argv0} {
    main
}
