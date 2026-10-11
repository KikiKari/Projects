#!/usr/bin/env tclsh8.6
# package_artifacts.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require zipfile::encode
package require sha256
package require fileutil
package require json
package require cmdline

# Global variables
set EXCLUDED_PARTS [list "__pycache__" ".gradle" ".kotlin" ".cxx" "build" "DerivedData" "xcuserdata" "Pods"]

# Helper procedures
proc resolve_path {path} {
    if {[catch {file normalize $path} result]} {
        return $path
    }
    return $result
}

proc parent_path {path} {
    return [file dirname $path]
}

proc read_json {filepath} {
    set fd [open $filepath r]
    set content [read $fd]
    close $fd
    return [json::json2dict $content]
}

proc write_json {filepath data} {
    set fd [open $filepath w]
    puts $fd [json::dict2json $data]
    close $fd
}

proc rglob {dir} {
    set result {}
    proc scan_dir {d} {
        upvar result result
        foreach f [glob -nocomplain -directory $d *] {
            if {[file isdirectory $f]} {
                lappend result $f
                scan_dir $f
            } else {
                lappend result $f
            }
        }
    }
    scan_dir $dir
    return $result
}

proc should_exclude {path} {
    global EXCLUDED_PARTS
    foreach part [file split $path] {
        if {$part in $EXCLUDED_PARTS} {
            return 1
        }
    }
    set ext [file extension $path]
    if {$ext in [list ".pyc" ".aar"]} {
        return 1
    }
    return 0
}

proc add_tree {archive source {prefix ""}} {
    set all_files [rglob $source]
    set sorted_files [lsort $all_files]
    
    foreach path $sorted_files {
        if {![file isfile $path] || [should_exclude $path]} {
            continue
        }
        
        set relative [string range $path [string length $source] end]
        if {[string index $relative 0] eq "/"} {
            set relative [string range $relative 1 end]
        }
        
        set archive_path $relative
        if {$prefix ne ""} {
            set archive_path [file join $prefix $relative]
        }
        
        # Convert to posix separators
        set archive_path [string map {\\ /} $archive_path]
        
        # Create zip entry with fixed timestamp
        set entry_data [read_binary_file $path]
        set permissions 0644
        if {[file tail $path] eq "gradlew"} {
            set permissions 0755
        }
        
        $archive addelement $entry_data $archive_path \
            -method deflate \
            -level 9 \
            -time [clock scan "1980-01-01 00:00:00"] \
            -permissions $permissions
    }
}

proc read_binary_file {filepath} {
    set fd [open $filepath rb]
    set data [read $fd]
    close $fd
    return $data
}

proc write_binary_file {filepath data} {
    set fd [open $filepath wb]
    puts -nonewline $fd $data
    close $fd
}

proc copy_directory {src dest} {
    file mkdir $dest
    file copy -force $src $dest
}

proc remove_directory {dir} {
    if {[file exists $dir]} {
        file delete -force $dir
    }
}

proc write_text_file {filepath text} {
    set fd [open $filepath w]
    puts $fd $text
    close $fd
}

proc read_text_file {filepath} {
    set fd [open $filepath r]
    set content [read $fd]
    close $fd
    return $content
}

proc compute_sha256 {filepath} {
    set fd [open $filepath rb]
    set sha [sha256::sha256 -channel $fd]
    close $fd
    return $sha
}

# Main script
proc main {} {
    global argv
    global EXCLUDED_PARTS
    
    # Parse arguments
    set optionspec {
        {output-dir.arg "" "Output directory"}
        {android-apk.arg "" "Optional verified mockDebug or shazamDebug APK"}
        {android-source.arg "" "Verified Android source root"}
        {ios-source.arg "" "Verified iOS source root"}
        {native-shared-source.arg "" "Shared native audio source root"}
    }
    
    array set options [cmdline::getoptions argv $optionspec]
    
    if {$options(output-dir) eq ""} {
        puts stderr "Error: --output-dir is required"
        exit 1
    }
    
    # Set up paths
    set script_path [info script]
    set ROOT [file dirname [file dirname $script_path]]
    set PROJECT_ROOT [file dirname $ROOT]
    
    # Set defaults for optional parameters
    if {$options(android-source) eq ""} {
        set options(android-source) [file join $PROJECT_ROOT "mobile" "android"]
    }
    if {$options(ios-source) eq ""} {
        set options(ios-source) [file join $PROJECT_ROOT "mobile" "ios"]
    }
    if {$options(native-shared-source) eq ""} {
        set options(native-shared-source) [file join $PROJECT_ROOT "mobile" "shared"]
    }
    
    # Resolve paths
    set output_dir [resolve_path $options(output-dir)]
    set android_source [resolve_path $options(android-source)]
    set ios_source [resolve_path $options(ios-source)]
    set native_shared [resolve_path $options(native-shared-source)]
    
    # Create output directory
    file mkdir $output_dir
    
    # Read manifest
    set manifest_path [file join $ROOT "browser-extension" "manifest.json"]
    set manifest [read_json $manifest_path]
    set version [dict get $manifest "version"]
    
    # Define output files
    set extension_zip [file join $output_dir "tiktok-live-companion-extension-$version.zip"]
    set plugin_zip [file join $output_dir "tiktok-live-companion-plugin-$version.zip"]
    set service_zip [file join $output_dir "tiktok-live-companion-service-$version.zip"]
    set ios_source_zip [file join $output_dir "tiktok-live-companion-ios-$version-source.zip"]
    set android_source_zip [file join $output_dir "tiktok-live-companion-android-$version-source.zip"]
    set android_apk [file join $output_dir "tiktok-live-companion-android-$version.apk"]
    set extension_dir [file join $output_dir "tiktok-live-companion-extension-$version"]
    set checksum_file [file join $output_dir "tiktok-live-companion-$version-SHA256.txt"]
    
    # Validate paths
    set resolved_extension_dir [resolve_path $extension_dir]
    if {[parent_path $resolved_extension_dir] ne $output_dir} {
        error "Refusing to package outside the requested output directory"
    }
    
    # Clean and prepare extension directory
    remove_directory $extension_dir
    copy_directory [file join $ROOT "browser-extension"] $extension_dir
    copy_directory [file join $ROOT "companion-service"] [file join $extension_dir "companion-service"]
    
    # Write Windows batch file
    set batch_content "@echo off\r\ncall \"%~dp0companion-service\\\\Sprachdienst-reparieren.cmd\"\\r\n"
    write_text_file [file join $extension_dir "Sprachdienst-reparieren.cmd"] $batch_content
    
    # Write package.json
    set package_json [dict create \
        name "tiktok-live-companion-extension-package" \
        private true \
        version $version \
        scripts [dict create \
            setup "npm --prefix companion-service run setup --" \
            start "npm --prefix companion-service start" \
            test "npm --prefix companion-service test" \
        ] \
    ]
    write_text_file [file join $extension_dir "package.json"] "[json::dict2json $package_json]\n"
    
    # Create extension zip
    set archive [zipfile::encode::create]
    add_tree $archive $extension_dir
    set fd [open $extension_zip w]
    puts -nonewline $fd [$archive write]
    close $fd
    $archive destroy
    
    # Create plugin zip
    set archive [zipfile::encode::create]
    add_tree $archive $ROOT "tiktok-live-companion"
    set fd [open $plugin_zip w]
    puts -nonewline $fd [$archive write]
    close $fd
    $archive destroy
    
    # Create service zip
    set archive [zipfile::encode::create]
    add_tree $archive [file join $ROOT "companion-service"]
    set fd [open $service_zip w]
    puts -nonewline $fd [$archive write]
    close $fd
    $archive destroy
    
    # Validate source directories
    if {![file isdirectory $ios_source] || ![file isdirectory $android_source]} {
        error "--ios-source and --android-source must point to existing source directories"
    }
    
    set limiter_header [file join $native_shared "native" "tlc_peak_limiter.h"]
    if {![file isfile $limiter_header]} {
        error "Shared native limiter source is required for both mobile source packages"
    }
    
    # Create iOS source zip
    set archive [zipfile::encode::create]
    add_tree $archive $ios_source "TikTokLiveCompanion-iOS"
    add_tree $archive $native_shared "shared"
    set fd [open $ios_source_zip w]
    puts -nonewline $fd [$archive write]
    close $fd
    $archive destroy
    
    # Create Android source zip
    set archive [zipfile::encode::create]
    add_tree $archive $android_source "TikTokLiveCompanion-Android"
    add_tree $archive $native_shared "shared"
    set fd [open $android_source_zip w]
    puts -nonewline $fd [$archive write]
    close $fd
    $archive destroy
    
    # Handle Android APK if provided
    if {$options(android-apk) ne ""} {
        set source_apk [resolve_path $options(android-apk)]
        if {![file isfile $source_apk] || [string tolower [file extension $source_apk]] ne ".apk"} {
            error "--android-apk must point to an existing APK"
        }
        if {$source_apk ne [resolve_path $android_apk]} {
            file copy -force $source_apk $android_apk
        }
    }
    
    # Compute checksums
    set artifacts [list $extension_zip $plugin_zip $service_zip $ios_source_zip $android_source_zip]
    if {[file exists $android_apk]} {
        lappend artifacts $android_apk
    }
    
    set checksums {}
    foreach artifact $artifacts {
        set digest [compute_sha256 $artifact]
        lappend checksums "$digest  [file tail $artifact]"
    }
    write_text_file $checksum_file "[join $checksums \n]\n"
    
    # Output results as JSON
    set result_dict [dict create \
        extension_dir [resolve_path $extension_dir] \
        extension_zip [resolve_path $extension_zip] \
        plugin_zip [resolve_path $plugin_zip] \
        service_zip [resolve_path $service_zip] \
        ios_source_zip [resolve_path $ios_source_zip] \
        android_source_zip [resolve_path $android_source_zip] \
        android_apk [expr {[file exists $android_apk] ? [resolve_path $android_apk] : ""}] \
        checksum_file [resolve_path $checksum_file] \
        version $version \
    ]
    
    # Filter out empty android_apk
    if {[dict get $result_dict android_apk] eq ""} {
        dict unset result_dict android_apk
    }
    
    puts [json::dict2json $result_dict]
}

# Run main procedure
if {[info script] eq $argv0} {
    main
}
