#!/usr/bin/env tclsh8.6
# node_health.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

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
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    
    global LOG_FILE
    set log_dir [file dirname $LOG_FILE]
    if {![file exists $log_dir]} {
        file mkdir $log_dir
    }
    
    if {[catch {open $LOG_FILE a} fd]} {
        puts "Failed to open log file: $fd"
        return
    }
    puts $fd $entry
    close $fd
}

proc check_ping {host {timeout 5}} {
    # Prüft Erreichbarkeit
    if {[catch {exec ping -c 1 -W $timeout $host} result]} {
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
    
    set cmd [list ssh -o ConnectTimeout=10 -o BatchMode=yes "$user@$host" "echo OK"]
    
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
    
    set metrics [dict create \
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"] \
        available false \
        cpu {} \
        ram {} \
        disk {} \
        load {} \
    ]
    
    # SSH-Command für alle Metriken
    set cmd "ssh -o ConnectTimeout=10 $user@$host '
        # CPU
        echo \"CPU:\$(top -bn1 | grep \"Cpu(s)\" | awk \"{print \\\$2}\" | cut -d\"%\" -f1)\"
        
        # RAM
        echo \"RAM:\$(free | grep Mem | awk \"{print (\\\$3/\\\$2) * 100.0}\")\"
        
        # Disk
        echo \"DISK:\$(df -h / | tail -1 | awk \"{print \\\$5}\" | tr -d \"%\")\"
        
        # Load
        echo \"LOAD:\$(uptime | awk -F\"load average:\" \"{print \\\$2}\" | awk \"{print \\\$1}\" | tr -d \",\")\"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo \"GATEWAY:inactive\"
        fi
    '"
    
    if {[catch {exec /bin/sh -c $cmd} result]} {
        log "Error checking node: $result" "ERROR"
        return $metrics
    }
    
    dict set metrics available true
    
    foreach line [split $result "\n"] {
        if {[string first ":" $line] != -1} {
            set parts [split $line ":"]
            set key [lindex $parts 0]
            set value [lindex $parts 1]
            
            switch $key {
                "CPU" {
                    if {$value ne ""} {
                        dict set metrics cpu [expr {double($value)}]
                    }
                }
                "RAM" {
                    if {$value ne ""} {
                        dict set metrics ram [expr {double($value)}]
                    }
                }
                "DISK" {
                    if {$value ne ""} {
                        dict set metrics disk [expr {int($value)}]
                    }
                }
                "LOAD" {
                    if {$value ne ""} {
                        dict set metrics load [expr {double($value)}]
                    }
                }
                "GATEWAY" {
                    dict set metrics gateway_status $value
                }
            }
        }
    }
    
    return $metrics
}

proc check_alerts {node_id node_config metrics} {
    # Prüft Schwellwerte und generiert Alerts
    array set config $node_config
    set alerts [list]
    
    # Verfügbarkeit
    if {![dict get $metrics available]} {
        if {![info exists config(optional)] || !$config(optional)} {
            lappend alerts [list level "CRITICAL" message "Node $config(name) nicht erreichbar!"]
        }
    } else {
        # CPU
        set cpu [dict get $metrics cpu]
        if {$cpu ne "" && $cpu > 90} {
            lappend alerts [list level "WARNING" message "Node $config(name): CPU bei $cpu%"]
        }
        
        # RAM
        set ram [dict get $metrics ram]
        if {$ram ne "" && $ram > 90} {
            lappend alerts [list level "WARNING" message "Node $config(name): RAM bei $ram%"]
        }
        
        # Disk
        set disk_threshold [expr {[info exists config(disk_warning)] ? $config(disk_warning) : 85}]
        set disk [dict get $metrics disk]
        if {$disk ne "" && $disk > $disk_threshold} {
            set level [expr {$disk > 95 ? "CRITICAL" : "WARNING"}]
            lappend alerts [list level $level message "Node $config(name): Disk bei $disk%"]
        }
        
        # Gateway
        if {[info exists config(critical)] && $config(critical)} {
            set gateway_status [dict get $metrics gateway_status]
            if {$gateway_status eq "inactive"} {
                lappend alerts [list level "CRITICAL" message "Node $config(name): OpenClaw Gateway nicht aktiv!"]
            }
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
    
    if {[catch {exec {*}$cmd}]} {
        log "Failed to send alert: $alert_data(message)" "ERROR"
    } else {
        log "Alert sent: $alert_data(message)"
    }
}

proc main {} {
    # Hauptfunktion
    global argv NODES WORKSPACE
    
    # Default-Werte für Argumente
    set node "all"
    set check "all"
    set alert 0
    
    # Argumente parsen
    for {set i 0} {$i < [llength $argv]} {incr i} {
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
        }
    }
    
    # Nodes bestimmen
    if {$node eq "all"} {
        set nodes_to_check [array get NODES]
    } else {
        if {[array names NODES $node] eq ""} {
            log "Unknown node: $node" "ERROR"
            exit 1
        }
        set nodes_to_check [list $node [array get NODES $node]]
    }
    
    # Health-Checks durchführen
    set all_alerts [list]
    
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
            
            if {[dict get $metrics available]} {
                set cpu [dict get $metrics cpu]
                set ram [dict get $metrics ram]
                set disk [dict get $metrics disk]
                set load [dict get $metrics load]
                
                log "  CPU: [expr {$cpu ne "" ? format "%.1f%%" $cpu : "N/A"}]"
                log "  RAM: [expr {$ram ne "" ? format "%.1f%%" $ram : "N/A"}]"
                log "  Disk: [expr {$disk ne "" ? "$disk%" : "N/A"}]"
                log "  Load: [expr {$load ne "" ? $load : "N/A"}]"
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

# Skript ausführen
if {[info script] eq $argv0} {
    main
}
