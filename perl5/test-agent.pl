#!/usr/bin/env perl
# test-agent.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway1:perplexity-pack/files/workspace/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:perplexity-pack/files/skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway1:skills/perplexity-pro-search/scripts/test-agent.sh
# auch in: OpenClaw@gateway2:skills/perplexity-pro-search/scripts/test-agent.sh
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use HTTP::Request;
use JSON;
use LWP::UserAgent;

die "PERPLEXITY_API_KEY is required\n" unless exists $ENV{PERPLEXITY_API_KEY};
my $api_key = $ENV{PERPLEXITY_API_KEY};

my $prompt = $ARGV[0] // "Compare recent open-source LLMs in terms of performance, licensing, and practical use.";
my $tmpdir = $ENV{TMPDIR} // "/tmp";
my $out = "$tmpdir/perplexity-agent-test.json";

my $json_data = encode_json({
    preset => "fast-search",
    input => $prompt
});

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(POST => 'https://api.perplexity.ai/v1/agent');
$req->header('Authorization' => "Bearer $api_key");
$req->header('Content-Type' => 'application/json');
$req->content($json_data);

my $response = $ua->request($req, $out);
my $code = $response->code;

print "agent_http=$code\n";

open my $fh, '<', $out or die "Cannot open $out: $!\n";
my $content = do { local $/; <$fh> };
close $fh;

my $data = decode_json($content);

my %result = (
    keys => [keys %$data],
    id => exists $data->{id} ? $data->{id} : undef,
    status => exists $data->{status} ? $data->{status} : undef,
    output_count => exists $data->{output} ? scalar(@{$data->{output}}) : 0,
    error => exists $data->{error} ? $data->{error} : undef
);

print encode_json(\%result), "\n";
