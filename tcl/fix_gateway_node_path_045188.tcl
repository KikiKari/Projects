#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "beaff11e8468e21404b090778bf8bafcadeededd344d17432aa1868f785c5171", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "tcl"}
# fix_gateway_node_path.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
# auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
    regsub {/home/openclaw/.nvm/versions/node/v22.22.2/bin/node} $line {/usr/bin/node} modified_line
    puts $output $modified_line
}

close $input
close $output

file rename -force $temp_file $service_file

# Service neu laden und neu starten
exec systemctl daemon-reload
exec systemctl restart openclaw-gateway

# Status prüfen
if {[catch {exec systemctl status openclaw-gateway --no-pager} result]} {
    puts stderr $result
    exit 1
} else {
    puts $result
}
