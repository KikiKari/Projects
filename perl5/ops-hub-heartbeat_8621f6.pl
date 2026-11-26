#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "3365d19947f0d19cfe799997725d5c19acce69ee7dc8df1334cf8346c1bfcd54", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "perl5"}
# ops-hub-heartbeat.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use Encode qw(decode encode);

# Aktualisiere den Statusbericht mit aktueller Zeit
my $script_dir = dirname(__FILE__);
my $statusPath = File::Spec->catfile($script_dir, '..', 'docs', 'ops-hub', 'status.md');

sub updateHeartbeat {
    my $content;
    eval {
        open my $fh, '<:encoding(UTF-8)', $statusPath or die "Cannot read file: $!";
        local $/;
        $content = <$fh>;
        close $fh;
    };
    if ($@) {
        print STDERR "❌ Konnte status.md nicht lesen: $@\n";
        return;
    }

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $now = sprintf("%02d.%02d.%04d, %02d:%02d:%02d", $mday, $mon+1, $year+1900, $hour, $min, $sec);

    $content =~ s/(Letzter Heartbeat:) [^\n]*/$1 $now/;

    eval {
        open my $fh, '>:encoding(UTF-8)', $statusPath or die "Cannot write file: $!";
        print $fh $content;
        close $fh;
        print "✅ Heartbeat aktualisiert: $now\n";
    };
    if ($@) {
        print STDERR "❌ Konnte status.md nicht schreiben: $@\n";
    }
}

updateHeartbeat();
