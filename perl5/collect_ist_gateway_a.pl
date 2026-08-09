#!/usr/bin/env perl
# collect_ist_gateway_a.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);
use File::Path qw(make_path);
use File::Basename qw(basename);

my $BASE_DIR = $ENV{HOME} . "/.openclaw";
my $OUT_DIR = $BASE_DIR . "/workspace/vscode";
my $NOW_UTC = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);
my $NOW_LOCAL = strftime("%Y-%m-%d %H:%M:%S %Z", localtime);
my $TS = strftime("%Y%m%d-%H%M%S", localtime);

make_path($OUT_DIR) unless -d $OUT_DIR;

my $IST_FILE = $OUT_DIR . "/IST-ZUSTAND_GATEWAY-A_NODE1.md";
my $INV_FILE = $OUT_DIR . "/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md";
my $CFG_FILE = $OUT_DIR . "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md";
my $ENV_FILE = $OUT_DIR . "/ENV-STATUS_GATEWAY-A_NODE1.md";
my $RUN_FILE = $OUT_DIR . "/RUN-" . $TS . ".md";

my $OPENCLAW_JSON = $BASE_DIR . "/openclaw.json";
my $ENV_DOT = $BASE_DIR . "/.env";
my $ENV_SYSTEMD = $BASE_DIR . "/gateway.systemd.env";
my $VSCODE_DIR = $BASE_DIR . "/.vscode";

my $HOSTNAME_FQDN = `hostname -f 2>/dev/null` || `hostname`;
chomp $HOSTNAME_FQDN;
my $HOSTNAME_SHORT = `hostname`;
chomp $HOSTNAME_SHORT;
my $ARCH = `uname -m`;
chomp $ARCH;
my $KERNEL = `uname -r`;
chomp $KERNEL;
my $OS_PRETTY = "";
if (open(my $fh, '<', '/etc/os-release')) {
    while (my $line = <$fh>) {
        if ($line =~ /^PRETTY_NAME=(.*)/) {
            $OS_PRETTY = $1;
            $OS_PRETTY =~ s/^"(.*)"$/\1/;
            last;
        }
    }
    close $fh;
}
my $IPV4_ALL = `hostname -I 2>/dev/null`;
chomp $IPV4_ALL;
$IPV4_ALL =~ s/\s+$//;
my $PUBLIC_IP = `curl -4 -s --max-time 4 ifconfig.me 2>/dev/null`;
chomp $PUBLIC_IP;
my $TAILSCALE_IP = `tailscale ip -4 2>/dev/null | head -n1`;
chomp $TAILSCALE_IP;
my $OPENCLAW_VER = `openclaw --version 2>/dev/null`;
chomp $OPENCLAW_VER;
my $NODE_VER = `node -v 2>/dev/null`;
chomp $NODE_VER;

$PUBLIC_IP = "(nicht ermittelt)" if !$PUBLIC_IP;
$TAILSCALE_IP = "(nicht ermittelt)" if !$TAILSCALE_IP;
$OPENCLAW_VER = "(nicht ermittelt)" if !$OPENCLAW_VER;
$NODE_VER = "(nicht ermittelt)" if !$NODE_VER;

open(my $fh, '>', $IST_FILE) or die "Could not open file '$IST_FILE' $!";
print $fh "# IST-Zustand: Gateway A / Node 1\n\n";
print $fh "Stand (lokal): $NOW_LOCAL  \n";
print $fh "Stand (UTC): $NOW_UTC\n\n";
print $fh "## 1) Identitaet & System\n\n";
print $fh "- Gateway: **A**\n";
print $fh "- Node: **1**\n";
print $fh "- Hostname (short): `$HOSTNAME_SHORT`\n";
print $fh "- Hostname (FQDN): `$HOSTNAME_FQDN`\n";
print $fh "- Architektur: `$ARCH`\n";
print $fh "- Kernel: `$KERNEL`\n";
print $fh "- OS: `$OS_PRETTY`\n";
print $fh "- IPv4 (lokal): `$IPV4_ALL`\n";
print $fh "- Public IPv4: `$PUBLIC_IP`\n";
print $fh "- Tailscale IPv4: `$TAILSCALE_IP`\n";
print $fh "- OpenClaw Version: `$OPENCLAW_VER`\n";
print $fh "- Node.js Version: `$NODE_VER`\n\n";
print $fh "## 2) Arbeitsverzeichnisse\n\n";
print $fh "- Basis: `$BASE_DIR`\n";
print $fh "- Funktionell VSCode: `$VSCODE_DIR`\n";
print $fh "- Workspace Doku: `$OUT_DIR`\n\n";
print $fh "## 3) Kernartefakte (Existenz)\n\n";
print $fh "- `$OPENCLAW_JSON`: " . (-f $OPENCLAW_JSON ? "vorhanden" : "fehlt") . "\n";
print $fh "- `$ENV_DOT`: " . (-f $ENV_DOT ? "vorhanden" : "fehlt") . "\n";
print $fh "- `$ENV_SYSTEMD`: " . (-f $ENV_SYSTEMD ? "vorhanden" : "fehlt") . "\n";
print $fh "- `$BASE_DIR/plugins/installs.json`: " . (-f "$BASE_DIR/plugins/installs.json" ? "vorhanden" : "fehlt") . "\n";
print $fh "- `$BASE_DIR/plugin-skills`: " . (-d "$BASE_DIR/plugin-skills" ? "vorhanden" : "fehlt") . "\n";
close $fh;

open($fh, '>', $INV_FILE) or die "Could not open file '$INV_FILE' $!";
print $fh "# Artefakt-Inventar: Gateway A / Node 1\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Top-Level in ~/.openclaw\n\n";
print $fh '```text' . "\n";
if (opendir(my $dir, $BASE_DIR)) {
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' or $file eq '..';
        print $fh "$file\n";
    }
} else {
    print $fh "Error reading directory\n";
}
print $fh '```' . "\n\n";
print $fh "## ~/.openclaw/.vscode\n\n";
print $fh '```text' . "\n";
if (-d $VSCODE_DIR) {
    opendir(my $dir, $VSCODE_DIR) or die "Could not open directory '$VSCODE_DIR': $!";
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' or $file eq '..';
        my $full_path = "$VSCODE_DIR/$file";
        my @stat = stat($full_path);
        printf $fh "%s %s %s %s %s %s %s\n", 
            (stat($full_path))[2] & 0777, 
            (stat($full_path))[3], 
            (stat($full_path))[4], 
            (stat($full_path))[5], 
            (stat($full_path))[7], 
            strftime("%b %d %H:%M", localtime((stat($full_path))[9])), 
            $file;
    }
} else {
    print $fh "(nicht vorhanden)\n";
}
print $fh '```' . "\n\n";
print $fh "## plugin-skills/\n\n";
print $fh '```text' . "\n";
if (-d "$BASE_DIR/plugin-skills") {
    opendir(my $dir, "$BASE_DIR/plugin-skills") or die "Could not open directory: $!";
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' or $file eq '..';
        print $fh "$file\n";
    }
} else {
    print $fh "(nicht vorhanden)\n";
}
print $fh '```' . "\n\n";
print $fh "## openclaw.json Backups\n\n";
print $fh '```text' . "\n";
my @backups = glob("$BASE_DIR/openclaw.json.bak*");
if (@backups) {
    for my $backup (@backups) {
        print $fh basename($backup) . "\n";
    }
} else {
    print $fh "(keine gefunden)\n";
}
print $fh '```' . "\n";
close $fh;

open($fh, '>', $CFG_FILE) or die "Could not open file '$CFG_FILE' $!";
print $fh "# OpenClaw Config Snapshot: Gateway A / Node 1\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Schluesselpositionen (grep)\n\n";
print $fh '```text' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or die "Could not open '$OPENCLAW_JSON': $!";
    my $line_num = 1;
    while (my $line = <$json_fh>) {
        if ($line =~ /"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/) {
            print $fh "$line_num: $line";
        }
        $line_num++;
    }
    close $json_fh;
} else {
    print $fh "openclaw.json fehlt\n";
}
print $fh '```' . "\n\n";
print $fh "## Ausschnitt gateway/session/auth\n\n";
print $fh '```json' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or die "Could not open '$OPENCLAW_JSON': $!";
    my $line_num = 1;
    while (my $line = <$json_fh>) {
        if ($line_num >= 580 && $line_num <= 780) {
            print $fh $line;
        }
        last if $line_num > 780;
        $line_num++;
    }
    close $json_fh;
} else {
    print $fh '{ "error": "openclaw.json fehlt" }' . "\n";
}
print $fh '```' . "\n";
close $fh;

open($fh, '>', $ENV_FILE) or die "Could not open file '$ENV_FILE' $!";
print $fh "# ENV-Status: Gateway A / Node 1\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Dateien\n\n";
print $fh '```text' . "\n";
if (-f $ENV_DOT && -f $ENV_SYSTEMD) {
    my @stat_dot = stat($ENV_DOT);
    my @stat_systemd = stat($ENV_SYSTEMD);
    printf $fh "%s %s %s %s %s %s %s\n", 
        (stat($ENV_DOT))[2] & 0777, 
        (stat($ENV_DOT))[3], 
        (stat($ENV_DOT))[4], 
        (stat($ENV_DOT))[5], 
        (stat($ENV_DOT))[7], 
        strftime("%b %d %H:%M", localtime((stat($ENV_DOT))[9])), 
        $ENV_DOT;
    printf $fh "%s %s %s %s %s %s %s\n", 
        (stat($ENV_SYSTEMD))[2] & 0777, 
        (stat($ENV_SYSTEMD))[3], 
        (stat($ENV_SYSTEMD))[4], 
        (stat($ENV_SYSTEMD))[5], 
        (stat($ENV_SYSTEMD))[7], 
        strftime("%b %d %H:%M", localtime((stat($ENV_SYSTEMD))[9])), 
        $ENV_SYSTEMD;
} else {
    print $fh "Files not found\n";
}
print $fh '```' . "\n\n";
print $fh "## .env (vollstaendig)\n\n";
print $fh '```dotenv' . "\n";
if (-f $ENV_DOT) {
    open(my $env_fh, '<', $ENV_DOT) or die "Could not open '$ENV_DOT': $!";
    while (my $line = <$env_fh>) {
        print $fh $line;
    }
    close $env_fh;
} else {
    print $fh "# .env fehlt\n";
}
print $fh '```' . "\n\n";
print $fh "## gateway.systemd.env (vollstaendig)\n\n";
print $fh '```dotenv' . "\n";
if (-f $ENV_SYSTEMD) {
    open(my $env_fh, '<', $ENV_SYSTEMD) or die "Could not open '$ENV_SYSTEMD': $!";
    while (my $line = <$env_fh>) {
        print $fh $line;
    }
    close $env_fh;
} else {
    print $fh "# gateway.systemd.env fehlt\n";
}
print $fh '```' . "\n";
close $fh;

open($fh, '>', $RUN_FILE) or die "Could not open file '$RUN_FILE' $!";
print $fh "# Laufprotokoll Gateway A / Node 1\n\n";
print $fh "- Zeit (lokal): $NOW_LOCAL\n";
print $fh "- Zeit (UTC): $NOW_UTC\n";
print $fh "- Script: " . __FILE__ . "\n\n";
print $fh "## Erzeugte Dateien\n\n";
print $fh "- " . basename($IST_FILE) . "\n";
print $fh "- " . basename($INV_FILE) . "\n";
print $fh "- " . basename($CFG_FILE) . "\n";
print $fh "- " . basename($ENV_FILE) . "\n";
close $fh;

print "OK: IST-Zustand erfasst.\n";
opendir(my $dir, $OUT_DIR) or die "Could not open directory '$OUT_DIR': $!";
my @files = readdir($dir);
closedir($dir);
for my $file (sort @files) {
    next if $file eq '.' or $file eq '..';
    print "- $file\n";
}
