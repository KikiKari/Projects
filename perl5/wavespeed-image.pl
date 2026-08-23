#!/usr/bin/perl
# wavespeed-image.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/wavespeed-image.js
# auch in: OpenClaw@gateway2:wavespeed-image.js
# auch in: OpenClaw@gateway2:scripts/wavespeed-image.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Basename;
use HTTP::Tiny;
use JSON::PP;

# Config
my $API_BASE = 'https://api.wavespeed.ai/v1';
my $MAX_IMAGES = 7;
my $PRICE_PER_IMAGE = 0.14;

# Load token from env
my $BANANA_TOKEN = $ENV{'BANANA_TOKEN'};

sub show_usage {
    print <<'EOF';

Usage: wavespeed-image <command> [options]

Commands:
  analyze <image...>    Analyze one or more images

Options:
  --prompt <text>       Analysis prompt (required)
  --dry-run             Show cost without executing
  -h, --help            Show this help

Examples:
  wavespeed-image analyze photo.jpg --prompt "What's in this image?"
  wavespeed-image analyze img1.jpg img2.jpg --prompt "Compare these"

EOF
}

sub show_cost_warning {
    my ($image_count) = @_;
    my $total_cost = sprintf("%.2f", $image_count * $PRICE_PER_IMAGE);
    my $count_padded = sprintf("%-44s", $image_count);
    my $price_padded = sprintf("%-43s", $PRICE_PER_IMAGE);
    my $cost_padded = sprintf("%-44s", $total_cost);

    print <<"EOF";

╔════════════════════════════════════════════════════════════╗
║  ⚠️  KOSTENHINWEIS — WaveSpeed Image Analysis              ║
╠════════════════════════════════════════════════════════════╣
║  Anzahl Bilder: $count_padded║
║  Preis pro Bild: \$$price_padded║
║  Gesamtkosten: ~\$$cost_padded║
╠════════════════════════════════════════════════════════════╣
║  Abrechnung über dein WaveSpeed Guthaben                   ║
║  https://wavespeed.ai/account/billing                      ║
╚════════════════════════════════════════════════════════════╝

EOF
}

sub confirm_execution {
    # In OpenClaw context, this would be handled by the system
    # For CLI: require explicit --confirm flag
    return grep { $_ eq '--confirm' } @ARGV;
}

sub analyze_images {
    my ($image_paths_ref, $prompt) = @_;
    my @image_paths = @$image_paths_ref;
    print "\n🖼️  Analysiere " . scalar(@image_paths) . " Bilder...\n";
    print "📝 Prompt: \"$prompt\"\n";
    print "\n⏳ Anfrage wird gesendet...\n\n";

    # TODO: Implement actual API call
    # For now, return simulated response
    my @results = map {
        {
            file => basename($_),
            analysis => "[Analyse-Ergebnis für " . basename($_) . " würde hier stehen]"
        }
    } @image_paths;

    return {
        success => 1,
        results => \@results
    };
}

sub main {
    my @args = @ARGV;

    if (@args == 0 || grep { $_ eq '-h' || $_ eq '--help' } @args) {
        show_usage();
        exit 0;
    }

    # Check auth
    if (!$BANANA_TOKEN) {
        print "❌ Fehler: BANANA_TOKEN nicht gesetzt in ~/.config/openclaw/env\n";
        exit 1;
    }

    my $command = $args[0];

    if ($command eq 'analyze') {
        # Parse arguments
        my @image_paths;
        my $prompt = '';
        my $dry_run = 0;
        my $confirm = 0;
        my $i = 1;

        while ($i < @args) {
            if ($args[$i] eq '--prompt') {
                $prompt = $args[++$i] || '';
            } elsif ($args[$i] eq '--dry-run') {
                $dry_run = 1;
            } elsif ($args[$i] eq '--confirm') {
                $confirm = 1;
            } elsif ($args[$i] !~ /^--/) {
                push @image_paths, $args[$i];
            }
            $i++;
        }

        # Validate
        if (@image_paths == 0) {
            print "❌ Fehler: Mindestens ein Bild-Pfad erforderlich\n";
            exit 1;
        }

        if (@image_paths > $MAX_IMAGES) {
            print "❌ Fehler: Maximum $MAX_IMAGES Bilder erlaubt\n";
            exit 1;
        }

        if (!$prompt) {
            print "❌ Fehler: --prompt erforderlich\n";
            exit 1;
        }

        # Validate files exist
        for my $img (@image_paths) {
            if (!-e $img) {
                print "❌ Fehler: Datei nicht gefunden: $img\n";
                exit 1;
            }
        }

        # Show cost warning
        show_cost_warning(scalar(@image_paths));

        # Dry run
        if ($dry_run) {
            print "✅ Dry-run: Keine API-Anfrage gesendet\n\n";
            exit 0;
        }

        # Check for confirmation
        if (!$confirm) {
            print "\n⚠️  Hinweis: Füge --confirm hinzu um die Anfrage auszuführen\n";
            print "   Befehl: wavespeed-image analyze " . join(' ', @image_paths) . " --prompt \"$prompt\" --confirm\n\n";
            exit 0;
        }

        # Execute
        my $result = analyze_images(\@image_paths, $prompt);

        if ($result->{success}) {
            print "✅ Analyse abgeschlossen\n\n";
            for my $r (@{$result->{results}}) {
                print "📄 $r->{file}:\n";
                print "   $r->{analysis}\n\n";
            }
        }

    } else {
        print "❌ Unbekannter Befehl: $command\n";
        show_usage();
        exit 1;
    }
}

eval {
    main();
};
if ($@) {
    print "❌ Fehler: $@\n";
    exit 1;
}
