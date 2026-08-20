#!/usr/bin/env perl
# test-embeddings.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-embeddings.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-embeddings.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Temp;

# Prüfe ob PERPLEXITY_API_KEY gesetzt ist
die "PERPLEXITY_API_KEY is required\n" unless exists $ENV{PERPLEXITY_API_KEY};

my $out = File::Temp->new( TEMPLATE => 'perplexity-embeddings-test-XXXX', SUFFIX => '.json' );
my $out_path = $out->filename;

# Erstelle Payload
my $payload = {
    input => [
        "Scientists explore the universe driven by curiosity.",
        "Curiosity compels us to seek explanations, not just observations.",
        "Historical discoveries began with curious questions.",
        "The pursuit of knowledge distinguishes human curiosity from mere stimulus response.",
        "Philosophy examines the nature of curiosity."
    ],
    model => "pplx-embed-v1-4b"
};

my $json_text = encode_json($payload);

# Sende Request
my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $req = POST 'https://api.perplexity.ai/v1/embeddings',
    Content_Type => 'application/json',
    Authorization => "Bearer $ENV{PERPLEXITY_API_KEY}",
    Content => $json_text;

my $response = $ua->request($req);

# Schreibe Response in Datei
open my $fh, '>', $out_path or die "Cannot write to $out_path: $!";
print $fh $response->content;
close $fh;

my $code = $response->code;
print "embeddings_http=${code}\n";

# Parse und zeige Ergebnisstruktur
my $data = decode_json($response->content // '{}');

my $result = {
    keys => [sort keys %$data],
    model => $data->{model} // undef,
    item_count => scalar(@{$data->{data} // []}),
    first_dim => (exists $data->{data} && @{$data->{data}} > 0) ? 
                 scalar(@{$data->{data}[0]{embedding} // []}) : 0,
    error => $data->{error} // undef
};

print encode_json($result) . "\n";
