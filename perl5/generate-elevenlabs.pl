#!/usr/bin/perl
# generate-elevenlabs.mjs — portiert nach perl5
# Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Path qw(make_path);
use File::Spec;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use URI::URL;

# Umgebungsvariablen abrufen
my $key = $ENV{ELEVENLABS_API_KEY};
my $voiceId = $ENV{ELEVENLABS_VOICE_ID} || "JBFqnCBsd6RMkjVDRZzb";

# Fehler werfen, wenn API-Key fehlt
die "ELEVENLABS_API_KEY fehlt." unless $key;

my $text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.";

# HTTP-Client initialisieren
my $ua = LWP::UserAgent->new;

# POST-Request vorbereiten
my $url = "https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128";

my $req = POST $url,
    Content_Type => 'application/json',
    'xi-api-key' => $key,
    Content => encode_json({
        text => $text,
        model_id => "eleven_multilingual_v2",
        voice_settings => {
            stability => 0.58,
            similarity_boost => 0.72,
            style => 0.18,
            use_speaker_boost => \1  # true in JSON
        }
    });

# Request senden
my $response = $ua->request($req);

# Fehler werfen, wenn Request fehlschlägt
die "ElevenLabs fehlgeschlagen: " . $response->code unless $response->is_success;

# Zielverzeichnis erstellen
my $audio_dir = File::Spec->catdir(qw(.. public audio));
make_path($audio_dir) or die "Konnte Verzeichnis nicht erstellen: $!";

# Audio-Datei speichern
my $audio_file = File::Spec->catfile($audio_dir, "project-narration.mp3");
open my $fh, '>', $audio_file or die "Konnte Datei nicht öffnen: $!";
print $fh $response->content;
close $fh;

# JSON-Datei mit Metadaten erstellen
my $meta_data = {
    model => "eleven_multilingual_v2",
    voiceId => $voiceId,
    characters => length($text),
    text => $text,
    output => "public/audio/project-narration.mp3"
};

my $json_text = to_json($meta_data, { pretty => 1 });

my $meta_file = File::Spec->catfile(qw(.. media-production elevenlabs-result.json));
open my $meta_fh, '>', $meta_file or die "Konnte Metadaten-Datei nicht öffnen: $!";
print $meta_fh $json_text;
close $meta_fh;

print "ElevenLabs abgeschlossen: " . length($text) . " Zeichen.\n";
