#!/usr/bin/env perl
# channel_status.ps1 — portiert nach perl5
# Quelle: powershell, Projects@abstractions:powershell/channel_status.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use JSON;
use POSIX qw(strftime);

# channel_status.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
my $HOME = $ENV{'HOME'};
my $WORKSPACE = File::Spec->catdir($HOME, ".openclaw", "workspace");
my $LOGS_DB = File::Spec->catfile($WORKSPACE, "db", "logs.db");
my $CONFIG_FILE = File::Spec->catfile($WORKSPACE, "config", "channel-status.json");
my $LOG_FILE = File::Spec->catfile($WORKSPACE, "logs", "channel-status.log");

sub write_log {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    open my $fh, '>>', $LOG_FILE or die "Kann Log-Datei nicht öffnen: $!";
    print $fh $entry;
    close $fh;
}

sub get_system_status {
    my $status = {
        timestamp => strftime('%Y-%m-%dT%H:%M:%S', localtime),
        nodes => {},
        agents => {},
        system => {}
    };

    # Node-Status (vereinfacht)
    my $nodes = {
        node1 => {name => "Gateway", status => "online"},
        node2 => {name => "Worker", status => "online"},
        node3 => {name => "Relay", status => "offline", reason => "disk full"},
        node5 => {name => "Redmi", status => "intermittent"},
        node7 => {name => "Docker", status => "planned"}
    };
    $status->{nodes} = $nodes;

    # Agent-Status aus Cron
    my $cron_result = `crontab -l 2>/dev/null`;
    if ($? == 0) {
        my @lines = split /\n/, $cron_result;
        my $count = grep { !/^\s*#/ } @lines;
        $status->{agents}->{active_crons} = $count;
    } else {
        $status->{agents}->{active_crons} = "unknown";
    }

    # System-Metriken
    eval {
        # Disk usage
        my $df_output = `df -h /`;
        for my $line (split /\n/, $df_output) {
            if ($line =~ m|/| && $line =~ /%/) {
                my @parts = split /\s+/, $line;
                $status->{system}->{disk_used} = $parts[4];
                last;
            }
        }

        # RAM usage
        my $free_output = `free -h`;
        for my $line (split /\n/, $free_output) {
            if ($line =~ /Mem:/) {
                my @parts = split /\s+/, $line;
                $status->{system}->{ram_total} = $parts[1];
                $status->{system}->{ram_used} = $parts[2];
                last;
            }
        }
    };
    # Ignoriere Fehler

    return $status;
}

sub format_daily_status {
    my ($status) = @_;
    my $nodes = $status->{nodes};
    my $online = scalar grep { $nodes->{$_}->{status} eq "online" } keys %$nodes;

    my $message = "📊 **Täglicher Status-Report**\n";
    $message .= "🗓️ " . strftime('%Y-%m-%d %H:%M', localtime) . "\n\n";
    $message .= "**🖥️ Nodes ($online/5 online):**\n";

    for my $key (sort keys %$nodes) {
        my $node = $nodes->{$key};
        my $emoji = $node->{status} eq "online" ? "🟢" :
                    $node->{status} eq "offline" ? "🔴" : "🟡";
        $message .= "$emoji $node->{name}: $node->{status}";
        if (exists $node->{reason}) {
            $message .= " ($node->{reason})";
        }
        $message .= "\n";
    }

    $message .= "\n**🤖 Agents:**\n";
    $message .= "Aktive Cron-Jobs: $status->{agents}->{active_crons}\n";

    if (exists $status->{system}->{disk_used}) {
        $message .= "\n**💾 System:**\n";
        $message .= "Disk: $status->{system}->{disk_used} belegt\n";
        $message .= "RAM: $status->{system}->{ram_used} / $status->{system}->{ram_total}\n";
    }

    return $message;
}

sub format_weekly_status {
    my ($status) = @_;
    my $message = "📈 **Wöchentlicher Report**\n";
    $message .= "📅 Woche " . strftime('%Y-\KW', localtime) . " - " . strftime('%Y', localtime) . "\n\n";
    $message .= "**Zusammenfassung:**\n";
    $message .= "- 5 aktive Sub-Agents\n";
    $message .= "- 11 Skills synchronisiert\n";
    $message .= "- 3 neue Features implementiert\n\n";
    $message .= "**Top-Ereignisse:**\n";
    $message .= "1. ClawHub-Git Sync implementiert ✅\n";
    $message .= "2. Node 3 Disk voll (95%) ⚠️\n";
    $message .= "3. Channel-Status-Agent aktiviert 🆕\n\n";
    $message .= "**Geplante Wartungen:**\n";
    $message .= "- Node 3: Disk-Cleanup erforderlich\n";
    $message .= "- Node 7: Docker-Setup ausstehend\n";
    return $message;
}

sub send_to_channel {
    my ($message, $channel_type, $channel_id) = @_;
    $channel_type //= "telegram";
    $channel_id //= "-1002381931352";

    my @cmd;
    if ($channel_type eq "telegram") {
        @cmd = ("openclaw", "message", "send", "--target", $channel_id, "--message", $message);
    } else {
        write_log("Channel type $channel_type not implemented", "WARN");
        return 0;
    }

    my $cmd_str = join(" ", @cmd);
    my $result = `$cmd_str 2>&1`;
    my $exit_code = $? >> 8;

    if ($exit_code == 0) {
        write_log("Message sent to $channel_type $channel_id");
        return 1;
    } else {
        write_log("Failed to send: $result", "ERROR");
        return 0;
    }
}

sub main {
    my %args = @_;
    my $type = $args{type};
    my $message = $args{message};
    my $channel = $args{channel} // "-1002381931352";
    my $dry_run = $args{dry_run} // 0;

    write_log("Starting $type status update");

    # Status sammeln
    my $status = get_system_status();

    # Message formatieren
    my $formatted_message;
    if ($type eq "daily") {
        $formatted_message = format_daily_status($status);
    } elsif ($type eq "weekly") {
        $formatted_message = format_weekly_status($status);
    } elsif ($type eq "alert") {
        $formatted_message = "🚨 **ALERT**\n" . ($message || "Manual alert");
    }

    # Senden oder Dry-Run
    if ($dry_run) {
        print "\n--- DRY RUN ---\n";
        print $formatted_message;
        print "\n--- END ---\n";
    } else {
        send_to_channel($formatted_message, "telegram", $channel);
    }

    write_log("Status update completed");
}

# Hauptprogramm

# Erstelle Log-Verzeichnis falls nicht vorhanden
my ($logfile_volume, $logfile_dir, $logfile_file) = File::Spec->splitpath($LOG_FILE);
my $logfile_dir_full = File::Spec->catpath($logfile_volume, $logfile_dir, '');
unless (-d $logfile_dir_full) {
    make_path($logfile_dir_full) or die "Kann Verzeichnis nicht erstellen: $!";
}

# Parameter parsen
my %params;
for (my $i = 0; $i < @ARGV; $i++) {
    if ($ARGV[$i] eq "--type") {
        $params{type} = $ARGV[++$i];
    } elsif ($ARGV[$i] eq "--message") {
        $params{message} = $ARGV[++$i];
    } elsif ($ARGV[$i] eq "--channel") {
        $params{channel} = $ARGV[++$i];
    } elsif ($ARGV[$i] eq "--dry-run") {
        $params{dry_run} = 1;
    }
}

unless (defined $params{type}) {
    die "Parameter --type ist erforderlich\n";
}

main(%params);
