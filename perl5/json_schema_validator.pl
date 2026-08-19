#!/usr/bin/env perl
# json_schema_validator.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_schema_validator.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_schema_validator.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON::PP qw(decode_json encode_json);
use File::Spec::Functions qw(catfile);
use Getopt::Long;
use Pod::Usage;

# JSON Schema Validator - Validiert JSON gegen JSON Schema Draft 7/2020-12.
# Erweitert Pydantic mit externen Schema-Dateien.

# Globale Variablen für Module
my $HAS_JSON_VALIDATOR;
my $HAS_JSON_XS;

# Versuche JSON::Validator zu laden
eval {
    require JSON::Validator;
    $HAS_JSON_VALIDATOR = 1;
};
if ($@) {
    $HAS_JSON_VALIDATOR = 0;
}

# Versuche JSON::XS zu laden
eval {
    require JSON::XS;
    $HAS_JSON_XS = 1;
};

# JSON Processor Subroutinen (ersetzen json_processor.py)
sub parse_json {
    my ($raw_input, $repair) = @_;
    $repair //= 1;
    
    eval {
        return decode_json($raw_input);
    };
    if ($@ && $repair) {
        # Versuche einfache Reparaturen
        my $repaired = $raw_input;
        $repaired =~ s/,\s*}/}/g;  # Entferne trailing commas
        $repaired =~ s/,\s*\]/]/g;
        eval {
            return decode_json($repaired);
        };
        if ($@) {
            die "JSON processing error: $@";
        }
    } elsif ($@) {
        die "JSON processing error: $@";
    }
}

# Exception Klassen
package SchemaValidationError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    
    sub message {
        my $self = shift;
        return $self->{message};
    }
}

package JSONProcessingError {
    sub new {
        my ($class, $message) = @_;
        return bless { message => $message }, $class;
    }
    
    sub message {
        my $self = shift;
        return $self->{message};
    }
}

# Hauptpaket
package main;

# Hilfsfunktionen
sub load_schema {
    my ($schema_source) = @_;
    
    # Wenn es bereits ein Hash ist
    if (ref($schema_source) eq 'HASH') {
        return $schema_source;
    }
    
    # Prüfe ob es eine Datei ist
    if (-f $schema_source) {
        open my $fh, '<:encoding(UTF-8)', $schema_source or die "Cannot open schema file '$schema_source': $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        
        eval {
            return decode_json($content);
        };
        if ($@) {
            die SchemaValidationError->new("Invalid JSON in schema file: $@");
        }
    }
    
    # Versuche als JSON String zu parsen
    eval {
        return decode_json($schema_source);
    };
    if ($@) {
        die SchemaValidationError->new("Schema not found or invalid: $schema_source");
    }
}

sub validate_with_jsonschema {
    my ($data, $schema, $draft) = @_;
    $draft //= "auto";
    
    if (!$HAS_JSON_VALIDATOR) {
        die SchemaValidationError->new("JSON::Validator not installed. Run: cpan JSON::Validator");
    }
    
    my $schema_dict = load_schema($schema);
    
    my $jv = JSON::Validator->new;
    if ($draft eq "draft7") {
        $jv->schema("http://json-schema.org/draft-07/schema#");
    } elsif ($draft eq "2020-12") {
        # Draft 2020-12 Unterstützung hängt von der Bibliothek ab
        $jv->schema("https://json-schema.org/draft/2020-12/schema");
    }
    
    my @errors = $jv->validate($data, $schema_dict);
    
    if (@errors) {
        my $error_msg = join(", ", map { $_->{message} } @errors);
        die SchemaValidationError->new("Schema validation failed: $error_msg");
    }
    
    return 1;
}

sub validate_and_convert {
    my ($raw_input, $schema, $repair) = @_;
    $repair //= 1;
    
    my $data;
    eval {
        $data = parse_json($raw_input, $repair);
    };
    if ($@) {
        die JSONProcessingError->new($@);
    }
    
    eval {
        validate_with_jsonschema($data, $schema);
    };
    if ($@) {
        die $@;
    }
    
    return $data;
}

# SchemaBuilder Klasse
package SchemaBuilder {
    sub object {
        my ($class, $properties, $required) = @_;
        my $schema = {
            type => "object",
            properties => $properties
        };
        if ($required) {
            $schema->{required} = $required;
        }
        return $schema;
    }
    
    sub string {
        my ($class, $enum, $pattern, $min_length) = @_;
        my $schema = { type => "string" };
        if ($enum) {
            $schema->{enum} = $enum;
        }
        if ($pattern) {
            $schema->{pattern} = $pattern;
        }
        if (defined $min_length) {
            $schema->{"minLength"} = $min_length;
        }
        return $schema;
    }
    
    sub integer {
        my ($class, $minimum, $maximum) = @_;
        my $schema = { type => "integer" };
        if (defined $minimum) {
            $schema->{minimum} = $minimum;
        }
        if (defined $maximum) {
            $schema->{maximum} = $maximum;
        }
        return $schema;
    }
    
    sub array {
        my ($class, $items, $min_items) = @_;
        my $schema = { 
            type => "array", 
            items => $items 
        };
        if (defined $min_items) {
            $schema->{minItems} = $min_items;
        }
        return $schema;
    }
}

# Main Funktion
sub main {
    my ($input, $schema, $file, $repair);
    GetOptions(
        "schema|s=s" => \$schema,
        "file|f"     => \$file,
        "repair|r"   => \$repair,
        "help|h"     => sub { pod2usage(1) }
    ) or pod2usage(2);
    
    if (!@ARGV) {
        pod2usage(2);
    }
    
    $input = $ARGV[0];
    $repair //= 1;
    
    if (!$schema) {
        print STDERR "Error: --schema is required\n";
        exit 1;
    }
    
    # Lade Input (Auto-detect file vs string)
    my $raw_input;
    if ($file || (-f $input)) {
        open my $fh, '<:encoding(UTF-8)', $input or die "Cannot open input file '$input': $!";
        $raw_input = do { local $/; <$fh> };
        close $fh;
    } else {
        $raw_input = $input;
    }
    
    eval {
        my $result = validate_and_convert($raw_input, $schema, $repair);
        print encode_json($result) . "\n";
        print STDERR "\n✓ Validation passed\n";
    };
    if ($@) {
        if ($@->isa('SchemaValidationError') || $@->isa('JSONProcessingError')) {
            print STDERR "✗ Validation failed: " . $@->message . "\n";
        } else {
            print STDERR "✗ Validation failed: $@\n";
        }
        exit 1;
    }
}

# Dokumentation
__END__

=head1 NAME

json_schema_validator.pl - JSON Schema Validator

=head1 SYNOPSIS

json_schema_validator.pl [options] <input>

 Options:
   --schema|-s    Schema file (required)
   --file|-f      Input is file
   --repair|-r    Repair JSON (default)
   --help|-h      Show this help

=head1 DESCRIPTION

Validiert JSON gegen JSON Schema Draft 7/2020-12.

=cut

main() unless caller;
