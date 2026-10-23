#!/usr/bin/env perl
# package_artifacts.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Basename;
use File::Copy;
use File::Path qw(make_path remove_tree);
use File::Spec;
use Cwd qw(abs_path);
use Digest::SHA qw(sha256_hex);
use JSON;
use Getopt::Long;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

my $ROOT = abs_path(File::Spec->catdir(dirname(abs_path($0)), '..'));
my $PROJECT_ROOT = abs_path(File::Spec->catdir($ROOT, '..'));
my %EXCLUDED_PARTS = map { $_ => 1 } qw(__pycache__ .gradle .kotlin .cxx build DerivedData xcuserdata Pods);

sub add_tree {
    my ($archive, $source, $prefix) = @_;
    $prefix //= '';
    my @files;
    my $iter = File::Find::find({wanted => sub {
        return unless -f $_;
        my $path = $File::Find::name;
        my @parts = File::Spec->splitdir($path);
        for my $part (@parts) {
            return if exists $EXCLUDED_PARTS{$part};
        }
        return if $path =~ /\.pyc$/ || $path =~ /\.aar$/;
        push @files, $path;
    }, no_chdir => 1}, $source);
    @files = sort @files;
    for my $file (@files) {
        my $relative = File::Spec->abs2rel($file, $source);
        my $archive_path = File::Spec->catfile($prefix, $relative);
        $archive_path =~ s{\\}{/}g;
        my $member = $archive->addFile($file, $archive_path);
        $member->desiredCompressionLevel(9);
        $member->unixFileAttributes(0100755) if basename($file) eq 'gradlew';
    }
}

my %args;
GetOptions(
    'output-dir=s' => \$args{'output_dir'},
    'android-apk=s' => \$args{'android_apk'},
    'android-source=s' => \$args{'android_source'},
    'ios-source=s' => \$args{'ios_source'},
    'native-shared-source=s' => \$args{'native_shared_source'}
) or die "Error in command line arguments\n";

die "--output-dir is required\n" unless $args{'output_dir'};
$args{'android_source'} //= File::Spec->catdir($PROJECT_ROOT, 'mobile', 'android');
$args{'ios_source'} //= File::Spec->catdir($PROJECT_ROOT, 'mobile', 'ios');
$args{'native_shared_source'} //= File::Spec->catdir($PROJECT_ROOT, 'mobile', 'shared');

make_path($args{'output_dir'});
my $output_dir = abs_path($args{'output_dir'});

my $manifest_file = File::Spec->catfile($ROOT, 'browser-extension', 'manifest.json');
open my $mfh, '<:utf8', $manifest_file or die "Cannot open $manifest_file: $!";
my $manifest_json = do { local $/; <$mfh> };
close $mfh;
my $manifest = decode_json($manifest_json);
my $version = $manifest->{'version'};

my $extension_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-extension-$version.zip");
my $plugin_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-plugin-$version.zip");
my $service_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-service-$version.zip");
my $ios_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-ios-$version-source.zip");
my $android_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version-source.zip");
my $android_apk = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version.apk");
my $extension_dir = File::Spec->catdir($output_dir, "tiktok-live-companion-extension-$version");
my $checksum_file = File::Spec->catfile($output_dir, "tiktok-live-companion-$version-SHA256.txt");

my $resolved_extension_dir = abs_path($extension_dir);
die "Refusing to package outside the requested output directory\n" unless dirname($resolved_extension_dir) eq $output_dir;
remove_tree($extension_dir) if -d $extension_dir;
dircopy(File::Spec->catdir($ROOT, 'browser-extension'), $extension_dir);
dircopy(File::Spec->catdir($ROOT, 'companion-service'), File::Spec->catdir($extension_dir, 'companion-service'));

my $cmd_file = File::Spec->catfile($extension_dir, 'Sprachdienst-reparieren.cmd');
open my $cfh, '>:utf8', $cmd_file or die "Cannot open $cmd_file: $!";
print $cfh "\@echo off\r\ncall \"%~dp0companion-service\\Sprachdienst-reparieren.cmd\"\r\n";
close $cfh;

my $package_json = {
    name => 'tiktok-live-companion-extension-package',
    private => JSON::true,
    version => $version,
    scripts => {
        setup => 'npm --prefix companion-service run setup --',
        start => 'npm --prefix companion-service start',
        test => 'npm --prefix companion-service test'
    }
};
my $pkg_file = File::Spec->catfile($extension_dir, 'package.json');
open my $pfh, '>:utf8', $pkg_file or die "Cannot open $pkg_file: $!";
print $pfh encode_json($package_json) . "\n";
close $pfh;

my $extension_archive = Archive::Zip->new();
add_tree($extension_archive, $extension_dir);
$extension_archive->writeToFileNamed($extension_zip) == AZ_OK or die "Error writing $extension_zip\n";

my $plugin_archive = Archive::Zip->new();
add_tree($plugin_archive, $ROOT, 'tiktok-live-companion');
$plugin_archive->writeToFileNamed($plugin_zip) == AZ_OK or die "Error writing $plugin_zip\n";

my $service_archive = Archive::Zip->new();
add_tree($service_archive, File::Spec->catdir($ROOT, 'companion-service'));
$service_archive->writeToFileNamed($service_zip) == AZ_OK or die "Error writing $service_zip\n";

my $ios_source = abs_path($args{'ios_source'});
my $android_source = abs_path($args{'android_source'});
die "--ios-source and --android-source must point to existing source directories\n" unless -d $ios_source && -d $android_source;
my $native_shared = abs_path($args{'native_shared_source'});
my $limiter_file = File::Spec->catfile($native_shared, 'native', 'tlc_peak_limiter.h');
die "Shared native limiter source is required for both mobile source packages\n" unless -f $limiter_file;

my $ios_source_archive = Archive::Zip->new();
add_tree($ios_source_archive, $ios_source, 'TikTokLiveCompanion-iOS');
add_tree($ios_source_archive, $native_shared, 'shared');
$ios_source_archive->writeToFileNamed($ios_source_zip) == AZ_OK or die "Error writing $ios_source_zip\n";

my $android_source_archive = Archive::Zip->new();
add_tree($android_source_archive, $android_source, 'TikTokLiveCompanion-Android');
add_tree($android_source_archive, $native_shared, 'shared');
$android_source_archive->writeToFileNamed($android_source_zip) == AZ_OK or die "Error writing $android_source_zip\n";

if ($args{'android_apk'}) {
    my $source_apk = abs_path($args{'android_apk'});
    die "--android-apk must point to an existing APK\n" unless -f $source_apk && $source_apk =~ /\.apk$/i;
    if ($source_apk ne abs_path($android_apk)) {
        copy($source_apk, $android_apk) or die "Copy failed: $!";
    }
}

my @artifacts = ($extension_zip, $plugin_zip, $service_zip, $ios_source_zip, $android_source_zip);
push @artifacts, $android_apk if -f $android_apk;
my @checksums;
for my $artifact (@artifacts) {
    open my $afh, '<', $artifact or die "Cannot open $artifact: $!";
    my $digest = sha256_hex(do { local $/; <$afh> });
    close $afh;
    push @checksums, "$digest  " . basename($artifact);
}
open my $chfh, '>:utf8', $checksum_file or die "Cannot open $checksum_file: $!";
print $chfh join("\n", @checksums) . "\n";
close $chfh;

my $result = {
    extension_dir => abs_path($extension_dir),
    extension_zip => abs_path($extension_zip),
    plugin_zip => abs_path($plugin_zip),
    service_zip => abs_path($service_zip),
    ios_source_zip => abs_path($ios_source_zip),
    android_source_zip => abs_path($android_source_zip),
    android_apk => (-f $android_apk) ? abs_path($android_apk) : undef,
    checksum_file => abs_path($checksum_file),
    version => $version
};
print encode_json($result);

sub dircopy {
    my ($src, $dst) = @_;
    make_path($dst);
    my $iter = File::Find::find({wanted => sub {
        my $file = $File::Find::name;
        my $rel = File::Spec->abs2rel($file, $src);
        my $target = File::Spec->catfile($dst, $rel);
        if (-d $file) {
            make_path($target);
        } else {
            copy($file, $target) or die "Copy failed: $!";
        }
    }, no_chdir => 1}, $src);
}
