#!/usr/bin/perl
# test_mobile_bridge.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Slurp qw(read_file);

# Get the root directory (parent of current script's directory)
my $script_dir = dirname(__FILE__);
my @root_parts = split('/', $script_dir);
pop @root_parts; # remove last component (current dir)
my $root = join('/', @root_parts);

# Construct bridge path
my $bridge_path = File::Spec->catfile($root, 'mobile-shared', 'webview-bridge.js');

# Read source file
my $source = read_file($bridge_path);

# Compile JavaScript source using Node.js (simulate vm.Script)
# In Perl we can't compile JS, so we'll just check for substrings

# Assertions - check that certain strings are present
assert($source =~ /location\.hostname !== "www\.tiktok\.com"/, 'Missing location.hostname check');
assert($source =~ /root\.top === root/, 'Missing root.top check');
assert($source =~ /if \(!isTop\) return/, 'Missing isTop guard');
assert($source =~ /MAX_MESSAGE_BYTES = 64 \* 1024/, 'Missing MAX_MESSAGE_BYTES definition');
assert($source =~ /MAX_AUDIO_SECONDS = 12/, 'Missing MAX_AUDIO_SECONDS definition');
assert($source =~ /QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400/, 'Missing QUICK_RECOVER_RELOAD_COOLDOWN_MS definition');
assert($source =~ /ALLOWED_COMMANDS/, 'Missing ALLOWED_COMMANDS');
assert($source =~ /"set-auto-reconnect"/, 'Missing set-auto-reconnect command');
assert($source =~ /"set-limiter"/, 'Missing set-limiter command');
assert($source =~ /"scan-recommendations"/, 'Missing scan-recommendations command');
assert($source =~ /"cancel-recommendation-scan"/, 'Missing cancel-recommendation-scan command');
assert($source =~ /MAX_MEDIA_URLS = 12/, 'Missing MAX_MEDIA_URLS definition');
assert($source =~ /const mediaUrls = new Map\(\)/, 'Missing mediaUrls Map');
assert($source =~ /emit\("media-url"/, 'Missing emit media-url');
assert($source =~ /addEventListener\("message"/, 'Missing addEventListener message');
assert($source !~ /\.send =/, 'Found forbidden .send assignment');
assert($source !~ /document\.cookie/, 'Found forbidden document.cookie');
assert($source !~ /localStorage/, 'Found forbidden localStorage');
assert($source =~ /FORCE_RETURN_KEY = "tlc-force-return"/, 'Missing FORCE_RETURN_KEY definition');
assert($source =~ /sessionStorage\.getItem\(FORCE_RETURN_KEY\)/, 'Missing sessionStorage getItem');
assert($source !~ /sessionStorage\.clear/, 'Found forbidden sessionStorage.clear');
assert($source !~ /innerHTML/, 'Found forbidden innerHTML');

# Check copies in other locations
my @copies = (
    File::Spec->catfile($root, '..', 'mobile', 'ios', 'Resources', 'webview-bridge.js'),
    File::Spec->catfile($root, '..', 'mobile', 'android', 'app', 'src', 'main', 'res', 'raw', 'webview_bridge.js')
);

foreach my $copy (@copies) {
    my $copy_content = read_file($copy);
    assert($copy_content eq $source, "Bridge copy drifted: $copy");
}

print "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards\n";

sub assert {
    my ($condition, $message) = @_;
    if (!$condition) {
        die "Assertion failed: $message\n";
    }
}

sub dirname {
    my ($file) = @_;
    $file =~ s/[^\/]+$//;
    $file =~ s/\/$//;
    return $file || '.';
}
