#!/usr/bin/perl
# test_mobile_projects.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json);
use File::Find;
use File::Spec;
use Cwd qw(abs_path);

# Helper to resolve paths similar to Python's Path.parents
sub resolve_parents {
    my ($path, $levels) = @_;
    my @parts = split('/', $path);
    splice(@parts, -$levels) if $levels > 0;
    return join('/', @parts);
}

# Get the script's directory and resolve root path
my $script_path = abs_path($0);
my $ROOT = resolve_parents($script_path, 2); # Equivalent to Path(__file__).resolve().parents[2]

my $IOS = "$ROOT/mobile/ios";
my $ANDROID = "$ROOT/mobile/android";
my $SHARED = "$ROOT/plugin-source/mobile-shared/webview-bridge.js";

# Mimic Python's assert function
sub require_condition {
    my ($condition, $message) = @_;
    die "AssertionError: $message\n" unless $condition;
}

# Read file content with UTF-8 encoding
sub read_file {
    my ($file_path) = @_;
    open(my $fh, '<:encoding(UTF-8)', $file_path) or die "Could not open file '$file_path': $!";
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

# Read binary file content
sub read_binary_file {
    my ($file_path) = @_;
    open(my $fh, '<', $file_path) or die "Could not open file '$file_path': $!";
    binmode($fh);
    local $/;
    my $content = <$fh>;
    close($fh);
    return $content;
}

# Check Android project
if (-d $ANDROID) {
    my $manifest = read_file("$ANDROID/app/src/main/AndroidManifest.xml");
    my $gradle = read_file("$ANDROID/app/build.gradle.kts");
    my $android_webview = read_file("$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt");

    require_condition(
        index($gradle, 'minSdk = 21') != -1 && index($gradle, 'versionName = "0.8.2"') != -1,
        "Android version contract"
    );

    require_condition(
        index($manifest, 'usesCleartextTraffic="false"') != -1,
        "Android cleartext must be disabled"
    );

    require_condition(
        index($android_webview, "addJavascriptInterface") == -1,
        "insecure Android JavaScript interface"
    );

    require_condition(
        index($android_webview, "addWebMessageListener") != -1 && index($android_webview, "ALLOWED_ORIGIN") != -1,
        "origin-restricted Android bridge"
    );

    opendir(my $libs_dir, "$ANDROID/app/libs") or die "Could not open directory: $!";
    my @aar_files = grep { /\.aar$/ } readdir($libs_dir);
    closedir($libs_dir);

    require_condition(
        !@aar_files,
        "ShazamKit AAR must not be committed"
    );

    my $shared_content = read_binary_file($SHARED);
    my $android_bridge_content = read_binary_file("$ANDROID/app/src/main/res/raw/webview_bridge.js");

    require_condition(
        $shared_content eq $android_bridge_content,
        "Android bridge copy drift"
    );
}

# Check iOS project
if (-d $IOS) {
    my $ios_webview = read_file("$IOS/TikTokLiveCompanion/CompanionWebView.swift");
    my $pbx = read_file("$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj");

    require_condition(
        index($ios_webview, "forMainFrameOnly: false") != -1 && index($ios_webview, "securityOrigin.host == \"www.tiktok.com\"") != -1,
        "origin-restricted iOS subframe bridge"
    );

    require_condition(
        index($pbx, "MARKETING_VERSION = 0.8.2") != -1 && index($pbx, "IPHONEOS_DEPLOYMENT_TARGET = 15.0") != -1,
        "iOS version contract"
    );

    require_condition(
        index($pbx, "StreamNameNormalizer.swift in Sources") != -1 &&
        index($pbx, "StreamNameNormalizerTests.swift in Sources") != -1 &&
        index($pbx, "MobileUIStructureTests.swift in Sources") != -1,
        "iOS source and XCTest membership"
    );

    my $shared_content = read_binary_file($SHARED);
    my $ios_bridge_content = read_binary_file("$IOS/Resources/webview-bridge.js");

    require_condition(
        $shared_content eq $ios_bridge_content,
        "iOS bridge copy drift"
    );

    # Load Info.plist using system plutil (since Perl lacks native plist support)
    my $info_plist_path = "$IOS/TikTokLiveCompanion/Info.plist";
    my $plist_json = `plutil -convert json -o - '$info_plist_path'`;
    my $info = decode_json($plist_json);

    require_condition(
        $info->{"CFBundleShortVersionString"} eq "0.8.2",
        "iOS plist version"
    );
}

# Check for .p8 files recursively
my @p8_files;
find(sub {
    push @p8_files, $File::Find::name if /\.p8$/;
}, $ROOT);

require_condition(
    !@p8_files,
    "Apple private key must not be committed"
);

# Validate recognition result schema
my $schema_path = "$ROOT/plugin-source/mobile-shared/recognition-result.schema.json";
my $schema_json = read_file($schema_path);
my $schema = decode_json($schema_json);

require_condition(
    $schema->{properties}->{source}->{enum} &&
    join(',', @{$schema->{properties}->{source}->{enum}}) eq "microphone,webview",
    "recognition source schema"
);

print "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions\n";
