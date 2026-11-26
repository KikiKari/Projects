#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "2e93b6b7600202c234881632d591155eb663d6a011272c0125409aab9540edaf", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "perl6"}
# model_usage.py — portiert nach perl6
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use v6;

# Summarize CodexBar local cost usage by model.
#
# Defaults to current model (most recent daily entry), or list all models.

use JSON::Fast;
use Getopt::Long;

sub MAIN(
    Str :$provider where * eq any(<codex claude>) = 'codex',
    Str :$mode where * eq any(<current all>) = 'current',
    Str :$model,
    Str :$input,
    Int :$days,
    Str :$format where * eq any(<text json>) = 'text',
    Bool :$pretty
) {
    my $payload;
    try {
        $payload = load-payload($input, $provider);
        CATCH {
            note $_.message;
            exit 1;
        }
    }

    my @entries = parse-daily-entries($payload);
    @entries = filter-by-days(@entries, $days);

    if $mode eq 'current' {
        my $current-model = $model;
        my $latest-date;
        unless $current-model {
            ($current-model, $latest-date) = pick-current-model(@entries);
        }
        unless $current-model {
            note "No model data found in codexbar cost payload.";
            exit 2;
        }
        my %totals = aggregate-costs(@entries);
        my $total-cost = %totals{$current-model};
        my ($latest-cost-date, $latest-cost) = latest-day-cost(@entries, $current-model);

        if $format eq 'json' {
            my %payload-out = build-json-current(
                :provider($provider),
                :model($current-model),
                :latest-date($latest-date),
                :total-cost($total-cost),
                :latest-cost($latest-cost),
                :latest-cost-date($latest-cost-date),
                :entry-count(+@entries)
            );
            if $pretty {
                say to-json(%payload-out, :pretty);
            } else {
                say to-json(%payload-out);
            }
        } else {
            say render-text-current(
                :provider($provider),
                :model($current-model),
                :latest-date($latest-date),
                :total-cost($total-cost),
                :latest-cost($latest-cost),
                :latest-cost-date($latest-cost-date),
                :entry-count(+@entries)
            );
        }
        exit 0;
    }

    my %totals = aggregate-costs(@entries);
    unless +%totals {
        note "No model breakdowns found in codexbar cost payload.";
        exit 2;
    }

    if $format eq 'json' {
        my %payload-out = build-json-all(:provider($provider), :totals(%totals));
        if $pretty {
            say to-json(%payload-out, :pretty);
        } else {
            say to-json(%payload-out);
        }
    } else {
        say render-text-all(:provider($provider), :totals(%totals));
    }
    exit 0;
}

sub load-payload(Str $input-path, Str $provider) {
    my $data;
    if $input-path {
        if $input-path eq '-' {
            $data = from-json($*IN.slurp);
        } else {
            $data = from-json(slurp($input-path));
        }
    } else {
        $data = run-codexbar-cost($provider);
    }

    if $data ~~ Hash {
        return $data;
    }

    if $data ~~ Array {
        for @$data -> $entry {
            if $entry ~~ Hash && $entry<provider> eq $provider {
                return $entry;
            }
        }
        die "Provider '$provider' not found in codexbar payload.";
    }

    die "Unsupported JSON input format.";
}

sub run-codexbar-cost(Str $provider) {
    my @cmd = <codexbar cost --format json --provider>, $provider;
    my $proc = run(|@cmd, :out, :err);
    if $proc.exitcode != 0 {
        if $proc.err.lines.grep(/'not found'/) {
            die "codexbar not found on PATH. Install CodexBar CLI first.";
        } else {
            die "codexbar cost failed (exit {$proc.exitcode}).";
        }
    }
    my $output = $proc.out.slurp-rest;
    try {
        return from-json($output);
        CATCH {
            die "Failed to parse codexbar JSON output: $_";
        }
    }
}

sub parse-daily-entries(%payload) {
    my $daily = %payload<daily>;
    return [] unless $daily ~~ Array;
    return $daily.grep(* ~~ Hash);
}

sub filter-by-days(@entries, $days) {
    return @entries unless $days.defined;
    my $cutoff = Date.today - $days - 1;
    my @filtered;
    for @entries -> $entry {
        my $day = $entry<date>;
        next unless $day ~~ Str;
        my $parsed = parse-date($day);
        next unless $parsed.defined && $parsed >= $cutoff;
        @filtered.push($entry);
    }
    return @filtered;
}

sub parse-date(Str $value) {
    try {
        return Date.new($value);
        CATCH {
            return Nil;
        }
    }
}

sub aggregate-costs(@entries) {
    my %totals;
    for @entries -> $entry {
        my $breakdowns = $entry<modelBreakdowns>;
        next unless $breakdowns ~~ Array;
        for @$breakdowns -> $item {
            next unless $item ~~ Hash;
            my $model = $item<modelName>;
            my $cost = $item<cost>;
            next unless $model ~~ Str && $cost ~~ Numeric;
            %totals{$model} += $cost.Num;
        }
    }
    return %totals;
}

sub pick-current-model(@entries) {
    return (Nil, Nil) unless +@entries;
    my @sorted-entries = @entries.sort({ $_<date> // '' });
    for @sorted-entries.reverse -> $entry {
        my $breakdowns = $entry<modelBreakdowns>;
        if $breakdowns ~~ Array && +@$breakdowns {
            my @scored;
            for @$breakdowns -> $item {
                next unless $item ~~ Hash;
                my $model = $item<modelName>;
                my $cost = $item<cost>;
                if $model ~~ Str && $cost ~~ Numeric {
                    @scored.push({ modelName => $model, cost => $cost.Num });
                }
            }
            if +@scored {
                @scored .= sort({ -$_.<cost> });
                return (@scored[0]<modelName>, $entry<date> // Nil) if $entry<date> ~~ Str;
            }
        }
        my $models-used = $entry<modelsUsed>;
        if $models-used ~~ Array && +@$models-used {
            my $last = @$models-used[*-1];
            if $last ~~ Str {
                return ($last, $entry<date> // Nil) if $entry<date> ~~ Str;
            }
        }
    }
    return (Nil, Nil);
}

sub usd($value) {
    return '—' unless $value.defined;
    return '$' ~ $value.fmt('%.2f').subst(',', '', :g);
}

sub latest-day-cost(@entries, Str $model) {
    return (Nil, Nil) unless +@entries;
    my @sorted-entries = @entries.sort({ $_<date> // '' });
    for @sorted-entries.reverse -> $entry {
        my $breakdowns = $entry<modelBreakdowns>;
        next unless $breakdowns ~~ Array;
        for @$breakdowns -> $item {
            next unless $item ~~ Hash;
            if $item<modelName> eq $model {
                my $cost = $item<cost> ~~ Numeric ?? $item<cost>.Num !! Nil;
                my $day = $entry<date> ~~ Str ?? $entry<date> !! Nil;
                return ($day, $cost);
            }
        }
    }
    return (Nil, Nil);
}

sub render-text-current(
    Str :$provider,
    Str :$model,
    Str :$latest-date,
    :$total-cost,
    :$latest-cost,
    Str :$latest-cost-date,
    Int :$entry-count
) {
    my @lines = "Provider: $provider", "Current model: $model";
    @lines.push("Latest model date: $latest-date") if $latest-date.defined;
    @lines.push("Total cost (rows): {usd($total-cost)}");
    @lines.push("Latest day cost: {usd($latest-cost)} ($latest-cost-date)") if $latest-cost-date.defined;
    @lines.push("Daily rows: $entry-count");
    return @lines.join("\n");
}

sub render-text-all(Str :$provider, :%totals) {
    my @lines = "Provider: $provider", "Models:";
    for %totals.sort({ -$_.value }) -> ($model, $cost) {
        @lines.push("- $model: {usd($cost)}");
    }
    return @lines.join("\n");
}

sub build-json-current(
    Str :$provider,
    Str :$model,
    Str :$latest-date,
    :$total-cost,
    :$latest-cost,
    Str :$latest-cost-date,
    Int :$entry-count
) {
    return {
        provider => $provider,
        mode => 'current',
        model => $model,
        latestModelDate => $latest-date,
        totalCostUSD => $total-cost,
        latestDayCostUSD => $latest-cost,
        latestDayCostDate => $latest-cost-date,
        dailyRowCount => $entry-count
    };
}

sub build-json-all(Str :$provider, :%totals) {
    return {
        provider => $provider,
        mode => 'all',
        models => %totals.sort({ -$_.value }).map({
            { model => .key, totalCostUSD => .value }
        }).Array
    };
}
