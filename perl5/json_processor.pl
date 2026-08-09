#!/usr/bin/env perl
# json_processor.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON qw(decode_json encode_json);
use File::Slurp qw(read_file);
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);

# JSON Processor mit Validierung und Reparatur.
# Für robuste Verarbeitung von LLM-Outputs.

# Globale Variablen
my $HAS_JSON_REPAIR = 0;
my $json_repair_error = 0;

# Versuche JSON::Repair zu laden
eval {
    require JSON::Repair;
    $HAS_JSON_REPAIR = 1;
};
if ($@) {
    warn "Warning: JSON::Repair not installed. Run: cpan JSON::Repair\n";
}

# Exception-Klassen
package JSONProcessingError {
    use parent -norequire, 'Exception::Class::Base';
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    sub message { $_[0]->{message} }
}

package JSONValidationError {
    use parent -norequire, 'JSONProcessingError';
}

package JSONRepairError {
    use parent -norequire, 'JSONProcessingError';
}

# Funktionen

sub repair_json_string {
    my ($raw_json) = @_;
    $raw_json //= '';
    $raw_json =~ s/^\s+|\s+$//g;

    if ($HAS_JSON_REPAIR) {
        eval {
            my $repaired = JSON::Repair::repair_json($raw_json);
            return $repaired;
        };
        if ($@) {
            JSONRepairError->throw("JSON repair failed: $@");
        }
    } else {
        # Fallback: Manuelle Reparaturen
        my $cleaned = $raw_json;
        # Entferne JavaScript-Kommentare
        $cleaned =~ s|//.*?\n|\n|g;
        $cleaned =~ s|/\*.*?\*/||gs;
        # Entferne trailing commas vor ] oder }
        $cleaned =~ s/,\s*([}\]])/$1/g;
        return $cleaned;
    }
}

sub parse_json {
    my ($raw_input, $repair) = @_;
    $repair //= 1;
    $raw_input //= '';
    $raw_input =~ s/^\s+|\s+$//g;

    # Versuche zuerst direktes Parsing
    my $data;
    eval {
        $data = decode_json($raw_input);
    };
    if (!$@) {
        return $data;
    }

    # Extrahiere JSON aus Markdown-Code-Blöcken
    if ($raw_input =~ /```/) {
        # Suche nach JSON in ```json ... ``` oder ``` ... ```
        my @patterns = (
            qr/```json\s*(.*?)\s*```/s,
            qr/```\s*(\{.*?\})\s*```/s,
            qr/```\s*(\[.*?\])\s*```/s,
        );
        for my $pattern (@patterns) {
            if ($raw_input =~ /$pattern/g) {
                my @matches = ($raw_input =~ /$pattern/g);
                for my $match (@matches) {
                    eval {
                        return decode_json($match);
                    };
                }
            }
        }
    }

    # Versuche Reparatur
    if ($repair) {
        my $repaired;
        eval {
            $repaired = repair_json_string($raw_input);
        };
        if ($@) {
            JSONProcessingError->throw("Could not parse JSON even after repair: " . $@->message);
        }
        eval {
            return decode_json($repaired);
        };
        if ($@) {
            JSONProcessingError->throw("Could not parse JSON even after repair: $@");
        }
    }

    JSONProcessingError->throw("Could not parse JSON");
}

sub parse_and_validate {
    my ($raw_input, $model_class, $repair, $strict) = @_;
    $repair //= 1;
    $strict //= 0;

    my $data;
    eval {
        $data = parse_json($raw_input, $repair);
    };
    if ($@ && $@->isa('JSONProcessingError')) {
        JSONValidationError->throw("JSON parsing failed: " . $@->message);
    } elsif ($@) {
        JSONValidationError->throw("JSON parsing failed: $@");
    }

    # Da Perl keine Pydantic-Modelle hat, simulieren wir eine einfache Validierung
    # In einer echten Implementierung würde hier die Validierung gegen ein Schema erfolgen
    return $data;
}

sub validate_tool_call {
    my ($raw_json, $tool_name) = @_;

    my $tool_call;
    eval {
        $tool_call = parse_and_validate($raw_json, 'ToolCall', 1, 0);
    };
    if ($@ && $@->isa('JSONProcessingError')) {
        JSONValidationError->throw("JSON parsing failed: " . $@->message);
    } elsif ($@) {
        JSONValidationError->throw("JSON parsing failed: $@");
    }

    if (defined $tool_name && $tool_call->{tool} ne $tool_name) {
        JSONValidationError->throw("Expected tool '$tool_name', got '$tool_call->{tool}'");
    }

    return {
        tool => $tool_call->{tool},
        arguments => $tool_call->{arguments} // {},
        reasoning => $tool_call->{reasoning}
    };
}

sub safe_json_loads {
    my ($raw_input, $default, $repair) = @_;
    $repair //= 1;
    $default //= undef;

    my $data;
    eval {
        $data = parse_json($raw_input, $repair);
    };
    if ($@) {
        return $default;
    }
    return $data;
}

sub extract_json_from_text {
    my ($text) = @_;
    my @results = ();

    # Pattern für JSON-Objekte und Arrays
    my @patterns = (
        qr/\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}/,  # Objekte
        qr/\[[^\[\]]*(?:\[[^\[\]]*\][^\[\]]*)*\]/,  # Arrays
    );

    for my $pattern (@patterns) {
        while ($text =~ /$pattern/g) {
            my $match = $&;
            eval {
                my $parsed = parse_json($match, 1);
                push @results, $parsed;
            };
        }
    }

    return \@results;
}

# CLI-Interface
sub main {
    my $input = '';
    my $file = 0;
    my $repair = 1;
    my $pretty = 0;
    my $help = 0;

    GetOptions(
        'input=s' => \$input,
        'file|f' => \$file,
        'repair|r' => \$repair,
        'no-repair' => sub { $repair = 0 },
        'pretty|p' => \$pretty,
        'help|h' => \$help,
    ) or pod2usage(2);

    pod2usage(1) if $help;

    if (!$input) {
        pod2usage(2);
    }

    my $content = '';
    eval {
        if ($file) {
            $content = read_file($input);
        } else {
            $content = $input;
        }

        my $result = parse_json($content, $repair);

        my $output = encode_json($result);
        if ($pretty) {
            # Pretty-printing simulieren
            $output =~ s/,/,\n/g;
            $output =~ s/\{/ {\n/g;
            $output =~ s/\}/\n}/g;
        }
        print "$output\n";
    };
    if ($@ && $@->isa('JSONProcessingError')) {
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

json_processor - JSON Processor mit Reparatur

=head1 SYNOPSIS

json_processor [options] input

 Options:
   -f, --file            Input ist ein Dateipfad
   -r, --repair          Aktiviere JSON-Reparatur (Standard)
   --no-repair           Deaktiviere JSON-Reparatur
   -p, --pretty          Pretty-print Ausgabe
   -h, --help            Zeige diese Hilfe

=head1 DESCRIPTION

Dieses Skript verarbeitet JSON-Eingaben mit optionaler Reparatur von häufigen Fehlern in LLM-Ausgaben.

=cut
