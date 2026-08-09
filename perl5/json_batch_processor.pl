#!/usr/bin/perl
# json_batch_processor.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON::PP;
use Getopt::Long;
use File::Spec;
use File::Basename;
use threads;
use Thread::Queue;

# JSON Batch Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON)

# Globale Variablen
my $json = JSON::PP->new->utf8;
my $HAS_PYDANTIC = 0; # In Perl nicht direkt verfügbar, daher immer 0

# BatchResult-Klasse (simuliert)
package BatchResult {
    sub new {
        my ($class, $index, $source, $success, $data, $error) = @_;
        my $self = {
            index => $index,
            source => $source,
            success => $success,
            data => $data,
            error => $error
        };
        bless $self, $class;
        return $self;
    }
    
    sub to_dict {
        my ($self) = @_;
        return {
            index => $self->{index},
            source => $self->{source},
            success => $self->{success},
            data => $self->{data},
            error => $self->{error}
        };
    }
}

# Hauptpaket
package main;

# Funktion zum Lesen von JSON-Lines (NDJSON)
sub read_jsonl {
    my ($file_path) = @_;
    my @results;
    
    open my $fh, '<:encoding(UTF-8)', $file_path or die "Cannot open $file_path: $!";
    
    my $line_num = 0;
    while (my $line = <$fh>) {
        $line_num++;
        chomp $line;
        $line =~ s/^\s+|\s+$//g; # strip
        next if !$line;
        
        eval {
            my $data = $json->decode($line);
            push @results, $data;
        };
        if ($@) {
            push @results, BatchResult->new(
                $line_num,
                "$file_path:$line_num",
                0,
                undef,
                "JSON decode error: $@"
            );
        }
    }
    close $fh;
    return @results;
}

# Funktion zur parallelen Batch-Verarbeitung
sub process_batch {
    my ($inputs_ref, $processor_ref, $max_workers) = @_;
    $max_workers //= 4;
    
    my @results;
    my @threads;
    my $queue = Thread::Queue->new();
    my $result_queue = Thread::Queue->new();
    
    # Worker threads starten
    for my $i (1..$max_workers) {
        my $thr = threads->create(sub {
            while (defined(my $item = $queue->dequeue())) {
                my ($inp, $idx) = @$item;
                eval {
                    my $result = $processor_ref->($inp, $idx);
                    $result_queue->enqueue($result);
                };
                if ($@) {
                    my $result = BatchResult->new(
                        $idx,
                        "$inp",
                        0,
                        undef,
                        "Unexpected error: $@"
                    );
                    $result_queue->enqueue($result);
                }
            }
        });
        push @threads, $thr;
    }
    
    # Aufgaben in die Queue stellen
    for my $idx (0..$#{$inputs_ref}) {
        $queue->enqueue([$inputs_ref->[$idx], $idx]);
    }
    
    # Queue beenden
    $queue->end();
    
    # Ergebnisse sammeln
    for my $thr (@threads) {
        $thr->join();
    }
    
    # Ergebnisse aus der Queue holen
    while (defined(my $result = $result_queue->dequeue_nb())) {
        push @results, $result;
    }
    
    # Nach Index sortieren
    @results = sort { $a->{index} <=> $b->{index} } @results;
    return @results;
}

# Funktion zur Verarbeitung von JSON-Dateien im Batch
sub process_file_batch {
    my ($file_paths_ref, $repair, $validate_model, $max_workers) = @_;
    $repair //= 1;
    $max_workers //= 4;
    
    my $processor = sub {
        my ($path, $idx) = @_;
        eval {
            open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
            my $content = do { local $/; <$fh> };
            close $fh;
            
            my $data;
            if ($validate_model && $HAS_PYDANTIC) {
                # In Perl keine direkte Pydantic-Unterstützung
                $data = parse_json($content, $repair);
            } else {
                $data = parse_json($content, $repair);
            }
            
            return BatchResult->new(
                $idx,
                "$path",
                1,
                $data,
                undef
            );
        };
        if ($@) {
            my $error = $@;
            chomp $error;
            return BatchResult->new(
                $idx,
                "$path",
                0,
                undef,
                $error
            );
        }
    };
    
    return process_batch($file_paths_ref, $processor, $max_workers);
}

# Funktion zur Verarbeitung von JSON-Lines-Dateien
sub process_jsonl_file {
    my ($file_path, $repair, $validate_model) = @_;
    $repair //= 1;
    
    my @results;
    open my $fh, '<:encoding(UTF-8)', $file_path or die "Cannot open $file_path: $!";
    
    my $line_num = 0;
    while (my $line = <$fh>) {
        $line_num++;
        chomp $line;
        $line =~ s/^\s+|\s+$//g; # strip
        next if !$line;
        
        eval {
            my $data;
            if ($validate_model && $HAS_PYDANTIC) {
                # In Perl keine direkte Pydantic-Unterstützung
                $data = parse_json($line, $repair);
            } else {
                $data = parse_json($line, $repair);
            }
            
            push @results, BatchResult->new(
                $line_num,
                "$file_path:$line_num",
                1,
                $data,
                undef
            );
        };
        if ($@) {
            my $error = $@;
            chomp $error;
            push @results, BatchResult->new(
                $line_num,
                "$file_path:$line_num",
                0,
                undef,
                $error
            );
        }
    }
    close $fh;
    return @results;
}

# Funktion zum Schreiben von JSON-Lines
sub write_jsonl {
    my ($results_ref, $output_path, $only_successful) = @_;
    $only_successful //= 1;
    
    open my $fh, '>:encoding(UTF-8)', $output_path or die "Cannot open $output_path: $!";
    
    for my $result (@$results_ref) {
        if ($only_successful && !$result->{success}) {
            next;
        }
        my $dict = $result->to_dict();
        print $fh $json->encode($dict) . "\n";
    }
    close $fh;
}

# Funktion zum Parsen von JSON mit Reparatur (vereinfacht)
sub parse_json {
    my ($content, $repair) = @_;
    $repair //= 1;
    
    eval {
        return $json->decode($content);
    };
    if ($@ && $repair) {
        # Versuche einfache Reparaturen
        my $cleaned = $content;
        # Entferne trailing commas
        $cleaned =~ s/,(\s*[}\]])/$1/g;
        # Entferne leading commas
        $cleaned =~ s/(\s*)\,(?=\s*["{\[])/$1/g;
        
        eval {
            return $json->decode($cleaned);
        };
        if ($@) {
            die "JSON parsing failed: $@";
        }
    } elsif ($@) {
        die "JSON parsing failed: $@";
    }
}

# Hauptfunktion
sub main {
    my @inputs;
    my $jsonl = 0;
    my $repair = 1;
    my $workers = 4;
    my $output = '';
    my $summary = 0;
    
    GetOptions(
        "jsonl|l" => \$jsonl,
        "repair|r" => \$repair,
        "workers|w=i" => \$workers,
        "output|o=s" => \$output,
        "summary|s" => \$summary,
        "<>" => sub { push @inputs, @_; }
    ) or die "Falsche Optionen\n";
    
    if (!@inputs) {
        die "Keine Eingabedateien angegeben\n";
    }
    
    my @all_results;
    
    if ($jsonl) {
        # JSON-Lines Modus
        for my $input_path (@inputs) {
            my @results = process_jsonl_file($input_path, $repair);
            push @all_results, @results;
        }
    } else {
        # Standard JSON Batch
        my @file_paths = @inputs;
        @all_results = process_file_batch(\@file_paths, $repair, undef, $workers);
    }
    
    # Ausgabe
    my $successful = 0;
    for my $result (@all_results) {
        $successful++ if $result->{success};
    }
    my $failed = scalar(@all_results) - $successful;
    
    if ($summary) {
        print "Processed: " . scalar(@all_results) . "\n";
        print "Successful: $successful\n";
        print "Failed: $failed\n";
    } else {
        for my $result (@all_results) {
            if ($result->{success}) {
                print $json->encode($result->{data}) . "\n";
            } else {
                print STDERR "ERROR [$result->{source}]: $result->{error}\n";
            }
        }
    }
    
    # Optional: JSONL Output
    if ($output) {
        write_jsonl(\@all_results, $output, 0);
        print STDERR "\nResults written to: $output\n";
    }
    
    # Exit code
    exit($failed == 0 ? 0 : 1);
}

main() if !caller;
