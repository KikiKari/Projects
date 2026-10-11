#!/usr/bin/perl
# package_artifacts.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Find;
use File::Copy;
use File::Path qw(make_path remove_tree);
use JSON;
use Digest::SHA qw(sha256_hex);
use File::Spec;
use Cwd qw(abs_path getcwd);

my $ROOT = abs_path(File::Spec->catdir(getcwd(), '..', '..'));
my $PROJECT_ROOT = abs_path(File::Spec->catdir($ROOT, '..'));
my %EXCLUDED_PARTS = map { $_ => 1 } ("__pycache__", ".gradle", ".kotlin", ".cxx", "build", "DerivedData", "xcuserdata", "Pods");

sub add_tree {
    my ($archive, $source, $prefix) = @_;
    $prefix //= "";
    
    my @files;
    find(sub {
        return unless -f $_;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $source);
        my @parts = split('/', $rel_path);
        return if grep { $EXCLUDED_PARTS{$_} } @parts;
        my ($ext) = $_ =~ /\.([^.]+)$/;
        return if defined $ext && ($ext eq 'pyc' || $ext eq 'aar');
        push @files, $File::Find::name;
    }, $source);
    
    @files = sort @files;
    
    for my $file (@files) {
        my $relative = File::Spec->abs2rel($file, $source);
        my $archive_path = File::Spec->catfile($prefix, $relative);
        $archive_path =~ s|\\|/|g; # Normalize path separators
        
        open my $fh, '<:raw', $file or die "Cannot open file $file: $!";
        my $content;
        {
            local $/;
            $content = <$fh>;
        }
        close $fh;
        
        my $entry = Archive::Zip::Member->new();
        $entry->fileName($archive_path);
        $entry->contents($content);
        $entry->desiredCompressionMethod(Archive::Zip::COMPRESSION_DEFLATED());
        $entry->unixFileAttributes(-f $file ? 0100644 : 0040755);
        $archive->addMember($entry);
    }
}

my $output_dir;
my $android_apk;
my $android_source_default = File::Spec->catdir($PROJECT_ROOT, "mobile", "android");
my $ios_source_default = File::Spec->catdir($PROJECT_ROOT, "mobile", "ios");
my $native_shared_default = File::Spec->catdir($PROJECT_ROOT, "mobile", "shared");
my $android_source = $android_source_default;
my $ios_source = $ios_source_default;
my $native_shared_source = $native_shared_default;

GetOptions(
    "output-dir=s" => \$output_dir,
    "android-apk=s" => \$android_apk,
    "android-source=s" => \$android_source,
    "ios-source=s" => \$ios_source,
    "native-shared-source=s" => \$native_shared_source,
) or die "Invalid options";

die "--output-dir is required" unless $output_dir;

make_path($output_dir) unless -d $output_dir;

$output_dir = abs_path($output_dir);

# Read manifest.json
my $manifest_path = File::Spec->catfile($ROOT, "browser-extension", "manifest.json");
open my $mfh, '<:encoding(UTF-8)', $manifest_path or die "Cannot read manifest.json: $!";
my $manifest_content;
{
    local $/;
    $manifest_content = <$mfh>;
}
close $mfh;
my $manifest = decode_json($manifest_content);
my $version = $manifest->{version};

my $extension_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-extension-$version.zip");
my $plugin_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-plugin-$version.zip");
my $service_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-service-$version.zip");
my $ios_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-ios-$version-source.zip");
my $android_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version-source.zip");
my $android_apk_file = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version.apk");
my $extension_dir = File::Spec->catdir($output_dir, "tiktok-live-companion-extension-$version");
my $checksum_file = File::Spec->catfile($output_dir, "tiktok-live-companion-$version-SHA256.txt");

my $resolved_extension_dir = abs_path($extension_dir);
my $resolved_output_dir = abs_path($output_dir);
die "Refusing to package outside the requested output directory" unless $resolved_extension_dir =~ /^\Q$resolved_output_dir\E/;

remove_tree($extension_dir) if -d $extension_dir;

# Copy browser-extension
my $src_browser_ext = File::Spec->catdir($ROOT, "browser-extension");
copytree($src_browser_ext, $extension_dir);

# Copy companion-service
my $src_companion_service = File::Spec->catdir($ROOT, "companion-service");
my $dest_companion_service = File::Spec->catdir($extension_dir, "companion-service");
copytree($src_companion_service, $dest_companion_service);

# Write Sprachdienst-reparieren.cmd
my $cmd_file = File::Spec->catfile($extension_dir, "Sprachdienst-reparieren.cmd");
open my $cmd_fh, '>:encoding(UTF-8)', $cmd_file or die "Cannot write to cmd file: $!";
print $cmd_fh '@echo off' . "\r\n";
print $cmd_fh 'call "%~dp0companion-service\\Sprachdienst-reparieren.cmd"' . "\r\n";
close $cmd_fh;

# Write package.json
my $pkg_json = {
    name => "tiktok-live-companion-extension-package",
    private => JSON::true,
    version => $version,
    scripts => {
        setup => "npm --prefix companion-service run setup --",
        start => "npm --prefix companion-service start",
        test => "npm --prefix companion-service test"
    }
};
my $pkg_json_str = to_json($pkg_json, { utf8 => 1, pretty => 1 });
$pkg_json_str .= "\n";
my $pkg_file = File::Spec->catfile($extension_dir, "package.json");
open my $pkg_fh, '>:encoding(UTF-8)', $pkg_file or die "Cannot write package.json: $!";
print $pkg_fh $pkg_json_str;
close $pkg_fh;

# Create zip archives using Archive::Zip
use Archive::Zip qw(:ERROR_CODES);

# Extension ZIP
my $ext_zip = Archive::Zip->new();
add_tree($ext_zip, $extension_dir);
unless ($ext_zip->writeToFileNamed($extension_zip) == AZ_OK) {
    die "Error writing extension ZIP";
}

# Plugin ZIP
my $plugin_zip_obj = Archive::Zip->new();
add_tree($plugin_zip_obj, $ROOT, "tiktok-live-companion");
unless ($plugin_zip_obj->writeToFileNamed($plugin_zip) == AZ_OK) {
    die "Error writing plugin ZIP";
}

# Service ZIP
my $service_zip_obj = Archive::Zip->new();
my $service_src = File::Spec->catdir($ROOT, "companion-service");
add_tree($service_zip_obj, $service_src);
unless ($service_zip_obj->writeToFileNamed($service_zip) == AZ_OK) {
    die "Error writing service ZIP";
}

# Resolve paths
$ios_source = abs_path($ios_source);
$android_source = abs_path($android_source);
die "--ios-source and --android-source must point to existing source directories" 
    unless -d $ios_source && -d $android_source;

$native_shared_source = abs_path($native_shared_source);
my $limiter_header = File::Spec->catfile($native_shared_source, "native", "tlc_peak_limiter.h");
die "Shared native limiter source is required for both mobile source packages" 
    unless -f $limiter_header;

# iOS Source ZIP
my $ios_zip = Archive::Zip->new();
add_tree($ios_zip, $ios_source, "TikTokLiveCompanion-iOS");
add_tree($ios_zip, $native_shared_source, "shared");
unless ($ios_zip->writeToFileNamed($ios_source_zip) == AZ_OK) {
    die "Error writing iOS source ZIP";
}

# Android Source ZIP
my $android_zip = Archive::Zip->new();
add_tree($android_zip, $android_source, "TikTokLiveCompanion-Android");
add_tree($android_zip, $native_shared_source, "shared");
unless ($android_zip->writeToFileNamed($android_source_zip) == AZ_OK) {
    die "Error writing Android source ZIP";
}

# Handle APK if provided
if ($android_apk) {
    my $source_apk = abs_path($android_apk);
    die "--android-apk must point to an existing APK" 
        unless -f $source_apk && lc((split(/\./, $source_apk))[-1]) eq 'apk';
    
    my $resolved_android_apk = abs_path($android_apk_file);
    copy($source_apk, $resolved_android_apk) unless $source_apk eq $resolved_android_apk;
}

# Calculate checksums
my @artifacts = (
    $extension_zip,
    $plugin_zip,
    $service_zip,
    $ios_source_zip,
    $android_source_zip
);
push @artifacts, $android_apk_file if -f $android_apk_file;

my @checksums;
for my $artifact (@artifacts) {
    open my $fh, '<:raw', $artifact or die "Cannot open artifact $artifact: $!";
    my $content;
    {
        local $/;
        $content = <$fh>;
    }
    close $fh;
    my $digest = sha256_hex($content);
    my ($basename) = $artifact =~ /([^\/\\]+)$/;
    push @checksums, "$digest  $basename";
}

open my $chk_fh, '>:encoding(UTF-8)', $checksum_file or die "Cannot write checksum file: $!";
print $chk_fh join("\n", @checksums) . "\n";
close $chk_fh;

# Output result as JSON
my $result = {
    extension_dir => $resolved_extension_dir,
    extension_zip => abs_path($extension_zip),
    plugin_zip => abs_path($plugin_zip),
    service_zip => abs_path($service_zip),
    ios_source_zip => abs_path($ios_source_zip),
    android_source_zip => abs_path($android_source_zip),
    android_apk => (-f $android_apk_file) ? abs_path($android_apk_file) : undef,
    checksum_file => abs_path($checksum_file),
    version => $version
};

print encode_json($result) . "\n";

# Helper function to copy directory trees
sub copytree {
    my ($src, $dst) = @_;
    make_path($dst) unless -d $dst;
    
    opendir(my $dh, $src) or die "Cannot open directory $src: $!";
    my @entries = readdir($dh);
    closedir($dh);
    
    for my $entry (@entries) {
        next if $entry eq '.' || $entry eq '..';
        my $src_path = File::Spec->catfile($src, $entry);
        my $dst_path = File::Spec->catfile($dst, $entry);
        
        if (-d $src_path) {
            copytree($src_path, $dst_path);
        } else {
            copy($src_path, $dst_path) or die "Cannot copy $src_path to $dst_path: $!";
        }
    }
}
