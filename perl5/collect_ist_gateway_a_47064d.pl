#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "20fe7488d0da28779f5ac0197742f7d76648946422f28c0591c1da8d4fa6d597", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "perl5"}
# collect_ist_gateway_a.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use File::Basename;
use POSIX qw(strftime);

my $BASE_DIR = $ENV{'HOME'} . "/.openclaw";
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
if (-f "/etc/os-release") {
    open(my $fh, '<', '/etc/os-release') or warn "Could not open /etc/os-release: $!";
    while (<$fh>) {
        if (/^PRETTY_NAME=(.*)/) {
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

open(my $ist_fh, '>', $IST_FILE) or die "Cannot write to $IST_FILE: $!";
print $ist_fh "# IST-Zustand: Gateway A / Node 1\n\n";
print $ist_fh "Stand (lokal): $NOW_LOCAL  \n";
print $ist_fh "Stand (UTC): $NOW_UTC\n\n";
print $ist_fh "## 1) Identitaet & System\n\n";
print $ist_fh "- Gateway: **A**\n";
print $ist_fh "- Node: **1**\n";
print $ist_fh "- Hostname (short): `$HOSTNAME_SHORT`\n";
print $ist_fh "- Hostname (FQDN): `$HOSTNAME_FQDN`\n";
print $ist_fh "- Architektur: `$ARCH`\n";
print $ist_fh "- Kernel: `$KERNEL`\n";
print $ist_fh "- OS: `$OS_PRETTY`\n";
print $ist_fh "- IPv4 (lokal): `$IPV4_ALL`\n";
print $ist_fh "- Public IPv4: `$PUBLIC_IP`\n";
print $ist_fh "- Tailscale IPv4: `$TAILSCALE_IP`\n";
print $ist_fh "- OpenClaw Version: `$OPENCLAW_VER`\n";
print $ist_fh "- Node.js Version: `$NODE_VER`\n\n";
print $ist_fh "## 2) Arbeitsverzeichnisse\n\n";
print $ist_fh "- Basis: `$BASE_DIR`\n";
print $ist_fh "- Funktionell VSCode: `$VSCODE_DIR`\n";
print $ist_fh "- Workspace Doku: `$OUT_DIR`\n\n";
print $ist_fh "## 3) Kernartefakte (Existenz)\n\n";
print $ist_fh "- `$OPENCLAW_JSON`: " . (-f $OPENCLAW_JSON ? "vorhanden" : "fehlt") . "\n";
print $ist_fh "- `$ENV_DOT`: " . (-f $ENV_DOT ? "vorhanden" : "fehlt") . "\n";
print $ist_fh "- `$ENV_SYSTEMD`: " . (-f $ENV_SYSTEMD ? "vorhanden" : "fehlt") . "\n";
print $ist_fh "- `$BASE_DIR/plugins/installs.json`: " . (-f "$BASE_DIR/plugins/installs.json" ? "vorhanden" : "fehlt") . "\n";
print $ist_fh "- `$BASE_DIR/plugin-skills`: " . (-d "$BASE_DIR/plugin-skills" ? "vorhanden" : "fehlt") . "\n";
close $ist_fh;

open(my $inv_fh, '>', $INV_FILE) or die "Cannot write to $INV_FILE: $!";
print $inv_fh "# Artefakt-Inventar: Gateway A / Node 1\n\n";
print $inv_fh "Stand: $NOW_LOCAL\n\n";
print $inv_fh "## Top-Level in ~/.openclaw\n\n";
print $inv_fh '```text' . "\n";
opendir(my $dir, $BASE_DIR) or warn "Cannot open directory $BASE_DIR: $!";
if ($dir) {
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' || $file eq '..';
        print $inv_fh "$file\n";
    }
} else {
    print $inv_fh "(nicht vorhanden)\n";
}
print $inv_fh "```\n\n";
print $inv_fh "## ~/.openclaw/.vscode\n\n";
print $inv_fh '```text' . "\n";
if (-d $VSCODE_DIR) {
    opendir(my $vscode_dir, $VSCODE_DIR) or warn "Cannot open directory $VSCODE_DIR: $!";
    if ($vscode_dir) {
        my @entries = readdir($vscode_dir);
        closedir($vscode_dir);
        for my $entry (@entries) {
            next if $entry eq '.' || $entry eq '..';
            print $inv_fh "$entry\n";
        }
    }
} else {
    print $inv_fh "(nicht vorhanden)\n";
}
print $inv_fh "```\n\n";
print $inv_fh "## plugin-skills/\n\n";
print $inv_fh '```text' . "\n";
if (-d "$BASE_DIR/plugin-skills") {
    opendir(my $skills_dir, "$BASE_DIR/plugin-skills") or warn "Cannot open directory $BASE_DIR/plugin-skills: $!";
    if ($skills_dir) {
        my @skills = readdir($skills_dir);
        closedir($skills_dir);
        for my $skill (@skills) {
            next if $skill eq '.' || $skill eq '..';
            print $inv_fh "$skill\n";
        }
    }
} else {
    print $inv_fh "(nicht vorhanden)\n";
}
print $inv_fh "```\n\n";
print $inv_fh "## openclaw.json Backups\n\n";
print $inv_fh '```text' . "\n";
my @backups = glob("$BASE_DIR/openclaw.json.bak*");
if (@backups) {
    for my $backup (@backups) {
        my $filename = basename($backup);
        print $inv_fh "$filename\n";
    }
} else {
    print $inv_fh "(keine gefunden)\n";
}
print $inv_fh "```\n";
close $inv_fh;

open(my $cfg_fh, '>', $CFG_FILE) or die "Cannot write to $CFG_FILE: $!";
print $cfg_fh "# OpenClaw Config Snapshot: Gateway A / Node 1\n\n";
print $cfg_fh "Stand: $NOW_LOCAL\n\n";
print $cfg_fh "## Schluesselpositionen (grep)\n\n";
print $cfg_fh '```text' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or warn "Could not open $OPENCLAW_JSON: $!";
    if ($json_fh) {
        my $line_num = 1;
        while (my $line = <$json_fh>) {
            if ($line =~ /"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/) {
                print $cfg_fh "$line_num:$line";
            }
            $line_num++;
        }
        close $json_fh;
    }
} else {
    print $cfg_fh "openclaw.json fehlt\n";
}
print $cfg_fh "```\n\n";
print $cfg_fh "## Ausschnitt gateway/session/auth\n\n";
print $cfg_fh '```json' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or warn "Could not open $OPENCLAW_JSON: $!";
    if ($json_fh) {
        my $line_count = 0;
        while (my $line = <$json_fh>) {
            $line_count++;
            last if $line_count > 780;
            if ($line_count >= 580) {
                print $cfg_fh $line;
            }
        }
        close $json_fh;
    }
} else {
    print $cfg_fh '{ "error": "openclaw.json fehlt" }' . "\n";
}
print $cfg_fh "```\n";
close $cfg_fh;

open(my $env_fh, '>', $ENV_FILE) or die "Cannot write to $ENV_FILE: $!";
print $env_fh "# ENV-Status: Gateway A / Node 1\n\n";
print $env_fh "Stand: $NOW_LOCAL\n\n";
print $env_fh "## Dateien\n\n";
print $env_fh '```text' . "\n";
if (-f $ENV_DOT || -f $ENV_SYSTEMD) {
    if (-f $ENV_DOT) {
        my @stat_dot = stat($ENV_DOT);
        printf $env_fh "%-10s %d %s %s\n", "-r--r--r--", $stat_dot[7], scalar localtime($stat_dot[9]), ".env";
    }
    if (-f $ENV_SYSTEMD) {
        my @stat_systemd = stat($ENV_SYSTEMD);
        printf $env_fh "%-10s %d %s %s\n", "-r--r--r--", $stat_systemd[7], scalar localtime($stat_systemd[9]), "gateway.systemd.env";
    }
} else {
    print $env_fh "(nicht vorhanden)\n";
}
print $env_fh "```\n\n";
print $env_fh "## .env (vollstaendig)\n\n";
print $env_fh '```dotenv' . "\n";
if (-f $ENV_DOT) {
    open(my $dot_fh, '<', $ENV_DOT) or warn "Could not open $ENV_DOT: $!";
    while (my $line = <$dot_fh>) {
        print $env_fh $line;
    }
    close $dot_fh;
} else {
    print $env_fh "# .env fehlt\n";
}
print $env_fh "```\n\n";
print $env_fh "## gateway.systemd.env (vollstaendig)\n\n";
print $env_fh '```dotenv' . "\n";
if (-f $ENV_SYSTEMD) {
    open(my $systemd_fh, '<', $ENV_SYSTEMD) or warn "Could not open $ENV_SYSTEMD: $!";
    while (my $line = <$systemd_fh>) {
        print $env_fh $line;
    }
    close $systemd_fh;
} else {
    print $env_fh "# gateway.systemd.env fehlt\n";
}
print $env_fh "```\n";
close $env_fh;

open(my $run_fh, '>', $RUN_FILE) or die "Cannot write to $RUN_FILE: $!";
print $run_fh "# Laufprotokoll Gateway A / Node 1\n\n";
print $run_fh "- Zeit (lokal): $NOW_LOCAL\n";
print $run_fh "- Zeit (UTC): $NOW_UTC\n";
print $run_fh "- Script: " . dirname($0) . "/" . basename($0) . "\n\n";
print $run_fh "## Erzeugte Dateien\n\n";
print $run_fh "- " . basename($IST_FILE) . "\n";
print $run_fh "- " . basename($INV_FILE) . "\n";
print $run_fh "- " . basename($CFG_FILE) . "\n";
print $run_fh "- " . basename($ENV_FILE) . "\n";
close $run_fh;

print "OK: IST-Zustand erfasst.\n";
opendir(my $out_dir, $OUT_DIR) or warn "Cannot open directory $OUT_DIR: $!";
if ($out_dir) {
    my @files = readdir($out_dir);
    closedir($out_dir);
    for my $file (@files) {
        next if $file eq '.' || $file eq '..';
        print "- $file\n";
    }
}
