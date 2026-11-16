#!/usr/bin/env perl
# dispatch_job.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON::PP;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use UUID::Tiny qw(create_uuid);
use IPC::Run3 qw(run3);
use Data::Dumper;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

# Node-Konfiguration
my %NODES = (
    "node1" => {
        "always_available" => 1,
        "capacity" => "medium",
        "priority" => 3,
        "description" => "Gateway"
    },
    "node2" => {
        "always_available" => 0,
        "capacity" => "high",
        "priority" => 1,
        "description" => "ARM Server"
    },
    "node3" => {
        "always_available" => 0,
        "capacity" => "medium",
        "priority" => 4,
        "description" => "AMD Server"
    },
    "node4" => {
        "always_available" => 0,
        "capacity" => "low",
        "priority" => 5,
        "device" => "Redmi Note 11S"
    },
    "node5" => {
        "always_available" => 0,
        "capacity" => "high",
        "priority" => 2,
        "device" => "Lenovo"
    },
    "node6" => {
        "always_available" => 0,
        "device" => "Lenovo (Docker)"
    }
);

my %NODE_NAMES = (
    "node2" => {
        "openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"
    },
    "node3" => {
        "openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"
    },
    "node4" => {
        "openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"
    },
    "node5" => {
        "openclaw-node5", "windows node (lenovo-7)"
    },
    "node6" => {
        "openclaw-node6"
    }
);

sub _job_weight_bytes {
    my ($script_path, $target_langs_count) = @_;
    # Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen
    my @stat = stat($script_path);
    return $stat[7] * $target_langs_count;
}

sub fetch_node_status {
    # Return mapped OpenClaw connection states; undef indicates lookup failure
    my $result;
    my $stdout;
    my $stderr;
    eval {
        run3(["openclaw", "nodes", "status", "--json"], \$result, \$stdout, \$stderr, { timeout => 10 });
    };
    if ($@ || !$stdout) {
        return undef;
    }
    
    my $payload;
    eval {
        $payload = decode_json($stdout);
    };
    if ($@ || ref($payload) ne 'HASH' || ref($payload->{nodes}) ne 'ARRAY') {
        return undef;
    }
    
    my %states = map { $_ => 0 } keys %NODE_NAMES;
    for my $item (@{$payload->{nodes}}) {
        next unless ref($item) eq 'HASH';
        my %names = map { lc($item->{$_} // "") => 1 } qw(displayName nodeId remoteIp);
        for my $node (keys %NODE_NAMES) {
            my $found = 0;
            for my $alias (keys %{$NODE_NAMES{$node}}) {
                if (exists $names{lc($alias)}) {
                    $found = 1;
                    last;
                }
            }
            if ($found && $item->{connected}) {
                $states{$node} = 1;
            }
        }
    }
    $states{"node1"} = 1; # successful Gateway status request
    return \%states;
}

package JobDispatcher;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub get_job_weight {
    my ($self, $script_path, $target_langs_count) = @_;
    $target_langs_count //= 1;
    # Bewertet Job-Gewicht
    unless (-e $script_path) {
        return "medium";
    }
    
    my $total_work = _job_weight_bytes($script_path, $target_langs_count);
    
    if ($total_work > 50000) {  # > 50KB
        return "heavy";
    } elsif ($total_work > 10000) {  # > 10KB
        return "medium";
    } else {
        return "light";
    }
}

sub select_node {
    my ($self, $job_weight) = @_;
    # Wählt besten Node basierend auf Job-Gewicht
    
    my @preferred;
    if ($job_weight eq "heavy") {
        @preferred = ("node1", "node2", "node5", "node6");
    } elsif ($job_weight eq "medium") {
        @preferred = ("node1", "node2", "node3", "node6");
    } elsif ($job_weight eq "light") {
        @preferred = ("node2", "node1", "node3", "node4");
    } else {
        die "Unknown job weight: $job_weight";
    }

    my $states = fetch_node_status();
    for my $node_id (@preferred) {
        if ($states && $states->{$node_id}) {
            return $node_id;
        }
    }
    return undef;  # no verified reachable node
}

sub check_node_available {
    my ($self, $node_id) = @_;
    # Use the live connection state rather than static availability
    my $states = fetch_node_status();
    return ($states && $states->{$node_id}) ? 1 : 0;
}

sub execute_translation {
    my ($self, $job, $transport) = @_;
    return execute_translation($job, $transport);
}

sub _check_mobile_online {
    my ($self) = @_;
    # Check Node4 (Redmi)
    return $self->check_node_available("node4");
}

sub dispatch {
    my ($self, $job_script, $target_langs, $source_text, $source_language) = @_;
    $target_langs //= ["perl5"];
    # Dispatched Job und gibt Info zurück
    my $weight = $self->get_job_weight($job_script, scalar @$target_langs);
    my $selected_node = $self->select_node($weight);
    my @translation_jobs = ();
    for my $language (@$target_langs) {
        my $job = {
            "job_id" => create_uuid(),
            "source" => "$job_script",
            "target_language" => $language,
            "selected_node" => $selected_node,
        };
        if (defined $source_text) {
            $job->{"source_text"} = $source_text;
        }
        if (defined $source_language) {
            $job->{"source_language"} = $source_language;
        }
        push @translation_jobs, $job;
    }
    
    return {
        "job" => "$job_script",
        "weight" => $weight,
        "selected_node" => $selected_node,
        "target_langs" => $target_langs,
        "translation_jobs" => \@translation_jobs,
        "status" => $selected_node ? "selected" : "unavailable"
    };
}

package main;

sub execute_translation {
    my ($job, $transport) = @_;
    # Execute via a supplied transport and verify its result belongs to the job
    if (!$job->{"selected_node"} || !defined $transport) {
        die "no verified node or authorized translation transport";
    }
    my $response = $transport->($job);
    if (ref($response) ne 'HASH') {
        die "invalid transport response";
    }
    for my $key (qw(job_id selected_node target_language)) {
        if ($response->{$key} ne $job->{$key}) {
            die "transport response does not match job";
        }
    }
    my $code = $response->{"code"};
    if ($response->{"status"} ne "ok" || !defined($code) || $code !~ /\S/) {
        die "translation did not complete with code";
    }
    return $code;
}

sub dispatch_abstraction_job {
    my ($job_script, $target_langs) = @_;
    # Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag
    my $dispatcher = JobDispatcher->new();
    return $dispatcher->dispatch($job_script, $target_langs);
}

sub main {
    use Getopt::Long;
    
    my $job_path;
    my $langs = "perl5";
    my $weight;
    my $execute = 0;
    
    GetOptions(
        "job|j=s" => \$job_path,
        "langs|l=s" => \$langs,
        "weight|w=s" => \$weight,
        "execute|x" => \$execute
    ) or die "Falsche Optionen\n";
    
    unless ($job_path) {
        die "Option --job ist erforderlich\n";
    }
    
    unless (-e $job_path) {
        print STDERR "❌ Job not found: $job_path\n";
        exit 1;
    }
    
    my $dispatcher = JobDispatcher->new();
    my @target_langs = split /,/, $langs;
    
    # Determine weight
    if (!defined $weight) {
        $weight = $dispatcher->get_job_weight($job_path, scalar @target_langs);
    }
    
    # Select node
    my $selected_node = $dispatcher->select_node($weight);
    
    # Output
    print "📦 Job Dispatch Information\n";
    print "=" x 50 . "\n";
    my @stat = stat($job_path);
    print "Job: $job_path\n";
    print "Size: $stat[7] bytes\n";
    print "Target langs: " . join(", ", @target_langs) . "\n";
    print "Job weight: $weight\n";
    print "Selected node: " . (defined $selected_node ? $selected_node : "undef") . "\n";
    print "=" x 50 . "\n";
    
    if ($execute) {
        print STDERR "\nTranslation dispatch on $selected_node is not implemented.\n";
        return 1;
    } else {
        print "\n💡 To execute: $0 --job $job_path --execute\n";
    }
    return 0;
}

exit(main()) unless caller;
