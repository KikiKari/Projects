#!/usr/bin/perl
# secret-scan.mjs — portiert nach perl5
# Quelle: javascript, Onboarding@main:scripts/secret-scan.mjs
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Find;
use File::Spec;
use Cwd qw(abs_path);

my $root = abs_path(File::Spec->catdir(__FILE__, "..", ".."));
my %skipped = map { $_ => 1 } (
    "node_modules",
    ".next",
    ".git",
    ".pytest_cache",
    "__pycache__",
    "media-production/raw",
    "media-production/private"
);
my @patterns = (
    qr/sk-(?:proj|svcacct|ant|or-v1|admin)-[A-Za-z0-9_-]{20,}/,
    qr/(?:nvapi|lin_api|ntn|vcp)_[A-Za-z0-9_-]{20,}/,
    qr/ELEVENLABS_API_KEY\s*=\s*["']?[A-Za-z0-9]{20,}/,
    qr/WAVESPEED_API_KEY\s*=\s*["']?[A-Za-z0-9]{20,}/
);
my @findings = ();

sub should_skip {
    my ($rel_path) = @_;
    
    # Prüfe ob es eine .env Datei ist (außer .env.example)
    return 1 if $rel_path eq '.env';
    return 1 if $rel_path =~ /^\.env\./ && $rel_path ne '.env.example';
    
    # Prüfe ob der Pfad übersprungen werden soll
    for my $skip (keys %skipped) {
        return 1 if $rel_path eq $skip;
        return 1 if $rel_path =~ /^\Q$skip\E[\/\\]/;
        
        # Prüfe ob ein Teilpfad übersprungen werden soll
        my @parts = split(/[\/\\]/, $rel_path);
        for my $part (@parts) {
            return 1 if $part eq $skip;
        }
    }
    
    return 0;
}

sub check_file {
    my $file = $File::Find::name;
    my $rel_path = File::Spec->abs2rel($file, $root);
    
    return if should_skip($rel_path);
    
    # Prüfe ob es eine Datei ist und nicht zu groß
    return unless -f $file;
    return if -s $file > 2_000_000;
    
    # Lese Dateiinhalt
    open(my $fh, '<:encoding(UTF-8)', $file) or return;
    my $content = do { local $/; <$fh> };
    close($fh);
    
    # Prüfe auf Muster
    for my $pattern (@patterns) {
        if ($content =~ /$pattern/) {
            push @findings, $rel_path;
            last;
        }
    }
}

# Durchsuche das Verzeichnis
find(\&check_file, $root);

# Entferne Duplikate
my %seen;
@findings = grep { !$seen{$_}++ } @findings;

if (@findings) {
    print STDERR "Secret-Scan fehlgeschlagen: " . join(", ", @findings) . "\n";
    exit 1;
}

print "Secret-Scan bestanden.\n";
