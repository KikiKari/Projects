#!/usr/bin/perl
# setup-xvfb-node2.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/setup-xvfb-node2.sh
# auch in: OpenClaw@gateway2:scripts/setup-xvfb-node2.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(system);

# Xvfb Setup für Node 2 (Netcup VPS)
# Erstellt: 2026-04-09

print "=== Xvfb + Chromium Setup für Node 2 ===\n";

# Update & Install
system("sudo apt-get update") == 0 or die "apt-get update failed: $?";
system("sudo apt-get install -y xvfb chromium-browser chromium-chromedriver fonts-liberation libappindicator3-1 libasound2 libatk-bridge2.0-0 libatk1.0-0 libcups2 libgtk-3-0 libnspr4 libnss3 libxss1 xdg-utils") == 0 or die "apt-get install failed: $?";

# Xvfb Systemd Service erstellen
open(my $fh, '>', '/tmp/xvfb.service') or die "Could not open file '/tmp/xvfb.service': $!";
print $fh <<'EOF';
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
EOF
close($fh);

system("sudo mv /tmp/xvfb.service /etc/systemd/system/") == 0 or die "mv failed: $?";

# Service aktivieren
system("sudo systemctl daemon-reload") == 0 or die "systemctl daemon-reload failed: $?";
system("sudo systemctl enable xvfb") == 0 or die "systemctl enable xvfb failed: $?";
system("sudo systemctl start xvfb") == 0 or die "systemctl start xvfb failed: $?";

print "=== Xvfb läuft auf DISPLAY :99 ===\n";
print "Chromium Version:\n";
system("chromium-browser --version") == 0 or print "Chromium nicht gefunden\n";

print "=== Setup abgeschlossen ===\n";
