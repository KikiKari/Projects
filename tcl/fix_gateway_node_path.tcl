#!/usr/bin/env tclsh
# fix_gateway_node_path.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Backup der originalen Service-Datei
set timestamp [clock format [clock seconds] -format "%Y%m%d_%H%M%S"]
set backup_file "/etc/systemd/system/openclaw-gateway.service.backup-$timestamp"
file copy "/etc/systemd/system/openclaw-gateway.service" $backup_file

# Korrektur des Node.js Pfads in der Service-Datei
# Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
set service_file "/etc/systemd/system/openclaw-gateway.service"
set temp_file "/tmp/openclaw-gateway.service.tmp"

set input [open $service_file r]
set output [open $temp_file w]

while {[gets $input line] != -1} {
    set line [regsub {/home/openclaw/.nvm/versions/node/v22.22.2/bin/node} $line {/usr/bin/node}]
    puts $output $line
}

close $input
close $output

file rename -force $temp_file $service_file

# Service neu laden und neu starten
exec systemctl daemon-reload
exec systemctl restart openclaw-gateway

# Status prüfen
exec systemctl status openclaw-gateway --no-pager
