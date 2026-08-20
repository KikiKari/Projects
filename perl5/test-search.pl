#!/usr/bin/env perl
# test-search.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-search.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-search.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use LWP::UserAgent;

die "PERPLEXITY_API_KEY is required\n" unless exists $ENV{PERPLEXITY_API_KEY};

my $query = $ARGV[0] || 'Perplexity API Platform';
my $max_results = $ENV{PERPLEXITY_MAX_RESULTS} || 3;
my $max_tokens_per_page = $ENV{PERPLEXITY_MAX_TOKENS_PER_PAGE} || 256;
my $out = ($ENV{TMPDIR} || '/tmp') . '/perplexity-search-test.json';

my $ua = LWP::UserAgent->new;
$ua->timeout(30);

my $req_data = {
    query => $query,
    max_results => int($max_results),
    max_tokens_per_page => int($max_tokens_per_page)
};

my $req = HTTP::Request->new(POST => 'https://api.perplexity.ai/search');
$req->header('Authorization' => "Bearer $ENV{PERPLEXITY_API_KEY}");
$req->header('Content-Type' => 'application/json');
$req->content(encode_json($req_data));

my $response = $ua->request($req);

open my $fh, '>', $out or die "Cannot write to $out: $!\n";
print $fh $response->decoded_content;
close $fh;

my $code = $response->code;
print "search_http=${code}\n";

# Parse and process the JSON response
my $json_text = $response->decoded_content;
my $data = decode_json($json_text);

# Determine results array (either 'results' or 'data' key)
my $results_array = [];
if (exists $data->{results} && ref $data->{results} eq 'ARRAY') {
    $results_array = $data->{results};
} elsif (exists $data->{data} && ref $data->{data} eq 'ARRAY') {
    $results_array = $data->{data};
}

# Get keys from the top-level object
my @keys = keys %$data;

# Get first result or null
my $first_result = @$results_array > 0 ? $results_array->[0] : undef;

# Create output structure
my $output = {
    keys => \@keys,
    result_count => scalar(@$results_array),
    first => $first_result
};

print encode_json($output) . "\n";
