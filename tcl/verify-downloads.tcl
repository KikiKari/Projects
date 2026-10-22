#!/usr/bin/env tclsh
# verify-downloads.py — portiert nach tcl
# Quelle: python, Projects@TikTok-Live-Companion:site/scripts/verify-downloads.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/scripts/verify-downloads.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Verify the candidate's actual HTTP downloads against committed files.

package require http
package require sha256
package require json
package require zipfile

# Parse command line arguments
proc getopts {argv} {
    set options [dict create]
    set i 0
    while {$i < [llength $argv]} {
        set arg [lindex $argv $i]
        incr i
        switch -exact -- $arg {
            --base-url {
                if {$i >= [llength $argv]} {
                    error "Option --base-url requires an argument"
                }
                dict set options base_url [lindex $argv $i]
                incr i
            }
            --report {
                if {$i >= [llength $argv]} {
                    error "Option --report requires an argument"
                }
                dict set options report [lindex $argv $i]
                incr i
            }
            default {
                error "Unknown option: $arg"
            }
        }
    }
    # Check required arguments
    if {![dict exists $options base_url] || ![dict exists $options report]} {
        error "Missing required arguments: --base-url and --report are required"
    }
    return $options
}

set opts [getopts $argv]

# Get script directory and root path
set script_dir [file normalize [file dirname [info script]]]
set root [file dirname $script_dir]

# Define checksum file path
set checksum_file [file join $root public downloads tiktok-live-companion-0.8.2-SHA256.txt]

# Initialize results list
set results [list]

# Read checksum file
if {![file exists $checksum_file]} {
    error "Checksum file not found: $checksum_file"
}
set checksum_content [encoding convertfrom utf-8 [read_binary_file $checksum_file]]
set lines [split $checksum_content "\n"]

foreach line [split $checksum_content "\n"] {
    if {$line eq ""} continue
    
    # Parse line: expected_hash  filename
    set parts [split $line "  "]
    if {[llength $parts] != 2} {
        error "Invalid line format in checksum file: $line"
    }
    lassign $parts expected name
    
    # Build URL
    set base_url [string trimright [dict get $opts base_url] "/"]
    set url ${base_url}/downloads/$name
    
    # Download file
    set token [http::geturl $url -timeout 30000]
    set data [http::data $token]
    http::cleanup $token
    
    # Calculate SHA256 hash
    set actual [sha256::sha256 -bin $data]
    set actual_hex [binary encode hex $actual]
    
    # Compare with expected hash
    if {$actual_hex ne $expected} {
        error "HTTP artifact hash mismatch: $name"
    }
    
    # Compare with local file
    set local_path [file join $root public downloads $name]
    if {![file exists $local_path]} {
        error "Local file does not exist: $local_path"
    }
    set local_data [read_binary_file $local_path]
    if {$data ne $local_data} {
        error "HTTP artifact content mismatch: $name"
    }
    
    # Test ZIP archive integrity
    set temp_zip [write_temp_file $data]
    if {[catch {zipfile::decode test $temp_zip} error_msg]} {
        file delete $temp_zip
        error "Corrupt archive: $name - $error_msg"
    }
    
    # Special checks for extension archives
    if {[string match "*-extension-*" $name]} {
        # Check manifest.json version
        set manifest_data [zipfile::decode get $temp_zip manifest.json]
        set manifest_dict [json::json2dict $manifest_data]
        if {[dict get $manifest_dict version] ne "0.8.2"} {
            file delete $temp_zip
            error "Wrong extension version"
        }
        
        # Check source files
        set plugin_source_dir [file join [file dirname $root] plugin-source browser-extension]
        foreach source {background.js content.js sidepanel.js sidepanel.html} {
            set source_data [zipfile::decode get $temp_zip $source]
            set expected_source_path [file join $plugin_source_dir $source]
            if {![file exists $expected_source_path]} {
                file delete $temp_zip
                error "Expected source file not found: $expected_source_path"
            }
            set expected_source_data [read_binary_file $expected_source_path]
            if {$source_data ne $expected_source_data} {
                file delete $temp_zip
                error "Extension source mismatch: $source"
            }
        }
    }
    
    # Clean up temporary file
    file delete $temp_zip
    
    # Add to results
    lappend results [dict create name $name sha256 $actual_hex bytes [string length $data] verified true]
}

# Write report
set report_dict [dict create base_url [dict get $opts base_url] artifacts $results]
set report_json [json::dict2json $report_dict 2]
set report_file [dict get $opts report]
set fh [open $report_file w]
fconfigure $fh -encoding utf-8
puts $fh $report_json
close $fh

# Print results
puts [json::dict2json $results 2]

# Helper procedures
proc read_binary_file {filename} {
    set fh [open $filename rb]
    set data [read $fh]
    close $fh
    return $data
}

proc write_temp_file {data} {
    set temp_file [file join [file tempfile] tmp_[pid]_[clock milliseconds]]
    set fh [open $temp_file wb]
    puts -nonewline $fh $data
    close $fh
    return $temp_file
}
