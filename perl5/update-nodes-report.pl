#!/usr/bin/perl
# update-nodes-report.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/update-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/update-nodes-report.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json);
use File::Spec;
use POSIX qw(strftime);

# Pfade
my $DASHBOARD_PATH = File::Spec->catfile(File::Spec->updir(), 'dashboards', 'nodes-overview.md');

# Farbcodes für Konsole
my %C = (
    green  => "\e[32m",
    yellow => "\e[33m",
    red    => "\e[31m",
    blue   => "\e[34m",
    reset  => "\e[0m"
);

sub getNodeStatus {
    my $output;
    eval {
        $output = qx(openclaw nodes status --json 2>/dev/null);
        if ($? != 0) {
            die "Befehl fehlgeschlagen";
        }
    };
    if ($@) {
        print $C{red} . "❌ Fehler beim Abrufen des Node-Status:" . $C{reset} . " $@\n";
        return [];
    }
    my $data;
    eval {
        $data = decode_json($output);
    };
    if ($@) {
        print $C{red} . "❌ Fehler beim Parsen des JSON:" . $C{reset} . " $@\n";
        return [];
    }
    return $data;
}

sub updateDashboard {
    my ($nodes) = @_;
    my $now = strftime "%d.%m.%Y, %H:%M:%S", localtime;

    # Manuelle Ergänzung statischer Konfigurationen (da nicht alle Infos über CLI)
    my %nodeConfig = (
        '1' => { name => 'Gateway',       os => 'Ubuntu 22.04', ip => '152.53.145.65',   wg => '10.10.0.1', tunnel => '–', mode => 'Gateway' },
        '2' => { name => 'Netcup Server', os => 'Ubuntu 22.04', ip => '78.46.123.10',  wg => '10.10.0.2', tunnel => '–', mode => 'Node' },
        '3' => { name => 'xNetX VPS',     os => 'Debian 11',    ip => '5.45.105.20',   wg => '–',        tunnel => 'Port 18794', mode => 'Node' },
        '4' => { name => 'Webhosting',    os => 'Shared Linux', ip => '–',              wg => '–',        tunnel => '–', mode => '–' },
        '5' => { name => 'Redmi Note 11', os => 'Android',      ip => '–',              wg => '10.10.0.5', tunnel => '–', mode => 'Node' },
        '6' => { name => 'Lenovo (Win)',  os => 'Windows 11',   ip => '–',              wg => '–',        tunnel => '–', mode => 'Node' }
    );

    my @rows;
    for my $nodeId (sort keys %nodeConfig) {
        my $cfg = $nodeConfig{$nodeId};
        my $node = undef;
        for my $n (@$nodes) {
            if ($n->{nodeId} eq $nodeId || (exists $n->{name} && index($n->{name}, (split / /, $cfg->{name})[0]) != -1)) {
                $node = $n;
                last;
            }
        }

        my $statusVPN = '⚠️';
        if ($node) {
            $statusVPN = ($node->{status} eq 'paired') ? '✅' : '🔴';
        }

        my $statusSSH = ($cfg->{tunnel} ne '–') ? '✅' : '❌';

        my $sshKey = '❌';
        if ($nodeId eq '1') {
            $sshKey = 'Local (id_ed25519)';
        } elsif ($nodeId eq '2' || $nodeId eq '3') {
            $sshKey = '❌ (Pending)';
        }

        my $lastCheck = '–';
        if ($node && exists $node->{lastSeen}) {
            $lastCheck = strftime "%d.%m.%Y, %H:%M:%S", localtime($node->{lastSeen});
        }

        push @rows, sprintf "| %-4s | %-13s | %-12s | %-14s | %-10s | %-18s | %-19s | %-9s | %-9s | %-19s | %-19s |",
            $nodeId,
            $cfg->{name},
            $cfg->{os},
            $cfg->{ip},
            $cfg->{mode},
            $cfg->{wg},
            $cfg->{tunnel},
            $statusVPN,
            $statusSSH,
            $sshKey,
            $lastCheck;
    }

    my $content = "# Nodes Overview (Network Status)\n\n";
    $content .= "| Node | Name          | OS           | IP             | Mode       | Primär WG IP       | Sekundär/SSH Tunnel | StatusVPN | StatusSSH | SSH Key (Deployed) | Letzter Check       |\n";
    $content .= "|------|---------------|--------------|----------------|------------|--------------------|---------------------|-----------|-----------|---------------------|---------------------|\n";
    $content .= join("\n", @rows) . "\n\n";
    $content .= "> 💡 **Legende:** \n";
    $content .= "> - **Primär WG IP**: Die WireGuard-VPN-IP des Nodes\n";
    $content .= "> - **Sekundär/SSH Tunnel**: Fallback-Mechanismus (z. B. Reverse-Tunnel)\n";
    $content .= "> - **StatusVPN**: Verbunden über OpenClaw/WireGuard\n";
    $content .= "> - **StatusSSH**: SSH-Zugriff via Reverse-Tunnel aktiv\n";
    $content .= "> - **SSH Key (Deployed)**: Zeigt an, ob der Gateway-Schlüssel (`id_ed25519`) auf dem Ziel bereitgestellt ist\n";
    $content .= "> - Letzter Stand: **${now} CET**\n\n";
    $content .= "*Größe: ~1.8 KB | Automatisch aktualisiert via `update-nodes-report.js`*\n";

    open(my $fh, '>:encoding(UTF-8)', $DASHBOARD_PATH) or do {
        print $C{red} . "❌ Fehler beim Schreiben der Datei:" . $C{reset} . " $!\n";
        return;
    };
    print $fh $content;
    close $fh;
    print $C{green} . "✅ Dashboard aktualisiert:" . $C{reset} . " $DASHBOARD_PATH\n";
}

# Hauptausführung
print $C{blue} . "🔄 Aktualisiere Nodes-Übersicht..." . $C{reset} . "\n";
my $nodes = getNodeStatus();
updateDashboard($nodes);
