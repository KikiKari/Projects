#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "0213d0dfb111018b426485d606f7c5dfa878aef568087cf737519924a9f749e5", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "perl5"}
# json_processor.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON::PP;
use File::Slurp qw(read_file);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

# JSON Processor mit Validation und Repair.
# Für robuste Verarbeitung von LLM-Outputs.

# Globale Variablen
my $HAS_JSON_REPAIR = 0;  # In Perl gibt es kein direktes Äquivalent zu json_repair

# Exception-Klassen (simuliert)
package JSONProcessingError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

package JSONValidationError {
    use base 'JSONProcessingError';
}

package JSONRepairError {
    use base 'JSONProcessingError';
}

# Hilfsfunktion zur Fehlerausgabe
sub throw_error {
    my ($class, $message) = @_;
    die $class->new($message);
}

# Hauptfunktionen

sub repair_json_string {
    my ($raw_json) = @_;
    $raw_json //= '';
    $raw_json =~ s/^\s+|\s+$//g;

    if (!$HAS_JSON_REPAIR) {
        warn "Warning: json_repair not available in Perl\n";
    }

    # Fallback: Manuelle Reparaturen
    my $cleaned = $raw_json;

    # Entferne JavaScript-Kommentare
    $cleaned =~ s|//.*$||mg;
    $cleaned =~ s|/\*.*?\*/||gs;

    # Entferne trailing commas vor ] oder }
    $cleaned =~ s/,(\s*[\}\]])/$1/g;

    return $cleaned;
}

sub parse_json {
    my ($raw_input, $repair) = @_;
    $raw_input //= '';
    $repair //= 1;
    $raw_input =~ s/^\s+|\s+$//g;

    my $json = JSON::PP->new;

    # Versuche zuerst direktes Parsing
    eval {
        return $json->decode($raw_input);
    };
    if ($@) {
        # Extrahiere JSON aus Markdown-Code-Blöcken
        if ($raw_input =~ m/```/) {
            my @patterns = (
                qr/```json\s*(.*?)\s*```/s,
                qr/```\s*(\{.*?\})\s*```/s,
                qr/```\s*(\[.*?\])\s*```/s,
            );
            for my $pattern (@patterns) {
                if ($raw_input =~ /$pattern/) {
                    my $match = $1;
                    eval {
                        return $json->decode($match);
                    };
                }
            }
        }

        # Versuche Reparatur
        if ($repair) {
            eval {
                my $repaired = repair_json_string($raw_input);
                return $json->decode($repaired);
            };
            if ($@) {
                throw_error('JSONProcessingError', "Could not parse JSON even after repair: $@");
            }
        }

        throw_error('JSONProcessingError', "Could not parse JSON");
    }
}

sub parse_and_validate {
    my ($raw_input, $model_class, $repair, $strict) = @_;
    $repair //= 1;
    $strict //= 0;

    my $data;
    eval {
        $data = parse_json($raw_input, $repair);
    };
    if ($@ && ref($@) eq 'JSONProcessingError') {
        throw_error('JSONValidationError', "JSON parsing failed: " . $@->message);
    } elsif ($@) {
        throw_error('JSONValidationError', "JSON parsing failed: $@");
    }

    # Da Perl kein Pydantic hat, simulieren wir nur das Parsen
    return $data;
}

sub validate_tool_call {
    my ($raw_json, $tool_name) = @_;

    my $tool_call;
    eval {
        $tool_call = parse_and_validate($raw_json, undef, 1, 0);
    };
    if ($@) {
        throw_error('JSONValidationError', $@->message);
    }

    if (defined $tool_name && $tool_call->{tool} ne $tool_name) {
        throw_error('JSONValidationError', 
            "Expected tool '$tool_name', got '" . $tool_call->{tool} . "'");
    }

    return {
        tool      => $tool_call->{tool},
        arguments => $tool_call->{arguments} || {},
        reasoning => $tool_call->{reasoning}
    };
}

sub safe_json_loads {
    my ($raw_input, $default, $repair) = @_;
    $default //= undef;
    $repair //= 1;

    eval {
        return parse_json($raw_input, $repair);
    };
    if ($@) {
        return $default;
    }
}

sub extract_json_from_text {
    my ($text) = @_;
    my @results;

    my @patterns = (
        qr/\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/,  # Objekte
        qr/\[[^\[\]]*(?:\[[^\[\]*\][^\[\]]*)*\]/,  # Arrays
    );

    for my $pattern (@patterns) {
        while ($text =~ /$pattern/g) {
            my $match = $&;
            eval {
                my $parsed = parse_json($match, 1);
                push @results, $parsed;
            };
            # Ignoriere Fehler beim Parsen einzelner Funde
        }
    }

    return \@results;
}

# CLI Interface
sub main {
    my $input = '';
    my $is_file = 0;
    my $repair = 1;
    my $pretty = 0;
    my $help = 0;

    GetOptions(
        'input=s'     => \$input,
        'file|f'      => \$is_file,
        'repair!'     => \$repair,
        'pretty|p'    => \$pretty,
        'help|h'      => \$help,
    ) or pod2usage(2);

    pod2usage(1) if $help;

    if (!$input) {
        pod2usage(2);
    }

    my $content;
    if ($is_file) {
        $content = read_file($input);
    } else {
        $content = $input;
    }

    eval {
        my $result = parse_json($content, $repair);
        my $json = JSON::PP->new;
        if ($pretty) {
            $json->indent(1);
        }
        print $json->encode($result) . "\n";
    };
    if ($@ && ref($@) eq 'JSONProcessingError') {
        print STDERR "Error: " . $@->message . "\n";
        exit 1;
    } elsif ($@) {
        print STDERR "Unexpected error: $@\n";
        exit 1;
    }
}

main() unless caller;

__END__

=head1 NAME

json_processor.pl - JSON Processor mit Reparatur

=head1 SYNOPSIS

json_processor.pl [Optionen] <Eingabe>

=head1 OPTIONS

=over 4

=item B<--file>, B<-f>

Die Eingabe ist ein Dateipfad

=item B<--repair>, B<--no-repair>

Aktiviere/Deaktiviere JSON-Reparatur (Standard: aktiviert)

=item B<--pretty>, B<-p>

Gibt das Ergebnis formatiert aus

=item B<--help>, B<-h>

Zeigt diese Hilfe an

=back

=head1 DESCRIPTION

Dieses Skript verarbeitet JSON-Eingaben mit optionaler Reparatur und Validierung.

=cut
