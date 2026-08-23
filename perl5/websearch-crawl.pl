#!/usr/bin/perl
# websearch-crawl.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-crawl.sh
# auch in: OpenClaw@gateway2:scripts/websearch-crawl.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Path qw(make_path);
use Time::Piece;

# Web Search Script: Website Crawling mit Firecrawl
# Verwendung: ./websearch-crawl.pl <URL> [OUTPUT_DIR]

my $website_url = $ARGV[0];
my $output_dir = $ARGV[1] // "./crawled";

# API-Key aus Umgebungsvariable oder Datei lesen
my $firecrawl_api_key = $ENV{'FIRECRAWL_API_KEY'} // get_openrouter_key();

if (!$website_url) {
    print "Verwendung: $0 <URL> [OUTPUT_DIR]\n";
    exit 1;
}

# Ausgabeverzeichnis erstellen
make_path($output_dir);
print "Crawling $website_url...\n";

# User-Agent für HTTP-Anfragen
my $ua = LWP::UserAgent->new;

# Crawl starten
my $req = POST 'https://api.firecrawl.dev/v1/crawl',
    Content_Type => 'application/json',
    Authorization => "Bearer $firecrawl_api_key",
    Content => encode_json({
        url => $website_url,
        limit => 100,
        scrapeOptions => { formats => ['markdown'] }
    });

my $res = $ua->request($req);
if (!$res->is_success) {
    print "Fehler: Crawl konnte nicht gestartet werden\n";
    print $res->content . "\n";
    exit 1;
}

my $data = decode_json($res->content);
my $crawl_id = $data->{id} // '';
if (!$crawl_id) {
    print "Fehler: Crawl konnte nicht gestartet werden\n";
    print $res->content . "\n";
    exit 1;
}

print "Crawl ID: $crawl_id\n";

# Status prüfen
while (1) {
    my $status_req = GET "https://api.firecrawl.dev/v1/crawl/$crawl_id",
        Authorization => "Bearer $firecrawl_api_key";

    my $status_res = $ua->request($status_req);
    if (!$status_res->is_success) {
        print "Fehler beim Abfragen des Status\n";
        exit 1;
    }

    my $status_data = decode_json($status_res->content);
    my $status = $status_data->{status} // "unknown";
    print "Status: $status\n";

    if ($status eq "completed") {
        my $timestamp = localtime->strftime('%Y%m%d');
        open(my $fh, '>', "$output_dir/${timestamp}_crawl.json") or die "Konnte Datei nicht öffnen: $!";
        print $fh $status_res->content;
        close $fh;
        print "Gespeichert in $output_dir\n";
        last;
    } elsif ($status eq "failed") {
        print "Crawl fehlgeschlagen\n";
        exit 1;
    }
    sleep 5;
}

# Funktion zum Lesen des API-Keys aus der Datei
sub get_openrouter_key {
    my $home = $ENV{'HOME'};
    my $env_file = "$home/.openclaw/openclaw.env";
    if (-f $env_file) {
        open(my $fh, '<', $env_file) or return '';
        while (my $line = <$fh>) {
            if ($line =~ /OPENROUTER\s*=\s*"([^"]+)"/) {
                close $fh;
                return $1;
            }
        }
        close $fh;
    }
    return '';
}
