#!/usr/bin/env tclsh8.6
# abstractions-publish-gateway-cron.sh — portiert nach tcl
# Quelle: shell, Projects@clawhub:clawhub/Scripts/abstractions-publish-gateway-cron.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Wrapper für Linux-crontab - setzt sauberes Environment
set env(HOME) "/home/openclaw"
set env(PATH) "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

set LOG_DIR "/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
file mkdir $LOG_DIR
set CRON_LOG "$LOG_DIR/linux-cron.log"

# Öffne Log-Datei im Anhang-Modus
set log_fd [open $CRON_LOG a]

# Führe Befehle aus und leite Ausgabe in Log-Datei
puts $log_fd ""
puts $log_fd "===== CRON START [clock format [clock seconds] -format {%Y-%m-%d %H:%M:%S}] ====="

# Führe das externe Skript aus und leite Ausgabe und Fehlerausgabe in Log
if {[catch {exec /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh 2>@1} result]} {
    puts $log_fd $result
    puts $log_fd "===== CRON END (exit 1) ====="
} else {
    puts $log_fd $result
    puts $log_fd "===== CRON END (exit 0) ====="
}

# Schließe Log-Datei
close $log_fd
