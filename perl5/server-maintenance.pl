#!/usr/bin/perl
# server-maintenance.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/server-maintenance.sh
# auch in: OpenClaw@gateway2:scripts/server-maintenance.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);

# Server Maintenance Script
# RAM: 8GB, Uhr: Europe/Berlin

my $LOG_FILE = "/var/log/server-maintenance.log";
my $DATE = strftime('%Y-%m-%d %H:%M:%S', localtime);
my $HOST = `hostname`;
chomp($HOST);

# Farben für Terminal
my $RED = "\033[0;31m";
my $GREEN = "\033[0;32m";
my $YELLOW = "\033[1;33m";
my $NC = "\033[0m";

log_message("=== Server Maintenance Check ===");

# 1. APT Update Check
log_message("Checking for updates...");
my @apt_output = `apt update -qq 2>&1`;
my @last_lines = @apt_output[-5..-1];
foreach my $line (@last_lines) {
    chomp($line);
    log_message($line);
}
my $updates_count = scalar(`apt list --upgradable 2>/dev/null | wc -l`) - 1;
if ($updates_count > 0) {
    log_message("⚠️ $updates_count packages can be upgraded");
}

# 2. RAM Check (8GB total)
log_message("Checking RAM usage...");
my $RAM_TOTAL = 8192;  # 8GB in MB
my $ram_line = `free -m | grep '^Mem:'`;
my @ram_parts = split(/\s+/, $ram_line);
my $RAM_USED = $ram_parts[2];
my $RAM_PERCENT = int(($RAM_USED * 100) / $RAM_TOTAL);
log_message("RAM: ${RAM_USED}MB / ${RAM_TOTAL}MB (${RAM_PERCENT}%)");
if ($RAM_PERCENT > 90) {
    log_message("🔴 WARNING: RAM usage > 90%!");
} elsif ($RAM_PERCENT > 80) {
    log_message("🟡 WARNING: RAM usage > 80%");
}

# 3. Disk Space Check
log_message("Checking disk space...");
my $disk_line = `df -h / | tail -1`;
chomp($disk_line);
$disk_line =~ s/^.*?(\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+)$/$1/;
my @disk_parts = split(/\s+/, $disk_line);
my $used = $disk_parts[2];
my $total = $disk_parts[1];
my $usage = $disk_parts[4];
log_message("Disk: $used / $total ($usage used)");
my $DISK_PERCENT = $usage;
$DISK_PERCENT =~ s/%$//;
if ($DISK_PERCENT > 90) {
    log_message("🔴 WARNING: Disk > 90%!");
} elsif ($DISK_PERCENT > 80) {
    log_message("🟡 WARNING: Disk > 80%");
}

# 4. NTP Check
log_message("Checking NTP sync...");
my $timedatectl_output = `timedatectl status`;
if ($timedatectl_output =~ /NTP synchronized: yes/) {
    log_message("✅ NTP synchronized");
} else {
    log_message("⚠️ NTP not synchronized");
}

# 5. OpenClaw Gateway Status
log_message("Checking OpenClaw Gateway...");
my $gateway_status = `systemctl is-active openclaw-gateway 2>/dev/null`;
chomp($gateway_status);
if ($gateway_status eq 'active') {
    log_message("✅ OpenClaw Gateway running");
} else {
    log_message("🔴 OpenClaw Gateway NOT running!");
    system("systemctl restart openclaw-gateway");
}

# 6. Load Average
my $uptime_output = `uptime`;
my ($LOAD) = $uptime_output =~ /load average:\s*([0-9.]+)/;
log_message("Load Average: $LOAD");

log_message("=== Maintenance Complete ===");
log_message("");

sub log_message {
    my ($message) = @_;
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $log_entry = "[$timestamp] $message\n";
    
    print $log_entry;
    open(my $fh, '>>', $LOG_FILE) or die "Could not open file '$LOG_FILE': $!";
    print $fh $log_entry;
    close($fh);
}
