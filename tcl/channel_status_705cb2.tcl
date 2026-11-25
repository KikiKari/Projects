#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "a8f70d78feb1009b970a6c325340d7f6a5a501c66290d11755f15a2b93d42fb8", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "tcl"}
# channel_status.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#
# Channel Status Agent - Automatische Status-Updates
#

package require json
package require sqlite3

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set LOGS_DB [file join $WORKSPACE "db" "logs.db"]
set CONFIG_FILE [file join $WORKSPACE "config" "channel-status.json"]
set LOG_FILE [file join $WORKSPACE "logs" "channel-status.log"]

proc log {message {level "INFO"}} {
    # Logging
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    set f [open $::LOG_FILE a]
    puts $f $entry
    close $f
}

proc get_system_status {} {
    # Sammelt System-Status
    set status [dict create]
    dict set status "timestamp" [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    dict set status "nodes" [dict create]
    dict set status "agents" [dict create]
    dict set status "system" [dict create]
    
    # Node-Status (vereinfacht)
    set nodes [dict create]
    dict set nodes "node1" [dict create "name" "Gateway" "status" "online"]
    dict set nodes "node2" [dict create "name" "Worker" "status" "online"]
    dict set nodes "node3" [dict create "name" "Relay" "status" "offline" "reason" "disk full"]
    dict set nodes "node5" [dict create "name" "Redmi" "status" "intermittent"]
    dict set nodes "node7" [dict create "name" "Docker" "status" "planned"]
    dict set status "nodes" $nodes
    
    # Agent-Status aus Cron
    if {[catch {exec crontab -l} result]} {
        dict set status "agents" "active_crons" "unknown"
    } else {
        set cron_lines [llength [split $result "\n"]]
        set comment_lines 0
        foreach line [split $result "\n"] {
            if {[string match "#*" $line]} {
                incr comment_lines
            }
        }
        dict set status "agents" "active_crons" [expr {$cron_lines - $comment_lines}]
    }
    
    # System-Metriken
    if {![catch {exec df -h "/"} df_result]} {
        foreach line [split $df_result "\n"] {
            if {[string match "*%*" $line] && [string match "*/ *" $line]} {
                set parts [split $line]
                dict set status "system" "disk_used" [lindex $parts 4]
                break
            }
        }
    }
    
    if {![catch {exec free -h} free_result]} {
        foreach line [split $free_result "\n"] {
            if {[string match "Mem:*" $line]} {
                set parts [split $line]
                dict set status "system" "ram_total" [lindex $parts 1]
                dict set status "system" "ram_used" [lindex $parts 2]
                break
            }
        }
    }
    
    return $status
}

proc format_daily_status {status} {
    # Formatiert täglichen Status
    set nodes [dict get $status "nodes"]
    set online_count 0
    dict for {node_id info} $nodes {
        if {[dict get $info "status"] eq "online"} {
            incr online_count
        }
    }
    
    set message "📊 **Täglicher Status-Report**\n"
    append message "🗓️ [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]\n\n"
    append message "**🖥️ Nodes ($online_count/5 online):**\n"
    
    dict for {node_id info} $nodes {
        set emoji "🟡"
        set node_status [dict get $info "status"]
        if {$node_status eq "online"} {
            set emoji "🟢"
        } elseif {$node_status eq "offline"} {
            set emoji "🔴"
        }
        append message "$emoji [dict get $info "name"]: $node_status"
        if {[dict exists $info "reason"]} {
            append message " ([dict get $info "reason"])"
        }
        append message "\n"
    }
    
    append message "\n**🤖 Agents:**\n"
    append message "Aktive Cron-Jobs: [dict get $status "agents" "active_crons"]\n"
    
    if {[dict exists $status "system" "disk_used"]} {
        append message "\n**💾 System:**\n"
        append message "Disk: [dict get $status "system" "disk_used"] belegt\n"
        append message "RAM: [dict get $status "system" "ram_used"] / [dict get $status "system" "ram_total"]\n"
    }
    
    return $message
}

proc format_weekly_status {status} {
    # Formatiert wöchentlichen Status
    set message "📈 **Wöchentlicher Report**\n"
    append message "📅 Woche [clock format [clock seconds] -format "%V"] - [clock format [clock seconds] -format "%Y"]\n\n"
    append message "**Zusammenfassung:**\n"
    append message "- 5 aktive Sub-Agents\n"
    append message "- 11 Skills synchronisiert\n"
    append message "- 3 neue Features implementiert\n\n"
    append message "**Top-Ereignisse:**\n"
    append message "1. ClawHub-Git Sync implementiert ✅\n"
    append message "2. Node 3 Disk voll (95%) ⚠️\n"
    append message "3. Channel-Status-Agent aktiviert 🆕\n\n"
    append message "**Geplante Wartungen:**\n"
    append message "- Node 3: Disk-Cleanup erforderlich\n"
    append message "- Node 7: Docker-Setup ausstehend\n"
    return $message
}

proc send_to_channel {message {channel_type "telegram"} {channel_id "-1002381931352"}} {
    # Sendet Nachricht an Channel
    if {$channel_type eq "telegram"} {
        # Nutze OpenClaw message tool
        set cmd [list openclaw message send --target $channel_id --message $message]
    } else {
        log "Channel type $channel_type not implemented" "WARN"
        return 0
    }
    
    if {[catch {exec {*}$cmd} result]} {
        log "Send error: $result" "ERROR"
        return 0
    } else {
        log "Message sent to $channel_type $channel_id"
        return 1
    }
}

proc main {argv} {
    # Hauptfunktion
    set options [dict create]
    dict set options "type" ""
    dict set options "message" ""
    dict set options "channel" "-1002381931352"
    dict set options "dry-run" 0
    
    # Simple argument parsing
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        if {$arg eq "--type"} {
            dict set options "type" [lindex $argv [expr {$i+1}]]
            incr i
        } elseif {$arg eq "--message"} {
            dict set options "message" [lindex $argv [expr {$i+1}]]
            incr i
        } elseif {$arg eq "--channel"} {
            dict set options "channel" [lindex $argv [expr {$i+1}]]
            incr i
        } elseif {$arg eq "--dry-run"} {
            dict set options "dry-run" 1
        }
        incr i
    }
    
    if {[dict get $options "type"] eq ""} {
        puts "Error: --type is required"
        exit 1
    }
    
    log "Starting [dict get $options "type"] status update"
    
    # Status sammeln
    set status [get_system_status]
    
    # Message formatieren
    set message ""
    switch [dict get $options "type"] {
        "daily" {
            set message [format_daily_status $status]
        }
        "weekly" {
            set message [format_weekly_status $status]
        }
        "alert" {
            set alert_msg [dict get $options "message"]
            if {$alert_msg eq ""} {
                set alert_msg "Manual alert"
            }
            set message "🚨 **ALERT**\n$alert_msg"
        }
    }
    
    # Senden oder Dry-Run
    if {[dict get $options "dry-run"]} {
        puts "\n--- DRY RUN ---"
        puts $message
        puts "--- END ---"
    } else {
        send_to_channel $message "telegram" [dict get $options "channel"]
    }
    
    log "Status update completed"
}

# Create log directory if needed
set log_dir [file dirname $LOG_FILE]
if {![file exists $log_dir]} {
    file mkdir $log_dir
}

# Run main function
main $argv
