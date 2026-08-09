#!/usr/bin/env tclsh8.6
# package_artifacts.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require zipfile::encode
package require sha256

# Helper function to get script directory
proc getScriptDir {} {
    set script [info script]
    if {$script eq ""} {
        set script [file normalize [lindex $::argv0 0]]
    }
    return [file dirname [file normalize $script]]
}

# Constants
set ROOT [file normalize [file join [getScriptDir] .. ..]]
set PROJECT_ROOT [file dirname $ROOT]
array set EXCLUDED_PARTS [list __pycache__ 1 .gradle 1 .kotlin 1 build 1 DerivedData 1 xcuserdata 1]

# Function to add directory tree to zip
proc addTree {archive source {prefix ""}} {
    global EXCLUDED_PARTS
    set files [lsort [glob -nocomplain -dir $source -type f *]]
    foreach file $files {
        set relPath [file relatiVe $source $file]
        set parts [file split $relPath]
        set skip 0
        foreach part $parts {
            if {[info exists EXCLUDED_PARTS($part)]} {
                set skip 1
                break
            }
        }
        if {!$skip && [string equal [file extension $file] ".pyc"] == 0 && [string equal [file extension $file] ".aar"] == 0} {
            set archivePath [file join $prefix $relPath]
            set archivePath [string map {\\ /} $archivePath]
            $archive addfile $file -name $archivePath
        }
    }
    # Recursively process subdirectories
    set dirs [lsort [glob -nocomplain -dir $source -type d *]]
    foreach dir $dirs {
        set dirName [file tail $dir]
        if {![info exists EXCLUDED_PARTS($dirName)]} {
            addTree $archive $dir [file join $prefix $dirName]
        }
    }
}

# Parse command line arguments
proc parseArgs {} {
    global argv
    array set args [list \
        output_dir "" \
        android_apk "" \
        android_source "" \
        ios_source "" \
    ]
    
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            --output-dir {
                incr i
                set args(output_dir) [lindex $argv $i]
            }
            --android-apk {
                incr i
                set args(android_apk) [lindex $argv $i]
            }
            --android-source {
                incr i
                set args(android_source) [lindex $argv $i]
            }
            --ios-source {
                incr i
                set args(ios_source) [lindex $argv $i]
            }
            default {
                puts stderr "Unknown argument: $arg"
                exit 1
            }
        }
    }
    
    if {$args(output_dir) eq ""} {
        puts stderr "Missing required argument --output-dir"
        exit 1
    }
    
    if {$args(android_source) eq ""} {
        set args(android_source) [file normalize [file join $::PROJECT_ROOT mobile android]]
    }
    
    if {$args(ios_source) eq ""} {
        set args(ios_source) [file normalize [file join $::PROJECT_ROOT mobile ios]]
    }
    
    return [array get args]
}

# Main execution
array set args [parseArgs]

# Create output directory
file mkdir $args(output_dir)
set output_dir [file normalize $args(output_dir)]

# Read manifest to get version
set manifest_file [file join $::ROOT browser-extension manifest.json]
if {![file exists $manifest_file]} {
    puts stderr "Manifest file not found: $manifest_file"
    exit 1
}
set manifest_fd [open $manifest_file r]
set manifest_content [read $manifest_fd]
close $manifest_fd
# Simple JSON parsing for version field
if {[regexp {"version"[[:space:]]*:[[:space:]]*"([^"]+)"} $manifest_content match version]} {
    # Version extracted
} else {
    puts stderr "Could not extract version from manifest"
    exit 1
}

# Define output file paths
set extension_zip [file join $args(output_dir) "tiktok-live-companion-extension-${version}.zip"]
set plugin_zip [file join $args(output_dir) "tiktok-live-companion-plugin-${version}.zip"]
set service_zip [file join $args(output_dir) "tiktok-live-companion-service-${version}.zip"]
set ios_source_zip [file join $args(output_dir) "tiktok-live-companion-ios-${version}-source.zip"]
set android_source_zip [file join $args(output_dir) "tiktok-live-companion-android-${version}-source.zip"]
set android_apk [file join $args(output_dir) "tiktok-live-companion-android-${version}.apk"]
set extension_dir [file join $args(output_dir) "tiktok-live-companion-extension-${version}"]
set checksum_file [file join $args(output_dir) "tiktok-live-companion-${version}-SHA256.txt"]

# Validate extension directory location
set resolved_extension_dir [file normalize $extension_dir]
if {[file dirname $resolved_extension_dir] ne $output_dir} {
    puts stderr "Refusing to package outside the requested output directory"
    exit 1
}

# Clean up existing extension directory
if {[file exists $extension_dir]} {
    file delete -force $extension_dir
}

# Copy directories
file copy [file join $::ROOT browser-extension] $extension_dir
file copy [file join $::ROOT companion-service] [file join $extension_dir companion-service]

# Create package.json content
set package_json_content "{\n  \"name\": \"tiktok-live-companion-extension-package\",\n  \"private\": true,\n  \"version\": \"$version\",\n  \"scripts\": {\n    \"setup\": \"npm --prefix companion-service run setup --\",\n    \"start\": \"npm --prefix companion-service start\",\n    \"test\": \"npm --prefix companion-service test\"\n  }\n}\n"

set package_fd [open [file join $extension_dir package.json] w]
puts $package_fd $package_json_content
close $package_fd

# Create extension zip
set ext_zip [zipfile::encode::open $extension_zip]
addTree $ext_zip $extension_dir
$ext_zip destroy

# Create plugin zip
set plugin_zip_obj [zipfile::encode::open $plugin_zip]
addTree $plugin_zip_obj $::ROOT "tiktok-live-companion"
$plugin_zip_obj destroy

# Create service zip
set service_zip_obj [zipfile::encode::open $service_zip]
addTree $service_zip_obj [file join $::ROOT companion-service]
$service_zip_obj destroy

# Validate source directories
set ios_source [file normalize $args(ios_source)]
set android_source [file normalize $args(android_source)]

if {![file isdirectory $ios_source] || ![file isdirectory $android_source]} {
    puts stderr "--ios-source and --android-source must point to existing source directories"
    exit 1
}

# Create iOS source zip
set ios_zip_obj [zipfile::encode::open $ios_source_zip]
addTree $ios_zip_obj $ios_source "TikTokLiveCompanion-iOS"
$ios_zip_obj destroy

# Create Android source zip
set android_zip_obj [zipfile::encode::open $android_source_zip]
addTree $android_zip_obj $android_source "TikTokLiveCompanion-Android"
$android_zip_obj destroy

# Handle Android APK if provided
if {$args(android_apk) ne ""} {
    set source_apk [file normalize $args(android_apk)]
    if {![file isfile $source_apk] || [string tolower [file extension $source_apk]] ne ".apk"} {
        puts stderr "--android-apk must point to an existing APK"
        exit 1
    }
    file copy -force $source_apk $android_apk
}

# Calculate checksums
set artifacts [list $extension_zip $plugin_zip $service_zip $ios_source_zip $android_source_zip]
if {[file exists $android_apk]} {
    lappend artifacts $android_apk
}

set checksums {}
foreach artifact $artifacts {
    if {[file exists $artifact]} {
        set fd [open $artifact r]
        fconfigure $fd -translation binary
        set content [read $fd]
        close $fd
        set digest [sha2::sha256 -bin $content]
        set hex_digest [binary encode hex $digest]
        lappend checksums "$hex_digest  [file tail $artifact]"
    }
}

set chk_fd [open $checksum_file w]
puts $chk_fd [join $checksums "\n"]
close $chk_fd

# Output JSON result
puts "{"
puts "  \"extension_dir\": \"[string map {\\ /} $resolved_extension_dir]\","
puts "  \"extension_zip\": \"[string map {\\ /} [file normalize $extension_zip]]\","
puts "  \"plugin_zip\": \"[string map {\\ /} [file normalize $plugin_zip]]\","
puts "  \"service_zip\": \"[string map {\\ /} [file normalize $service_zip]]\","
puts "  \"ios_source_zip\": \"[string map {\\ /} [file normalize $ios_source_zip]]\","
puts "  \"android_source_zip\": \"[string map {\\ /} [file normalize $android_source_zip]]\","
if {[file exists $android_apk]} {
    puts "  \"android_apk\": \"[string map {\\ /} [file normalize $android_apk]]\","
} else {
    puts "  \"android_apk\": null,"
}
puts "  \"checksum_file\": \"[string map {\\ /} [file normalize $checksum_file]]\","
puts "  \"version\": \"$version\""
puts "}"
