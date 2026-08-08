#!/usr/bin/perl
# channel_status.js — portiert nach perl5
# Quelle: javascript, Projects@abstractions:javascript/channel_status.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use File::Basename;
use JSON;
use POSIX qw(strftime);

# channel_status.py — portiert nach javascript
# Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
# auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Channel Status Agent - Automatische Status-Updates

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $LOGS_DB = "$WORKSPACE/db/logs.db";
my $CONFIG_FILE = "$WORKSPACE/config/channel-status.json";
my $LOG_FILE = "$WORKSPACE/logs/channel-status.log";

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    # Logging
    my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    open(my $fh, '>>', $LOG_FILE) or die "Could not open file '$LOG_FILE' $!";
    print $fh $entry;
    close $fh;
}

sub get_system_status {
    # Sammelt System-Status
    my %status = (
        timestamp => strftime("%Y-%m-%dT%H:%M:%SZ", gmtime),
        nodes => {},
        agents => {},
        system => {}
    );
    
    # Node-Status (vereinfacht)
    my %nodes = (
        "node1" => {"name" => "Gateway", "status" => "online"},
        "node2" => {"name" => "Worker", "status" => "online"},
        "node3" => {"name" => "Relay", "status" => "offline", "reason" => "disk full"},
        "node5" => {"name" => "Redmi", "status" => "intermittent"},
        "node7" => {"name" => "Docker", "status" => "planned"}
    );
    $status{nodes} = \%nodes;
    
    # Agent-Status aus Cron
    my $cron_result = `crontab -l 2>/dev/null`;
    if ($? == 0) {
        my @lines = grep { $_ && !/^\s*#/ } split /\n/, $cron_result;
        $status{agents}{active_crons} = scalar @lines;
    } else {
        $status{agents}{active_crons} = "unknown";
    }
    
    # System-Metriken
    eval {
        # Disk usage
        my $df = `df -h / 2>/dev/null`;
        for my $line (split /\n/, $df) {
            if ($line =~ m|/$| && $line =~ /%/) {
                my @parts = split /\s+/, $line;
                $status{system}{disk_used} = $parts[4];
                last;
            }
        }
        
        # RAM usage
        my $free = `free -h 2>/dev/null`;
        for my $line (split /\n/, $free) {
            if ($line =~ /^Mem:/) {
                my @parts = split /\s+/, $line;
                $status{system}{ram_total} = $parts[1];
                $status{system}{ram_used} = $parts[2];
                last;
            }
        }
    };
    
    return \%status;
}

sub format_daily_status {
    my ($status) = @_;
    # Formatiert täglichen Status
    my $nodes = $status->{nodes};
    my $online_count = 0;
    for my $node (values %$nodes) {
        if ($node->{status} eq "online") {
            $online_count++;
        }
    }
    
    my $timestamp = strftime "%d.%m.%Y %H:%M", localtime;
    
    my $message = "📊 **Täglicher Status-Report**
🗓️ $timestamp

**🖥️ Nodes ($online_count/5 online):**
";
    
    for my $node_id (sort keys %$nodes) {
        my $info = $nodes->{$node_id};
        my $emoji = $info->{status} eq "online" ? "🟢" : 
                   ($info->{status} eq "offline" ? "🔴" : "🟡");
        $message .= "$emoji $info->{name}: $info->{status}";
        if ($info->{reason}) {
            $message .= " ($info->{reason})";
        }
        $message .= "\n";
    }
    
    $message .= "\n**🤖 Agents:**\n";
    $message .= "Aktive Cron-Jobs: $status->{agents}{active_crons}\n";
    
    if ($status->{system}{disk_used}) {
        $message .= "\n**💾 System:**\n";
        $message .= "Disk: $status->{system}{disk_used} belegt\n";
        $message .= "RAM: $status->{system}{ram_used} / $status->{system}{ram_total}\n";
    }
    
    return $message;
}

sub format_weekly_status {
    # Formatiert wöchentlichen Status
    my $now = time;
    my $year = (localtime)[5] + 1900;
    my $jan1 = timelocal(0, 0, 0, 1, 0, $year - 1900);
    my $days = int(($now - $jan1) / (24 * 60 * 60));
    my $week_number = int(($days + (localtime($jan1))[6] + 1) / 7) + 1;
    $week_number = sprintf "%02d", $week_number;
    
    return "📈 **Wöchentlicher Report**
📅 Woche $week_number - $year

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
";
}

sub send_to_channel {
    my ($message, $channel_type, $channel_id) = @_;
    $channel_type //= "telegram";
    $channel_id //= "-1002381931352";
    # Sendet Nachricht an Channel
    my $cmd;
    if ($channel_type eq "telegram") {
        # Nutze OpenClaw message tool
        $message =~ s/"/\\"/g;
        $cmd = "openclaw message send --target $channel_id --message \"$message\"";
    } else {
        log_message("Channel type $channel_type not implemented", "WARN");
        return 0;
    }
    
    my $result = system($cmd);
    if ($result == 0) {
        log_message("Message sent to $channel_type $channel_id");
        return 1;
    } else {
        log_message("Failed to send: $!", "ERROR");
        return 0;
    }
}

sub main {
    # Hauptfunktion
    use Getopt::Long;
    my %args;
    GetOptions(\%args,
        "type=s",
        "message=s",
        "channel=s",
        "dry-run"
    ) or die "Error in command line arguments\n";
    
    if (!$args{type} || ($args{type} ne "daily" && $args{type} ne "weekly" && $args{type} ne "alert")) {
        die "Usage: $0 --type [daily|weekly|alert] [options]
Options:
  --type TYPE       Type of status update (daily|weekly|alert)
  --message MSG     Alert message
  --channel ID      Channel ID (default: -1002381931352)
  --dry-run         Show message without sending
";
    }
    
    log_message("Starting $args{type} status update");
    
    # Status sammeln
    my $status = get_system_status();
    
    # Message formatieren
    my $message;
    if ($args{type} eq 'daily') {
        $message = format_daily_status($status);
    } elsif ($args{type} eq 'weekly') {
        $message = format_weekly_status();
    } elsif ($args{type} eq 'alert') {
        $message = "🚨 **ALERT**\n" . ($args{message} || 'Manual alert');
    }
    
    # Senden oder Dry-Run
    if ($args{'dry-run'}) {
        print "\n--- DRY RUN ---\n";
        print $message;
        print "\n--- END ---\n";
    } else {
        send_to_channel($message, "telegram", $args{channel} // "-1002381931352");
    }
    
    log_message("Status update completed");
}

# Ensure log directory exists
my $log_dir = dirname($LOG_FILE);
unless (-d $log_dir) {
    make_path($log_dir) or die "Failed to create directory $log_dir: $!";
}

main();
