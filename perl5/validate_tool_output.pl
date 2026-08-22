#!/usr/bin/perl
# validate_tool_output.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/validate_tool_output.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/validate_tool_output.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use JSON;
use File::Slurp;
use Data::Dumper;

# Hilfsfunktionen für Fehlerausgabe
sub error {
    my ($msg) = @_;
    print STDERR "Error: $msg\n";
    exit 1;
}

# Dynamisches Modell erstellen (vereinfacht)
sub create_dynamic_model {
    my ($schema) = @_;
    my %model;
    
    my $properties = $schema->{properties} || {};
    my $required = { map { $_ => 1 } @{$schema->{required} || []} };
    
    for my $field_name (keys %$properties) {
        my $field_info = $properties->{$field_name};
        my $field_type = 'string'; # Default
        
        my $json_type = $field_info->{type} || 'string';
        if ($json_type eq 'integer') {
            $field_type = 'integer';
        } elsif ($json_type eq 'number') {
            $field_type = 'number';
        } elsif ($json_type eq 'boolean') {
            $field_type = 'boolean';
        } elsif ($json_type eq 'array') {
            $field_type = 'array';
        } elsif ($json_type eq 'object') {
            $field_type = 'object';
        }
        
        my $default = exists $field_info->{default} ? $field_info->{default} : undef;
        unless ($required->{$field_name}) {
            $default = exists $field_info->{default} ? $field_info->{default} : undef;
        }
        
        $model{$field_name} = {
            type => $field_type,
            default => $default,
            description => $field_info->{description} || '',
        };
    }
    
    return \%model;
}

# Validierungsfunktion (vereinfacht)
sub parse_and_validate {
    my ($raw_input, $model, $repair, $strict) = @_;
    
    my $data;
    eval {
        $data = decode_json($raw_input);
    };
    if ($@) {
        error("Invalid JSON input: $@");
    }
    
    my $result = {};
    for my $field_name (keys %$model) {
        my $field_def = $model->{$field_name};
        my $value = $data->{$field_name};
        
        if (!defined $value && defined $field_def->{default}) {
            $value = $field_def->{default};
        }
        
        if (!defined $value) {
            next unless $strict;
            error("Missing required field: $field_name");
        }
        
        # Typvalidierung (vereinfacht)
        if ($field_def->{type} eq 'integer' && defined $value) {
            if (ref $value || $value !~ /^-?\d+$/) {
                error("Field '$field_name' must be an integer") unless $repair;
                $value = int($value);
            }
        } elsif ($field_def->{type} eq 'number' && defined $value) {
            if (ref $value || $value !~ /^-?\d+(\.\d+)?$/) {
                error("Field '$field_name' must be a number") unless $repair;
                $value = $value + 0;
            }
        } elsif ($field_def->{type} eq 'boolean' && defined $value) {
            if ($value ne 'true' && $value ne 'false' && $value != 0 && $value != 1) {
                error("Field '$field_name' must be a boolean") unless $repair;
                $value = $value ? 'true' : 'false';
            }
        } elsif ($field_def->{type} eq 'array' && defined $value) {
            if (ref $value ne 'ARRAY') {
                error("Field '$field_name' must be an array") unless $repair;
                $value = [$value];
            }
        } elsif ($field_def->{type} eq 'object' && defined $value) {
            if (ref $value ne 'HASH') {
                error("Field '$field_name' must be an object") unless $repair;
                $value = { value => $value };
            }
        }
        
        $result->{$field_name} = $value;
    }
    
    return $result;
}

# Hauptprogramm
sub main {
    my $json_input;
    my $schema_file;
    my $is_file = 0;
    my $repair = 1;
    my $strict = 0;
    
    GetOptions(
        'schema|s=s' => \$schema_file,
        'file|f'     => \$is_file,
        'repair|r'   => \$repair,
        'strict'     => \$strict,
    ) or error("Invalid options");
    
    @ARGV or error("Missing json_input argument");
    $json_input = $ARGV[0];
    
    $schema_file or error("--schema is required");
    
    # Lade Schema
    my $schema_content;
    eval {
        $schema_content = read_file($schema_file);
    };
    if ($@) {
        error("Error loading schema: $@");
    }
    
    my $schema;
    eval {
        $schema = decode_json($schema_content);
    };
    if ($@) {
        error("Invalid JSON in schema file: $@");
    }
    
    # Lade Input
    my $raw_input;
    if ($is_file) {
        eval {
            $raw_input = read_file($json_input);
        };
        if ($@) {
            error("Error loading input file: $@");
        }
    } else {
        $raw_input = $json_input;
    }
    
    # Erstelle dynamisches Modell und validiere
    my $model = create_dynamic_model($schema);
    my $result;
    eval {
        $result = parse_and_validate($raw_input, $model, $repair, $strict);
    };
    if ($@) {
        error("Validation error: $@");
    }
    
    print encode_json($result) . "\n";
}

main() unless caller;
