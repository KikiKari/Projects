#!/usr/bin/perl
# setup-xvfb-node3.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node3.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node3.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX;

# Xvfb Setup für Node 3 (xNetX VPS)
# Erstellt: 2026-04-09
# Hinweis: Altes VNC-Setup wird entfernt

print "=== Xvfb + Chromium Setup für Node 3 ===\n";
print "=== Entferne altes VNC-Setup ===\n";

# Altes VNC stoppen & entfernen (falls vorhanden)
system("sudo systemctl stop vncserver\@* 2>/dev/null");
system("sudo systemctl disable vncserver\@* 2>/dev/null");
system("sudo apt-get remove -y tightvncserver tigervnc-standalone-server 2>/dev/null");

# Entferne VNC-Dateien
system("sudo rm -rf ~/.vnc /tmp/.X11-unix/X* 2>/dev/null");

print "=== Installiere Xvfb + Chromium ===\n";

# Update & Install
system("sudo apt-get update");
my @packages = (
    "xvfb",
    "chromium",
    "chromium-driver",
    "fonts-liberation",
    "libappindicator3-1",
    "libasound2",
    "libatk-bridge2.0-0",
    "libatk1.0-0",
    "libcups2",
    "libgtk-3-0",
    "libnspr4",
    "libnss3",
    "libxss1",
    "xdg-utils"
);

system("sudo apt-get install -y " . join(" ", @packages));

# Xvfb Systemd Service erstellen
open(my $fh, '>', '/etc/systemd/system/xvfb.service') or die "Kann Datei nicht öffnen: $!";
print $fh <<'EOF';
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
EOF
close($fh);

# Service aktivieren
system("sudo systemctl daemon-reload");
system("sudo systemctl enable xvfb");
system("sudo systemctl start xvfb");

print "=== Xvfb läuft auf DISPLAY :99 ===\n";
print "Chromium Version:\n";

my $chromium_version = `chromium --version`;
if ($chromium_version) {
    print $chromium_version;
} else {
    print "Chromium nicht gefunden\n";
}

print "=== Setup abgeschlossen ===\n";
print "=== Altes VNC-Setup wurde entfernt ===\n";
