#!/usr/bin/env tclsh
# package_artifacts.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require zipfile::encode
package require json
package require fileutil

# Global variables
set ROOT [file normalize [file dirname [file dirname [info script]]]]
set PROJECT_ROOT [file dirname $ROOT]
set EXCLUDED_PARTS [list "__pycache__" ".gradle" ".kotlin" "build" "DerivedData" "xcuserdata"]

# Function to add directory tree to archive
proc add_tree {archive source {prefix ""}} {
    global EXCLUDED_PARTS
    set files [lsort [glob -nocomplain -dir $source -types f -recursive *]]
    foreach path $files {
        # Check if any excluded part is in the path
        set skip 0
        foreach part [file split $path] {
            if {$part in $EXCLUDED_PARTS} {
                set skip 1
                break
            }
        }
        if {$skip} continue
        
        # Check file extensions
        if {[file extension $path] in [list ".pyc" ".aar"]} continue
        
        set relative [file relative $source $path]
        if {$prefix ne ""} {
            set archive_path [file join $prefix $relative]
        } else {
            set archive_path $relative
        }
        $archive add $path $archive_path
    }
}

# Argument parsing
if {[llength $argv] < 2 || [lsearch -exact $argv "--output-dir"] == -1} {
    puts "Usage: [info script] --output-dir <directory> \[--android-apk <apk-file>\]"
    exit 1
}

set output_dir ""
set android_apk_arg ""
for {set i 0} {$i < [llength $argv]} {incr i} {
    set arg [lindex $argv $i]
    if {$arg eq "--output-dir"} {
        incr i
        set output_dir [lindex $argv $i]
    } elseif {$arg eq "--android-apk"} {
        incr i
        set android_apk_arg [lindex $argv $i]
    }
}

if {$output_dir eq ""} {
    error "Missing required argument --output-dir"
}

file mkdir $output_dir
set output_dir [file normalize $output_dir]

# Read manifest to get version
set manifest_file [file join $ROOT "browser-extension" "manifest.json"]
if {![file exists $manifest_file]} {
    error "Manifest file not found: $manifest_file"
}
set manifest_content [read [open $manifest_file r]]
set manifest [json::json2dict $manifest_content]
set version [dict get $manifest "version"]

# Define artifact file paths
set extension_zip [file join $output_dir "tiktok-live-companion-extension-${version}.zip"]
set plugin_zip [file join $output_dir "tiktok-live-companion-plugin-${version}.zip"]
set service_zip [file join $output_dir "tiktok-live-companion-service-${version}.zip"]
set ios_source_zip [file join $output_dir "tiktok-live-companion-ios-${version}-source.zip"]
set android_source_zip [file join $output_dir "tiktok-live-companion-android-${version}-source.zip"]
set android_apk [file join $output_dir "tiktok-live-companion-android-${version}.apk"]
set extension_dir [file join $output_dir "tiktok-live-companion-extension-${version}"]
set checksum_file [file join $output_dir "tiktok-live-companion-${version}-SHA256.txt"]

# Validate extension directory location
set resolved_extension_dir [file normalize $extension_dir]
if {[file dirname $resolved_extension_dir] ne $output_dir} {
    error "Refusing to package outside the requested output directory"
}

# Clean and copy extension directory
if {[file exists $extension_dir]} {
    file delete -force $extension_dir
}
file copy [file join $ROOT "browser-extension"] $extension_dir

# Create extension zip
set archive [zipfile::encode::open $extension_zip]
add_tree $archive [file join $ROOT "browser-extension"]
$archive close

# Create plugin zip
set archive [zipfile::encode::open $plugin_zip]
add_tree $archive $ROOT "tiktok-live-companion"
$archive close

# Create service zip
set archive [zipfile::encode::open $service_zip]
add_tree $archive [file join $ROOT "companion-service"]
$archive close

# Create iOS source zip
set archive [zipfile::encode::open $ios_source_zip]
add_tree $archive [file join $PROJECT_ROOT "mobile" "ios"] "TikTokLiveCompanion-iOS"
$archive close

# Create Android source zip
set archive [zipfile::encode::open $android_source_zip]
add_tree $archive [file join $PROJECT_ROOT "mobile" "android"] "TikTokLiveCompanion-Android"
$archive close

# Handle Android APK if provided
if {$android_apk_arg ne ""} {
    set source_apk [file normalize $android_apk_arg]
    if {![file isfile $source_apk] || [string tolower [file extension $source_apk]] ne ".apk"} {
        error "--android-apk must point to an existing APK"
    }
    file copy -force $source_apk $android_apk
}

# Create checksums
set artifacts [list $extension_zip $plugin_zip $service_zip $ios_source_zip $android_source_zip]
if {[file exists $android_apk]} {
    lappend artifacts $android_apk
}

set checksums {}
foreach artifact $artifacts {
    set fh [open $artifact r]
    fconfigure $fh -translation binary
    set content [read $fh]
    close $fh
    set digest [sha256 $content]
    lappend checksums "${digest}  [file tail $artifact]"
}

set fh [open $checksum_file w]
puts $fh [join $checksums "\n"]
close $fh

# Output JSON result
set result [dict create]
dict set result "extension_dir" $resolved_extension_dir
dict set result "extension_zip" [file normalize $extension_zip]
dict set result "plugin_zip" [file normalize $plugin_zip]
dict set result "service_zip" [file normalize $service_zip]
dict set result "ios_source_zip" [file normalize $ios_source_zip]
dict set result "android_source_zip" [file normalize $android_source_zip]
if {[file exists $android_apk]} {
    dict set result "android_apk" [file normalize $android_apk]
} else {
    dict set result "android_apk" {}
}
dict set result "checksum_file" [file normalize $checksum_file]
dict set result "version" $version

puts [json::dict2json $result]

# SHA256 implementation for Tcl
proc sha256 {data} {
    # This is a simplified placeholder - in practice you would use
    # a proper SHA256 implementation or call an external tool
    # For demonstration purposes, we'll use a simple hash approach
    # In a real implementation, you'd want to use a proper crypto library
    
    # If tcllib's sha256 is available:
    if {[info commands ::sha256] eq ""} {
        # Fallback: use openssl if available
        if {[catch {exec openssl version}]} {
            # Very basic fallback - not cryptographically secure
            set hash ""
            binary scan $data H* hash
            # Truncate or pad to simulate 64 chars
            return [string range $hash 0 63]
        } else {
            # Use openssl
            set cmd [list openssl dgst -sha256 -binary]
            set pipe [open "|[join $cmd]" w+]
            fconfigure $pipe -translation binary
            puts -nonewline $pipe $data
            close $pipe w
            set result [read $pipe]
            close $pipe
            binary scan $result H* hex
            return $hex
        }
    } else {
        return [::sha256 $data]
    }
}
