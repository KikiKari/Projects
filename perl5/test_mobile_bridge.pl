#!/usr/bin/perl
# test_mobile_bridge.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_bridge.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_bridge.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Spec;
use File::Slurp qw(read_file);
use JavaScript::V8;

# Helper to resolve paths similar to path.resolve
sub resolve_path {
    my @parts = @_;
    return File::Spec->rel2abs(File::Spec->catfile(@parts));
}

# Get the directory of the script (similar to __dirname)
my $script_dir = dirname($0);
my $root = resolve_path($script_dir, "..");
my $bridge_path = File::Spec->catfile($root, "mobile-shared", "webview-bridge.js");

# Read the bridge file
my $source = read_file($bridge_path);

# Create a V8 context and compile the script
my $context = JavaScript::V8::Context->new();
$context->eval($source); # This will throw if syntax is bad

# Assertions using basic Perl die/checks
sub assert_contains {
    my ($text, $needle, $msg) = @_;
    die "$msg\n" unless index($text, $needle) != -1;
}

sub assert_not_contains {
    my ($text, $needle, $msg) = @_;
    die "$msg\n" unless index($text, $needle) == -1;
}

sub assert_equals {
    my ($a, $b, $msg) = @_;
    die "$msg\n" unless $a eq $b;
}

# Run assertions
assert_contains($source, 'location.hostname !== "www.tiktok.com"', 'Missing hostname check');
assert_contains($source, "root.top === root", 'Missing frame check');
assert_contains($source, "if (!isTop) return", 'Missing early return');
assert_contains($source, "MAX_MESSAGE_BYTES = 64 * 1024", 'Missing message limit');
assert_contains($source, "MAX_AUDIO_SECONDS = 12", 'Missing audio limit');
assert_contains($source, "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400", 'Missing reload cooldown');
assert_contains($source, "ALLOWED_COMMANDS", 'Missing allowed commands list');
assert_contains($source, '"set-auto-reconnect"', 'Missing auto-reconnect command');
assert_contains($source, '"set-limiter"', 'Missing limiter command');
assert_contains($source, '"scan-recommendations"', 'Missing scan command');
assert_contains($source, '"cancel-recommendation-scan"', 'Missing cancel command');
assert_contains($source, "MAX_MEDIA_URLS = 12", 'Missing media URL limit');
assert_contains($source, "const mediaUrls = new Map()", 'Missing media URLs map');
assert_contains($source, 'emit("media-url"', 'Missing media URL emit');
assert_contains($source, 'addEventListener("message"', 'Missing message listener');
assert_not_contains($source, ".send =", 'Forbidden send method found');
assert_not_contains($source, "document.cookie", 'Forbidden cookie access found');
assert_not_contains($source, "localStorage", 'Forbidden localStorage found');
assert_contains($source, 'FORCE_RETURN_KEY = "tlc-force-return"', 'Missing force return key');
assert_contains($source, "sessionStorage.getItem(FORCE_RETURN_KEY)", 'Missing session storage get');
assert_not_contains($source, "sessionStorage.clear", 'Forbidden session clear found');
assert_not_contains($source, "innerHTML", 'Forbidden innerHTML found');

# Check copies
my @copies = (
    File::Spec->catfile($root, "..", "mobile", "ios", "Resources", "webview-bridge.js"),
    File::Spec->catfile($root, "..", "mobile", "android", "app", "src", "main", "res", "raw", "webview_bridge.js")
);

for my $copy (@copies) {
    my $copy_content = read_file($copy);
    assert_equals($copy_content, $source, "Bridge copy drifted: $copy");
}

print "PASS: mobile bridge origin, main-frame, size, command, audio-duration and storage guards\n";

# Helper function to get dirname (since File::Basename is not used yet)
use File::Basename;
sub dirname {
    my $path = shift;
    return basename($path) eq '' ? dirname(dirname($path)) : dirname($path);
}
