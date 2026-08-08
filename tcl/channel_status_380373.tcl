#!/usr/bin/env tclsh
# channel_status.pl — portiert nach tcl
# Quelle: perl5, Projects@abstractions:perl5/channel_status.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set LOGS_DB "$WORKSPACE/db/logs.db"
set CONFIG_FILE "$WORKSPACE/config/channel-status.json"
set LOG_FILE "$WORKSPACE/logs/channel-status.log"

proc log_message {message {level "INFO"}} {
    global LOG_FILE
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[$timestamp\] \[$level\] $message\n"
    puts -nonewline $entry
    set fh [open $LOG_FILE a]
    puts -nonewline $fh $entry
    close $fh
}

proc get_system_status {} {
    set status [dict create]
    dict set status timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
    dict set status nodes [dict create]
    dict set status agents [dict create]
    dict set status system [dict create]
    
    # Node-Status (vereinfacht)
    set nodes [dict create]
    dict set nodes node1 [dict create name "Gateway" status "online"]
    dict set nodes node2 [dict create name "Worker" status "online"]
    dict set nodes node3 [dict create name "Relay" status "offline" reason "disk full"]
    dict set nodes node5 [dict create name "Redmi" status "intermittent"]
    dict set nodes node7 [dict create name "Docker" status "planned"]
    dict set status nodes $nodes
    
    # Agent-Status aus Cron
    if {[catch {exec crontab -l} stdout]} {
        dict set status agents active_crons "unknown"
    } else {
        set lines [split $stdout "\n"]
        set cron_lines 0
        foreach line $lines {
            if {![regexp {^\s*#} $line] && [string trim $line] ne ""} {
                incr cron_lines
            }
        }
        dict set status agents active_crons $cron_lines
    }
    
    # System-Metriken
    if {![catch {exec df -h /} stdout]} {
        foreach line [split $stdout "\n"] {
            if {[regexp {/} $line] && [regexp {%} $line]} {
                set parts [regexp -all -inline {\S+} $line]
                dict set status system disk_used [lindex $parts 4]
                break
            }
        }
    }
    
    if {![catch {exec free -h} stdout]} {
        foreach line [split $stdout "\n"] {
            if {[regexp {Mem:} $line]} {
                set parts [regexp -all -inline {\S+} $line]
                dict set status system ram_total [lindex $parts 1]
                dict set status system ram_used [lindex $parts 2]
                break
            }
        }
    }
    
    return $status
}

proc format_daily_status {status} {
    set nodes [dict get $status nodes]
    set online 0
    dict for {node_id info} $nodes {
        if {[dict get $info status] eq "online"} {
            incr online
        }
    }
    
    set message "📊 **Täglicher Status-Report**\n"
    append message "🗓️ [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]\n\n"
    append message "**🖥️ Nodes ($online/5 online):**\n"
    
    set sorted_nodes [lsort [dict keys $nodes]]
    foreach node_id $sorted_nodes {
        set info [dict get $nodes $node_id]
        set status_val [dict get $info status]
        set emoji ""
        switch $status_val {
            "online" { set emoji "🟢" }
            "offline" { set emoji "🔴" }
            default { set emoji "🟡" }
        }
        append message "$emoji [dict get $info name]: $status_val"
        if {[dict exists $info reason]} {
            append message " ([dict get $info reason])"
        }
        append message "\n"
    }
    
    append message "\n**🤖 Agents:**\n"
    append message "Aktive Cron-Jobs: [dict get $status agents active_crons]\n"
    
    if {[dict exists $status system disk_used]} {
        append message "\n**💾 System:**\n"
        append message "Disk: [dict get $status system disk_used] belegt\n"
        append message "RAM: [dict get $status system ram_used] / [dict get $status system ram_total]\n"
    }
    
    return $message
}

proc format_weekly_status {status} {
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
    if {$channel_type eq "telegram"} {
        # Nutze OpenClaw message tool
        if {[catch {exec openclaw message send --target $channel_id --message $message} stdout stderr]} {
            log_message "Failed to send: $stderr" "ERROR"
            return 0
        } else {
            log_message "Message sent to $channel_type $channel_id"
            return 1
        }
    } else {
        log_message "Channel type $channel_type not implemented" "WARN"
        return 0
    }
}

proc main {} {
    global LOG_FILE
    
    # Optionen parsen
    set type ""
    set message ""
    set channel "-1002381931352"
    set dry_run 0
    
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch $arg {
            "--type" {
                incr i
                set type [lindex $argv $i]
            }
            "--message" {
                incr i
                set message [lindex $argv $i]
            }
            "--channel" {
                incr i
                set channel [lindex $argv $i]
            }
            "--dry-run" {
                set dry_run 1
            }
            default {
                if {[string match "-*" $arg]} {
                    error "Invalid options"
                }
            }
        }
    }
    
    if {$type eq ""} {
        error "Type is required"
    }
    if {![string match {daily|weekly|alert} $type]} {
        error "Invalid type: $type"
    }
    
    log_message "Starting $type status update"
    
    # Status sammeln
    set status [get_system_status]
    
    # Message formatieren
    set formatted_message ""
    switch $type {
        "daily" {
            set formatted_message [format_daily_status $status]
        }
        "weekly" {
            set formatted_message [format_weekly_status $status]
        }
        "alert" {
            set formatted_message "🚨 **ALERT**\n"
            if {$message ne ""} {
                append formatted_message $message
            } else {
                append formatted_message "Manual alert"
            }
        }
    }
    
    # Senden oder Dry-Run
    if {$dry_run} {
        puts "\n--- DRY RUN ---"
        puts $formatted_message
        puts "--- END ---"
    } else {
        send_to_channel $formatted_message "telegram" $channel
    }
    
    log_message "Status update completed"
}

# Ensure log directory exists
set log_dir [file dirname $LOG_FILE]
if {![file exists $log_dir]} {
    file mkdir $log_dir
}

main
