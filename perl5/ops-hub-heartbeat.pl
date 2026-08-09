#!/usr/bin/perl
# ops-hub-heartbeat.js — portiert nach perl5
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use POSIX qw(strftime);

# Aktualisiere den Statusbericht mit aktueller Zeit
my $statusPath = File::Spec->catfile(File::Spec->updir(), 'docs', 'ops-hub', 'status.md');

sub updateHeartbeat {
    my $content;
    open(my $fh, '<:encoding(UTF-8)', $statusPath) or do {
        warn "❌ Konnte status.md nicht lesen: $!";
        return;
    };
    {
        local $/;
        $content = <$fh>;
    }
    close($fh);

    my $now = strftime("%d.%m.%Y, %H:%M:%S", localtime());
    $content =~ s/(Letzter Heartbeat:) [^\n]*/$1 $now/;

    open($fh, '>:encoding(UTF-8)', $statusPath) or do {
        warn "❌ Konnte status.md nicht schreiben: $!";
        return;
    };
    print $fh $content;
    close($fh);
    
    print "✅ Heartbeat aktualisiert: $now\n";
}

updateHeartbeat();
