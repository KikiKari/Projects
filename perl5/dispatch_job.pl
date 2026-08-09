#!/usr/bin/env perl
# dispatch_job.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';

# Node-Konfiguration
my %NODES = (
    "node1" => { "always_available" => 1, "capacity" => "medium", "priority" => 2 },
    "node2" => { "always_available" => 1, "capacity" => "medium", "priority" => 3 },
    "node3" => { "always_available" => 0, "capacity" => "medium", "priority" => 4 },
    "node5" => { "always_available" => 0, "capacity" => "low", "priority" => 5, "device" => "Redmi Note 11S" },
    "node7" => { "always_available" => 1, "capacity" => "high", "priority" => 1 },
);

# JobDispatcher package
package JobDispatcher;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

# Bewertet Job-Gewicht
sub get_job_weight {
    my ($self, $script_path, $target_langs_count) = @_;
    $target_langs_count //= 1;

    unless (-e $script_path) {
        return "medium";
    }

    my $script_size = (stat($script_path))[7];
    my $total_work = $script_size * $target_langs_count;

    if ($total_work > 50000) {  # > 50KB
        return "heavy";
    } elsif ($total_work > 10000) {  # > 10KB
        return "medium";
    } else {
        return "light";
    }
}

# Wählt besten Node basierend auf Job-Gewicht
sub select_node {
    my ($self, $job_weight) = @_;
    my @preferred;

    if ($job_weight eq "heavy") {
        # Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
        @preferred = ("node7", "node2", "node1");
    } elsif ($job_weight eq "medium") {
        # Mittlere Jobs → Stable Nodes
        @preferred = ("node2", "node1", "node7");
    } else {  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        @preferred = ("node5", "node1", "node2");
    }

    # Prüfe Verfügbarkeit
    for my $node_id (@preferred) {
        if ($self->check_node_available($node_id)) {
            return $node_id;
        }
    }

    # Fallback
    return "node1";
}

# Prüft ob Node erreichbar ist
sub check_node_available {
    my ($self, $node_id) = @_;

    unless (exists $NODES{$node_id}) {
        return 0;
    }

    my $node = $NODES{$node_id};

    # Nicht immer-verfügbare Nodes nur wenn explizit requested
    unless ($node->{"always_available"}) {
        # Für light-jobs prüfen wir ob online
        if ($node_id eq "node5") {  # Redmi
            return $self->_check_mobile_online();
        }
        return 0;
    }

    # Für immer-verfügbare Nodes: prüfe ob wirklich online
    my $result = eval {
        open(my $fh, '-|', "openclaw nodes status $node_id 2>/dev/null");
        local $/;
        my $output = <$fh>;
        close($fh);
        return ($? == 0) ? 1 : 0;
    };

    if ($@) {
        return $node->{"always_available"} ? 1 : 0;
    }

    return $result // ($node->{"always_available"} ? 1 : 0);
}

# Prüft ob Redmi (Node 5) Internet hat
sub _check_mobile_online {
    my $self = shift;

    my $result = eval {
        open(my $fh, '-|', "openclaw nodes status node5 2>/dev/null");
        local $/;
        my $output = <$fh>;
        close($fh);
        return ($? == 0 && $output =~ /online/i) ? 1 : 0;
    };

    if ($@) {
        return 0;
    }

    return $result // 0;
}

# Dispatched Job und gibt Info zurück
sub dispatch {
    my ($self, $job_script, $target_langs) = @_;
    $target_langs //= ["perl5"];

    my $weight = $self->get_job_weight($job_script, scalar @$target_langs);
    my $selected_node = $self->select_node($weight);

    return {
        "job" => $job_script,
        "weight" => $weight,
        "selected_node" => $selected_node,
        "target_langs" => $target_langs,
        "status" => "dispatched"
    };
}

# Main program
package main;

my ($job, $langs, $weight, $execute);
GetOptions(
    "job|j=s" => \$job,
    "langs|l=s" => \$langs,
    "weight|w=s" => \$weight,
    "execute|x" => \$execute
) or die "Error in command line arguments\n";

unless ($job) {
    die "❌ Job argument is required\n";
}

unless (-e $job) {
    die "❌ Job not found: $job\n";
}

my $dispatcher = JobDispatcher->new();
my @target_langs = split(',', $langs // "perl5");

# Determine weight
my $job_weight = $weight // $dispatcher->get_job_weight($job, scalar @target_langs);

# Select node
my $selected_node = $dispatcher->select_node($job_weight);

# Output
print "📦 Job Dispatch Information\n";
print "=" x 50 . "\n";
print "Job: $job\n";
print "Size: " . (stat($job))[7] . " bytes\n";
print "Target langs: " . join(', ', @target_langs) . "\n";
print "Job weight: $job_weight\n";
print "Selected node: $selected_node\n";
print "=" x 50 . "\n";

if ($execute) {
    print "\n🚀 Executing on $selected_node...\n";
    # TODO: Implement remote execution
    print "(Remote execution not yet implemented)\n";
} else {
    my $script_name = basename($0);
    print "\n💡 To execute: $^X $script_name --job $job --execute\n";
}
