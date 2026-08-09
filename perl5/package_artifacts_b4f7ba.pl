#!/usr/bin/perl
# package_artifacts.py — portiert nach perl5
# Quelle: python, Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use JSON;
use File::Path qw(make_path remove_tree);
use File::Copy qw(copy);
use File::Spec;
use File::Basename;
use Digest::SHA qw(sha256_hex);
use Cwd qw(abs_path);

my $ROOT = dirname(dirname(abs_path($0)));
my $PROJECT_ROOT = dirname($ROOT);
my %EXCLUDED_PARTS = map { $_ => 1 } ("__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata");

sub add_tree {
    my ($archive, $source, $prefix) = @_;
    $prefix //= "";
    my @files = traverse_directory($source);
    for my $file (@files) {
        my $relative_path = File::Spec->abs2rel($file, $source);
        next if is_excluded($file, $source) || $file =~ /\.(?:pyc|aar)$/i;
        my $archive_path = $prefix ? File::Spec->catfile($prefix, $relative_path) : $relative_path;
        $archive_path =~ s/\\/\//g; # Normalize path separators
        $archive->addFile($file, $archive_path);
    }
}

sub traverse_directory {
    my ($dir) = @_;
    my @files;
    opendir(my $dh, $dir) or die "Cannot opendir $dir: $!";
    my @entries = readdir($dh);
    closedir($dh);
    for my $entry (@entries) {
        next if $entry eq '.' || $entry eq '..';
        my $full_path = File::Spec->catfile($dir, $entry);
        if (-d $full_path) {
            push @files, traverse_directory($full_path);
        } elsif (-f $full_path) {
            push @files, $full_path;
        }
    }
    return sort @files;
}

sub is_excluded {
    my ($file, $source) = @_;
    my $rel_path = File::Spec->abs2rel($file, $source);
    my @parts = split /[\/\\]/, $rel_path;
    for my $part (@parts) {
        return 1 if exists $EXCLUDED_PARTS{$part};
    }
    return 0;
}

my $output_dir;
my $android_apk;
GetOptions(
    "output-dir=s" => \$output_dir,
    "android-apk=s" => \$android_apk,
) or die "Invalid options\n";

die "Missing --output-dir\n" unless $output_dir;

make_path($output_dir) unless -d $output_dir;
$output_dir = abs_path($output_dir);

my $manifest_path = File::Spec->catfile($ROOT, "browser-extension", "manifest.json");
open my $fh, '<:encoding(UTF-8)', $manifest_path or die "Cannot read $manifest_path: $!";
my $manifest_content = do { local $/; <$fh> };
close $fh;
my $manifest = decode_json($manifest_content);
my $version = $manifest->{version};

my $extension_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-extension-$version.zip");
my $plugin_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-plugin-$version.zip");
my $service_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-service-$version.zip");
my $ios_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-ios-$version-source.zip");
my $android_source_zip = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version-source.zip");
my $apk_output = File::Spec->catfile($output_dir, "tiktok-live-companion-android-$version.apk");
my $extension_dir = File::Spec->catfile($output_dir, "tiktok-live-companion-extension-$version");
my $checksum_file = File::Spec->catfile($output_dir, "tiktok-live-companion-$version-SHA256.txt");

my $resolved_extension_dir = abs_path($extension_dir);
my $resolved_output_dir = abs_path($output_dir);
die "Refusing to package outside the requested output directory\n" unless $resolved_extension_dir =~ /^\Q$resolved_output_dir\E/;

if (-d $extension_dir) {
    remove_tree($extension_dir);
}
my $source_extension = File::Spec->catfile($ROOT, "browser-extension");
copytree($source_extension, $extension_dir);

create_zip($extension_zip, File::Spec->catfile($ROOT, "browser-extension"), undef);
create_zip($plugin_zip, $ROOT, "tiktok-live-companion");
create_zip($service_zip, File::Spec->catfile($ROOT, "companion-service"), undef);
create_zip($ios_source_zip, File::Spec->catfile($PROJECT_ROOT, "mobile", "ios"), "TikTokLiveCompanion-iOS");
create_zip($android_source_zip, File::Spec->catfile($PROJECT_ROOT, "mobile", "android"), "TikTokLiveCompanion-Android");

if ($android_apk) {
    my $source_apk = abs_path($android_apk);
    die "--android-apk must point to an existing APK\n" unless -f $source_apk && $source_apk =~ /\.apk$/i;
    copy($source_apk, $apk_output) or die "Cannot copy APK: $!";
}

my @artifacts = ($extension_zip, $plugin_zip, $service_zip, $ios_source_zip, $android_source_zip);
push @artifacts, $apk_output if -f $apk_output;

my @checksums;
for my $artifact (@artifacts) {
    open my $fh, '<', $artifact or die "Cannot open $artifact: $!";
    binmode $fh;
    my $digest = sha256_hex(do { local $/; <$fh> });
    close $fh;
    my $basename = basename($artifact);
    push @checksums, "$digest  $basename";
}
open my $chk_fh, '>:encoding(UTF-8)', $checksum_file or die "Cannot write checksum file: $!";
print $chk_fh join("\n", @checksums) . "\n";
close $chk_fh;

my %result = (
    extension_dir => $resolved_extension_dir,
    extension_zip => abs_path($extension_zip),
    plugin_zip => abs_path($plugin_zip),
    service_zip => abs_path($service_zip),
    ios_source_zip => abs_path($ios_source_zip),
    android_source_zip => abs_path($android_source_zip),
    android_apk => -f $apk_output ? abs_path($apk_output) : undef,
    checksum_file => abs_path($checksum_file),
    version => $version,
);

print encode_json(\%result) . "\n";

sub create_zip {
    my ($zip_path, $source, $prefix) = @_;
    require Archive::Zip;
    my $zip = Archive::Zip->new();
    add_tree($zip, $source, $prefix);
    $zip->writeToFileNamed($zip_path) == 0 or die "Error writing $zip_path: $!";
}

sub copytree {
    my ($src, $dst) = @_;
    die "Source $src is not a directory\n" unless -d $src;
    make_path($dst) unless -d $dst;
    opendir(my $dh, $src) or die "Cannot opendir $src: $!";
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
