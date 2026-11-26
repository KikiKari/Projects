#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "c90d858c7a19f38699d32bd0558f2980d939861b858c35ac2cde6285bfb7882a", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "perl5"}
# json_batch_processor.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use Getopt::Long;
use Pod::Usage;
use File::Basename;
use threads;
use Thread::Queue;

# Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

# Globale Variablen
my $json = JSON->new->utf8;
my $HAS_JSON_XS = eval { require JSON::XS; 1 };

# JSONProcessingError Exception-Klasse
package JSONProcessingError {
    sub new {
        my ($class, $message) = @_;
        my $self = { message => $message };
        bless $self, $class;
        return $self;
    }
    sub message { $_[0]->{message} }
}

# BatchResult Klasse
package BatchResult {
    sub new {
        my ($class, %args) = @_;
        my $self = {
            index     => $args{index},
            source    => $args{source},
            success   => $args{success} // 0,
            data      => $args{data},
            error     => $args{error}
        };
        bless $self, $class;
        return $self;
    }

    sub to_hash {
        my ($self) = @_;
        return {
            index   => $self->{index},
            source  => $self->{source},
            success => $self->{success},
            data    => $self->{data},
            error   => $self->{error}
        };
    }
}

# Hauptpaket
package main;

# Hilfsfunktionen
sub read_jsonl {
    my ($file_path) = @_;
    open my $fh, '<:encoding(UTF-8)', $file_path or die "Cannot open $file_path: $!";
    my @results;
    my $line_num = 0;
    while (my $line = <$fh>) {
        chomp $line;
        $line_num++;
        next unless $line =~ /\S/;
        eval {
            my $data = $json->decode($line);
            push @results, $data;
        };
        if ($@) {
            push @results, BatchResult->new(
                index   => $line_num,
                source  => "$file_path:$line_num",
                success => 0,
                error   => "JSON decode error: $@"
            );
        }
    }
    close $fh;
    return @results;
}

sub parse_json {
    my ($content, $repair) = @_;
    $repair //= 1;
    eval {
        return $json->decode($content);
    };
    if ($@ && $repair) {
        # Versuche einfache Reparaturen
        $content =~ s/,\s*}/}/g;
        $content =~ s/\[\s*,/[/g;
        $content =~ s/,(\s*[}\]])/$1/g;
        eval {
            return $json->decode($content);
        };
    }
    die JSONProcessingError->new("Invalid JSON: $@");
}

sub process_file_batch_worker {
    my ($queue, $results_queue, $repair, $validate_model) = @_;
    while (defined(my $item = $queue->dequeue)) {
        my ($path, $idx) = @$item;
        my $result = process_single_file($path, $idx, $repair, $validate_model);
        $results_queue->enqueue($result);
    }
    $results_queue->enqueue(undef); # Signal beenden
}

sub process_single_file {
    my ($path, $idx, $repair, $validate_model) = @_;
    eval {
        open my $fh, '<:encoding(UTF-8)', $path or die "Cannot open $path: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        my $data;
        if ($validate_model) {
            # Ohne Pydantic-Unterstützung immer nur parsen
            $data = parse_json($content, $repair);
        } else {
            $data = parse_json($content, $repair);
        }
        return BatchResult->new(
            index   => $idx,
            source  => "$path",
            success => 1,
            data    => $data
        );
    };
    if ($@) {
        my $error_msg = $@;
        if (ref($error_msg) && $error_msg->isa('JSONProcessingError')) {
            $error_msg = $error_msg->message;
        } else {
            $error_msg = ref($error_msg) . ": $error_msg";
        }
        return BatchResult->new(
            index   => $idx,
            source  => "$path",
            success => 0,
            error   => $error_msg
        );
    }
}

sub process_file_batch {
    my ($file_paths, $repair, $validate_model, $max_workers) = @_;
    $repair //= 1;
    $max_workers //= 4;

    my $queue = Thread::Queue->new();
    my $results_queue = Thread::Queue->new();

    for my $idx (0 .. $#{$file_paths}) {
        $queue->enqueue([$file_paths->[$idx], $idx]);
    }

    my @threads;
    for (1..$max_workers) {
        my $thr = threads->create(\&process_file_batch_worker, $queue, $results_queue, $repair, $validate_model);
        push @threads, $thr;
    }

    my @results;
    my $finished = 0;
    while ($finished < $max_workers) {
        my $result = $results_queue->dequeue;
        if (!defined $result) {
            $finished++;
        } else {
            push @results, $result;
        }
    }

    for my $thr (@threads) {
        $thr->join();
    }

    @results = sort { $a->{index} <=> $b->{index} } @results;
    return @results;
}

sub process_jsonl_file {
    my ($file_path, $repair, $validate_model) = @_;
    $repair //= 1;

    my @results;
    open my $fh, '<:encoding(UTF-8)', $file_path or die "Cannot open $file_path: $!";
    my $line_num = 0;
    while (my $line = <$fh>) {
        chomp $line;
        $line_num++;
        next unless $line =~ /\S/;
        eval {
            my $data;
            if ($validate_model) {
                # Ohne Pydantic immer nur parsen
                $data = parse_json($line, $repair);
            } else {
                $data = parse_json($line, $repair);
            }
            push @results, BatchResult->new(
                index   => $line_num,
                source  => "$file_path:$line_num",
                success => 1,
                data    => $data
            );
        };
        if ($@) {
            my $error_msg = $@;
            if (ref($error_msg) && $error_msg->isa('JSONProcessingError')) {
                $error_msg = $error_msg->message;
            } else {
                $error_msg = ref($error_msg) . ": $error_msg";
            }
            push @results, BatchResult->new(
                index   => $line_num,
                source  => "$file_path:$line_num",
                success => 0,
                error   => $error_msg
            );
        }
    }
    close $fh;
    return @results;
}

sub write_jsonl {
    my ($results, $output_path, $only_successful) = @_;
    $only_successful //= 1;
    open my $fh, '>:encoding(UTF-8)', $output_path or die "Cannot write to $output_path: $!";
    for my $result (@$results) {
        if ($only_successful && !$result->{success}) {
            next;
        }
        my $hash = $result->to_hash;
        print $fh $json->encode($hash) . "\n";
    }
    close $fh;
}

sub main {
    my @inputs;
    my $jsonl = 0;
    my $repair = 1;
    my $workers = 4;
    my $output;
    my $summary = 0;
    my $help = 0;

    GetOptions(
        'jsonl|l'     => \$jsonl,
        'repair|r!'   => \$repair,
        'workers|w=i' => \$workers,
        'output|o=s'  => \$output,
        'summary|s'   => \$summary,
        'help|h'      => \$help,
    ) or pod2usage(2);

    pod2usage(1) if $help;

    @inputs = @ARGV;
    if (@inputs == 0) {
        pod2usage("No input files provided.");
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

    # Statistiken
    my $successful = 0;
    my $failed = 0;
    for my $result (@all_results) {
        if ($result->{success}) {
            $successful++;
        } else {
            $failed++;
        }
    }

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

    exit($failed == 0 ? 0 : 1);
}

main() unless caller;

__END__

=head1 NAME

json_batch_processor - Batch JSON Processor

=head1 SYNOPSIS

json_batch_processor [options] file1.json [file2.json ...]

 Options:
   --jsonl, -l           Treat inputs as JSON-Lines files
   --repair, -r          Enable JSON repair (default)
   --no-repair           Disable JSON repair
   --workers, -w NUM     Parallel workers (default: 4)
   --output, -o FILE     Output JSON-Lines file
   --summary, -s         Show summary only
   --help, -h            Show this help

=head1 DESCRIPTION

Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).

=cut
