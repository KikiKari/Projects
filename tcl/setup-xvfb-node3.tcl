#!/usr/bin/tclsh8.6
# setup-xvfb-node3.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node3.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node3.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Xvfb Setup für Node 3 (xNetX VPS)
# Erstellt: 2026-04-09
# Hinweis: Altes VNC-Setup wird entfernt

proc execute_command {cmd} {
    if {[catch {exec {*}$cmd} result]} {
        puts stderr $result
        return 1
    } else {
        puts $result
        return 0
    }
}

proc remove_vnc_setup {} {
    # Altes VNC stoppen & entfernen (falls vorhanden)
    catch {execute_command [list sudo systemctl stop vncserver@*]}
    catch {execute_command [list sudo systemctl disable vncserver@*]}
    catch {execute_command [list sudo apt-get remove -y tightvncserver tigervnc-standalone-server]}
    
    # Entferne VNC-Dateien
    catch {file delete -force ~/.vnc}
    foreach file [glob -nocomplain /tmp/.X11-unix/X*] {
        catch {file delete -force $file}
    }
}

proc install_packages {} {
    # Update & Install
    execute_command [list sudo apt-get update]
    set packages {
        xvfb
        chromium
        chromium-driver
        fonts-liberation
        libappindicator3-1
        libasound2
        libatk-bridge2.0-0
        libatk1.0-0
        libcups2
        libgtk-3-0
        libnspr4
        libnss3
        libxss1
        xdg-utils
    }
    execute_command [concat [list sudo apt-get install -y] $packages]
}

proc create_xvfb_service {} {
    set service_content {
[Unit]
Description=X Virtual Framebuffer
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/bin/Xvfb :99 -screen 0 1920x1080x24 -ac +extension GLX +render -noreset
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
    }
    
    # Schreibe Service-Datei
    set fh [open "/etc/systemd/system/xvfb.service" w]
    puts $fh [string trim $service_content]
    close $fh
    
    # Service aktivieren
    execute_command [list sudo systemctl daemon-reload]
    execute_command [list sudo systemctl enable xvfb]
    execute_command [list sudo systemctl start xvfb]
}

puts "=== Xvfb + Chromium Setup für Node 3 ==="
puts "=== Entferne altes VNC-Setup ==="

remove_vnc_setup

puts "=== Installiere Xvfb + Chromium ==="

install_packages

create_xvfb_service

puts "=== Xvfb läuft auf DISPLAY :99 ==="
puts "Chromium Version:"

if {[catch {execute_command [list chromium --version]} result]} {
    puts "Chromium nicht gefunden"
} else {
    puts $result
}

puts "=== Setup abgeschlossen ==="
puts "=== Altes VNC-Setup wurde entfernt ==="
