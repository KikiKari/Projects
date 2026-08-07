#!/usr/bin/perl
# check_nodes.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use POSIX qw(strftime);
use Getopt::Long;
use IPC::Run3 qw(run3);

# Node-Konfiguration (sollte aus config file geladen werden)
my %NODES = (
    "node1" => {
        "always_available" => 1,
        "capacity" => "medium",
        "priority" => 2,
        "description" => "Gateway-Master"
    },
    "node2" => {
        "always_available" => 1,
        "capacity" => "medium",
        "priority" => 3,
        "description" => "Stable Worker"
    },
    "node3" => {
        "always_available" => 0,
        "capacity" => "medium",
        "priority" => 4,
        "description" => "Bald verfügbar (nach Reorganisation)"
    },
    "node5" => {
        "always_available" => 0,
        "capacity" => "low",
        "priority" => 5,
        "device" => "Redmi Note 11S",
        "description" => "Mobile (bei Internet verfügbar)"
    },
    "node7" => {
        "always_available" => 1,
        "capacity" => "high",
        "priority" => 1,
        "description" => "Docker Hauptarbeitspferd (bald verfügbar)"
    },
);

sub check_node_status {
    my ($node_id) = @_;
    
    my $config = $NODES{$node_id};
    
    my ($stdout, $stderr, $exit_code);
    my @cmd = ("openclaw", "nodes", "status", $node_id);
    
    eval {
        local $SIG{ALRM} = sub { die "timeout" };
        alarm(5);
        run3(\@cmd, \$stdout, \$stderr, \$exit_code);
        alarm(0);
    };
    
    if ($@ && $@ eq "timeout") {
        return {
            "id" => $node_id,
            "online" => 0,
            "available" => $config->{"always_available"} // 0,
            "response" => "Timeout"
        };
    } elsif ($@) {
        return {
            "id" => $node_id,
            "online" => 0,
            "available" => $config->{"always_available"} // 0,
            "response" => "Error: $@"
        };
    }
    
    my $is_online = ($exit_code == 0) && 
        (($stdout && $stdout =~ /online/i) || ($stdout && $stdout =~ /active/i));
    
    return {
        "id" => $node_id,
        "online" => $is_online ? 1 : 0,
        "available" => $config->{"always_available"} // 0,
        "response" => $stdout ? substr($stdout, 0, 100) : "No response"
    };
}

sub print_table {
    my ($nodes_status) = @_;
    
    print "\n" . "=" x 90 . "\n";
    printf "%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung";
    print "=" x 90 . "\n";
    
    for my $status (@$nodes_status) {
        my $node_id = $status->{"id"};
        my $config = $NODES{$node_id};
        
        my $status_icon = $status->{"online"} ? "🟢 Online" : "🔴 Offline";
        my $avail_icon = $status->{"available"} ? "✅ Immer" : "📱 Bedingt";
        my $capacity = $config->{"capacity"} // "unknown";
        my $priority = $config->{"priority"} // "-";
        my $device = $config->{"device"} // $config->{"description"} // "";
        
        printf "%-8s %-12s %-12s %-10s %-10s %s\n", $node_id, $status_icon, $avail_icon, $capacity, $priority, $device;
    }
    
    print "=" x 90 . "\n";
    print "\nGeprüft am: " . strftime("%Y-%m-%d %H:%M:%S", localtime()) . "\n";
}

sub print_json {
    my ($nodes_status) = @_;
    
    my %output = (
        "timestamp" => strftime("%Y-%m-%dT%H:%M:%S", localtime()),
        "nodes" => {}
    );
    
    for my $status (@$nodes_status) {
        my $node_id = $status->{"id"};
        $output{"nodes"}{$node_id} = {
            "status" => $status,
            "config" => $NODES{$node_id}
        };
    }
    
    print to_json(\%output, { pretty => 1 }) . "\n";
}

sub main {
    my $format = "table";
    my $save;
    
    GetOptions(
        "format|f=s" => \$format,
        "save|s=s" => \$save
    ) or die "Falsche Optionen\n";
    
    print "🔍 Prüfe Node-Status...\n";
    
    # Prüfe alle Nodes
    my @nodes_status;
    for my $node_id (sort keys %NODES) {
        print "  → $node_id... ";
        my $status = check_node_status($node_id);
        push @nodes_status, $status;
        print ($status->{"online"} ? "✓\n" : "✗\n");
    }
    
    # Ausgabe
    if ($format eq "table") {
        print_table(\@nodes_status);
    } else {
        print_json(\@nodes_status);
    }
    
    # Speichern
    if ($save) {
        my %output = (
            "timestamp" => strftime("%Y-%m-%dT%H:%M:%S", localtime()),
            "nodes" => {}
        );
        
        for my $status (@nodes_status) {
            $output{"nodes"}{$status->{"id"}} = $status;
        }
        
        open my $fh, ">", $save or die "Kann $save nicht öffnen: $!";
        print $fh to_json(\%output, { pretty => 1 });
        close $fh;
        print "\n💾 Gespeichert: $save\n";
    }
    
    # Zusammenfassung
    my $online_count = 0;
    for my $status (@nodes_status) {
        $online_count++ if $status->{"online"};
    }
    print "\n📊 Zusammenfassung: $online_count/" . scalar(@nodes_status) . " Nodes online\n";
}

main() if __FILE__ eq $0;
