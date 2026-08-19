#!/usr/bin/env perl
# spawn_agent.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use Getopt::Long;
use Pod::Usage;
use File::Spec;
use File::Basename;

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

# Load models function
sub load_models {
    my $config_path = $ENV{'OPENCLAW_CONFIG'} // '/home/openclaw/.openclaw/openclaw.json';
    
    my $config_content;
    if (open(my $fh, '<:encoding(UTF-8)', $config_path)) {
        local $/;
        $config_content = <$fh>;
        close($fh);
    } else {
        die "Modellkonfiguration kann nicht geladen werden: $config_path: $!";
    }
    
    my $config;
    eval {
        $config = decode_json($config_content);
    };
    if ($@) {
        die "Modellkonfiguration kann nicht geladen werden: $config_path: $@";
    }
    
    my $model_config = $config->{'agents'}->{'defaults'}->{'model'};
    my @candidates = ($model_config->{'primary'}, @{$model_config->{'fallbacks'}});
    
    my %seen;
    my @models = grep { 
        defined($_) && $_ && !/^anthropic\// 
    } grep { 
        !$seen{$_}++ 
    } @candidates;
    
    if (!@models) {
        die "Keine allgemein verfügbaren Modelle in $config_path";
    }
    
    return @models;
}

my @MODELS = load_models();

# SubAgentSpawner package
{
    package SubAgentSpawner;
    
    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    
    sub get_spawn_config {
        my ($self, %args) = @_;
        
        my %config = (
            task => $args{task}
        );
        
        $config{label} = $args{label} if defined $args{label};
        $config{model} = $args{model} if defined $args{model} && grep { $_ eq $args{model} } @MODELS;
        $config{thinking} = $args{thinking} if defined $args{thinking};
        $config{runTimeoutSeconds} = $args{timeout} if defined $args{timeout};
        
        if ($args{thread}) {
            $config{thread} = JSON::true;
            if ($args{mode} eq 'run') {
                $config{mode} = 'session';  # thread requires session mode
            }
        } else {
            $config{mode} = $args{mode} if defined $args{mode};
        }
        
        return \%config;
    }
    
    sub print_spawn_command {
        my ($self, $config) = @_;
        print "\n🛠️  Tool-Aufruf:\n";
        print "=" x 50 . "\n";
        print "sessions_spawn(\n";
        for my $key (sort keys %$config) {
            my $value = $config->{$key};
            if (ref($value) eq 'JSON::PP::Boolean') {
                print "    $key=" . ($value ? "True" : "False") . "\n";
            } elsif (ref($value)) {
                # Handle other reference types if needed
                print "    $key=$value\n";
            } else {
                if ($value =~ /^[0-9]+$/) {
                    print "    $key=$value\n";
                } else {
                    print "    $key=\"$value\"\n";
                }
            }
        }
        print ")\n";
        print "=" x 50 . "\n";
    }
    
    sub print_slash_command {
        my ($self, $config) = @_;
        my $task = $config->{task} // '';
        my $label = $config->{label} // 'agent';
        my $model = $config->{model} // '';
        
        my $cmd = "/subagents spawn $label \"$task\"";
        $cmd .= " --model $model" if $model;
        $cmd .= " --thinking " . $config->{thinking} if $config->{thinking};
        
        print "\n💬 Slash Command:\n";
        print "=" x 50 . "\n";
        print "$cmd\n";
        print "=" x 50 . "\n";
    }
}

# Main execution
sub main {
    my $task;
    my $label;
    my $model;
    my $thinking;
    my $timeout = 900;
    my $thread = 0;
    my $mode = 'run';
    my $output = 'tool';
    my $help = 0;
    
    GetOptions(
        'task|t=s'      => \$task,
        'label|l=s'     => \$label,
        'model|m=s'     => \$model,
        'thinking=s'    => \$thinking,
        'timeout=i'     => \$timeout,
        'thread'        => \$thread,
        'mode=s'        => \$mode,
        'output|o=s'    => \$output,
        'help|h'        => \$help,
    ) or pod2usage(2);
    
    pod2usage(1) if $help;
    pod2usage(2) unless defined $task;
    
    # Validate model choice
    if (defined $model && !grep { $_ eq $model } @MODELS) {
        die "Ungültiges Modell: $model. Gültige Optionen: " . join(', ', @MODELS) . "\n";
    }
    
    # Validate thinking level
    if (defined $thinking && !grep { $_ eq $thinking } qw(low medium high)) {
        die "Ungültiges Thinking Level: $thinking. Gültige Optionen: low, medium, high\n";
    }
    
    # Validate mode
    if (!grep { $_ eq $mode } qw(run session)) {
        die "Ungültiger Modus: $mode. Gültige Optionen: run, session\n";
    }
    
    # Validate output format
    if (!grep { $_ eq $output } qw(tool slash json)) {
        die "Ungültiges Ausgabeformat: $output. Gültige Optionen: tool, slash, json\n";
    }
    
    my $spawner = SubAgentSpawner->new();
    my $config = $spawner->get_spawn_config(
        task     => $task,
        label    => $label,
        model    => $model,
        thinking => $thinking,
        timeout  => $timeout,
        thread   => $thread,
        mode     => $mode
    );
    
    print "✅ Sub-Agent Konfiguration:\n";
    print to_json($config, { pretty => 1, canonical => 1 });
    
    if ($output eq 'tool') {
        $spawner->print_spawn_command($config);
    } elsif ($output eq 'slash') {
        $spawner->print_slash_command($config);
    } elsif ($output eq 'json') {
        print "\n📄 JSON:\n";
        my $json_string = to_json($config, { pretty => 1, canonical => 1 });
        print $json_string . "\n";
        
        # Speichere als Datei
        my $label_for_filename = $config->{label} // 'spawn';
        $label_for_filename =~ s/[^\w\-]//g;  # Sanitize filename
        my $output_file = File::Spec->catfile('/tmp', "subagent_${label_for_filename}.json");
        
        if (open(my $fh, '>:encoding(UTF-8)', $output_file)) {
            print $fh $json_string;
            close($fh);
            print "💾 Gespeichert: $output_file\n";
        } else {
            warn "Konnte nicht speichern: $output_file: $!\n";
        }
    }
}

main() unless caller;

__END__

=head1 NAME

spawn_agent - Sub-Agent spawner - Einfache CLI für sessions_spawn

=head1 SYNOPSIS

spawn_agent [OPTIONEN]

=head1 OPTIONS

=over 4

=item B<--task>, B<-t>

Aufgabenbeschreibung (erforderlich)

=item B<--label>, B<-l>

Optionaler Label

=item B<--model>, B<-m>

KI-Modell

=item B<--thinking>

Thinking Level (low, medium, high)

=item B<--timeout>

Timeout in Sekunden (default: 900)

=item B<--thread>

Thread-Binding aktivieren

=item B<--mode>

Run mode (run, session) (default: run)

=item B<--output>, B<-o>

Output format (tool, slash, json) (default: tool)

=item B<--help>, B<-h>

Hilfe anzeigen

=back

=head1 BEISPIELE

  spawn_agent --task "Analyze logs"
  spawn_agent --task "Code review" --model openai/gpt-5.6-sol --timeout 1800
  spawn_agent --task "Batch process" --label "batch-worker" --thread

=cut
