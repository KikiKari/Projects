#!/usr/bin/perl
# generate-wavespeed.mjs — portiert nach perl5
# Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON;
use File::Spec;
use File::Path qw(make_path);
use LWP::UserAgent;
use HTTP::Request;
use MIME::Base64;
use Time::HiRes qw(sleep);

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

# Umgebungsvariable prüfen
my $key = $ENV{'WAVESPEED_API_KEY'};
die "WAVESPEED_API_KEY fehlt." unless $key;

# Pfade bestimmen
my $script_dir = __FILE__;
$script_dir =~ s/[^\/\\]+$//;
my $base_dir = $script_dir;
$base_dir =~ s/[\/\\]media-production[\/\\]?$//;
my $jobs_file = File::Spec->catfile($base_dir, 'media-production', 'wavespeed-jobs.json');
my $raw_dir = File::Spec->catfile($base_dir, 'media-production', 'raw');
my $public_dir = File::Spec->catfile($base_dir, 'public', 'media');
my $result_file = File::Spec->catfile($base_dir, 'media-production', 'wavespeed-results.json');

# Verzeichnisse erstellen
make_path($raw_dir) unless -d $raw_dir;
make_path($public_dir) unless -d $public_dir;

# Jobs laden
open my $fh, '<:encoding(UTF-8)', $jobs_file or die "Kann $jobs_file nicht lesen: $!";
my $jobs_json = do { local $/; <$fh> };
close $fh;
my $jobs = decode_json($jobs_json);

# Log laden oder initialisieren
my $log = [];
if (-f $result_file) {
    open my $log_fh, '<:encoding(UTF-8)', $result_file or die "Kann $result_file nicht lesen: $!";
    my $log_json = do { local $/; <$log_fh> };
    close $log_fh;
    $log = decode_json($log_json // '[]');
}

# HTTP-Client initialisieren
my $ua = LWP::UserAgent->new;
$ua->timeout(60);

for my $job (@$jobs) {
    my $raw_path = File::Spec->catfile($raw_dir, $job->{id} . '.png');
    my $target_filename = $job->{output} . '.png';
    my $target_path = File::Spec->catfile($public_dir, $target_filename);
    
    # Prüfen, ob bereits generiert
    if (-f $raw_path) {
        my $found = 0;
        for my $entry (@$log) {
            if ($entry->{id} eq $job->{id}) {
                $found = 1;
                last;
            }
        }
        unless ($found) {
            push @$log, {
                id => $job->{id},
                requestId => 'completed-before-resume',
                model => 'google/nano-banana-2/edit',
                resolution => '4k',
                plannedCostUsd => 0.14,
                output => $target_filename
            };
            open my $out_fh, '>:encoding(UTF-8)', $result_file or die "Kann $result_file nicht schreiben: $!";
            print $out_fh encode_json($log);
            close $out_fh;
        }
        print "Übersprungen: $job->{id} ist bereits vorhanden.\n";
        next;
    }
    
    # Bilder laden
    my @images;
    for my $image (@{$job->{images}}) {
        if ($image =~ /^https?:|^data:/) {
            push @images, $image;
        } else {
            my $image_path = File::Spec->catfile($base_dir, $image);
            open my $img_fh, '<:raw', $image_path or die "Kann $image_path nicht lesen: $!";
            my $content;
            {
                local $/;
                $content = <$img_fh>;
            }
            close $img_fh;
            my $encoded = encode_base64($content, '');
            push @images, "data:image/png;base64,$encoded";
        }
    }
    
    # Request vorbereiten
    my $req_data = {
        prompt => $job->{prompt},
        images => \@images,
        aspect_ratio => $job->{aspectRatio},
        resolution => '4k',
        output_format => 'png',
        enable_web_search => JSON::false,
        enable_image_search => JSON::false,
        enable_sync_mode => JSON::false,
        enable_base64_output => JSON::false
    };
    
    my $req = HTTP::Request->new('POST' => 'https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit');
    $req->header('Authorization' => "Bearer $key");
    $req->header('Content-Type' => 'application/json');
    $req->content(encode_json($req_data));
    
    # Request senden
    my $res = $ua->request($req);
    unless ($res->is_success) {
        die "WaveSpeed submit fehlgeschlagen: " . $res->status_line . " " . $res->content;
    }
    
    my $submitted = decode_json($res->content);
    my $requestId = $submitted->{data}->{id} // $submitted->{id};
    my $result;
    
    # Polling
    for my $attempt (0..89) {
        sleep(4);
        my $poll_req = HTTP::Request->new('GET' => "https://api.wavespeed.ai/api/v3/predictions/$requestId/result");
        $poll_req->header('Authorization' => "Bearer $key");
        my $poll_res = $ua->request($poll_req);
        $result = decode_json($poll_res->content);
        if ($result->{data}->{status} eq 'completed') {
            last;
        }
        if ($result->{data}->{status} eq 'failed') {
            die "WaveSpeed job fehlgeschlagen: $job->{id}";
        }
    }
    
    my $url = $result->{data}->{outputs}->[0];
    unless ($url) {
        die "Kein Output für $job->{id}";
    }
    
    # Bild herunterladen
    my $img_res = $ua->get($url);
    unless ($img_res->is_success) {
        die "Kann Bild von $url nicht herunterladen";
    }
    
    # Speichern
    open my $raw_fh, '>:raw', $raw_path or die "Kann $raw_path nicht schreiben: $!";
    print $raw_fh $img_res->content;
    close $raw_fh;
    
    open my $target_fh, '>:raw', $target_path or die "Kann $target_path nicht schreiben: $!";
    print $target_fh $img_res->content;
    close $target_fh;
    
    push @$log, {
        id => $job->{id},
        requestId => $requestId,
        model => 'google/nano-banana-2/edit',
        resolution => '4k',
        plannedCostUsd => 0.14,
        output => $target_filename
    };
    
    open my $out_fh, '>:encoding(UTF-8)', $result_file or die "Kann $result_file nicht schreiben: $!";
    print $out_fh encode_json($log);
    close $out_fh;
    
    print "Abgeschlossen: $job->{id}\n";
}

# Abschließendes Log schreiben
open my $final_fh, '>:encoding(UTF-8)', $result_file or die "Kann $result_file nicht schreiben: $!";
print $final_fh encode_json($log);
close $final_fh;

my $count = scalar @$log;
my $cost = $count * 0.14;
printf "WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten \$%.2f.\n", $count, $cost;
