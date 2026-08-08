#!/usr/bin/env tclsh8.6
# channel_status.js — portiert nach tcl
# Quelle: javascript, Projects@abstractions:javascript/channel_status.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# channel_status.py — portiert nach javascript
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

package require Tcl 8.6
package require json

# Konfiguration
set WORKSPACE [file join $env(HOME) .openclaw workspace]
set LOGS_DB [file join $WORKSPACE db logs.db]
set CONFIG_FILE [file join $WORKSPACE config channel-status.json]
set LOG_FILE [file join $WORKSPACE logs channel-status.log]

proc log {message {level "INFO"}} {
    # Logging
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set entry "\[[string range $timestamp 0 18]\] \[$level\] $message"
    puts $entry
    set fh [open $::LOG_FILE a]
    puts $fh $entry
    close $fh
}

proc getSystemStatus {} {
    # Sammelt System-Status
    array set status [list \
        timestamp [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ" -gmt 1] \
        nodes {} \
        agents {} \
        system {} \
    ]
    
    # Node-Status (vereinfacht)
    set nodes(node1) [dict create name Gateway status online]
    set nodes(node2) [dict create name Worker status online]
    set nodes(node3) [dict create name Relay status offline reason "disk full"]
    set nodes(node5) [dict create name Redmi status intermittent]
    set nodes(node7) [dict create name Docker status planned]
    set status(nodes) [array get nodes]
    
    # Agent-Status aus Cron
    if {[catch {exec crontab -l} result]} {
        set status(agents,active_crons) "unknown"
    } else {
        set lines [split $result \n]
        set count 0
        foreach line $lines {
            if {$line ne "" && ![string match "#*" $line]} {
                incr count
            }
        }
        set status(agents,active_crons) $count
    }
    
    # System-Metriken
    if {![catch {exec df -h /} df_result]} {
        set df_lines [split $df_result \n]
        foreach line $df_lines {
            if {[string first "/" $line] != -1 && [string first "%" $line] != -1} {
                set parts [regexp -all -inline {\S+} $line]
                set status(system,disk_used) [lindex $parts 4]
                break
            }
        }
    }
    
    if {![catch {exec free -h} free_result]} {
        set free_lines [split $free_result \n]
        foreach line $free_lines {
            if {[string first "Mem:" $line] != -1} {
                set parts [regexp -all -inline {\S+} $line]
                set status(system,ram_total) [lindex $parts 1]
                set status(system,ram_used) [lindex $parts 2]
                break
            }
        }
    }
    
    return [array get status]
}

proc formatDailyStatus {status_array} {
    # Formatiert täglichen Status
    array set status $status_array
    array set nodes $status(nodes)
    
    set online_count 0
    dict for {key value} $status(nodes) {
        if {[dict get $value status] eq "online"} {
            incr online_count
        }
    }
    
    set timestamp [clock format [clock seconds] -format "%d.%m.%Y %H:%M"]
    set message "📊 **Täglicher Status-Report**
🗓️ $timestamp

**🖥️ Nodes ($online_count/5 online):**
"
    
    dict for {node_id info} $status(nodes) {
        set status_val [dict get $info status]
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
    append message "Aktive Cron-Jobs: $status(agents,active_crons)\n"
    
    if {[info exists status(system,disk_used)]} {
        append message "\n**💾 System:**\n"
        append message "Disk: $status(system,disk_used) belegt\n"
        append message "RAM: $status(system,ram_used) / $status(system,ram_total)\n"
    }
    
    return $message
}

proc formatWeeklyStatus {status_array} {
    # Formatiert wöchentlichen Status
    set now [clock seconds]
    set year [clock format $now -format "%Y"]
    set start_of_year [clock scan "01/01/$year"]
    set days_since_start [expr {int(($now - $start_of_year) / 86400)}]
    set week_number [expr {int((($days_since_start + [clock format $start_of_year -format "%u"]) / 7) + 1)}]
    
    return "📈 **Wöchentlicher Report**
📅 Woche [format %02d $week_number] - $year

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
"
}

proc sendToChannel {message {channelType "telegram"} {channelId "-1002381931352"}} {
    # Sendet Nachricht an Channel
    set cmd ""
    if {$channelType eq "telegram"} {
        # Nutze OpenClaw message tool
        regsub -all "\"" $message "\\\"" escaped_message
        set cmd "openclaw message send --target $channelId --message \"$escaped_message\""
    } else {
        log "Channel type $channelType not implemented" "WARN"
        return 0
    }
    
    if {[catch {exec {*}$cmd} result]} {
        log "Failed to send: $result" "ERROR"
        return 0
    } else {
        log "Message sent to $channelType $channelId"
        return 1
    }
}

proc print_usage {} {
    puts "Usage: [info script] --type daily|weekly|alert \[options\]"
    puts "Options:"
    puts "  --type TYPE       Type of status update (daily|weekly|alert)"
    puts "  --message MSG     Alert message"
    puts "  --channel ID      Channel ID (default: -1002381931352)"
    puts "  --dry-run         Show message without sending"
    puts "  --help            Show this help"
}

proc main {argv} {
    # Hauptfunktion
    set options(type) ""
    set options(message) ""
    set options(channel) "-1002381931352"
    set options(dry_run) 0
    
    # Argument parsing
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        
        switch -exact -- $arg {
            "--type" {
                if {$i < [llength $argv]} {
                    set options(type) [lindex $argv $i]
                    incr i
                }
            }
            "--message" {
                if {$i < [llength $argv]} {
                    set options(message) [lindex $argv $i]
                    incr i
                }
            }
            "--channel" {
                if {$i < [llength $argv]} {
                    set options(channel) [lindex $argv $i]
                    incr i
                }
            }
            "--dry-run" {
                set options(dry_run) 1
            }
            "--help" {
                print_usage
                exit 0
            }
            default {
                if {[string match "--*" $arg]} {
                    puts stderr "Unknown option: $arg"
                    print_usage
                    exit 1
                }
            }
        }
    }
    
    # Validate required arguments
    if {$options(type) eq ""} {
        puts stderr "Error: --type is required"
        print_usage
        exit 1
    }
    
    if {$options(type) ni {"daily" "weekly" "alert"}} {
        puts stderr "Error: --type must be one of: daily, weekly, alert"
        print_usage
        exit 1
    }
    
    log "Starting $options(type) status update"
    
    # Status sammeln
    set status [getSystemStatus]
    
    # Message formatieren
    set message ""
    switch $options(type) {
        "daily" {
            set message [formatDailyStatus $status]
        }
        "weekly" {
            set message [formatWeeklyStatus $status]
        }
        "alert" {
            set msg_text "Manual alert"
            if {$options(message) ne ""} {
                set msg_text $options(message)
            }
            set message "🚨 **ALERT**\n$msg_text"
        }
    }
    
    # Senden oder Dry-Run
    if {$options(dry_run)} {
        puts "\n--- DRY RUN ---"
        puts $message
        puts "--- END ---"
    } else {
        sendToChannel $message "telegram" $options(channel)
    }
    
    log "Status update completed"
}

# Ensure log directory exists
set log_dir [file dirname $LOG_FILE]
if {![file exists $log_dir]} {
    file mkdir $log_dir
}

# Run main with command line arguments
main $argv
