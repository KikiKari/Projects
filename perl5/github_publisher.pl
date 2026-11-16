#!/usr/bin/perl
# github_publisher.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use Digest::SHA qw(sha256_hex);
use MIME::Base64 qw(encode_base64 decode_base64);
use JSON qw(decode_json encode_json);
use File::Spec;
use Cwd qw(realpath);
use URI::Escape qw(uri_escape_utf8);

sub queue_artifact {
    my ($state, $root, $path) = @_;
    
    # Resolve paths
    $root = realpath($root);
    my $resolved_path = realpath($path);
    die "Path does not exist: $path" unless defined $resolved_path;
    
    # Check if it's a symlink
    if (-l $path) {
        die "artifact must not be a symlink";
    }
    
    # Get relative path
    my $relative = substr($resolved_path, length($root));
    $relative =~ s/^\/+//;  # Remove leading slashes
    
    # Validate that it's under a language directory
    my @parts = split('/', $relative);
    if (!@parts || $parts[0] !~ /^(perl5|powershell|perl6|tcl|javascript|ruby|python|lua|shell|go)$/) {
        die "artifact is outside a language directory";
    }
    
    # Read file content and calculate hash
    open(my $fh, '<:raw', $path) or die "Cannot read $path: $!";
    my $content;
    {
        local $/;
        $content = <$fh>;
    }
    close($fh);
    
    my $hash = sha256_hex($content);
    
    # Store in state
    $state->{ausstehende_veroeffentlichungen} //= {};
    $state->{ausstehende_veroeffentlichungen}{$relative} = $hash;
}

sub publish_pending {
    my ($root, $state, $save, $token, %options) = @_;
    my $opener = $options{opener} // sub {
        my ($request) = @_;
        require LWP::UserAgent;
        my $ua = LWP::UserAgent->new();
        $ua->timeout(60);
        return $ua->request($request);
    };
    
    my $pending = $state->{ausstehende_veroeffentlichungen} // {};
    
    # Validate pending structure
    if (ref($pending) ne 'HASH') {
        die "invalid publication queue";
    }
    
    # Return early if nothing to do
    if (!%$pending) {
        return 1;
    }
    
    # Check token
    if (!$token || $token !~ /\S/) {
        return 0;
    }
    
    $root = realpath($root);
    my %headers = (
        Authorization => "Bearer " . ($token =~ s/^\s+|\s+$//gr),
        Accept => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
        "User-Agent" => "abstractions-manager"
    );
    
    my $success = 1;
    
    # Work on a copy of the keys to avoid modification during iteration
    my @names = keys %$pending;
    
    for my $name (@names) {
        eval {
            my $expected = $pending->{$name};
            
            my $full_path = File::Spec->catfile($root, $name);
            
            # Check if it's still valid
            if (-l $full_path) {
                die "invalid queued path - is symlink";
            }
            
            my $resolved_path = realpath($full_path);
            die "Cannot resolve path: $full_path" unless defined $resolved_path;
            
            my $rel_path = substr($resolved_path, length($root));
            $rel_path =~ s/^\/+//;
            
            if ($rel_path ne $name) {
                die "invalid queued path - mismatch";
            }
            
            # Read file content and verify hash
            open(my $fh, '<:raw', $full_path) or die "Cannot read $full_path: $!";
            my $data;
            {
                local $/;
                $data = <$fh>;
            }
            close($fh);
            
            my $current_hash = sha256_hex($data);
            if ($current_hash ne $expected) {
                die "queued artifact changed";
            }
            
            # Helper functions
            sub lookup {
                my ($remote_name) = @_;
                my $endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" . uri_escape_utf8($remote_name, "^A-Za-z0-9_.~/-");
                
                require HTTP::Request;
                my $req = HTTP::Request->new(GET => $endpoint . "?ref=gateway1-abstractions");
                for my $key (keys %headers) {
                    $req->header($key => $headers{$key});
                }
                
                my $response = $opener->($req);
                if ($response->is_success) {
                    return ($endpoint, decode_json($response->decoded_content));
                } elsif ($response->code == 404) {
                    return ($endpoint, undef);
                } else {
                    die "HTTP Error: " . $response->status_line;
                }
            }
            
            sub same {
                my ($existing) = @_;
                return 0 unless ref($existing) eq 'HASH';
                return 0 unless exists $existing->{encoding} && $existing->{encoding} eq 'base64';
                return 0 unless exists $existing->{content};
                my $decoded = decode_base64($existing->{content});
                return $decoded eq $_[0];
            }
            
            # Check if file already exists
            my ($endpoint, $existing) = lookup($name);
            
            if (defined $existing && !same($data, $existing)) {
                # Need to create alternate filename
                my ($volume, $directories, $file) = File::Spec->splitpath($name);
                my ($filename) = $file =~ /^([^.]+)/;
                my $suffix = $file;
                $suffix =~ s/^[^.]+//;
                my $alternate = File::Spec->catpath($volume, $directories, $filename . "_" . substr($expected, 0, 12) . $suffix);
                
                ($endpoint, $existing) = lookup($alternate);
                
                if (defined $existing && !same($data, $existing)) {
                    die "remote artifact conflict";
                }
            }
            
            # Upload if needed
            if (!defined $existing) {
                my $content = encode_base64($data, '');
                my $body = encode_json({
                    message => "Publish script abstraction",
                    branch => "gateway1-abstractions",
                    content => $content
                });
                
                require HTTP::Request;
                my $req = HTTP::Request->new(PUT => $endpoint);
                for my $key (keys %headers) {
                    $req->header($key => $headers{$key});
                }
                $req->header('Content-Type' => 'application/json');
                $req->content($body);
                
                my $response = $opener->($req);
                if (!$response->is_success) {
                    die "Failed to upload: " . $response->status_line;
                }
                
                # Process response
                decode_json($response->decoded_content);
            }
            
            # Remove from pending and save state
            delete $pending->{$name};
            $save->($state);
            
            1;
        } or do {
            $success = 0;
        };
    }
    
    return $success;
}

1;
