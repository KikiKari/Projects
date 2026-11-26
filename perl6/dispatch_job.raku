#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "f074c8f00444b9f18be16e1025a81124a17edbb50b30fbbb7acc7bdc8ad13cc0", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "perl6"}
# dispatch_job.py — portiert nach perl6
# Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

# Node-Konfiguration
my %NODES = (
    node1 => { always_available => True, capacity => "medium", priority => 2 },
    node2 => { always_available => True, capacity => "medium", priority => 3 },
    node3 => { always_available => False, capacity => "medium", priority => 4 },
    node5 => { always_available => False, capacity => "low", priority => 5, device => "Redmi Note 11S" },
    node7 => { always_available => True, capacity => "high", priority => 1 },
);

class JobDispatcher {
    # Bewerte Job-Gewicht
    method get-job-weight($script-path, $target-langs-count = 1) {
        unless $script-path.IO.e {
            return "medium";
        }
        
        my $script-size = $script-path.IO.s;
        my $total-work = $script-size * $target-langs-count;
        
        if $total-work > 50000 {  # > 50KB
            return "heavy";
        } elsif $total-work > 10000 {  # > 10KB
            return "medium";
        } else {
            return "light";
        }
    }
    
    # Wähle besten Node basierend auf Job-Gewicht
    method select-node($job-weight) {
        my @preferred;
        
        if $job-weight eq "heavy" {
            # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
            @preferred = <node7 node2 node1>;
        } elsif $job-weight eq "medium" {
            # Mittlere Jobs → Stable Nodes
            @preferred = <node2 node1 node7>;
        } else {  # light
            # Leichte Jobs → Mobile/verfügbare Nodes
            @preferred = <node5 node1 node2>;
        }
        
        # Prüfe Verfügbarkeit
        for @preferred -> $node-id {
            if self.check-node-available($node-id) {
                return $node-id;
            }
        }
        
        # Fallback
        return "node1";
    }
    
    # Prüfe ob Node erreichbar ist
    method check-node-available($node-id) {
        unless %NODES{$node-id}:exists {
            return False;
        }
        
        my $node = %NODES{$node-id};
        
        # Nicht immer-verfügbare Nodes nur wenn explizit requested
        if !$node<always_available> {
            # Für light-jobs prüfen wir ob online
            if $node-id eq "node5" {  # Redmi
                return self!check-mobile-online();
            }
            return False;
        }
        
        # Für immer-verfügbare Nodes: prüfe ob wirklich online
        try {
            my $result = run("openclaw", "nodes", "status", $node-id, :out, :err);
            return $result.exitcode == 0;
        }
        return $node<always_available> // False;
    }
    
    # Prüfe ob Redmi (Node 5) Internet hat
    method !check-mobile-online() {
        try {
            my $result = run("openclaw", "nodes", "status", "node5", :out, :err);
            return $result.exitcode == 0 && $result.out.slurp.lc ~~ /'online'/;
        }
        return False;
    }
    
    # Dispatche Job und gib Info zurück
    method dispatch($job-script, @target-langs = ("perl5")) {
        my $weight = self.get-job-weight($job-script, @target-langs.elems);
        my $selected-node = self.select-node($weight);
        
        return {
            job => ~$job-script,
            weight => $weight,
            selected_node => $selected-node,
            target_langs => @target-langs,
            status => "dispatched"
        };
    }
}

sub MAIN(
    Str :j(:$job) where { .IO.e },           # Pfad zum Job-Skript
    Str :l(:$langs) = "perl5",              # Kommagetrennte Ziel-Sprachen
    Str :w(:$weight) where * ~~ any(<light medium heavy>),  # Erzwinge Job-Gewicht
    Bool :x(:$execute)                      # Tatsächlich auf ausgewähltem Node ausführen
) {
    my $dispatcher = JobDispatcher.new;
    my @target-langs = $langs.split(",");
    
    # Bestimme Gewicht
    my $actual-weight = $weight // $dispatcher.get-job-weight($job.IO, @target-langs.elems);
    
    # Wähle Node
    my $selected-node = $dispatcher.select-node($actual-weight);
    
    # Ausgabe
    say "📦 Job Dispatch Information";
    say "=" x 50;
    say "Job: $job";
    say "Size: {$job.IO.s} bytes";
    say "Target langs: {@target-langs.join(', ')}";
    say "Job weight: $actual-weight";
    say "Selected node: $selected-node";
    say "=" x 50;
    
    if $execute {
        say "\n🚀 Executing on $selected-node...";
        # TODO: Implement remote execution
        say "(Remote execution not yet implemented)";
    } else {
        say "\n💡 To execute: {$*PROGRAM-NAME} --job $job --execute";
    }
}
