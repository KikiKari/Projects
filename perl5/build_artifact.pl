#!/usr/bin/perl
# build_artifact.py — portiert nach perl5
# Quelle: python, Projects@Telegram-Monitor:build_artifact.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use JSON qw(decode_json encode_json);
use File::Spec;
use Cwd qw(abs_path);

my $ROOT = dirname(abs_path($0));
my $TEMPLATE = File::Spec->catfile($ROOT, "web", "artifact_template.html");
my $DATA = File::Spec->catfile($ROOT, "data", "latest.json");
my $OUT = File::Spec->catfile(dirname($ROOT), "telegram-monitor-uebersicht.html");

sub dirname {
    my ($path) = @_;
    $path =~ s/[\/\\][^\/\\]*$//;
    return $path || ".";
}

sub build {
    my ($data_path, $out_path) = @_;
    $data_path //= $DATA;
    $out_path //= $OUT;

    open(my $fh_tpl, '<:encoding(UTF-8)', $TEMPLATE) or die "Kann Template nicht lesen: $!";
    my $tpl = do { local $/; <$fh_tpl> };
    close($fh_tpl);

    open(my $fh_data, '<:encoding(UTF-8)', $data_path) or die "Kann Daten nicht lesen: $!";
    my $json_text = do { local $/; <$fh_data> };
    close($fh_data);

    my $data = decode_json($json_text);
    my $payload = encode_json($data);
    $payload =~ s/\//\\\//g;
    $payload =~ s/</\</g;

    my $html = $tpl;
    $html =~ s/__DATA__/$payload/g;

    open(my $fh_out, '>:encoding(UTF-8)', $out_path) or die "Kann Ausgabe nicht schreiben: $!";
    print $fh_out $html;
    close($fh_out);

    return $out_path;
}

if (!caller) {
    my $data_arg = @ARGV ? $ARGV[0] : $DATA;
    my $path = build($data_arg);
    my $size = -s $path;
    print "geschrieben: $path ($size Bytes)\n";
}

1;
