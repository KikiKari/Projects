#!/usr/bin/perl
# websearch-research.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON qw(decode_json);
use File::Path qw(make_path);
use POSIX qw(strftime);

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.pl "Beschreibung des Problems"

my $query = $ARGV[0];
my $output_dir = $ARGV[1] // "./research";

if (!$query) {
    print "Verwendung: $0 \"Problem Beschreibung\" [OUTPUT_DIR]\n";
    exit 1;
}

make_path($output_dir);
my $timestamp = strftime "%Y%m%d_%H%M%S", localtime;
my $output_file = "$output_dir/incident_$timestamp.md";

open(my $fh, '>', $output_file) or die "Konnte Datei '$output_file' nicht öffnen: $!";

print $fh "# Incident Research\n";
print $fh "Datum: " . strftime("%Y-%m-%d %H:%M:%S", localtime) . "\n";
print $fh "Query: $query\n\n";

# 1. EXA für schnelle Recherche
print $fh "## 1. Schnelle Recherche (EXA)\n";

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $api_key = $ENV{'OPENROUTER_API_KEY'};
if (!$api_key) {
    die "OPENROUTER_API_KEY Umgebungsvariable nicht gesetzt\n";
}

my $req_data_exa = {
    model => "openai/gpt-5.6-terra",
    messages => [{ role => "user", content => $query }],
    plugins => [{ id => "web", engine => "exa", max_results => 5 }]
};

my $req_exa = POST 'https://openrouter.ai/api/v1/chat/completions',
    Content_Type => 'application/json',
    Authorization => "Bearer $api_key",
    Content => encode_json($req_data_exa);

my $res_exa = $ua->request($req_exa);

my $content_exa = "Keine Ergebnisse";
if ($res_exa->is_success) {
    my $data = decode_json($res_exa->decoded_content);
    $content_exa = $data->{choices}[0]{message}{content} // "Keine Ergebnisse";
}
print $fh "$content_exa\n\n---\n";

# 2. Verifizierte Quellen (Perplexity) falls verfügbar
print $fh "## 2. Verifizierte Fakten (Perplexity)\n";

my $req_data_perplexity = {
    model => "perplexity/sonar:online",
    messages => [{ role => "user", content => "$query troubleshooting" }]
};

my $req_perplexity = POST 'https://openrouter.ai/api/v1/chat/completions',
    Content_Type => 'application/json',
    Authorization => "Bearer $api_key",
    Content => encode_json($req_data_perplexity);

my $res_perplexity = $ua->request($req_perplexity);

my $content_perplexity = "Keine Ergebnisse";
if ($res_perplexity->is_success) {
    my $data = decode_json($res_perplexity->decoded_content);
    $content_perplexity = $data->{choices}[0]{message}{content} // "Keine Ergebnisse";
}
print $fh "$content_perplexity\n\n";

close $fh;

print "Gespeichert in: $output_file\n";
