#!/usr/bin/perl
# status-overview.css — portiert nach perl5
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-01 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Generate CSS content for status-overview
sub generate_css {
    my $css = <<'EOF';
* {
    box-sizing: border-box;
}

html, body {
    margin: 0;
    min-height: 100%;
    background: #101015;
    color: #fff;
    font: 14px system-ui, sans-serif;
}

body {
    display: flex;
    flex-direction: column;
    height: 100vh;
}

header {
    display: flex;
    gap: 1em;
    align-items: baseline;
    padding: 0 12px;
}

h1 {
    font-size: 17px;
    margin: 8px 0;
}

header p {
    font-size: 12px;
    color: #bbb;
    margin: 0;
}

main {
    flex: 1;
    min-height: 0;
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    grid-template-rows: repeat(3, minmax(0, 1fr));
    gap: 4px;
    padding: 0;
}

.tile {
    min-width: 0;
    min-height: 0;
    display: flex;
    flex-direction: column;
    background: #202026;
    border: 1px solid #393940;
}

.tile h2 {
    font-size: 13px;
    margin: 3px 8px;
}

.tile video {
    min-height: 0;
    width: 100%;
    flex: 1;
    object-fit: contain;
    background: #000;
}

.tile p {
    font-size: 11px;
    margin: 3px 8px;
    color: #ddd;
}

main.grid2 {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    grid-template-rows: repeat(2, minmax(0, 1fr));
}

.tile[hidden] {
    display: none;
}
EOF

    return $css;
}

# Main execution
sub main {
    my $output_file = $ARGV[0] || 'status-overview.css';
    
    open my $fh, '>', $output_file or die "Cannot write to $output_file: $!";
    print $fh generate_css();
    close $fh;
    
    print "CSS file generated: $output_file\n";
}

main() if __FILE__ eq $0;
