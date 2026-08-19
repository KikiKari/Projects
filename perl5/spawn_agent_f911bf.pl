#!/usr/bin/perl
# spawn_agent.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use JSON;
use File::Spec;
use File::Path qw(make_path);
use File::Basename;

=head1 NAME

spawn_agent.pl - Sub-Agent Spawner - Einfache CLI fuer sessions_spawn

=head1 SYNOPSIS

spawn_agent.pl [options]

 Options:
   --task, -t            Aufgabenbeschreibung (required)
   --label, -l           Optionaler Label
   --model, -m           KI-Modell
   --thinking            Thinking Level (low|medium|high)
   --timeout             Timeout in Sekunden (default: 900)
   --thread              Thread-Binding aktivieren
   --mode                Run mode (run|session) (default: run)
   --output, -o          Output format (tool|slash|json) (default: tool)
   --help, -h            Zeige diese Hilfe

=cut

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my @MODELS = qw(openrouter/anthropic/claude-haiku-4.5 openrouter/google/gemini-pro openai/gpt-4);

# Optionen
my ($task, $label, $model, $thinking, $timeout, $thread, $mode, $output, $help);
$timeout = 900;
$mode = "run";
$output = "tool";

GetOptions(
    "task|t=s"      => \$task,
    "label|l=s"     => \$label,
    "model|m=s"     => \$model,
    "thinking=s"    => \$thinking,
    "timeout=i"     => \$timeout,
    "thread"        => \$thread,
    "mode=s"        => \$mode,
    "output|o=s"    => \$output,
    "help|h"        => \$help,
) or pod2usage(2);

pod2usage(1) if $help;

unless ($task) {
    print STDERR "Fehler: --task ist erforderlich\n";
    pod2usage(2);
}

# Modellvalidierung
if ($model && !grep { $_ eq $model } @MODELS) {
    print STDERR "Fehler: Unbekanntes Modell '$model'. Verfuegbare Modelle: " . join(", ", @MODELS) . "\n";
    exit 1;
}

# Denken-Level Validierung
if ($thinking && $thinking !~ /^(low|medium|high)$/) {
    print STDERR "Fehler: Ungueltiges Thinking Level '$thinking'. Erlaubt: low, medium, high\n";
    exit 1;
}

# Mode Validierung
if ($mode !~ /^(run|session)$/) {
    print STDERR "Fehler: Ungueltiger Mode '$mode'. Erlaubt: run, session\n";
    exit 1;
}

# Output Format Validierung
if ($output !~ /^(tool|slash|json)$/) {
    print STDERR "Fehler: Ungueltiges Output Format '$output'. Erlaubt: tool, slash, json\n";
    exit 1;
}

# Konfiguration erstellen
my %config = (
    task => $task
);

$config{label} = $label if $label;
$config{model} = $model if $model && grep { $_ eq $model } @MODELS;
$config{thinking} = $thinking if $thinking;
$config{runTimeoutSeconds} = $timeout if $timeout;

if ($thread) {
    $config{thread} = JSON::true;
    if ($mode eq "run") {
        $config{mode} = "session";  # thread erfordert session mode
    }
} else {
    $config{mode} = $mode;
}

# Ausgabe
print "✅ Sub-Agent Konfiguration:\n";
print to_json(\%config, { pretty => 1 }), "\n";

if ($output eq "tool") {
    print_spawn_command(\%config);
} elsif ($output eq "slash") {
    print_slash_command(\%config);
} elsif ($output eq "json") {
    print "\n📄 JSON:\n";
    print to_json(\%config), "\n";
    
    # Speichere als Datei
    my $label_for_filename = $config{label} || "spawn";
    my $filename = "/tmp/subagent_$label_for_filename.json";
    open(my $fh, '>', $filename) or die "Kann Datei '$filename' nicht schreiben: $!";
    print $fh to_json(\%config, { pretty => 1 });
    close($fh);
    print "💾 Gespeichert: $filename\n";
}

sub print_spawn_command {
    my ($config) = @_;
    print "\n🛠️  Tool-Aufruf:\n";
    print "=" x 50 . "\n";
    print "sessions_spawn(\n";
    for my $key (sort keys %$config) {
        my $value = $config->{$key};
        if (ref($value) eq 'JSON::true' || ref($value) eq 'JSON::false') {
            print "    $key=" . ($value ? "True" : "False") . "\n";
        } elsif ($value =~ /^[0-9]+$/) {
            print "    $key=$value\n";
        } else {
            print "    $key=\"$value\"\n";
        }
    }
    print ")\n";
    print "=" x 50 . "\n";
}

sub print_slash_command {
    my ($config) = @_;
    my $task = $config->{task} // "";
    my $label = $config->{label} // "agent";
    my $model = $config->{model} // "";
    
    my $cmd = "/subagents spawn $label \"$task\"";
    $cmd .= " --model $model" if $model;
    $cmd .= " --thinking $config->{thinking}" if $config->{thinking};
    
    print "\n💬 Slash Command:\n";
    print "=" x 50 . "\n";
    print "$cmd\n";
    print "=" x 50 . "\n";
}
