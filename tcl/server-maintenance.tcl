#!/usr/bin/tclsh
# server-maintenance.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/server-maintenance.sh
# auch in: OpenClaw@gateway2:scripts/server-maintenance.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Server Maintenance Script
# RAM: 8GB, Uhr: Europe/Berlin

set LOG_FILE "/var/log/server-maintenance.log"
set DATE [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
set HOST [exec hostname]

# Farben für Terminal
set RED "\033\[0;31m"
set GREEN "\033\[0;32m"
set YELLOW "\033\[1;33m"
set NC "\033\[0m"

proc log_message {message} {
    global LOG_FILE DATE
    set msg "\[$DATE\] $message"
    puts $msg
    exec tee -a $LOG_FILE << $msg
}

log_message "=== Server Maintenance Check ==="

# 1. APT Update Check
log_message "Checking for updates..."
set apt_update [exec apt update -qq 2>@1 | tail -5]
puts $apt_update
exec tee -a $::LOG_FILE << $apt_update
set UPDATES [llength [split [exec apt list --upgradable 2>/dev/null] "\n"]]
if {$UPDATES > 1} {
    log_message "⚠️ $UPDATES packages can be upgraded"
}

# 2. RAM Check (8GB total)
log_message "Checking RAM usage..."
set RAM_TOTAL 8192  ;# 8GB in MB
set free_output [exec free -m]
set lines [split $free_output "\n"]
set mem_line [lindex $lines 1]
set RAM_USED [lindex [split $mem_line] 2]
set RAM_PERCENT [expr {$RAM_USED * 100 / $RAM_TOTAL}]
log_message "RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)"
if {$RAM_PERCENT > 90} {
    log_message "🔴 WARNING: RAM usage > 90%!"
} elseif {$RAM_PERCENT > 80} {
    log_message "🟡 WARNING: RAM usage > 80%"
}

# 3. Disk Space Check
log_message "Checking disk space..."
set df_output [exec df -h /]
set disk_line [lindex [split $df_output "\n"] end]
set disk_fields [split $disk_line]
set used [lindex $disk_fields 2]
set total [lindex $disk_fields 1]
set percent [lindex $disk_fields 4]
log_message "Disk: $used / $total ($percent used)"
set DISK_PERCENT [string trim $percent "%"]
if {$DISK_PERCENT > 90} {
    log_message "🔴 WARNING: Disk > 90%!"
} elseif {$DISK_PERCENT > 80} {
    log_message "🟡 WARNING: Disk > 80%"
}

# 4. NTP Check
log_message "Checking NTP sync..."
set timedatectl_output [exec timedatectl status]
if {[string match "*NTP synchronized: yes*" $timedatectl_output]} {
    log_message "✅ NTP synchronized"
} else {
    log_message "⚠️ NTP not synchronized"
}

# 5. OpenClaw Gateway Status
log_message "Checking OpenClaw Gateway..."
if {[catch {exec systemctl is-active --quiet openclaw-gateway} result]} {
    log_message "🔴 OpenClaw Gateway NOT running!"
    if {[catch {exec systemctl restart openclaw-gateway} restart_result]} {
        log_message "Failed to restart OpenClaw Gateway: $restart_result"
    }
} else {
    log_message "✅ OpenClaw Gateway running"
}

# 6. Load Average
set uptime_output [exec uptime]
set load_avg_field [lindex [split $uptime_output] end]
set LOAD [string trim $load_avg_field ","]
log_message "Load Average: $LOAD"

log_message "=== Maintenance Complete ==="
log_message ""
