#!/usr/bin/env perl
# abstraction-provenance: {"artifact_sha256": "dcf290e63fc2196154be4aad1e985c01bf8d40b261421ea9a9ca9dc2d68b551e", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "perl5"}
# model_usage.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long qw(GetOptions);
use JSON qw(decode_json encode_json);
use File::Slurp qw(read_file);
use POSIX qw(strftime);

# Summarize CodexBar local cost usage by model.
#
# Defaults to current model (most recent daily entry), or list all models.

sub eprint {
    my ($msg) = @_;
    print STDERR "$msg\n";
}

sub run_codexbar_cost {
    my ($provider) = @_;
    my @cmd = ("codexbar", "cost", "--format", "json", "--provider", $provider);
    my $output;
    eval {
        open(my $fh, '-|', @cmd) or die "Failed to execute codexbar: $!";
        $output = do { local $/; <$fh> };
        close($fh);
    };
    if ($@) {
        if ($@ =~ /Failed to execute/) {
            die "codexbar not found on PATH. Install CodexBar CLI first.";
        } else {
            die "codexbar cost failed.";
        }
    }
    my $payload = eval { decode_json($output) };
    if ($@) {
        die "Failed to parse codexbar JSON output: $@";
    }
    if (ref($payload) ne 'ARRAY') {
        die "Expected codexbar cost JSON array.";
    }
    return $payload;
}

sub load_payload {
    my ($input_path, $provider) = @_;
    my $raw;
    if ($input_path) {
        if ($input_path eq '-') {
            $raw = do { local $/; <STDIN> };
        } else {
            $raw = read_file($input_path);
        }
    } else {
        my $data = run_codexbar_cost($provider);
        return { daily => $data };
    }

    my $data = eval { decode_json($raw) };
    if ($@) {
        die "Failed to parse JSON input: $@";
    }

    if (ref($data) eq 'HASH') {
        return $data;
    }

    if (ref($data) eq 'ARRAY') {
        for my $entry (@$data) {
            if (ref($entry) eq 'HASH' && exists $entry->{provider} && $entry->{provider} eq $provider) {
                return $entry;
            }
        }
        die "Provider '$provider' not found in codexbar payload.";
    }

    die "Unsupported JSON input format.";
}

sub parse_daily_entries {
    my ($payload) = @_;
    my $daily = $payload->{daily};
    return [] unless defined $daily && ref($daily) eq 'ARRAY';
    return [grep { ref($_) eq 'HASH' } @$daily];
}

sub parse_date {
    my ($value) = @_;
    return unless defined $value;
    eval {
        my ($year, $month, $day) = $value =~ /^(\d{4})-(\d{2})-(\d{2})$/;
        die unless defined $year && defined $month && defined $day;
        return sprintf("%04d-%02d-%02d", $year, $month, $day);
    };
    return;
}

sub filter_by_days {
    my ($entries, $days) = @_;
    return $entries unless defined $days;

    my $cutoff = strftime("%Y-%m-%d", localtime(time - ($days - 1) * 86400));
    my @filtered;
    for my $entry (@$entries) {
        next unless ref($entry) eq 'HASH';
        my $day = $entry->{date};
        next unless defined $day && !ref($day);
        my $parsed = parse_date($day);
        if ($parsed && $parsed ge $cutoff) {
            push @filtered, $entry;
        }
    }
    return \@filtered;
}

sub aggregate_costs {
    my ($entries) = @_;
    my %totals;
    for my $entry (@$entries) {
        next unless ref($entry) eq 'HASH';
        my $breakdowns = $entry->{modelBreakdowns};
        next unless defined $breakdowns && ref($breakdowns) eq 'ARRAY';
        for my $item (@$breakdowns) {
            next unless ref($item) eq 'HASH';
            my $model = $item->{modelName};
            my $cost = $item->{cost};
            next unless defined $model && !ref($model) && defined $cost && ($cost =~ /^\d+\.?\d*$/);
            $totals{$model} += $cost;
        }
    }
    return \%totals;
}

sub pick_current_model {
    my ($entries) = @_;
    return (undef, undef) unless @$entries;

    my @sorted_entries = sort { ($a->{date} || "") cmp ($b->{date} || "") } @$entries;
    for my $entry (reverse @sorted_entries) {
        my $breakdowns = $entry->{modelBreakdowns};
        if (defined $breakdowns && ref($breakdowns) eq 'ARRAY' && @$breakdowns) {
            my @scored;
            for my $item (@$breakdowns) {
                next unless ref($item) eq 'HASH';
                my $model = $item->{modelName};
                my $cost = $item->{cost};
                if (defined $model && !ref($model) && defined $cost && ($cost =~ /^\d+\.?\d*$/)) {
                    push @scored, { model => $model, cost => $cost };
                }
            }
            if (@scored) {
                @scored = sort { $b->{cost} <=> $a->{cost} } @scored;
                my $date = $entry->{date};
                $date = undef unless defined $date && !ref($date);
                return ($scored[0]{model}, $date);
            }
        }
        my $models_used = $entry->{modelsUsed};
        if (defined $models_used && ref($models_used) eq 'ARRAY' && @$models_used) {
            my $last = $models_used->[-1];
            if (defined $last && !ref($last)) {
                my $date = $entry->{date};
                $date = undef unless defined $date && !ref($date);
                return ($last, $date);
            }
        }
    }
    return (undef, undef);
}

sub usd {
    my ($value) = @_;
    return "—" unless defined $value;
    return sprintf("\$%.2f", $value);
}

sub latest_day_cost {
    my ($entries, $model) = @_;
    return (undef, undef) unless @$entries;

    my @sorted_entries = sort { ($a->{date} || "") cmp ($b->{date} || "") } @$entries;
    for my $entry (reverse @sorted_entries) {
        my $breakdowns = $entry->{modelBreakdowns};
        next unless defined $breakdowns && ref($breakdowns) eq 'ARRAY';
        for my $item (@$breakdowns) {
            next unless ref($item) eq 'HASH';
            if (exists $item->{modelName} && $item->{modelName} eq $model) {
                my $cost = $item->{cost};
                $cost = undef unless defined $cost && ($cost =~ /^\d+\.?\d*$/);
                my $day = $entry->{date};
                $day = undef unless defined $day && !ref($day);
                return ($day, $cost);
            }
        }
    }
    return (undef, undef);
}

sub render_text_current {
    my ($provider, $model, $latest_date, $total_cost, $latest_cost, $latest_cost_date, $entry_count) = @_;
    my @lines = ("Provider: $provider", "Current model: $model");
    push @lines, "Latest model date: $latest_date" if defined $latest_date;
    push @lines, "Total cost (rows): " . usd($total_cost);
    if (defined $latest_cost_date) {
        push @lines, "Latest day cost: " . usd($latest_cost) . " ($latest_cost_date)";
    }
    push @lines, "Daily rows: $entry_count";
    return join("\n", @lines);
}

sub render_text_all {
    my ($provider, $totals) = @_;
    my @lines = ("Provider: $provider", "Models:");
    for my $model (sort { $totals->{$b} <=> $totals->{$a} } keys %$totals) {
        my $cost = $totals->{$model};
        push @lines, "- $model: " . usd($cost);
    }
    return join("\n", @lines);
}

sub build_json_current {
    my ($provider, $model, $latest_date, $total_cost, $latest_cost, $latest_cost_date, $entry_count) = @_;
    return {
        provider => $provider,
        mode => "current",
        model => $model,
        latestModelDate => $latest_date,
        totalCostUSD => $total_cost,
        latestDayCostUSD => $latest_cost,
        latestDayCostDate => $latest_cost_date,
        dailyRowCount => $entry_count,
    };
}

sub build_json_all {
    my ($provider, $totals) = @_;
    my @models;
    for my $model (sort { $totals->{$b} <=> $totals->{$a} } keys %$totals) {
        push @models, { model => $model, totalCostUSD => $totals->{$model} };
    }
    return {
        provider => $provider,
        mode => "all",
        models => \@models,
    };
}

sub main {
    my $provider = "codex";
    my $mode = "current";
    my $model;
    my $input;
    my $days;
    my $format = "text";
    my $pretty;

    GetOptions(
        "provider=s" => \$provider,
        "mode=s"     => \$mode,
        "model=s"    => \$model,
        "input=s"    => \$input,
        "days=i"     => \$days,
        "format=s"   => \$format,
        "pretty"     => \$pretty,
    ) or die "Invalid options";

    my $payload;
    eval {
        $payload = load_payload($input, $provider);
    };
    if ($@) {
        eprint($@);
        return 1;
    }

    my $entries = parse_daily_entries($payload);
    $entries = filter_by_days($entries, $days);

    if ($mode eq "current") {
        my $latest_date;
        if (!defined $model) {
            ($model, $latest_date) = pick_current_model($entries);
        }
        if (!defined $model) {
            eprint("No model data found in codexbar cost payload.");
            return 2;
        }
        my $totals = aggregate_costs($entries);
        my $total_cost = $totals->{$model};
        my ($latest_cost_date, $latest_cost) = latest_day_cost($entries, $model);

        if ($format eq "json") {
            my $payload_out = build_json_current(
                $provider,
                $model,
                $latest_date,
                $total_cost,
                $latest_cost,
                $latest_cost_date,
                scalar @$entries
            );
            my $json = JSON->new;
            $json->pretty if $pretty;
            print $json->encode($payload_out) . "\n";
        } else {
            print render_text_current(
                $provider,
                $model,
                $latest_date,
                $total_cost,
                $latest_cost,
                $latest_cost_date,
                scalar @$entries
            ) . "\n";
        }
        return 0;
    }

    my $totals = aggregate_costs($entries);
    if (!%$totals) {
        eprint("No model breakdowns found in codexbar cost payload.");
        return 2;
    }

    if ($format eq "json") {
        my $payload_out = build_json_all($provider, $totals);
        my $json = JSON->new;
        $json->pretty if $pretty;
        print $json->encode($payload_out) . "\n";
    } else {
        print render_text_all($provider, $totals) . "\n";
    }
    return 0;
}

exit(main());
