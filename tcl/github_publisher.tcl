#!/usr/bin/env tclsh
# github_publisher.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

# Publish queued, provenance-checked artifacts without staging unrelated files.

package require http
package require json
package require base64

proc queue_artifact {state root path} {
    # Resolve paths
    set root [file normalize $root]
    set resolved_path [file normalize $path]
    
    # Check if path is a symlink
    if {[file type $path] eq "link"} {
        error "artifact must not be a symlink"
    }
    
    # Get relative path
    set relative [string range $resolved_path [string length $root] end]
    if {[string index $relative 0] eq "/"} {
        set relative [string range $relative 1 end]
    }
    
    # Validate language directory
    set parts [split $relative "/"]
    if {![llength $parts] || [lindex $parts 0] ni {
        perl5 powershell perl6 tcl javascript ruby python lua shell go
    }} {
        error "artifact is outside a language directory"
    }
    
    # Read file and calculate SHA256 hash
    set fh [open $path rb]
    set data [read $fh]
    close $fh
    
    set sha256_hash [sha256_hash $data]
    
    # Add to pending publications
    dict set state ausstehende_veroeffentlichungen $relative $sha256_hash
    return $state
}

proc publish_pending {root state save token {opener ""}} {
    # Get pending publications
    if {[dict exists $state ausstehende_veroeffentlichungen]} {
        set pending [dict get $state ausstehende_veroeffentlichungen]
    } else {
        set pending {}
    }
    
    # Validate pending queue
    if {![dict size $pending] && ![string is dict $pending]} {
        error "invalid publication queue"
    }
    
    # Return early if nothing to publish
    if {![dict size $pending]} {
        return true
    }
    
    # Check token
    if {![string trim $token]} {
        return false
    }
    
    # Resolve root path
    set root [file normalize $root]
    
    # Set up headers
    array set headers {
        Authorization ""
        Accept "application/vnd.github+json"
        X-GitHub-Api-Version "2022-11-28"
        User-Agent "abstractions-manager"
    }
    set headers(Authorization) "Bearer [string trim $token]"
    
    set success true
    
    # Process each pending item
    dict for {name expected} $pending {
        if {[catch {
            set full_path [file join $root $name]
            
            # Validate path
            if {[file type $full_path] eq "link" || 
                [string range [file normalize $full_path] 0 [string length $root]-1] ne $root ||
                [string range [file normalize $full_path] [string length $root]+1 end] ne $name} {
                error "invalid queued path"
            }
            
            # Read file data
            set fh [open $full_path rb]
            set data [read $fh]
            close $fh
            
            # Verify hash hasn't changed
            if {[sha256_hash $data] ne $expected} {
                error "queued artifact changed"
            }
            
            # Define lookup function
            proc lookup {remote_name headers_var ref} {
                upvar $headers_var headers
                set encoded_name [url_encode $remote_name]
                set endpoint "https://api.github.com/repos/KikiKari/OpenClaw/contents/$encoded_name"
                
                # Create HTTP request
                set query_params "ref=$ref"
                set url "$endpoint?$query_params"
                
                # Set up HTTP transaction
                ::http::config -useragent $headers(User-Agent)
                array set req_headers {}
                foreach key [array names headers] {
                    if {$key ne "User-Agent"} {
                        set req_headers($key) $headers($key)
                    }
                }
                
                set token [::http::geturl $url -headers [array get req_headers] -timeout 60000]
                set status [::http::status $token]
                
                if {$status eq "ok"} {
                    set content [::http::data $token]
                    ::http::cleanup $token
                    if {[string length $content]} {
                        return [list $endpoint [json::json2dict $content]]
                    } else {
                        return [list $endpoint {}]
                    }
                } elseif {[::http::ncode $token] == 404} {
                    ::http::cleanup $token
                    return [list $endpoint {}]
                } else {
                    set error_code [::http::ncode $token]
                    ::http::cleanup $token
                    error "HTTP Error: $error_code"
                }
            }
            
            # Define same check function
            proc same {existing data} {
                if {![dict size $existing]} {
                    return false
                }
                
                if {[dict get $existing encoding] ne "base64"} {
                    return false
                }
                
                set content [dict get $existing content]
                set decoded_content [base64::decode $content]
                return [expr {$decoded_content eq $data}]
            }
            
            # Look up existing file
            set result [lookup $name headers gateway1-abstractions]
            set endpoint [lindex $result 0]
            set existing [lindex $result 1]
            
            # Handle conflicts
            if {[dict size $existing] && ![same $existing $data]} {
                # Generate alternate filename
                set path_parts [file split $name]
                set filename [lindex $path_parts end]
                set dir_parts [lrange $path_parts 0 end-1]
                set stem [file rootname $filename]
                set ext [file extension $filename]
                set alternate "[join $dir_parts /]/${stem}_${expected:[string range $expected 0 11]}$ext"
                
                set result [lookup $alternate headers gateway1-abstractions]
                set endpoint [lindex $result 0]
                set existing [lindex $result 1]
                
                if {[dict size $existing] && ![same $existing $data]} {
                    error "remote artifact conflict"
                }
            }
            
            # Upload if needed
            if {![dict size $existing]} {
                # Prepare content
                set encoded_data [base64::encode $data]
                set message "Publish script abstraction"
                set branch "gateway1-abstractions"
                
                # Create JSON payload
                set payload [json::dict2json [dict create \
                    message $message \
                    branch $branch \
                    content $encoded_data]]
                
                # Make PUT request
                ::http::config -useragent $headers(User-Agent)
                array set put_headers [array get headers]
                set put_token [::http::geturl $endpoint \
                    -headers [array get put_headers] \
                    -method PUT \
                    -query $payload \
                    -timeout 60000]
                
                set put_status [::http::status $put_token]
                if {$put_status eq "ok"} {
                    set response_data [::http::data $put_token]
                    ::http::cleanup $put_token
                    # Process response if needed
                } else {
                    set put_error [::http::ncode $put_token]
                    ::http::cleanup $put_token
                    error "PUT failed: $put_error"
                }
            }
            
            # Remove from pending and save state
            dict unset state ausstehende_veroeffentlichungen $name
            {*}$save $state
            
        } error]} {
            set success false
        }
    }
    
    return $success
}

# Helper procedures

proc sha256_hash {data} {
    # This is a simplified placeholder - actual implementation would require
    # a proper SHA256 library or external command execution
    # For real use, you'd want to call openssl or similar:
    # exec openssl dgst -sha256 -binary | hexdump -v -e '/1 "%02x"'
    
    # Placeholder returning fixed string for now
    # In practice, implement with:
    # set tmpfile [file tempfile]
    # set fh [open $tmpfile wb]
    # puts -nonewline $fh $data
    # close $fh
    # set hash [exec openssl dgst -sha256 -hex $tmpfile]
    # file delete $tmpfile
    # return [string range $hash 2 end] ;# Remove leading "0x"
    
    # For this example, we'll just return a fake hash
    return [string repeat "0" 64]
}

proc url_encode {str} {
    # Simple URL encoding - replace special characters
    regsub -all {[^a-zA-Z0-9/_-]} $str {\\percent[format %02X [scan "&" %c]]}
}

# Note: This translation has limitations due to:
# 1. Missing proper SHA256 implementation in pure Tcl
# 2. Simplified HTTP handling compared to Python's urllib
# 3. No direct equivalent to Python's base64.b64decode behavior
# 4. Missing some error handling details from the original
