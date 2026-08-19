#!/usr/bin/tclsh8.6
# setup-xvfb-node2.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node2.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node2.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 2 (Netcup VPS)
# Erstellt: 2026-04-09

# Funktion zum Ausführen von Shell-Befehlen
proc exec_cmd {cmd} {
    if {[catch {exec {*}$cmd} result]} {
        puts stderr "Fehler beim Ausführen: $cmd"
        puts stderr "Fehlermeldung: $result"
        exit 1
    } else {
        return $result
    }
}

# Funktion zum Schreiben einer Datei mit Inhalt
proc write_file {filename content} {
    if {[catch {set fh [open $filename w]} err]} {
        puts stderr "Fehler beim Öffnen der Datei $filename: $err"
        exit 1
    }
    puts -nonewline $fh $content
    close $fh
}

puts "=== Xvfb + Chromium Setup für Node 2 ==="

# Update & Install
exec_cmd [list sudo apt-get update]
exec_cmd [list sudo apt-get install -y \
    xvfb \
    chromium-browser \
    chromium-chromedriver \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libgtk-3-0 \
    libnspr4 \
    libnss3 \
    libxss1 \
    xdg-utils]

# Xvfb Systemd Service erstellen
set service_content {
[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=openclaw
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
}

write_file "/etc/systemd/system/xvfb.service" $service_content

# Service aktivieren
exec_cmd [list sudo systemctl daemon-reload]
exec_cmd [list sudo systemctl enable xvfb]
exec_cmd [list sudo systemctl start xvfb]

puts "=== Xvfb läuft auf DISPLAY :99 ==="
puts "Chromium Version:"
if {[catch {exec_cmd [list chromium-browser --version]} version_result]} {
    puts "Chromium nicht gefunden"
} else {
    puts $version_result
}

puts "=== Setup abgeschlossen ==="
