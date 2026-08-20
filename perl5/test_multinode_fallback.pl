#!/usr/bin/perl
# test_multinode_fallback.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/test_multinode_fallback.py
# auch in: OpenClaw@gateway2:scripts/test_multinode_fallback.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use IPC::Run3;
use File::Spec;
use Cwd qw(abs_path);

# Testet Multi-Node Fallback-Logik des db-maintainer
# Simuliert: Worker-Node nicht erreichbar → Fallback auf lokal

my $WORKSPACE = "/home/openclaw/.openclaw/workspace";

sub check_node_reachable {
    my ($node_id) = @_;
    # Prüft ob Node erreichbar ist
    eval {
        my ($stdout, $stderr);
        run3(['openclaw', 'nodes', 'status'], \undef, \$stdout, \$stderr);
        if (index($stdout, $node_id) != -1 && index($stdout, 'connected') != -1) {
            return 1;
        }
    };
    return 0;
}

sub spawn_on_node {
    my ($node_id, $task) = @_;
    # Versucht Task auf Node auszuführen
    print "Versuche Task auf Node $node_id zu starten...\n";
    eval {
        my ($stdout, $stderr);
        run3(['echo', "Spawned on $node_id: $task"], \undef, \$stdout, \$stderr);
        print "✅ Erfolgreich delegiert an $node_id\n";
        return 1;
    };
    if ($@) {
        print "❌ Node $node_id nicht erreichbar: $@\n";
        return 0;
    }
}

sub execute_locally {
    my ($task) = @_;
    # Führt Task lokal aus (Fallback)
    print "🔄 Fallback: Führe Task lokal aus...\n";
    eval {
        if ($task eq 'db_maintainer') {
            my $script_path = File::Spec->catfile($WORKSPACE, 'skills', 'db-maintainer', 'scripts', 'db_maintainer.py');
            my ($stdout, $stderr);
            run3(['python3', $script_path], \undef, \$stdout, \$stderr);
            if ($? == 0) {
                print "✅ Lokale Ausführung erfolgreich\n";
                return 1;
            } else {
                my $err_msg = substr($stderr, 0, 200);
                print "❌ Fehler: $err_msg\n";
                return 0;
            }
        }
    };
    if ($@) {
        print "❌ Lokale Ausführung fehlgeschlagen: $@\n";
        return 0;
    }
}

sub main {
    print "=" x 60 . "\n";
    print "MULTI-NODE FALLBACK TEST\n";
    print "=" x 60 . "\n\n";
    
    # Konfiguration
    my $primary_node = 'v2202603104722445775';  # Node 2
    my $task = 'db_maintainer';
    
    print "Primärer Node: $primary_node\n";
    print "Task: $task\n\n";
    
    # 1. Prüfe Node-Erreichbarkeit
    print "--- 1. Prüfe Node-Erreichbarkeit ---\n";
    if (check_node_reachable($primary_node)) {
        print "✅ Node $primary_node ist erreichbar\n";
        
        # 2. Versuche Delegation
        print "\n--- 2. Versuche Delegation ---\n";
        if (spawn_on_node($primary_node, $task)) {
            print "\n✅ MULTI-NODE: Task erfolgreich delegiert\n";
            return 0;
        } else {
            print "\n⚠️ Delegation fehlgeschlagen, aktiviere Fallback...\n";
        }
    } else {
        print "❌ Node $primary_node nicht erreichbar\n";
        print "🔄 Fallback wird aktiviert...\n";
    }
    
    # 3. Lokale Ausführung (Fallback)
    print "\n--- 3. Lokale Ausführung (Fallback) ---\n";
    if (execute_locally($task)) {
        print "\n✅ FALLBACK: Task lokal erfolgreich ausgeführt\n";
        return 0;
    } else {
        print "\n❌ FEHLER: Weder Delegation noch Fallback erfolgreich\n";
        return 1;
    }
}

exit(main());
