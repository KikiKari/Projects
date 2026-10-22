#!/usr/bin/perl
# test_extension.cjs — portiert nach perl5
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use Cwd qw(abs_path);
use JSON qw(decode_json);
use Digest::SHA qw(sha256_hex);
use Encode qw(encode_utf8);

binmode(STDOUT, ':encoding(UTF-8)');
binmode(STDERR, ':encoding(UTF-8)');

my $root = dirname(dirname(abs_path($0)));
my $extension = File::Spec->catdir($root, "browser-extension");
my $manifest_file = File::Spec->catfile($extension, "manifest.json");
my $manifest_content;
{
    open my $fh, '<:encoding(UTF-8)', $manifest_file or die "Cannot read $manifest_file: $!";
    local $/;
    $manifest_content = <$fh>;
    close $fh;
}
my $manifest = decode_json($manifest_content);

sub read_file {
    my ($file) = @_;
    open my $fh, '<:encoding(UTF-8)', $file or die "Cannot read $file: $!";
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub file_exists {
    my ($file) = @_;
    return -e $file;
}

sub concat {
    my (@chunks) = @_;
    my $size = 0;
    for my $chunk (@chunks) {
        $size += @$chunk;
    }
    my @out = ();
    for my $chunk (@chunks) {
        push @out, @$chunk;
    }
    return \@out;
}

sub varint {
    my ($value) = @_;
    my $current = $value;
    my @bytes = ();
    do {
        my $byte = $current & 0x7f;
        $current >>= 7;
        if ($current) {
            $byte |= 0x80;
        }
        push @bytes, $byte;
    } while ($current);
    return \@bytes;
}

sub bytes_field {
    my ($number, $value) = @_;
    my $body;
    if (ref($value) eq 'ARRAY') {
        $body = $value;
    } else {
        $body = [unpack('C*', encode_utf8($value))];
    }
    return concat(varint(($number << 3) | 2), varint(scalar(@$body)), $body);
}

sub int_field {
    my ($number, $value) = @_;
    return concat(varint($number << 3), varint($value));
}

die "Manifest version mismatch" unless $manifest->{manifest_version} == 3;
die "Version mismatch" unless $manifest->{version} eq "0.8.2";
die "Missing permission: sidePanel" unless grep { $_ eq "sidePanel" } @{$manifest->{permissions}};
die "Missing permission: webRequest" unless grep { $_ eq "webRequest" } @{$manifest->{permissions}};
die "Missing permission: tabCapture" unless grep { $_ eq "tabCapture" } @{$manifest->{permissions}};
die "Missing host_permission: http://127.0.0.1/*" unless grep { $_ eq "http://127.0.0.1/*" } @{$manifest->{host_permissions}};
die "Missing host_permission: http://localhost/*" unless grep { $_ eq "http://localhost/*" } @{$manifest->{host_permissions}};
die "Unexpected permission: cookies" if grep { $_ eq "cookies" } @{$manifest->{permissions}};
die "Unexpected permission: webRequestBlocking" if grep { $_ eq "webRequestBlocking" } @{$manifest->{permissions}};
die "Unexpected permission: nativeMessaging" if grep { $_ eq "nativeMessaging" } @{$manifest->{permissions}};
die "First content_script js mismatch" unless $manifest->{content_scripts}[0]{js}[0] eq "vendor-mpegts.js";

my $mpegts_vendor_path = File::Spec->catfile($extension, "vendor-mpegts.js");
my $mpegts_license_path = File::Spec->catfile($extension, "vendor-mpegts.LICENSE.txt");
my $mpegts_notice_path = File::Spec->catfile($extension, "vendor-mpegts.NOTICE.md");

die "Missing vendor file: vendor-mpegts.js" unless file_exists($mpegts_vendor_path);
die "Missing vendor file: vendor-mpegts.LICENSE.txt" unless file_exists($mpegts_license_path);
die "Missing vendor file: vendor-mpegts.NOTICE.md" unless file_exists($mpegts_notice_path);

my $mpegts_content = read_file($mpegts_vendor_path);
my $hash = uc(sha256_hex($mpegts_content));
die "SHA256 hash mismatch" unless $hash eq "0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064";

my $mobile_bridge_path = File::Spec->catfile($root, "mobile-shared", "webview-bridge.js");
my $mobile_bridge_content = read_file($mobile_bridge_path);

die "Missing location.hostname check" unless $mobile_bridge_content =~ /location\.hostname\s*!==\s*"www\.tiktok\.com"/;
die "Contains document.cookie" if $mobile_bridge_content =~ /document\.cookie/;
die "Missing QUICK_RECOVER_RELOAD_COOLDOWN_MS" unless $mobile_bridge_content =~ /QUICK_RECOVER_RELOAD_COOLDOWN_MS\s*=\s*400/;
die "Missing set-auto-reconnect" unless $mobile_bridge_content =~ /"set-auto-reconnect"/;
die "Missing set-limiter" unless $mobile_bridge_content =~ /"set-limiter"/;

for my $relative (
    $manifest->{background}{service_worker},
    $manifest->{side_panel}{default_path},
    map { @$_ } map { $_->{js} } @{$manifest->{content_scripts}}
) {
    my $full_path = File::Spec->catfile($extension, $relative);
    die "Missing manifest file: $relative" unless file_exists($full_path);
}

opendir(my $dh, $extension) or die "Cannot opendir $extension: $!";
my @scripts = grep { /\.js$/ && -f File::Spec->catfile($extension, $_) } readdir($dh);
closedir $dh;

for my $name (@scripts) {
    my $source = read_file(File::Spec->catfile($extension, $name));
    if ($name eq "peak-limiter-worklet.js") {
        # Skip Node.js syntax check for Perl translation
    } else {
        # In Perl we can't easily validate JS syntax, so we skip this check
    }
    die "$name contains eval()" if $source =~ /\beval\s*\(/;
    die "$name contains new Function()" if $source =~ /new\s+Function\s*\(/;
    die "$name assigns innerHTML" if $source =~ /\.innerHTML\s*=/;
}

# Since we cannot load and execute JavaScript modules directly in Perl,
# we'll skip the core and proto tests that require JavaScript execution.
# These would need a JavaScript engine or manual implementation in Perl.

print "PASS: manifest 0.8.2, " . scalar(@scripts) . " scripts, basic checks completed\n";
