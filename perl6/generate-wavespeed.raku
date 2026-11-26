#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "05fc0975b70a0cf409ef3790bf27ec7a54947a06f9e0e01499e4dcfa5dcd5926", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "perl6"}
# generate-wavespeed.mjs — portiert nach perl6
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use MONKEY-SEE-NO-EVAL;

constant $key = %*ENV<WAVESPEED_API_KEY>;
die "WAVESPEED_API_KEY fehlt." unless $key;

my $jobs-url = $*PROGRAM.parent(2).child("media-production/wavespeed-jobs.json");
my @jobs = from-json(slurp($jobs-url));

my $raw-dir = $*PROGRAM.parent(2).child("media-production/raw/");
my $public-dir = $*PROGRAM.parent(2).child("public/media/");
mkdir($raw-dir, :parents) unless $raw-dir.d;
mkdir($public-dir, :parents) unless $public-dir.d;

my $result-url = $*PROGRAM.parent(2).child("media-production/wavespeed-results.json");
my @log = try { from-json(slurp($result-url)) } // [];

for @jobs -> $job {
    my $raw-path = $raw-dir.child("{$job<id>}.png");
    my $target-path = $public-dir.child("{$job<output>}.png");
    my $already-generated = $raw-path.e;

    if $already-generated {
        unless @log.first({ $_<id> eq $job<id> }) {
            @log.push({
                id => $job<id>,
                requestId => "completed-before-resume",
                model => "google/nano-banana-2/edit",
                resolution => "4k",
                plannedCostUsd => 0.14,
                output => $target-path.basename
            });
            spurt($result-url, to-json(@log, :pretty));
        }
        say "Übersprungen: {$job<id>} ist bereits vorhanden.";
        next;
    }

    my @images = await Promise.at(-1).then({
        start {
            my @encoded-images;
            for $job<images>.list -> $image {
                if $image ~~ /^https?\: | ^data\:/ {
                    @encoded-images.push($image);
                } else {
                    my $image-path = $*PROGRAM.parent(2).child($image);
                    my $bytes = slurp($image-path, :bin);
                    @encoded-images.push("data:image/png;base64," ~ $bytes.encode('base64'));
                }
            }
            @encoded-images;
        }
    });

    my $submit-response = await HTTP::UserAgent.new.post(
        "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit",
        :headers({
            Authorization => "Bearer $key",
            Content-Type => "application/json"
        }),
        :content(to-json({
            prompt => $job<prompt>,
            images => @images,
            aspect_ratio => $job<aspectRatio>,
            resolution => "4k",
            output_format => "png",
            enable_web_search => False,
            enable_image_search => False,
            enable_sync_mode => False,
            enable_base64_output => False
        }))
    );

    unless $submit-response.is-success {
        my $detail = $submit-response.content;
        die "WaveSpeed submit fehlgeschlagen: {$submit-response.code} $detail";
    }

    my $submitted = from-json($submit-response.content);
    my $request-id = $submitted<data><id> // $submitted<id>;

    my $result;
    loop (my $attempt = 0; $attempt < 90; $attempt++) {
        await Promise.in(4);
        my $poll-response = await HTTP::UserAgent.new.get(
            "https://api.wavespeed.ai/api/v3/predictions/$request-id/result",
            :headers({ Authorization => "Bearer $key" })
        );
        $result = from-json($poll-response.content);
        last if $result<data><status> eq "completed";
        if $result<data><status> eq "failed" {
            die "WaveSpeed job fehlgeschlagen: {$job<id>}";
        }
    }

    my $url = $result<data><outputs>[0] // "";
    unless $url {
        die "Kein Output für {$job<id>}";
    }

    my $image-response = await HTTP::UserAgent.new.get($url);
    my $bytes = $image-response.content.Blob;
    spurt($raw-path, $bytes, :bin);
    spurt($target-path, $bytes, :bin);

    @log.push({
        id => $job<id>,
        requestId => $request-id,
        model => "google/nano-banana-2/edit",
        resolution => "4k",
        plannedCostUsd => 0.14,
        output => $target-path.basename
    });

    spurt($result-url, to-json(@log, :pretty));
    say "Abgeschlossen: {$job<id>}";
}

spurt($result-url, to-json(@log, :pretty));
say "WaveSpeed abgeschlossen: {@log.elems} Assets, geplante Basiskosten \$" ~ (@log.elems * 0.14).fmt("%.2f") ~ ".";
