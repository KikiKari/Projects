#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "61185a6c3aaba77845cf2f451d9119e45e88d3047a081760bd8538b1f9b1b516", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "perl5"}
# channel_status.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $LOGS_DB = "$WORKSPACE/db/logs.db";
my $CONFIG_FILE = "$WORKSPACE/config/channel-status.json";
my $LOG_FILE = "$WORKSPACE/logs/channel-status.log";

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    open(my $fh, '>>', $LOG_FILE) or die "Could not open log file: $!";
    print $fh $entry;
    close($fh);
}

sub get_system_status {
    my %status = (
        timestamp => strftime('%Y-%m-%dT%H:%M:%S', localtime),
        nodes => {},
        agents => {},
        system => {}
    );
    
    # Node-Status (vereinfacht)
    my %nodes = (
        node1 => { name => "Gateway", status => "online" },
        node2 => { name => "Worker", status => "online" },
        node3 => { name => "Relay", status => "offline", reason => "disk full" },
        node5 => { name => "Redmi", status => "intermittent" },
        node7 => { name => "Docker", status => "planned" }
    );
    $status{nodes} = \%nodes;
    
    # Agent-Status aus Cron
    my $cron_result = `crontab -l 2>/dev/null`;
    if ($? == 0) {
        my @lines = grep { !/^#/ } split(/\n/, $cron_result);
        $status{agents}->{active_crons} = scalar(@lines);
    } else {
        $status{agents}->{active_crons} = "unknown";
    }
    
    # System-Metriken
    eval {
        # Disk usage
        my $df_output = `df -h / 2>/dev/null`;
        for my $line (split(/\n/, $df_output)) {
            if ($line =~ m|/| && $line =~ /%/) {
                my @parts = split(/\s+/, $line);
                $status{system}->{disk_used} = $parts[4];
                last;
            }
        }
        
        # RAM usage
        my $free_output = `free -h 2>/dev/null`;
        for my $line (split(/\n/, $free_output)) {
            if ($line =~ /Mem:/) {
                my @parts = split(/\s+/, $line);
                $status{system}->{ram_total} = $parts[1];
                $status{system}->{ram_used} = $parts[2];
                last;
            }
        }
    };
    
    return \%status;
}

sub format_daily_status {
    my ($status) = @_;
    my $nodes = $status->{nodes};
    my $online = 0;
    for my $info (values %$nodes) {
        $online++ if $info->{status} eq "online";
    }
    
    my $message = "📊 **Täglicher Status-Report**\n";
    $message .= "🗓️ " . strftime('%Y-%m-%d %H:%M', localtime) . "\n\n";
    $message .= "**🖥️ Nodes ($online/5 online):**\n";
    
    for my $node_id (sort keys %$nodes) {
        my $info = $nodes->{$node_id};
        my $emoji = $info->{status} eq "online" ? "🟢" : 
                   ($info->{status} eq "offline" ? "🔴" : "🟡");
        $message .= "$emoji $info->{name}: $info->{status}";
        if (exists $info->{reason}) {
            $message .= " ($info->{reason})";
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
    my $week_number = strftime('%V', localtime);
    my $year = strftime('%Y', localtime);
    
    my $message = "📈 **Wöchentlicher Report**\n";
    $message .= "📅 Woche $week_number - $year\n\n";
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
    
    if ($channel_type eq "telegram") {
        # Nutze OpenClaw message tool
        my @cmd = ("openclaw", "message", "send", "--target", $channel_id, "--message", $message);
        system(@cmd) == 0 or do {
            log_message("Failed to send message: $!", "ERROR");
            return 0;
        };
        log_message("Message sent to $channel_type $channel_id");
        return 1;
    } else {
        log_message("Channel type $channel_type not implemented", "WARN");
        return 0;
    }
}

sub main {
    use Getopt::Long;
    
    my $type;
    my $message;
    my $channel = "-1002381931352";
    my $dry_run = 0;
    
    GetOptions(
        "type=s" => \$type,
        "message=s" => \$message,
        "channel=s" => \$channel,
        "dry-run" => \$dry_run
    ) or die "Invalid options\n";
    
    die "Type is required\n" unless $type;
    die "Invalid type. Choose from: daily, weekly, alert\n" 
        unless $type =~ /^(daily|weekly|alert)$/;
    
    log_message("Starting $type status update");
    
    # Status sammeln
    my $status = get_system_status();
    
    # Message formatieren
    my $formatted_message;
    if ($type eq 'daily') {
        $formatted_message = format_daily_status($status);
    } elsif ($type eq 'weekly') {
        $formatted_message = format_weekly_status($status);
    } elsif ($type eq 'alert') {
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
    
    log_message("Status update completed");
}

# Create log directory if it doesn't exist
my ($log_dir) = $LOG_FILE =~ m|^(.+)/|;
make_path($log_dir) unless -d $log_dir;

main();
