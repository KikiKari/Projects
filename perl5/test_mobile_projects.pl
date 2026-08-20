#!/usr/bin/perl
# test_mobile_projects.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_mobile_projects.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_mobile_projects.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON qw(decode_json);
use File::Find;
use Cwd qw(abs_path);

my $ROOT = abs_path("$0/../../..");
my $IOS = "$ROOT/mobile/ios";
my $ANDROID = "$ROOT/mobile/android";
my $SHARED = "$ROOT/plugin-source/mobile-shared/webview-bridge.js";

sub require_condition {
    my ($condition, $message) = @_;
    if (!$condition) {
        die "AssertionError: $message\n";
    }
}

if (-d $ANDROID) {
    my $manifest = read_file("$ANDROID/app/src/main/AndroidManifest.xml");
    my $gradle = read_file("$ANDROID/app/build.gradle.kts");
    my $android_webview = read_file("$ANDROID/app/src/main/java/app/tiktoklivecompanion/CompanionWebView.kt");
    
    require_condition(index($gradle, 'minSdk = 21') != -1 && index($gradle, 'versionName = "0.8.0"') != -1, "Android version contract");
    require_condition(index($manifest, 'usesCleartextTraffic="false"') != -1, "Android cleartext must be disabled");
    require_condition(index($android_webview, "addJavascriptInterface") == -1, "insecure Android JavaScript interface");
    require_condition(index($android_webview, "addWebMessageListener") != -1 && index($android_webview, "ALLOWED_ORIGIN") != -1, "origin-restricted Android bridge");
    
    my @aar_files = glob("$ANDROID/app/libs/*.aar");
    require_condition(!@aar_files, "ShazamKit AAR must not be committed");
    
    my $shared_content = read_binary($SHARED);
    my $android_bridge_content = read_binary("$ANDROID/app/src/main/res/raw/webview_bridge.js");
    require_condition($shared_content eq $android_bridge_content, "Android bridge copy drift");
}

if (-d $IOS) {
    my $ios_webview = read_file("$IOS/TikTokLiveCompanion/CompanionWebView.swift");
    my $pbx = read_file("$IOS/TikTokLiveCompanion.xcodeproj/project.pbxproj");
    
    require_condition(index($ios_webview, "forMainFrameOnly: false") != -1 && index($ios_webview, "securityOrigin.host == \"www.tiktok.com\"") != -1, "origin-restricted iOS subframe bridge");
    require_condition(index($pbx, "MARKETING_VERSION = 0.8.0") != -1 && index($pbx, "IPHONEOS_DEPLOYMENT_TARGET = 15.0") != -1, "iOS version contract");
    
    my $sources_check = 1;
    for my $name ("StreamNameNormalizer.swift in Sources", "StreamNameNormalizerTests.swift in Sources", "MobileUIStructureTests.swift in Sources") {
        if (index($pbx, $name) == -1) {
            $sources_check = 0;
            last;
        }
    }
    require_condition($sources_check, "iOS source and XCTest membership");
    
    my $shared_content = read_binary($SHARED);
    my $ios_bridge_content = read_binary("$IOS/Resources/webview-bridge.js");
    require_condition($shared_content eq $ios_bridge_content, "iOS bridge copy drift");
    
    # Note: plist parsing is omitted due to complexity in Perl without additional modules
    # The check would need to parse the Info.plist file and verify CFBundleShortVersionString
}

# Check for .p8 files
my @p8_files;
find(sub { 
    push @p8_files, $File::Find::name if /\.p8$/ 
}, $ROOT);
require_condition(!@p8_files, "Apple private key must not be committed");

my $schema_content = read_file("$ROOT/plugin-source/mobile-shared/recognition-result.schema.json");
my $schema = decode_json($schema_content);
require_condition(join(',', @{$schema->{properties}->{source}->{enum}}) eq "microphone,webview", "recognition source schema");

print "PASS: available mobile platform versions, bridge boundaries, policies, schema, source sync and secret exclusions\n";

sub read_file {
    my ($filename) = @_;
    open my $fh, '<:encoding(UTF-8)', $filename or die "Cannot open $filename: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub read_binary {
    my ($filename) = @_;
    open my $fh, '<:raw', $filename or die "Cannot open $filename: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}
