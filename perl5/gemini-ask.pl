#!/usr/bin/env perl
# gemini-ask.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use Getopt::Long;
use File::Slurp;
use Env qw(GEMINI_API_KEY GEMINI_MODEL);

# Default model
my $DEFAULT_MODEL = $GEMINI_MODEL || 'gemini-pro';

# Parse command line options
my $model_name = $DEFAULT_MODEL;
my $system_prompt = '';
my $file_path = '';
my $prompt = '';

GetOptions(
    'model|m=s'  => \$model_name,
    'system|s=s' => \$system_prompt,
    'file|f=s'   => \$file_path,
) or die "Error in command line arguments\n";

# Check API key
if (!$GEMINI_API_KEY) {
    die "Error: GEMINI_API_KEY environment variable is required\n";
}

# Handle input from file, command line arguments or stdin
if ($file_path) {
    $prompt = read_file($file_path, binmode => ':utf8');
} elsif (@ARGV) {
    $prompt = join(' ', @ARGV);
} elsif (!-t STDIN) {
    # Read from stdin
    local $/ = undef;
    $prompt = <STDIN>;
}

if (!$prompt || $prompt =~ /^\s*$/) {
    die "Error: No prompt provided\n" .
        "Usage: gemini-ask \"your question\"\n" .
        "       gemini-ask --model gemini-pro \"your question\"\n" .
        "       echo \"your question\" | gemini-ask\n";
}

# Prepare the API request
my $ua = LWP::UserAgent->new;
my $api_url = "https://generativelanguage.googleapis.com/v1beta/models/$model_name:generateContent?key=$GEMINI_API_KEY";

# Prepare generation config
my $generation_config = {
    maxOutputTokens => 8192,
    temperature     => 0.7,
    topP           => 0.95,
};

# Prepare request content
my $request_content;
if ($system_prompt) {
    # Use chat with system prompt
    $request_content = {
        contents => [
            {
                role => 'user',
                parts => [{ text => $system_prompt }]
            },
            {
                role => 'model',
                parts => [{ text => 'Understood. I will follow that instruction.' }]
            },
            {
                role => 'user',
                parts => [{ text => $prompt }]
            }
        ],
        generationConfig => $generation_config
    };
} else {
    # Direct generation
    $request_content = {
        contents => [
            {
                role => 'user',
                parts => [{ text => $prompt }]
            }
        ],
        generationConfig => $generation_config
    };
}

# Create HTTP request
my $req = POST $api_url,
    Content_Type => 'application/json',
    Content      => encode_json($request_content);

# Send request
my $res = $ua->request($req);

if ($res->is_success) {
    my $data = decode_json($res->decoded_content);
    if (exists $data->{candidates} && @{$data->{candidates}} > 0) {
        print $data->{candidates}[0]{content}{parts}[0]{text}, "\n";
    } else {
        die "Error: No response from API\n";
    }
} else {
    my $error_msg = $res->status_line;
    if ($res->decoded_content) {
        my $error_data = decode_json($res->decoded_content);
        $error_msg = $error_data->{error}{message} if exists $error_data->{error}{message};
    }
    die "Error: $error_msg\n";
}
