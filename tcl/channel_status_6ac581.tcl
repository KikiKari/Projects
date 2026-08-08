#!/usr/bin/env tclsh8.6
# channel_status.sh — portiert nach tcl
# Quelle: shell, Projects@abstractions:shell/channel_status.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set LOGS_DB "${WORKSPACE}/db/logs.db"
set CONFIG_FILE "${WORKSPACE}/config/channel-status.json"
set LOG_FILE "${WORKSPACE}/logs/channel-status.log"

# Logging
proc log {message {level INFO}} {
    global LOG_FILE
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[${timestamp}\] \[${level}\] ${message}"
    puts ${entry}
    set fh [open ${LOG_FILE} a]
    puts $fh ${entry}
    close $fh
}

# Sammelt System-Status
proc get_system_status {} {
    # Basis JSON Struktur
    set timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S%z"]
    set status_json [dict create \
        timestamp ${timestamp} \
        nodes [dict create \
            node1 [dict create name Gateway status online] \
            node2 [dict create name Worker status online] \
            node3 [dict create name Relay status offline reason "disk full"] \
            node5 [dict create name Redmi status intermittent] \
            node7 [dict create name Docker status planned] \
        ] \
        agents [dict create] \
        system [dict create] \
    ]
    
    # Agent-Status aus Cron
    if {[catch {exec crontab -l} cron_output]} {
        set cron_lines "unknown"
    } else {
        set cron_lines [llength [split $cron_output "\n"]]
    }
    dict set status_json agents active_crons ${cron_lines}
    
    # System-Metriken
    if {![catch {exec df -h /} df_output]} {
        set disk_line [lindex [split $df_output "\n"] 1]
        set disk_used [lindex [split $disk_line] 4]
        dict set status_json system disk_used ${disk_used}
    }
    
    if {![catch {exec free -h} free_output]} {
        set ram_line [lindex [split $free_output "\n"] 1]
        set ram_fields [split $ram_line]
        set ram_total [lindex $ram_fields 1]
        set ram_used [lindex $ram_fields 2]
        dict set status_json system ram_total ${ram_total}
        dict set status_json system ram_used ${ram_used}
    }
    
    return $status_json
}

# Formatiert täglichen Status
proc format_daily_status {status_json} {
    set message "📊 **Täglicher Status-Report**\n"
    append message [clock format [clock seconds] -format "🗓️ %Y-%m-%d %H:%M"]\n\n
    
    append message "**🖥️ Nodes (**"
    set online_count 0
    dict for {key node_data} [dict get $status_json nodes] {
        if {[dict get $node_data status] eq "online"} {
            incr online_count
        }
    }
    append message "${online_count}/5 online):\n"
    
    dict for {node_id node_data} [dict get $status_json nodes] {
        set name [dict get $node_data name]
        set status [dict get $node_data status]
        switch ${status} {
            "online" { set emoji "🟢" }
            "offline" { set emoji "🔴" }
            default { set emoji "🟡" }
        }
        append message "${emoji} ${name}: ${status}"
        if {[dict exists $node_data reason] && [dict get $node_data reason] ne ""} {
            set reason [dict get $node_data reason]
            if {$reason ne "null"} {
                append message " (${reason})"
            }
        }
        append message "\n"
    }
    
    append message "\n**🤖 Agents:**\n"
    set active_crons [dict get $status_json agents active_crons]
    append message "Aktive Cron-Jobs: ${active_crons}\n"
    
    if {[dict exists $status_json system disk_used]} {
        append message "\n**💾 System:**\n"
        set disk_used [dict get $status_json system disk_used]
        set ram_used [dict get $status_json system ram_used]
        set ram_total [dict get $status_json system ram_total]
        append message "Disk: ${disk_used} belegt\n"
        append message "RAM: ${ram_used} / ${ram_total}\n"
    }
    
    return $message
}

# Formatiert wöchentlichen Status
proc format_weekly_status {} {
    set message "📈 **Wöchentlicher Report**\n"
    append message [clock format [clock seconds] -format "📅 Woche %V - %Y"]\n\n
    
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

# Sendet Nachricht an Channel
proc send_to_channel {message {channel_type telegram} {channel_id -1002381931352}} {
    if {${channel_type} eq "telegram"} {
        set cmd [list openclaw message send --target ${channel_id} --message ${message}]
    } else {
        log "Channel type ${channel_type} not implemented" WARN
        return 1
    }
    
    if {[catch {exec {*}$cmd} result]} {
        log "Failed to send message" ERROR
        return 1
    } else {
        log "Message sent to ${channel_type} ${channel_id}"
        return 0
    }
}

# Hauptfunktion
proc main {argv} {
    global LOG_FILE WORKSPACE
    
    set type ""
    set message ""
    set channel "-1002381931352"
    set dry_run false
    
    # Argumente parsen
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -- $arg {
            --type {
                incr i
                set type [lindex $argv $i]
            }
            --message {
                incr i
                set message [lindex $argv $i]
            }
            --channel {
                incr i
                set channel [lindex $argv $i]
            }
            --dry-run {
                set dry_run true
            }
            default {
                puts stderr "Unbekannte Option: $arg"
                exit 1
            }
        }
    }
    
    if {${type} eq ""} {
        puts stderr "Fehler: --type ist erforderlich"
        exit 1
    }
    
    log "Starting ${type} status update"
    
    # Status sammeln
    set status [get_system_status]
    
    # Message formatieren
    set formatted_message ""
    switch -- ${type} {
        daily {
            set formatted_message [format_daily_status $status]
        }
        weekly {
            set formatted_message [format_weekly_status]
        }
        alert {
            if {${message} eq ""} {
                set formatted_message "🚨 **ALERT**\nManual alert"
            } else {
                set formatted_message "🚨 **ALERT**\n${message}"
            }
        }
        default {
            puts stderr "Unbekannter Typ: ${type}"
            exit 1
        }
    }
    
    # Senden oder Dry-Run
    if {${dry_run}} {
        puts ""
        puts "--- DRY RUN ---"
        puts -nonewline $formatted_message
        puts "--- END ---"
        puts ""
    } else {
        send_to_channel $formatted_message telegram $channel
    }
    
    log "Status update completed"
}

# Sicherstellen, dass das Log-Verzeichnis existiert
file mkdir [file dirname ${LOG_FILE}]

# Hauptfunktion aufrufen
main $argv
