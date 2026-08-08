#!/usr/bin/perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use Cwd 'abs_path';

# Compatibility entry point for the canonical Abstractions Manager.

my $CANONICAL_MANAGER = '/home/openclaw/.openclaw/workspace/abstraction-manager/ABSTRACTIONS_MANAGER.py';

if (__FILE__ eq $0) {
    unless (-f $CANONICAL_MANAGER) {
        die "Kanonischer Abstraction-Manager fehlt: $CANONICAL_MANAGER\n";
    }
    do $CANONICAL_MANAGER or die "Fehler beim Ausfuehren von $CANONICAL_MANAGER: $@\n";
}
