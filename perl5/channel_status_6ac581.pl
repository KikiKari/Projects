#!/usr/bin/env perl
# channel_status.sh — portiert nach perl5
# Quelle: shell, Projects@abstractions:shell/channel_status.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use POSIX qw(strftime);

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $LOGS_DB = "$WORKSPACE/db/logs.db";
my $CONFIG_FILE = "$WORKSPACE/config/channel-status.json";
my $LOG_FILE = "$WORKSPACE/logs/channel-status.log";

# Logging
sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $entry = "[${timestamp}] [${level}] ${message}";
    print "${entry}\n";
    open(my $fh, '>>', $LOG_FILE) or die "Could not open file '$LOG_FILE' $!";
    print $fh "${entry}\n";
    close $fh;
}

# Sammelt System-Status
sub get_system_status {
    my $status = {
        timestamp => strftime('%Y-%m-%dT%H:%M:%S%z', localtime),
        nodes => {
            node1 => { name => "Gateway", status => "online" },
            node2 => { name => "Worker", status => "online" },
            node3 => { name => "Relay", status => "offline", reason => "disk full" },
            node5 => { name => "Redmi", status => "intermittent" },
            node7 => { name => "Docker", status => "planned" }
        },
        agents => {},
        system => {}
    };

    # Agent-Status aus Cron
    my $cron_lines = `crontab -l 2>/dev/null | grep -v '^#' | wc -l`;
    chomp($cron_lines);
    $cron_lines = "unknown" if $? != 0;
    $status->{agents}->{active_crons} = $cron_lines;

    # System-Metriken
    my $disk_output = `df -h / | awk 'NR==2 {print \$5}'`;
    chomp($disk_output);
    $status->{system}->{disk_used} = $disk_output;

    my $ram_output = `free -h | awk 'NR==2 {print \$2" "\$3}'`;
    chomp($ram_output);
    my ($ram_total, $ram_used) = split(' ', $ram_output);
    $status->{system}->{ram_total} = $ram_total;
    $status->{system}->{ram_used} = $ram_used;

    return encode_json($status);
}

# Formatiert täglichen Status
sub format_daily_status {
    my ($status_json) = @_;
    my $status = decode_json($status_json);
    my $message = "";
    $message .= "📊 **Täglicher Status-Report**\n";
    $message .= strftime('🗓️ %Y-%m-%d %H:%M', localtime) . "\n\n";

    my $online_count = 0;
    for my $node (values %{$status->{nodes}}) {
        $online_count++ if $node->{status} eq "online";
    }
    $message .= "**🖥️ Nodes (**${online_count}/5 online):\n";

    for my $node_id (sort keys %{$status->{nodes}}) {
        my $node = $status->{nodes}->{$node_id};
        my $emoji = "";
        if ($node->{status} eq "online") {
            $emoji = "🟢";
        } elsif ($node->{status} eq "offline") {
            $emoji = "🔴";
        } else {
            $emoji = "🟡";
        }
        $message .= "${emoji} $node->{name}: $node->{status}";
        if (exists $node->{reason} && defined $node->{reason} && $node->{reason} ne "") {
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

# Formatiert wöchentlichen Status
sub format_weekly_status {
    my $message = "";
    $message .= "📈 **Wöchentlicher Report**\n";
    $message .= strftime('📅 Woche %V - %Y', localtime) . "\n\n";

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

# Sendet Nachricht an Channel
sub send_to_channel {
    my ($message, $channel_type, $channel_id) = @_;
    $channel_type //= "telegram";
    $channel_id //= "-1002381931352";

    if ($channel_type eq "telegram") {
        my @cmd = ("openclaw", "message", "send", "--target", $channel_id, "--message", $message);
        system(@cmd) == 0
            or do {
                log_message("Failed to send message", "ERROR");
                return 0;
            };
        log_message("Message sent to ${channel_type} ${channel_id}");
        return 1;
    } else {
        log_message("Channel type ${channel_type} not implemented", "WARN");
        return 0;
    }
}

# Hauptfunktion
sub main {
    my %args = (
        type => "",
        message => "",
        channel => "-1002381931352",
        dry_run => 0
    );

    # Argumente parsen
    while (@ARGV) {
        my $arg = shift @ARGV;
        if ($arg eq "--type") {
            $args{type} = shift @ARGV;
        } elsif ($arg eq "--message") {
            $args{message} = shift @ARGV;
        } elsif ($arg eq "--channel") {
            $args{channel} = shift @ARGV;
        } elsif ($arg eq "--dry-run") {
            $args{dry_run} = 1;
        } else {
            print STDERR "Unbekannte Option: $arg\n";
            exit 1;
        }
    }

    if (!$args{type}) {
        print STDERR "Fehler: --type ist erforderlich\n";
        exit 1;
    }

    log_message("Starting $args{type} status update");

    # Status sammeln
    my $status = get_system_status();

    # Message formatieren
    my $formatted_message = "";
    if ($args{type} eq "daily") {
        $formatted_message = format_daily_status($status);
    } elsif ($args{type} eq "weekly") {
        $formatted_message = format_weekly_status();
    } elsif ($args{type} eq "alert") {
        $formatted_message = "🚨 **ALERT**\n" . ($args{message} || "Manual alert");
    } else {
        print STDERR "Unbekannter Typ: $args{type}\n";
        exit 1;
    }

    # Senden oder Dry-Run
    if ($args{dry_run}) {
        print "\n--- DRY RUN ---\n";
        print $formatted_message;
        print "\n--- END ---\n\n";
    } else {
        send_to_channel($formatted_message, "telegram", $args{channel});
    }

    log_message("Status update completed");
}

# Sicherstellen, dass das Log-Verzeichnis existiert
make_path(dirname($LOG_FILE));

# Hauptfunktion aufrufen
main();
