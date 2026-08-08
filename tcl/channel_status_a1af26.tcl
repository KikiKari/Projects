#!/usr/bin/env tclsh8.6
# channel_status.ps1 — portiert nach tcl
# Quelle: powershell, Projects@abstractions:powershell/channel_status.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
set WORKSPACE [file join $env(HOME) ".openclaw" "workspace"]
set LOGS_DB [file join $WORKSPACE "db" "logs.db"]
set CONFIG_FILE [file join $WORKSPACE "config" "channel-status.json"]
set LOG_FILE [file join $WORKSPACE "logs" "channel-status.log"]

proc write_log {message {level "INFO"}} {
    set timestamp [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}]
    set entry "\[$timestamp\] \[$level\] $message"
    puts $entry
    set fh [open $::LOG_FILE a]
    puts $fh $entry
    close $fh
}

proc get_system_status {} {
    set status [dict create \
        timestamp [clock format [clock seconds] -format {%Y-%m-%dT%H:%M:%S}] \
        nodes [dict create] \
        agents [dict create] \
        system [dict create] \
    ]

    # Node-Status (vereinfacht)
    set nodes [dict create \
        node1 [dict create name "Gateway" status "online"] \
        node2 [dict create name "Worker" status "online"] \
        node3 [dict create name "Relay" status "offline" reason "disk full"] \
        node5 [dict create name "Redmi" status "intermittent"] \
        node7 [dict create name "Docker" status "planned"] \
    ]
    dict set status nodes $nodes

    # Agent-Status aus Cron
    if {[catch {exec crontab -l} cron_result]} {
        dict set status agents active_crons "unknown"
    } else {
        set count 0
        foreach line [split $cron_result \n] {
            if {![regexp {^#} $line]} {
                incr count
            }
        }
        dict set status agents active_crons $count
    }

    # System-Metriken
    if {![catch {exec df -h /} df_output]} {
        foreach line [split $df_output \n] {
            if {[regexp {/.*%} $line]} {
                set parts [regexp -all -inline {\S+} $line]
                dict set status system disk_used [lindex $parts 4]
                break
            }
        }
    }

    if {![catch {exec free -h} free_output]} {
        foreach line [split $free_output \n] {
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
    set online_count 0
    dict for {key node} $nodes {
        if {[dict get $node status] eq "online"} {
            incr online_count
        }
    }

    set message "📊 **Täglicher Status-Report**\n"
    append message "🗓️ [clock format [clock seconds] -format {%Y-%m-%d %H:%M}]\n\n"
    append message "**🖥️ Nodes ($online_count/5 online):**\n"

    dict for {key node} $nodes {
        set emoji "🟡"
        switch [dict get $node status] {
            "online" { set emoji "🟢" }
            "offline" { set emoji "🔴" }
        }
        append message "$emoji [dict get $node name]: [dict get $node status]"
        if {[dict exists $node reason]} {
            append message " ([dict get $node reason])"
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
    append message "📅 Woche [clock format [clock seconds] -format {%Y-\\K\\W}] - [clock format [clock seconds] -format {%Y}]\n\n"
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
        set cmd [list openclaw message send --target $channel_id --message $message]
    } else {
        write_log "Channel type $channel_type not implemented" "WARN"
        return false
    }

    if {[catch {exec {*}$cmd} result]} {
        write_log "Failed to send: $result" "ERROR"
        return false
    } else {
        write_log "Message sent to $channel_type $channel_id"
        return true
    }
}

proc main {type {message ""} {channel "-1002381931352"} {dry_run false}} {
    write_log "Starting $type status update"

    # Status sammeln
    set status [get_system_status]

    # Message formatieren
    set formatted_message ""
    switch $type {
        "daily" { set formatted_message [format_daily_status $status] }
        "weekly" { set formatted_message [format_weekly_status $status] }
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

    write_log "Status update completed"
}

# Hauptprogramm
# Erstelle Log-Verzeichnis falls nicht vorhanden
set logfile_dir [file dirname $LOG_FILE]
if {![file exists $logfile_dir]} {
    file mkdir $logfile_dir
}

# Parameter parsen
set param_type ""
set param_message ""
set param_channel "-1002381931352"
set dry_run false

for {set i 0} {$i < $argc} {incr i} {
    set arg [lindex $argv $i]
    switch $arg {
        "--type" { 
            incr i
            set param_type [lindex $argv $i]
        }
        "--message" { 
            incr i
            set param_message [lindex $argv $i]
        }
        "--channel" { 
            incr i
            set param_channel [lindex $argv $i]
        }
        "--dry-run" { 
            set dry_run true
        }
    }
}

if {$param_type eq ""} {
    puts stderr "Parameter --type ist erforderlich"
    exit 1
}

main $param_type $param_message $param_channel $dry_run
