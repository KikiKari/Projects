#!/usr/bin/perl
# package_artifacts.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use JSON;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Spec;
use File::Find;
use Digest::SHA qw(sha256_hex);
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);

my $ROOT = File::Spec->rel2abs(File::Spec->catdir(__FILE__, '..', '..'));
my $PROJECT_ROOT = File::Spec->rel2abs(File::Spec->catdir($ROOT, '..'));
my %EXCLUDED_PARTS = map { $_ => 1 } ("__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata");

sub add_tree {
    my ($archive, $source, $prefix) = @_;
    $prefix //= "";
    
    my @files;
    find(sub {
        return unless -f $_;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $source);
        my @parts = split(/\//, $rel_path);
        return if grep { exists $EXCLUDED_PARTS{$_} } @parts;
        return if /\.(?:pyc|aar)$/i;
        push @files, $File::Find::name;
    }, $source);
    
    for my $file (sort @files) {
        my $relative = File::Spec->abs2rel($file, $source);
        my $archive_path = $prefix ? File::Spec->catdir($prefix, $relative) : $relative;
        $archive_path =~ s/\\/\//g; # Normalize to forward slashes
        
        my $member = $archive->addFile($file, $archive_path);
        $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
        $member->unixFileAttributes(0100644);
    }
}

my ($output_dir, $android_apk, $android_source, $ios_source);
GetOptions(
    "output-dir=s" => \$output_dir,
    "android-apk=s" => \$android_apk,
    "android-source=s" => \$android_source // File::Spec->catdir($PROJECT_ROOT, "mobile", "android"),
    "ios-source=s" => \$ios_source // File::Spec->catdir($PROJECT_ROOT, "mobile", "ios")
) or die "Error in command line arguments\n";

die "--output-dir is required\n" unless $output_dir;

make_path($output_dir) unless -d $output_dir;
$output_dir = File::Spec->rel2abs($output_dir);

my $manifest_path = File::Spec->catdir($ROOT, "browser-extension", "manifest.json");
open(my $fh, '<', $manifest_path) or die "Cannot read $manifest_path: $!";
my $json_text = do { local $/; <$fh> };
close $fh;
my $manifest = decode_json($json_text);
my $version = $manifest->{version};

my $extension_zip = File::Spec->catdir($output_dir, "tiktok-live-companion-extension-$version.zip");
my $plugin_zip = File::Spec->catdir($output_dir, "tiktok-live-companion-plugin-$version.zip");
my $service_zip = File::Spec->catdir($output_dir, "tiktok-live-companion-service-$version.zip");
my $ios_source_zip = File::Spec->catdir($output_dir, "tiktok-live-companion-ios-$version-source.zip");
my $android_source_zip = File::Spec->catdir($output_dir, "tiktok-live-companion-android-$version-source.zip");
my $android_apk_dest = File::Spec->catdir($output_dir, "tiktok-live-companion-android-$version.apk");
my $extension_dir = File::Spec->catdir($output_dir, "tiktok-live-companion-extension-$version");
my $checksum_file = File::Spec->catdir($output_dir, "tiktok-live-companion-$version-SHA256.txt");

my $resolved_extension_dir = File::Spec->rel2abs($extension_dir);
my $resolved_output_dir = File::Spec->rel2abs($output_dir);
die "Refusing to package outside the requested output directory\n" 
    unless $resolved_extension_dir =~ /^\Q$resolved_output_dir\E/;

remove_tree($extension_dir) if -d $extension_dir;

# Copy browser-extension
system("cp", "-r", File::Spec->catdir($ROOT, "browser-extension"), $extension_dir) == 0 
    or die "Failed to copy browser-extension: $?";

# Copy companion-service
system("cp", "-r", File::Spec->catdir($ROOT, "companion-service"), File::Spec->catdir($extension_dir, "companion-service")) == 0 
    or die "Failed to copy companion-service: $?";

# Create batch file
my $batch_content = '@echo off' . "\r\n" . 'call "%~dp0companion-service\Sprachdienst-reparieren.cmd"' . "\r\n";
open($fh, '>:encoding(utf-8)', File::Spec->catdir($extension_dir, "Sprachdienst-reparieren.cmd")) or die $!;
print $fh $batch_content;
close $fh;

# Create package.json
my $package_json = {
    name => "tiktok-live-companion-extension-package",
    private => JSON::true,
    version => $version,
    scripts => {
        setup => "npm --prefix companion-service run setup --",
        start => "npm --prefix companion-service start",
        test => "npm --prefix companion-service test"
    }
};
open($fh, '>:encoding(utf-8)', File::Spec->catdir($extension_dir, "package.json")) or die $!;
print $fh to_json($package_json, { utf8 => 1, pretty => 1 }) . "\n";
close $fh;

# Create extension zip
{
    my $zip = Archive::Zip->new();
    add_tree($zip, $extension_dir);
    die "Failed to write $extension_zip\n" unless $zip->writeToFileNamed($extension_zip) == AZ_OK;
}

# Create plugin zip
{
    my $zip = Archive::Zip->new();
    add_tree($zip, $ROOT, "tiktok-live-companion");
    die "Failed to write $plugin_zip\n" unless $zip->writeToFileNamed($plugin_zip) == AZ_OK;
}

# Create service zip
{
    my $zip = Archive::Zip->new();
    add_tree($zip, File::Spec->catdir($ROOT, "companion-service"));
    die "Failed to write $service_zip\n" unless $zip->writeToFileNamed($service_zip) == AZ_OK;
}

$ios_source = File::Spec->rel2abs($ios_source);
$android_source = File::Spec->rel2abs($android_source);
die "--ios-source and --android-source must point to existing source directories\n" 
    unless -d $ios_source && -d $android_source;

# Create iOS source zip
{
    my $zip = Archive::Zip->new();
    add_tree($zip, $ios_source, "TikTokLiveCompanion-iOS");
    die "Failed to write $ios_source_zip\n" unless $zip->writeToFileNamed($ios_source_zip) == AZ_OK;
}

# Create Android source zip
{
    my $zip = Archive::Zip->new();
    add_tree($zip, $android_source, "TikTokLiveCompanion-Android");
    die "Failed to write $android_source_zip\n" unless $zip->writeToFileNamed($android_source_zip) == AZ_OK;
}

# Handle APK
if ($android_apk) {
    $android_apk = File::Spec->rel2abs($android_apk);
    die "--android-apk must point to an existing APK\n" unless -f $android_apk && $android_apk =~ /\.apk$/i;
    
    if (File::Spec->rel2abs($android_apk) ne File::Spec->rel2abs($android_apk_dest)) {
        copy($android_apk, $android_apk_dest) or die "Failed to copy APK: $!";
    }
}

my @artifacts = ($extension_zip, $plugin_zip, $service_zip, $ios_source_zip, $android_source_zip);
push @artifacts, $android_apk_dest if -f $android_apk_dest;

my @checksums;
for my $artifact (@artifacts) {
    open($fh, '<', $artifact) or die "Cannot read $artifact: $!";
    binmode $fh;
    my $digest = sha256_hex(do { local $/; <$fh> });
    close $fh;
    my ($artifact_name) = File::Spec->splitpath($artifact);
    push @checksums, "$digest  $artifact_name";
}

open($fh, '>:encoding(utf-8)', $checksum_file) or die $!;
print $fh join("\n", @checksums) . "\n";
close $fh;

my $result = {
    extension_dir => $resolved_extension_dir,
    extension_zip => File::Spec->rel2abs($extension_zip),
    plugin_zip => File::Spec->rel2abs($plugin_zip),
    service_zip => File::Spec->rel2abs($service_zip),
    ios_source_zip => File::Spec->rel2abs($ios_source_zip),
    android_source_zip => File::Spec->rel2abs($android_source_zip),
    android_apk => (-f $android_apk_dest ? File::Spec->rel2abs($android_apk_dest) : undef),
    checksum_file => File::Spec->rel2abs($checksum_file),
    version => $version
};

print encode_json($result) . "\n";
