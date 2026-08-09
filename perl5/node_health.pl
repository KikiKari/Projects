#!/usr/bin/perl
# node_health.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/node-health-monitor/scripts/node_health.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::Basename;
use Time::Piece;
use IPC::Run3;

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $HEALTH_DB = "$WORKSPACE/db/health.db";
my $LOG_FILE = "$WORKSPACE/logs/node-health.log";

# Node-Definitionen
my %NODES = (
    "node1" => {
        "name" => "Gateway",
        "host" => "localhost",
        "user" => "openclaw",
        "critical" => 1
    },
    "node2" => {
        "name" => "Worker", 
        "host" => "100.92.155.34",
        "user" => "root",
        "ssh_key" => "~/.ssh/id_rsa"
    },
    "node3" => {
        "name" => "Relay",
        "host" => "185.242.xxx.xxx",
        "user" => "root",
        "disk_warning" => 85
    },
    "node5" => {
        "name" => "Redmi",
        "host" => "192.168.1.x",
        "user" => "openclaw",
        "optional" => 1
    }
);

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $entry = "[$timestamp] [$level] $message\n";
    print $entry;
    
    my $log_dir = dirname($LOG_FILE);
    make_path($log_dir) unless -d $log_dir;
    
    open(my $fh, '>>', $LOG_FILE) or die "Could not open log file: $!";
    print $fh $entry;
    close $fh;
}

sub check_ping {
    my ($host, $timeout) = @_;
    $timeout //= 5;
    
    my @cmd = ('ping', '-c', '1', '-W', $timeout, $host);
    my ($stdout, $stderr);
    my $result = run3(\@cmd, \undef, \$stdout, \$stderr);
    
    return $result == 0;
}

sub check_ssh {
    my ($node_config) = @_;
    my $host = $node_config->{"host"};
    my $user = $node_config->{"user"} // "root";
    
    my @cmd = ('ssh', '-o', 'ConnectTimeout=10', '-o', 'BatchMode=yes',
               "$user\@$host", 'echo "OK"');
    
    my ($stdout, $stderr);
    my $result = run3(\@cmd, \undef, \$stdout, \$stderr);
    
    return $result == 0 && $stdout =~ /OK/;
}

sub get_node_metrics {
    my ($node_config) = @_;
    my $host = $node_config->{"host"};
    my $user = $node_config->{"user"} // "root";
    
    my %metrics = (
        "timestamp" => localtime->datetime,
        "available" => 0,
        "cpu" => undef,
        "ram" => undef,
        "disk" => undef,
        "load" => undef
    );
    
    # SSH-Command für alle Metriken
    my $cmd = qq(ssh -o ConnectTimeout=10 $user\@$host '
        # CPU
        echo "CPU:\$(top -bn1 | grep "Cpu(s)" | awk "{print \\\$2}" | cut -d"%" -f1)"
        
        # RAM
        echo "RAM:\$(free | grep Mem | awk "{print (\\\$3/\\\$2) * 100.0}")"
        
        # Disk
        echo "DISK:\$(df -h / | tail -1 | awk "{print \\\$5}" | tr -d "%")"
        
        # Load
        echo "LOAD:\$(uptime | awk -F"load average:" "{print \\\$2}" | awk "{print \\\$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    ');
    
    my ($stdout, $stderr);
    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm 15;
        my $result = run3($cmd, \undef, \$stdout, \$stderr);
        alarm 0;
        
        if ($result == 0) {
            $metrics{"available"} = 1;
            
            for my $line (split /\n/, $stdout) {
                if ($line =~ /:/) {
                    my ($key, $value) = split /:/, $line, 2;
                    if ($key eq "CPU") {
                        $metrics{"cpu"} = $value + 0;
                    } elsif ($key eq "RAM") {
                        $metrics{"ram"} = $value + 0;
                    } elsif ($key eq "DISK") {
                        $metrics{"disk"} = int($value);
                    } elsif ($key eq "LOAD") {
                        $metrics{"load"} = $value + 0;
                    } elsif ($key eq "GATEWAY") {
                        $metrics{"gateway_status"} = $value;
                    }
                }
            }
        }
    };
    
    if ($@) {
        if ($@ eq "timeout") {
            log_message("SSH timeout for " . $node_config->{"name"}, "WARN");
        } else {
            log_message("Error checking " . $node_config->{"name"} . ": $@", "ERROR");
        }
    }
    
    return \%metrics;
}

sub check_alerts {
    my ($node_id, $node_config, $metrics) = @_;
    my @alerts = ();
    
    # Verfügbarkeit
    if (!$metrics->{"available"}) {
        if (!$node_config->{"optional"}) {
            push @alerts, {
                "level" => "CRITICAL",
                "message" => "Node " . $node_config->{"name"} . " nicht erreichbar!"
            };
        }
    } else {
        # CPU
        if (defined $metrics->{"cpu"} && $metrics->{"cpu"} > 90) {
            push @alerts, {
                "level" => "WARNING",
                "message" => "Node " . $node_config->{"name"} . ": CPU bei " . sprintf("%.1f", $metrics->{"cpu"}) . "%"
            };
        }
        
        # RAM
        if (defined $metrics->{"ram"} && $metrics->{"ram"} > 90) {
            push @alerts, {
                "level" => "WARNING", 
                "message" => "Node " . $node_config->{"name"} . ": RAM bei " . sprintf("%.1f", $metrics->{"ram"}) . "%"
            };
        }
        
        # Disk
        my $disk_threshold = $node_config->{"disk_warning"} // 85;
        if (defined $metrics->{"disk"} && $metrics->{"disk"} > $disk_threshold) {
            my $level = $metrics->{"disk"} > 95 ? "CRITICAL" : "WARNING";
            push @alerts, {
                "level" => $level,
                "message" => "Node " . $node_config->{"name"} . ": Disk bei " . $metrics->{"disk"} . "%"
            };
        }
        
        # Gateway
        if ($node_config->{"critical"} && $metrics->{"gateway_status"} && $metrics->{"gateway_status"} eq "inactive") {
            push @alerts, {
                "level" => "CRITICAL",
                "message" => "Node " . $node_config->{"name"} . ": OpenClaw Gateway nicht aktiv!"
            };
        }
    }
    
    return @alerts;
}

sub send_alert {
    my ($alert) = @_;
    
    eval {
        my @cmd = (
            "python3",
            "$WORKSPACE/skills/channel-status-agent/scripts/channel_status.py",
            "--type", "alert",
            "--message", $alert->{"level"} . ": " . $alert->{"message"}
        );
        run3(\@cmd, \undef, \undef, \undef);
        log_message("Alert sent: " . $alert->{"message"});
    };
    
    if ($@) {
        log_message("Failed to send alert: $@", "ERROR");
    }
}

sub main {
    use Getopt::Long;
    
    my $node = 'all';
    my $check = 'all';
    my $alert_flag = 0;
    
    GetOptions(
        'node=s' => \$node,
        'check=s' => \$check,
        'alert' => \$alert_flag
    ) or die "Falsche Optionen\n";
    
    # Nodes bestimmen
    my @nodes_to_check;
    if ($node eq 'all') {
        @nodes_to_check = %NODES;
    } else {
        if (exists $NODES{$node}) {
            @nodes_to_check = ($node, $NODES{$node});
        } else {
            log_message("Unknown node: $node", "ERROR");
            exit 1;
        }
    }
    
    # Health-Checks durchführen
    my @all_alerts = ();
    
    for my $i (0..$#nodes_to_check) {
        next if $i % 2 == 1;  # Skip values, only process keys
        my $node_id = $nodes_to_check[$i];
        my $node_config = $nodes_to_check[$i+1];
        
        log_message("Checking " . $node_config->{"name"} . " ($node_id)");
        
        # Ping
        if ($check eq 'ping' || $check eq 'all') {
            if ($node_config->{"host"} ne "localhost") {
                my $ping_ok = check_ping($node_config->{"host"});
                log_message("  Ping: " . ($ping_ok ? "OK" : "FAILED"));
            }
        }
        
        # SSH
        if ($check eq 'ssh' || $check eq 'all') {
            my $ssh_ok = check_ssh($node_config);
            log_message("  SSH: " . ($ssh_ok ? "OK" : "FAILED"));
        }
        
        # Metriken
        if ($check eq 'metrics' || $check eq 'all') {
            my $metrics = get_node_metrics($node_config);
            
            if ($metrics->{"available"}) {
                log_message("  CPU: " . (defined $metrics->{"cpu"} ? sprintf("%.1f", $metrics->{"cpu"}) . "%" : "N/A"));
                log_message("  RAM: " . (defined $metrics->{"ram"} ? sprintf("%.1f", $metrics->{"ram"}) . "%" : "N/A"));
                log_message("  Disk: " . (defined $metrics->{"disk"} ? $metrics->{"disk"} . "%" : "N/A"));
                log_message("  Load: " . (defined $metrics->{"load"} ? $metrics->{"load"} : "N/A"));
            } else {
                log_message("  Metrics: UNAVAILABLE");
            }
            
            # Alerts prüfen
            my @alerts = check_alerts($node_id, $node_config, $metrics);
            push @all_alerts, @alerts;
        }
    }
    
    # Alerts senden
    if ($alert_flag && @all_alerts) {
        log_message("\nSending " . scalar(@all_alerts) . " alerts...");
        for my $alert (@all_alerts) {
            send_alert($alert);
        }
    } elsif (@all_alerts) {
        log_message("\n" . scalar(@all_alerts) . " alerts found (use --alert to send)");
    } else {
        log_message("\nAll nodes healthy!");
    }
}

main() if __FILE__ eq $0;
