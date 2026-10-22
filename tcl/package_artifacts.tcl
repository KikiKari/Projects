#!/usr/bin/env tclsh
# package_artifacts.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require zipfile::encode
package require sha256

# Define constants
set ROOT [file normalize [file dirname [info script]]]
set PROJECT_ROOT [file dirname $ROOT]
array set EXCLUDED_PARTS [list __pycache__ 1 .gradle 1 .kotlin 1 .cxx 1 build 1 DerivedData 1 xcuserdata 1 Pods 1]

proc add_tree {archive source {prefix ""}} {
    global EXCLUDED_PARTS
    # Get all files recursively
    set files {}
    proc walk_dir {dir} {
        upvar files files
        foreach item [glob -nocomplain -dir $dir *] {
            if {[file isdirectory $item]} {
                walk_dir $item
            } else {
                lappend files $item
            }
        }
    }
    walk_dir $source
    set files [lsort $files]
    
    foreach path $files {
        # Check if file should be excluded
        set exclude 0
        foreach part [split [string range $path [string length $source]+1 end] "/\\"] {
            if {[info exists EXCLUDED_PARTS($part)]} {
                set exclude 1
                break
            }
        }
        if {$exclude || [string match "*.pyc" $path] || [string match "*.aar" $path]} {
            continue
        }
        
        set relative [file join $prefix [file relative $source $path]]
        set entry [dict create]
        dict set entry filename $relative
        dict set entry datetime {1980 1 1 0 0 0}
        dict set entry compress 1
        dict set entry level 9
        
        # Set permissions
        if {[file tail $path] eq "gradlew"} {
            dict set entry permissions 0755
        } else {
            dict set entry permissions 0644
        }
        
        set data [read_binary_file $path]
        ::zipfile::encode::addEntry $archive $entry $data
    }
}

proc read_binary_file {filename} {
    set fh [open $filename rb]
    set data [read $fh]
    close $fh
    return $data
}

proc write_text_file {filename content} {
    set fh [open $filename w]
    puts -nonewline $fh $content
    close $fh
}

proc copy_directory {src dst} {
    file mkdir $dst
    foreach item [glob -nocomplain -dir $src *] {
        set basename [file tail $item]
        set dest_item [file join $dst $basename]
        if {[file isdirectory $item]} {
            file copy $item $dest_item
        } else {
            file copy $item $dest_item
        }
    }
}

proc remove_directory {dir} {
    if {[file exists $dir]} {
        file delete -force $dir
    }
}

proc parse_json {json_str} {
    # Simple JSON parser - assumes valid simple JSON structure
    regsub -all {^\s*//.*$} $json_str {} json_str ;# Remove comments if any
    return [dict create {*}[lmap pair [regexp -inline -all {"[^"]+"}\s*:\s*(?:"[^"]*"|\{[^{}]*\}|\[[^\[\]]*\]|[0-9]+|true|false|null)} $json_str] {
        lassign [split $pair ":"] key value
        set key [string trim $key "\" "]
        set value [string trim $value " \"\{\}"]
        list $key $value
    }]]
}

# Parse arguments manually since we don't have argparse equivalent
set args $argv
array set parsed_args {}

# Default values
set parsed_args(output_dir) ""
set parsed_args(android_apk) ""
set parsed_args(android_source) [file join $PROJECT_ROOT mobile android]
set parsed_args(ios_source) [file join $PROJECT_ROOT mobile ios]
set parsed_args(native_shared_source) [file join $PROJECT_ROOT mobile shared]

# Process command line arguments
for {set i 0} {$i < [llength $args]} {incr i} {
    set arg [lindex $args $i]
    switch -exact -- $arg {
        --output-dir {
            incr i
            set parsed_args(output_dir) [lindex $args $i]
        }
        --android-apk {
            incr i
            set parsed_args(android_apk) [lindex $args $i]
        }
        --android-source {
            incr i
            set parsed_args(android_source) [lindex $args $i]
        }
        --ios-source {
            incr i
            set parsed_args(ios_source) [lindex $args $i]
        }
        --native-shared-source {
            incr i
            set parsed_args(native_shared_source) [lindex $args $i]
        }
    }
}

# Validate required argument
if {$parsed_args(output_dir) eq ""} {
    puts stderr "Error: --output-dir is required"
    exit 1
}

# Create output directory
file mkdir $parsed_args(output_dir)
set output_dir [file normalize $parsed_args(output_dir)]

# Read manifest to get version
set manifest_fh [open [file join $ROOT browser-extension manifest.json] r]
set manifest_content [read $manifest_fh]
close $manifest_fh
set manifest_dict [parse_json $manifest_content]
set version [dict get $manifest_dict version]

# Define artifact paths
set extension_zip [file join $output_dir "tiktok-live-companion-extension-$version.zip"]
set plugin_zip [file join $output_dir "tiktok-live-companion-plugin-$version.zip"]
set service_zip [file join $output_dir "tiktok-live-companion-service-$version.zip"]
set ios_source_zip [file join $output_dir "tiktok-live-companion-ios-$version-source.zip"]
set android_source_zip [file join $output_dir "tiktok-live-companion-android-$version-source.zip"]
set android_apk [file join $output_dir "tiktok-live-companion-android-$version.apk"]
set extension_dir [file join $output_dir "tiktok-live-companion-extension-$version"]
set checksum_file [file join $output_dir "tiktok-live-companion-$version-SHA256.txt"]

# Validate extension directory location
set resolved_extension_dir [file normalize $extension_dir]
if {[file dirname $resolved_extension_dir] ne $output_dir} {
    error "Refusing to package outside the requested output directory"
}

# Clean and prepare extension directory
remove_directory $extension_dir
copy_directory [file join $ROOT browser-extension] $extension_dir
copy_directory [file join $ROOT companion-service] [file join $extension_dir companion-service]

# Write Windows batch file
write_text_file [file join $extension_dir "Sprachdienst-reparieren.cmd"] "@echo off\r\ncall \"%~dp0companion-service\\\\Sprachdienst-reparieren.cmd\"\r\n"

# Write package.json
set package_json_content "{\n  \"name\": \"tiktok-live-companion-extension-package\",\n  \"private\": true,\n  \"version\": \"$version\",\n  \"scripts\": {\n    \"setup\": \"npm --prefix companion-service run setup --\",\n    \"start\": \"npm --prefix companion-service start\",\n    \"test\": \"npm --prefix companion-service test\"\n  }\n}\n"
write_text_file [file join $extension_dir package.json] $package_json_content

# Package extensions
set archive [::zipfile::encode::create $extension_zip]
add_tree $archive $extension_dir
::zipfile::encode::close $archive

set archive [::zipfile::encode::create $plugin_zip]
add_tree $archive $ROOT tiktok-live-companion
::zipfile::encode::close $archive

set archive [::zipfile::encode::create $service_zip]
add_tree $archive [file join $ROOT companion-service]
::zipfile::encode::close $archive

# Resolve source directories
set ios_source [file normalize $parsed_args(ios_source)]
set android_source [file normalize $parsed_args(android_source)]
if {![file isdirectory $ios_source] || ![file isdirectory $android_source]} {
    error "--ios-source and --android-source must point to existing source directories"
}

set native_shared [file normalize $parsed_args(native_shared_source)]
if {![file exists [file join $native_shared native tlc_peak_limiter.h]]} {
    error "Shared native limiter source is required for both mobile source packages"
}

# Package iOS sources
set archive [::zipfile::encode::create $ios_source_zip]
add_tree $archive $ios_source TikTokLiveCompanion-iOS
add_tree $archive $native_shared shared
::zipfile::encode::close $archive

# Package Android sources
set archive [::zipfile::encode::create $android_source_zip]
add_tree $archive $android_source TikTokLiveCompanion-Android
add_tree $archive $native_shared shared
::zipfile::encode::close $archive

# Handle optional APK
if {$parsed_args(android_apk) ne ""} {
    set source_apk [file normalize $parsed_args(android_apk)]
    if {![file isfile $source_apk] || [string tolower [file extension $source_apk]] ne ".apk"} {
        error "--android-apk must point to an existing APK"
    }
    if {$source_apk ne [file normalize $android_apk]} {
        file copy -force $source_apk $android_apk
    }
}

# Calculate checksums
set artifacts [list $extension_zip $plugin_zip $service_zip $ios_source_zip $android_source_zip]
if {[file exists $android_apk]} {
    lappend artifacts $android_apk
}

set checksums {}
foreach artifact $artifacts {
    set fh [open $artifact r]
    fconfigure $fh -translation binary
    set data [read $fh]
    close $fh
    set digest [sha256::sha256 -hex $data]
    lappend checksums "$digest  [file tail $artifact]"
}

write_text_file $checksum_file "[join $checksums \n]\n"

# Output result as JSON
puts "{\"extension_dir\":\"[string map {\\ /} [file normalize $extension_dir]]\",\"extension_zip\":\"[string map {\\ /} [file normalize $extension_zip]]\",\"plugin_zip\":\"[string map {\\ /} [file normalize $plugin_zip]]\",\"service_zip\":\"[string map {\\ /} [file normalize $service_zip]]\",\"ios_source_zip\":\"[string map {\\ /} [file normalize $ios_source_zip]]\",\"android_source_zip\":\"[string map {\\ /} [file normalize $android_source_zip]]\",\"android_apk\":\"[expr {[file exists $android_apk] ? [string map {\\ /} [file normalize $android_apk]] : "null"}]\",\"checksum_file\":\"[string map {\\ /} [file normalize $checksum_file]]\",\"version\":\"$version\"}"
