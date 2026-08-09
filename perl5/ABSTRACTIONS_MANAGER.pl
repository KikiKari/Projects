#!/usr/bin/perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use Cwd 'abs_path';

# Skill-Einstieg fuer den kanonischen Abstractions Manager.

my $KANONISCHER_MANAGER = "/home/openclaw/.openclaw/workspace/abstractions/ABSTRACTIONS_MANAGER.py";

# Pruefe ob der kanonische Manager existiert
unless (-f $KANONISCHER_MANAGER) {
    die "Kanonischer Abstractions Manager fehlt: $KANONISCHER_MANAGER\n";
}

# Fuehre das Python-Skript aus
my $return_code = system("python3", $KANONISCHER_MANAGER);
if ($return_code != 0) {
    die "Ausfuehrung des kanonischen Abstractions Managers fehlgeschlagen mit Rueckgabewert: $return_code\n";
}
