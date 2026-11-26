#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "2cfe2aff715df8e319981187bcea732b34ed3c97e4d7ef02df2bef5f2616d459", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "perl5"}
# check_nodes.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use JSON qw(encode_json decode_json);
use Getopt::Long;
use POSIX qw(strftime);

binmode(STDOUT, ':utf8');

# Node-Konfiguration (sollte aus config file geladen werden)
my $NODES = {
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
};

sub check_node_status {
    my ($node_id) = @_;
    
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(5);
        
        open(my $fh, '-|', "openclaw nodes status $node_id 2>&1") or die "Failed to run command: $!";
        my $output = do { local $/; <$fh> };
        close($fh);
        my $exit_code = $?;
        alarm(0);
        
        my $is_online = ($exit_code == 0) && ($output =~ /online/i || $output =~ /active/i);
        
        return {
            "id" => $node_id,
            "online" => $is_online,
            "available" => $NODES->{$node_id}->{"always_available"} // 0,
            "response" => substr($output // "", 0, 100) || "No response"
        };
    };
    
    if ($@) {
        alarm(0);
        if ($@ eq "timeout\n") {
            return {
                "id" => $node_id,
                "online" => 0,
                "available" => $NODES->{$node_id}->{"always_available"} // 0,
                "response" => "Timeout"
            };
        } else {
            chomp($@);
            return {
                "id" => $node_id,
                "online" => 0,
                "available" => $NODES->{$node_id}->{"always_available"} // 0,
                "response" => "Error: $@"
            };
        }
    }
}

sub print_table {
    my ($nodes_status) = @_;
    
    print "\n" . "=" x 90 . "\n";
    printf "%-8s %-12s %-12s %-10s %-10s %s\n", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung";
    print "=" x 90 . "\n";
    
    for my $status (@$nodes_status) {
        my $node_id = $status->{"id"};
        my $config = $NODES->{$node_id};
        
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
    
    my $output = {
        "timestamp" => strftime("%Y-%m-%dT%H:%M:%S", localtime()),
        "nodes" => {}
    };
    
    for my $status (@$nodes_status) {
        my $node_id = $status->{"id"};
        $output->{"nodes"}->{$node_id} = {
            "status" => $status,
            "config" => $NODES->{$node_id}
        };
    }
    
    print encode_json($output) . "\n";
}

sub main {
    my $format = "table";
    my $save_file;
    
    GetOptions(
        "format|f=s" => \$format,
        "save|s=s"   => \$save_file
    ) or die "Falsche Optionen\n";
    
    print "🔍 Prüfe Node-Status...\n";
    
    # Prüfe alle Nodes
    my @nodes_status;
    for my $node_id (sort keys %$NODES) {
        print "  → $node_id... ";
        my $status = check_node_status($node_id);
        push @nodes_status, $status;
        print $status->{"online"} ? "✓\n" : "✗\n";
    }
    
    # Ausgabe
    if ($format eq "table") {
        print_table(\@nodes_status);
    } else {
        print_json(\@nodes_status);
    }
    
    # Speichern
    if ($save_file) {
        my $output = {
            "timestamp" => strftime("%Y-%m-%dT%H:%M:%S", localtime()),
            "nodes" => { map { $_->{"id"} => $_ } @nodes_status }
        };
        
        open(my $fh, '>', $save_file) or die "Konnte nicht schreiben nach $save_file: $!";
        print $fh encode_json($output);
        close($fh);
        print "\n💾 Gespeichert: $save_file\n";
    }
    
    # Zusammenfassung
    my $online_count = grep { $_->{"online"} } @nodes_status;
    print "\n📊 Zusammenfassung: $online_count/" . scalar(@nodes_status) . " Nodes online\n";
}

main() if __FILE__ eq $0;
