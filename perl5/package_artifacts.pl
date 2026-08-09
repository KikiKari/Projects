#!/usr/bin/perl
# package_artifacts.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use JSON;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Spec;
use File::Find;
use Digest::SHA qw(sha256_hex);
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);

my $ROOT = File::Spec->rel2abs(File::Spec->catdir((split '/', __FILE__)[-3], (split '/', __FILE__)[-2]));
my $PROJECT_ROOT = File::Spec->rel2abs(File::Spec->catdir($ROOT, '..'));

my %EXCLUDED_PARTS = (
    "__pycache__" => 1,
    ".gradle" => 1,
    ".kotlin" => 1,
    "build" => 1,
    "DerivedData" => 1,
    "xcuserdata" => 1
);

sub add_tree {
    my ($archive, $source, $prefix) = @_;
    $prefix //= "";
    
    my @files;
    find(sub {
        return unless -f $_;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $source);
        my @parts = split '/', $rel_path;
        return if grep { exists $EXCLUDED_PARTS{$_} } @parts;
        my ($ext) = $_ =~ /(\.[^.]+)$/;
        return if defined $ext && ($ext eq ".pyc" || $ext eq ".aar");
        push @files, $File::Find::name;
    }, $source);
    
    @files = sort @files;
    
    for my $file (@files) {
        my $relative = File::Spec->abs2rel($file, $source);
        my $archive_path = $prefix ? File::Spec->catfile($prefix, $relative) : $relative;
        $archive_path =~ s|\\|/|g;
        
        my $member = $archive->addFile($file, $archive_path);
        $member->desiredCompressionMethod(COMPRESSION_DEFLATED);
        $member->desiredCompressionLevel(9);
    }
}

my $output_dir;
my $android_apk;
my $android_source = File::Spec->catdir($PROJECT_ROOT, "mobile", "android");
my $ios_source = File::Spec->catdir($PROJECT_ROOT, "mobile", "ios");

GetOptions(
    "output-dir=s" => \$output_dir,
    "android-apk=s" => \$android_apk,
    "android-source=s" => \$android_source,
    "ios-source=s" => \$ios_source
) or die "Error in command line arguments\n";

die "--output-dir is required\n" unless $output_dir;

make_path($output_dir) unless -d $output_dir;
$output_dir = File::Spec->rel2abs($output_dir);

my $manifest_path = File::Spec->catfile($ROOT, "browser-extension", "manifest.json");
open my $fh, '<', $manifest_path or die "Cannot read $manifest_path: $!";
my $manifest_content = do { local $/; <$fh> };
close $fh;
my $manifest = decode_json($manifest_content);
my $version = $manifest->{version};

my $extension_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-extension-$version.zip");
my $plugin_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-plugin-$version.zip");
my $service_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-service-$version.zip");
my $ios_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-ios-$version-source.zip");
my $android_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version-source.zip");
my $android_apk_dest = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version.apk");
my $extension_dir = File::Spec->catdir($output_dir, "tiktok-live-companion-extension-$version");
my $checksum_file = File::Spec->catfile($output_dir, "tiktok-live-companion-$version-SHA256.txt");

my $resolved_extension_dir = File::Spec->rel2abs($extension_dir);
my $resolved_output_dir = File::Spec->rel2abs($output_dir);
die "Refusing to package outside the requested output directory\n" unless $resolved_extension_dir =~ /^\Q$resolved_output_dir\E/;

remove_tree($extension_dir) if -d $extension_dir;
make_path($extension_dir);

my $browser_ext_source = File::Spec->catdir($ROOT, "browser-extension");
my $service_source = File::Spec->catdir($ROOT, "companion-service");

system("cp", "-r", $browser_ext_source, $extension_dir) == 0 or die "Failed to copy browser-extension: $!";
system("cp", "-r", $service_source, File::Spec->catdir($extension_dir, "companion-service")) == 0 or die "Failed to copy companion-service: $!";

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

my $package_json_path = File::Spec->catfile($extension_dir, "package.json");
open $fh, '>', $package_json_path or die "Cannot write to $package_json_path: $!";
print $fh to_json($package_json, { utf8 => 1, pretty => 1 }) . "\n";
close $fh;

{
    my $zip = Archive::Zip->new();
    add_tree($zip, $extension_dir);
    die "Error writing $extension_zip\n" unless $zip->writeToFileNamed($extension_zip) == AZ_OK;
}

{
    my $zip = Archive::Zip->new();
    add_tree($zip, $ROOT, "tiktok-live-companion");
    die "Error writing $plugin_zip\n" unless $zip->writeToFileNamed($plugin_zip) == AZ_OK;
}

{
    my $zip = Archive::Zip->new();
    add_tree($zip, $service_source);
    die "Error writing $service_zip\n" unless $zip->writeToFileNamed($service_zip) == AZ_OK;
}

$ios_source = File::Spec->rel2abs($ios_source);
$android_source = File::Spec->rel2abs($android_source);
die "--ios-source and --android-source must point to existing source directories\n" unless -d $ios_source && -d $android_source;

{
    my $zip = Archive::Zip->new();
    add_tree($zip, $ios_source, "TikTokLiveCompanion-iOS");
    die "Error writing $ios_source_zip\n" unless $zip->writeToFileNamed($ios_source_zip) == AZ_OK;
}

{
    my $zip = Archive::Zip->new();
    add_tree($zip, $android_source, "TikTokLiveCompanion-Android");
    die "Error writing $android_source_zip\n" unless $zip->writeToFileNamed($android_source_zip) == AZ_OK;
}

if ($android_apk) {
    $android_apk = File::Spec->rel2abs($android_apk);
    die "--android-apk must point to an existing APK\n" unless -f $android_apk && $android_apk =~ /\.apk$/i;
    copy($android_apk, $android_apk_dest) or die "Failed to copy APK: $!";
}

my @artifacts = ($extension_zip, $plugin_zip, $service_zip, $ios_source_zip, $android_source_zip);
push @artifacts, $android_apk_dest if -f $android_apk_dest;

my @checksums;
for my $artifact (@artifacts) {
    open my $fh, '<', $artifact or die "Cannot read $artifact: $!";
    binmode $fh;
    my $digest = sha256_hex(do { local $/; <$fh> });
    close $fh;
    my ($name) = $artifact =~ /([^\/\\]+)$/;
    push @checksums, "$digest  $name";
}

open $fh, '>', $checksum_file or die "Cannot write to $checksum_file: $!";
print $fh join("\n", @checksums) . "\n";
close $fh;

my $result = {
    extension_dir => $resolved_extension_dir,
    extension_zip => File::Spec->rel2abs($extension_zip),
    plugin_zip => File::Spec->rel2abs($plugin_zip),
    service_zip => File::Spec->rel2abs($service_zip),
    ios_source_zip => File::Spec->rel2abs($ios_source_zip),
    android_source_zip => File::Spec->rel2abs($android_source_zip),
    android_apk => -f $android_apk_dest ? File::Spec->rel2abs($android_apk_dest) : undef,
    checksum_file => File::Spec->rel2abs($checksum_file),
    version => $version
};

print to_json($result, { utf8 => 1, pretty => 1 }) . "\n";
