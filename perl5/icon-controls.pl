#!/usr/bin/perl
# icon-controls.css — portiert nach perl5
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Get output file name from command line argument
my $output_file = shift @ARGV or die "Usage: $0 <output_file>\n";

# Define icon styles and their corresponding paths
my %icon_styles = (
    'plastisch' => 'icons/plastisch',
    'glass'     => 'icons/glass',
    'linear'    => 'icons/linear'
);

# Define icon names
my @icon_names = qw(
    auto-chat-refresh-counter
    browser
    captions
    chat-counter
    fullscreen
    mute
    off
    on
    pip
    play
    player
    protection-slider
    recommendation-counter
    report
    reset
    settings
    status
    stop
    unmute
    volume-slider
);

# Open output file for writing
open my $fh, '>', $output_file or die "Cannot open '$output_file' for writing: $!";

# Generate CSS for each icon style
for my $style (keys %icon_styles) {
    my $path = $icon_styles{$style};
    print $fh qq(html[data-icon-style="$style"] {);
    
    for my $icon (@icon_names) {
        print $fh qq(--icon-$icon:url("$path/$icon.png"););
    }
    
    print $fh qq(}\n);
}

# Generate CSS for button and input elements
print $fh <<'CSS_END';
button[data-control-icon]::before,.control-icon::before { content:""; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }
button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }
button[data-control-icon][hidden] { display:none; }
input[type="checkbox"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }
input[type="checkbox"]:checked { background-image:var(--icon-on); }
input[type="checkbox"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }
input[type="checkbox"]:disabled { opacity:.45; cursor:default; }
.control-icon { display:inline-flex; align-items:center; }
input[type="range"] { min-height:32px; }
.icon-style-setting { display:flex; align-items:center; gap:8px; }

CSS_END

# Generate CSS for each control icon
for my $icon (@icon_names) {
    print $fh qq([data-control-icon="$icon"] { --control-icon:var(--icon-$icon); }\n);
}

# Close output file
close $fh;

print "CSS file generated successfully: $output_file\n";
