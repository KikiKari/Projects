#!/usr/bin/perl
# verify-downloads.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:site/scripts/verify-downloads.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/scripts/verify-downloads.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use Digest::SHA qw(sha256_hex);
use JSON;
use File::Spec;
use File::Basename;
use Archive::Zip;

my ($base_url, $report_file);
GetOptions(
    'base-url=s' => \$base_url,
    'report=s'   => \$report_file,
) or die "Invalid options\n";

die "--base-url and --report are required\n" unless defined $base_url && defined $report_file;

# Determine root directory (parent of script's directory)
my $script_dir = dirname(__FILE__);
my $root = File::Spec->rel2abs(File::Spec->catdir($script_dir, '..'));

my $checksum_file = File::Spec->catdir($root, 'public', 'downloads', 'tiktok-live-companion-0.8.2-SHA256.txt');
open my $fh, '<:encoding(UTF-8)', $checksum_file or die "Cannot open $checksum_file: $!\n";
my @lines = <$fh>;
close $fh;

my @results;
foreach my $line (@lines) {
    chomp $line;
    next unless $line =~ /\S/;
    my ($expected, $name) = split /\s{2,}/, $line, 2;
    my $url = $base_url;
    $url =~ s/\/+$//;
    $url .= '/downloads/' . $name;

    # Download file content
    my $response = `curl -s --max-time 30 "$url"`;
    die "Failed to download $url\n" if $? != 0;

    my $actual = sha256_hex($response);

    # Check against local file
    my $local_path = File::Spec->catdir($root, 'public', 'downloads', $name);
    open my $local_fh, '<:raw', $local_path or die "Cannot open $local_path: $!\n";
    my $local_data;
    {
        local $/;
        $local_data = <$local_fh>;
    }
    close $local_fh;

    if ($actual ne $expected || $response ne $local_data) {
        die "HTTP artifact mismatch: $name\n";
    }

    # Verify ZIP integrity
    my $zip = Archive::Zip->new();
    my $status = $zip->readFromString(\$response);
    die "Cannot read ZIP from string: $status\n" if $status != AZ_OK;

    foreach my $member ($zip->members()) {
        if (!$member->isDirectory() && !$member->crc32() == $member->computeCRC32()) {
            die "Corrupt archive: $name\n";
        }
    }

    if ($name =~ /-extension-/) {
        my $manifest_content = $zip->contents('manifest.json');
        my $manifest = decode_json($manifest_content);
        if ($manifest->{version} ne '0.8.2') {
            die "Wrong extension version\n";
        }

        my @sources = ('background.js', 'content.js', 'sidepanel.js', 'sidepanel.html');
        foreach my $source (@sources) {
            my $source_content = $zip->contents($source);
            my $source_path = File::Spec->catdir($root, '..', 'plugin-source', 'browser-extension', $source);
            open my $src_fh, '<:raw', $source_path or die "Cannot open $source_path: $!\n";
            my $expected_source;
            {
                local $/;
                $expected_source = <$src_fh>;
            }
            close $src_fh;

            if ($source_content ne $expected_source) {
                die "Extension source mismatch: $source\n";
            }
        }
    }

    push @results, {
        name     => $name,
        sha256   => $actual,
        bytes    => length($response),
        verified => JSON::true,
    };
}

my $output = encode_json({
    base_url  => $base_url,
    artifacts => \@results,
});
$output =~ s/^/  /gm;  # Indentation like Python's indent=2
$output = "{\n  \"base_url\": \"" . $base_url . "\",\n  \"artifacts\": [\n" . join(",\n", map { "    $_" } split /\n/, substr($output, 2, -2)) . "\n  ]\n}\n";

open my $out_fh, '>:encoding(UTF-8)', $report_file or die "Cannot write to $report_file: $!\n";
print $out_fh $output;
close $out_fh;

print encode_json(\@results) . "\n";
