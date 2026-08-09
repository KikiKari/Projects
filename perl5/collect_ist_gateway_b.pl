#!/usr/bin/env perl
# collect_ist_gateway_b.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use POSIX qw(strftime);
use File::Path qw(make_path);
use File::Basename;
use Cwd 'abs_path';

my $BASE_DIR = $ENV{HOME} . "/.openclaw";
my $OUT_DIR = $BASE_DIR . "/workspace/vscode";
my $NOW_UTC = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);
my $NOW_LOCAL = strftime("%Y-%m-%d %H:%M:%S %Z", localtime);
my $TS = strftime("%Y%m%d-%H%M%S", localtime);

make_path($OUT_DIR) unless -d $OUT_DIR;

my $IST_FILE = "$OUT_DIR/IST-ZUSTAND_GATEWAY-B_NODE7.md";
my $INV_FILE = "$OUT_DIR/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md";
my $CFG_FILE = "$OUT_DIR/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md";
my $ENV_FILE = "$OUT_DIR/ENV-STATUS_GATEWAY-B_NODE7.md";
my $RUN_FILE = "$OUT_DIR/RUN-$TS.md";

my $OPENCLAW_JSON = "$BASE_DIR/openclaw.json";
my $ENV_DOT = "$BASE_DIR/.env";
my $ENV_SYSTEMD = "$BASE_DIR/gateway.systemd.env";
my $VSCODE_DIR = "$BASE_DIR/.vscode";

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
            $OS_PRETTY =~ s/^"(.*)"$/$1/;
            last;
        }
    }
    close($fh);
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
print $fh "# IST-Zustand: Gateway B / Node 7\n\n";
print $fh "Stand (lokal): $NOW_LOCAL  \n";
print $fh "Stand (UTC): $NOW_UTC\n\n";
print $fh "## 1) Identität & System\n\n";
print $fh "- Gateway: **B**\n";
print $fh "- Node: **7**\n";
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
print $fh "- `$BASE_DIR/plugin-skills`: " . (-d "$BASE_DIR/plugin-skills" ? "vorhanden" : "fehlt") . "\n\n";
print $fh "## 4) Hinweis\n\n";
print $fh "Diese Datei wird bei jedem Lauf neu geschrieben.\n";
print $fh "Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.\n";
close($fh);

open($fh, '>', $INV_FILE) or die "Could not open file '$INV_FILE' $!";
print $fh "# Artefakt-Inventar: Gateway B / Node 7\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Top-Level in ~/.openclaw\n\n";
print $fh '```text' . "\n";
opendir(my $dir, $BASE_DIR) or warn "Could not open directory '$BASE_DIR': $!";
if ($dir) {
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' or $file eq '..';
        print $fh "$file\n";
    }
}
print $fh "```\n\n";
print $fh "## ~/.openclaw/.vscode\n\n";
print $fh '```text' . "\n";
if (-d $VSCODE_DIR) {
    opendir($dir, $VSCODE_DIR) or warn "Could not open directory '$VSCODE_DIR': $!";
    if ($dir) {
        my @files = readdir($dir);
        closedir($dir);
        for my $file (sort @files) {
            print $fh "$file\n";
        }
    }
} else {
    print $fh "(nicht vorhanden)\n";
}
print $fh "```\n\n";
print $fh "## plugin-skills/\n\n";
print $fh '```text' . "\n";
if (-d "$BASE_DIR/plugin-skills") {
    opendir($dir, "$BASE_DIR/plugin-skills") or warn "Could not open directory '$BASE_DIR/plugin-skills': $!";
    if ($dir) {
        my @files = readdir($dir);
        closedir($dir);
        for my $file (sort @files) {
            print $fh "$file\n";
        }
    }
} else {
    print $fh "(nicht vorhanden)\n";
}
print $fh "```\n\n";
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
print $fh "```\n";
close($fh);

open($fh, '>', $CFG_FILE) or die "Could not open file '$CFG_FILE' $!";
print $fh "# OpenClaw Config Snapshot: Gateway B / Node 7\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Schlüsselpositionen (grep)\n\n";
print $fh '```text' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or warn "Could not open '$OPENCLAW_JSON': $!";
    if ($json_fh) {
        while (my $line = <$json_fh>) {
            if ($line =~ /"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"/) {
                print $fh $line;
            }
        }
        close($json_fh);
    }
} else {
    print $fh "openclaw.json fehlt\n";
}
print $fh "```\n\n";
print $fh "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)\n\n";
print $fh '```json' . "\n";
if (-f $OPENCLAW_JSON) {
    open(my $json_fh, '<', $OPENCLAW_JSON) or warn "Could not open '$OPENCLAW_JSON': $!";
    if ($json_fh) {
        my $line_num = 0;
        while (my $line = <$json_fh>) {
            $line_num++;
            if ($line_num >= 580 && $line_num <= 780) {
                print $fh $line;
            }
            last if $line_num > 780;
        }
        close($json_fh);
    }
} else {
    print $fh "{ \"error\": \"openclaw.json fehlt\" }\n";
}
print $fh "```\n";
close($fh);

open($fh, '>', $ENV_FILE) or die "Could not open file '$ENV_FILE' $!";
print $fh "# ENV-Status: Gateway B / Node 7\n\n";
print $fh "Stand: $NOW_LOCAL\n\n";
print $fh "## Dateien\n\n";
print $fh '```text' . "\n";
if (-f $ENV_DOT && -f $ENV_SYSTEMD) {
    print $fh `ls -la "$ENV_DOT" "$ENV_SYSTEMD" 2>/dev/null`;
} elsif (-f $ENV_DOT) {
    print $fh `ls -la "$ENV_DOT" 2>/dev/null`;
} elsif (-f $ENV_SYSTEMD) {
    print $fh `ls -la "$ENV_SYSTEMD" 2>/dev/null`;
}
print $fh "```\n\n";
print $fh "## .env (vollständig, ungefiltert)\n\n";
print $fh '```dotenv' . "\n";
if (-f $ENV_DOT) {
    open(my $env_fh, '<', $ENV_DOT) or warn "Could not open '$ENV_DOT': $!";
    if ($env_fh) {
        while (my $line = <$env_fh>) {
            print $fh $line;
        }
        close($env_fh);
    }
} else {
    print $fh "# .env fehlt\n";
}
print $fh "```\n\n";
print $fh "## gateway.systemd.env (vollständig, ungefiltert)\n\n";
print $fh '```dotenv' . "\n";
if (-f $ENV_SYSTEMD) {
    open(my $env_fh, '<', $ENV_SYSTEMD) or warn "Could not open '$ENV_SYSTEMD': $!";
    if ($env_fh) {
        while (my $line = <$env_fh>) {
            print $fh $line;
        }
        close($env_fh);
    }
} else {
    print $fh "# gateway.systemd.env fehlt\n";
}
print $fh "```\n";
close($fh);

open($fh, '>', $RUN_FILE) or die "Could not open file '$RUN_FILE' $!";
print $fh "# Laufprotokoll Gateway B / Node 7\n\n";
print $fh "- Zeit (lokal): $NOW_LOCAL\n";
print $fh "- Zeit (UTC): $NOW_UTC\n";
print $fh "- Script: " . abs_path($0) . "\n\n";
print $fh "## Erzeugte Dateien\n\n";
print $fh "- " . basename($IST_FILE) . "\n";
print $fh "- " . basename($INV_FILE) . "\n";
print $fh "- " . basename($CFG_FILE) . "\n";
print $fh "- " . basename($ENV_FILE) . "\n\n";
close($fh);

print "OK: IST-Zustand erfasst.\n";
print "Ausgabeordner: $OUT_DIR\n";
print "Dateien:\n";
opendir($dir, $OUT_DIR) or warn "Could not open directory '$OUT_DIR': $!";
if ($dir) {
    my @files = readdir($dir);
    closedir($dir);
    for my $file (sort @files) {
        next if $file eq '.' or $file eq '..';
        print "- $file\n";
    }
}
