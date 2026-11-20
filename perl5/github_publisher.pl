#!/usr/bin/perl
# github_publisher.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON qw(decode_json encode_json);
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256_hex);
use File::Temp qw(tempdir);
use File::Spec;
use File::Find;
use File::Copy;
use Cwd qw(abs_path getcwd);
use HTTP::Request;
use LWP::UserAgent;

my %LANGUAGES = map { $_ => 1 } qw(perl5 powershell perl6 tcl javascript ruby python lua shell go);

sub synchronize_checkout {
    my ($root, $remote, $branch) = @_;
    $remote //= "https://github.com/KikiKari/OpenClaw.git";
    $branch //= "gateway1-abstractions";

    $root = abs_path($root);
    die "Root path does not exist: $root" unless -d $root;

    my $tmp = tempdir("abstractions-snapshot-XXXXXX", CLEANUP => 1);
    my $snapshot = "$tmp/repo";

    system("git", "clone", "--quiet", "--depth=1", "--single-branch",
           "--branch", $branch, "--", $remote, $snapshot) == 0
        or die "Failed to clone repository";

    my $revision = `git -C "$snapshot" rev-parse HEAD`;
    chomp $revision;

    my %counts;
    for my $language (sort keys %LANGUAGES) {
        my $source = "$snapshot/$language";
        my $target = "$root/$language";

        if (-l $source || -l $target) {
            die "Language directory is a symlink";
        }

        if (-e $source && !-d $source) {
            die "Invalid remote language directory";
        }

        mkdir $target unless -d $target;

        my %known;
        if (opendir(my $dh, $target)) {
            while (my $file = readdir($dh)) {
                next if $file =~ /^\.\.?$/;
                my $path = "$target/$file";
                if (-f $path && !-l $path) {
                    open(my $fh, "<", $path) or die "Cannot open $path: $!";
                    my $content;
                    {
                        local $/;
                        $content = <$fh>;
                    }
                    close($fh);
                    $known{sha256_hex($content)} = 1;
                }
            }
            closedir($dh);
        }

        my @files;
        if (-d $source) {
            opendir(my $dh, $source) or die "Cannot open $source: $!";
            while (my $file = readdir($dh)) {
                next if $file =~ /^\.\.?$/;
                push @files, "$source/$file";
            }
            closedir($dh);
        }

        for my $file (@files) {
            if (-l $file || !-f $file) {
                die "Invalid remote abstraction";
            }
        }

        $counts{$language} = scalar @files;

        for my $item (@files) {
            open(my $fh, "<", $item) or die "Cannot open $item: $!";
            my $data;
            {
                local $/;
                $data = <$fh>;
            }
            close($fh);

            my $digest = sha256_hex($data);
            next if exists $known{$digest};

            my ($volume, $directories, $filename) = File::Spec->splitpath($item);
            my $destination = "$target/$filename";

            if (-e $destination || -l $destination) {
                my ($name, $suffix) = $filename =~ /^(.+?)(\.[^.]*$|$)/;
                $destination = "$target/${name}__pool_${digest}${suffix}";
            }

            eval {
                open(my $out_fh, ">", $destination) or die "Cannot create $destination: $!";
                print $out_fh $data;
                close($out_fh);
                1;
            } or do {
                if (-l $destination || !-f $destination) {
                    die "Local abstraction conflict";
                }
                open(my $check_fh, "<", $destination) or die "Cannot open $destination: $!";
                my $existing_data;
                {
                    local $/;
                    $existing_data = <$check_fh>;
                }
                close($check_fh);
                if ($existing_data ne $data) {
                    die "Local abstraction conflict";
                }
            };

            $known{$digest} = 1;
        }
    }

    return ($revision, \%counts);
}

sub update_status_counts {
    my ($path, $revision, $counts) = @_;

    open(my $fh, "<:encoding(UTF-8)", $path) or die "Cannot open $path: $!";
    my $text;
    {
        local $/;
        $text = <$fh>;
    }
    close($fh);

    my @rows = (
        "## Bestand",
        "",
        "GitHub-Stand: `$revision`",
        "",
        "| Zielsprache | Dateien |",
        "|---|---:|"
    );

    for my $language (sort keys %LANGUAGES) {
        push @rows, "| $language | $counts->{$language} |";
    }

    my $total = 0;
    $total += $_ for values %$counts;
    push @rows, "| **gesamt** | **$total** |", "", "";

    my $updated = $text;
    $updated =~ s/^## Bestand\n.*?(?=^## Quellen\n)/join("\n", @rows)/ems;

    if ($text eq $updated) {
        die "Status inventory section missing";
    }

    open(my $out_fh, ">:encoding(UTF-8)", $path) or die "Cannot write to $path: $!";
    print $out_fh $updated;
    close($out_fh);
}

sub queue_artifact {
    my ($state, $root, $path) = @_;

    $root = abs_path($root);
    $path = abs_path($path);

    if (-l $path) {
        die "Artifact must not be a symlink";
    }

    my $relative = File::Spec->abs2rel($path, $root);
    if ($relative ne 'STATUS.md' && (!defined $relative || !exists $LANGUAGES{(split '/', $relative)[0]})) {
        die "Artifact is outside a language directory";
    }

    open(my $fh, "<", $path) or die "Cannot open $path: $!";
    my $data;
    {
        local $/;
        $data = <$fh>;
    }
    close($fh);

    $state->{ausstehende_veroeffentlichungen} //= {};
    $state->{ausstehende_veroeffentlichungen}{$relative} = sha256_hex($data);
}

sub publish_pending {
    my ($root, $state, $save, $token, $opener, $sync) = @_;
    $opener //= sub {
        my $req = shift;
        my $ua = LWP::UserAgent->new;
        $ua->timeout(60);
        return $ua->request($req);
    };

    my $pending = $state->{ausstehende_veroeffentlichungen} // {};
    if (ref($pending) ne 'HASH') {
        die "Invalid publication queue";
    }

    if (!%$pending && !defined $sync) {
        return 1;
    }

    if (!$token || $token !~ /\S/) {
        return 0;
    }

    $root = abs_path($root);

    my %headers = (
        Authorization => "Bearer $token",
        Accept => "application/vnd.github+json",
        "X-GitHub-Api-Version" => "2022-11-28",
        "User-Agent" => "abstractions-manager"
    );

    my $success = 1;
    my @entries = sort { ($a->[0] eq 'STATUS.md') cmp ($b->[0] eq 'STATUS.md') } 
                  map { [$_, $pending->{$_}] } keys %$pending;

    my $synced = 0;
    for my $entry (@entries) {
        my ($name, $expected) = @$entry;
        eval {
            my $full_path = "$root/$name";
            if (-l $full_path || File::Spec->abs2rel(abs_path($full_path), $root) ne $name) {
                die "Invalid queued path";
            }

            open(my $fh, "<", $full_path) or die "Cannot open $full_path: $!";
            my $data;
            {
                local $/;
                $data = <$fh>;
            }
            close($fh);

            if (sha256_hex($data) ne $expected) {
                die "Queued artifact changed";
            }

            if ($name eq 'STATUS.md' && defined $sync) {
                if (!$success) {
                    die "Artifact publication incomplete";
                }
                my ($revision, $counts) = $sync->($root);
                $synced = 1;
                update_status_counts($full_path, $revision, $counts);

                open($fh, "<", $full_path) or die "Cannot open $full_path: $!";
                {
                    local $/;
                    $data = <$fh>;
                }
                close($fh);

                $expected = sha256_hex($data);
                $pending->{$name} = $expected;
                $save->($state);
            }

            my $lookup = sub {
                my $remote_name = shift;
                my $endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" . 
                               join("/", map { $_ =~ s/%/%25/g; $_ =~ s/([^A-Za-z0-9_.\-~\/])/sprintf("%%%02X", ord($1))/ge; $_ } split('/', $remote_name));
                my $url = $endpoint . "?ref=gateway1-abstractions";
                
                my $req = HTTP::Request->new(GET => $url);
                for my $key (keys %headers) {
                    $req->header($key => $headers{$key});
                }
                
                my $response = $opener->($req);
                if ($response->code == 404) {
                    return ($endpoint, undef);
                }
                if (!$response->is_success) {
                    die "HTTP error: " . $response->status_line;
                }
                
                return ($endpoint, decode_json($response->decoded_content));
            };

            my $same = sub {
                my $existing = shift;
                return 0 unless ref($existing) eq 'HASH';
                return 0 unless $existing->{encoding} eq "base64";
                return decode_base64($existing->{content} // "") eq $_[0];
            };

            my ($endpoint, $existing) = $lookup->($name);
            if ($name eq 'STATUS.md' && defined $existing && !$same->($existing, $data)) {
                my $sha = ref($existing) eq 'HASH' ? $existing->{sha} : undef;
                if (!defined $sha || $sha !~ /\S/) {
                    die "Missing remote status version";
                }
                
                my $body = encode_json({
                    message => "Update abstraction status",
                    branch => "gateway1-abstractions",
                    content => encode_base64($data, ""),
                    sha => $sha
                });
                
                my $req = HTTP::Request->new(PUT => $endpoint);
                for my $key (keys %headers) {
                    $req->header($key => $headers{$key});
                }
                $req->content($body);
                
                my $response = $opener->($req);
                if (!$response->is_success) {
                    die "HTTP error: " . $response->status_line;
                }
                decode_json($response->decoded_content);
            } elsif (defined $existing && !$same->($existing, $data)) {
                my ($volume, $directories, $filename) = File::Spec->splitpath($name);
                my ($name_part, $suffix) = $filename =~ /^(.+?)(\.[^.]*$|$)/;
                my $alternate = File::Spec->catpath($volume, $directories, "${name_part}_" . substr($expected, 0, 12) . $suffix);
                
                ($endpoint, $existing) = $lookup->($alternate);
                if (defined $existing && !$same->($existing, $data)) {
                    die "Remote artifact conflict";
                }
            }

            if (!defined $existing) {
                my $body = encode_json({
                    message => "Publish script abstraction",
                    branch => "gateway1-abstractions",
                    content => encode_base64($data, "")
                });
                
                my $req = HTTP::Request->new(PUT => $endpoint);
                for my $key (keys %headers) {
                    $req->header($key => $headers{$key});
                }
                $req->content($body);
                
                my $response = $opener->($req);
                if (!$response->is_success) {
                    die "HTTP error: " . $response->status_line;
                }
                decode_json($response->decoded_content);
            }

            delete $pending->{$name};
            $save->($state);
            1;
        } or do {
            $success = 0;
        };
    }

    if (defined $sync && !$synced) {
        eval {
            $sync->($root);
            1;
        } or do {
            $success = 0;
        };
    }

    return $success;
}

1;
