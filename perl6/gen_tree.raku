#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "a6773904838573e55404276479bb8e2971ffd612eb57800a4e6926c3b1020ee1", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "perl6"}
# gen_tree.py — portiert nach perl6
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

use v6;

my $ROOT = "/workspace";
my $OUT = "/workspace/important/openclaw-tree.txt";
my $MAX_DEPTH = 6;

sub collect($path, $prefix = "", $depth = 1) {
    my @lines;
    my @entries;
    try {
        @entries = dir($path).map({ .basename }).sort;
        CATCH {
            return @lines;
        }
    }
    my $total = @entries.elems;
    for @entries.kv -> $i, $name {
        my $is_last = ($i == $total - 1);
        my $connector = $is_last ?? "└── " !! "├── ";
        @lines.push($prefix ~ $connector ~ $name);
        my $full = $path ~ "/" ~ $name;
        if $depth < $MAX_DEPTH && $full.IO.d && !$full.IO.l {
            my $next_prefix = $prefix ~ ($is_last ?? "    " !! "│   ");
            @lines.append(|collect($full, $next_prefix, $depth + 1));
        }
    }
    return @lines;
}

my @body = collect($ROOT);
my $now = DateTime.now;
my $header = join("\n",
    "# OpenClaw Workspace Tree",
    "# Generiert: " ~ $now.Str,
    "# Befehl: tree -a -L 6 " ~ $ROOT ~ " (emuliert via gen_tree.py)",
    "# Diese Datei wird automatisch von db-maintainer aktualisiert",
    ""
);
my $content = $header ~ ".\n" ~ @body.join("\n") ~ "\n";

$OUT.IO.spurt($content, :enc<utf8>);

say "written $OUT: " ~ (@body.elems + 1) ~ " lines, " ~ $content.encode('utf8').elems ~ " bytes";
