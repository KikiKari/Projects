#!/usr/bin/perl
# websearch-research.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/websearch-research.sh
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);
use JSON;
use File::Path qw(make_path);
use POSIX qw(strftime);

# Web Search Script: Deep Research für Incidents
# Verwendung: ./websearch-research.pl "Beschreibung des Problems"

my $query = $ARGV[0];
my $output_dir = $ARGV[1] // "./research";

if (!defined $query) {
    print "Verwendung: $0 \"Problem Beschreibung\" [OUTPUT_DIR]\n";
    exit 1;
}

make_path($output_dir);
my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);
my $output_file = "$output_dir/incident_$timestamp.md";

open(my $fh, '>', $output_file) or die "Kann Datei '$output_file' nicht öffnen: $!";

print $fh "# Incident Research\n";
print $fh "Datum: " . strftime("%Y-%m-%d %H:%M:%S", localtime) . "\n";
print $fh "Query: $query\n\n";

# 1. EXA für schnelle Recherche
print $fh "## 1. Schnelle Recherche (EXA)\n";

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $exa_data = {
    model => "openai/gpt-5.4-mini",
    messages => [{ role => "user", content => $query }],
    plugins => [{ id => "web", engine => "exa", max_results => 5 }]
};

my $exa_request = POST 'https://openrouter.ai/api/v1/chat/completions',
    Content_Type => 'application/json',
    Content => encode_json($exa_data),
    Authorization => "Bearer $ENV{OPENROUTER_API_KEY}";

my $exa_response = $ua->request($exa_request);
my $exa_result = "Keine Ergebnisse";

if ($exa_response->is_success) {
    my $json_response = decode_json($exa_response->decoded_content);
    $exa_result = $json_response->{choices}[0]{message}{content} // "Keine Ergebnisse";
}

print $fh "$exa_result\n\n";
print $fh "---\n\n";

# 2. Verifizierte Quellen (Perplexity) falls verfügbar
print $fh "## 2. Verifizierte Fakten (Perplexity)\n";

my $perplexity_data = {
    model => "perplexity/sonar:online",
    messages => [{ role => "user", content => "$query troubleshooting" }]
};

my $perplexity_request = POST 'https://openrouter.ai/api/v1/chat/completions',
    Content_Type => 'application/json',
    Content => encode_json($perplexity_data),
    Authorization => "Bearer $ENV{OPENROUTER_API_KEY}";

my $perplexity_response = $ua->request($perplexity_request);
my $perplexity_result = "Keine Ergebnisse";

if ($perplexity_response->is_success) {
    my $json_response = decode_json($perplexity_response->decoded_content);
    $perplexity_result = $json_response->{choices}[0]{message}{content} // "Keine Ergebnisse";
}

print $fh "$perplexity_result\n\n";
print $fh "Gespeichert in: $output_file\n";

close($fh);
