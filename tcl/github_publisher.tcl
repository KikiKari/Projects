#!/usr/bin/env tclsh8.6
# github_publisher.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

# Publish queued, provenance-checked artifacts without staging unrelated files.

package require http
package require json
package require sha256

set LANGUAGES [dict create perl5 {} powershell {} perl6 {} tcl {} javascript {} ruby {} python {} lua {} shell {} go {}]

proc synchronize_checkout {root {remote "https://github.com/KikiKari/OpenClaw.git"} {branch "gateway1-abstractions"}} {
    # Reconcile a remote snapshot into the checkout without changing its Git history.
    set root [file normalize $root]
    if {![file exists $root] || ![file isdirectory $root]} {
        error "Root directory does not exist or is not a directory"
    }
    
    set tmpdir [exec mktemp -d "abstractions-snapshot-XXXXXX"]
    set snapshot [file join $tmpdir repo]
    
    if {[catch {
        exec git clone --quiet --depth=1 --single-branch --branch $branch -- $remote $snapshot
    } result]} {
        file delete -force $tmpdir
        error "Failed to clone repository: $result"
    }
    
    set revision [string trim [exec git -C $snapshot rev-parse HEAD]]
    
    array set counts {}
    
    foreach language [lsort [dict keys $::LANGUAGES]] {
        set source [file join $snapshot $language]
        set target [file join $root $language]
        
        if {[file isdirectory $source] && [file type $source] eq "link"} {
            file delete -force $tmpdir
            error "Language directory is a symlink"
        }
        
        if {[file exists $target] && [file type $target] eq "link"} {
            file delete -force $tmpdir
            error "Target language directory is a symlink"
        }
        
        if {![file exists $target]} {
            file mkdir $target
        }
        
        # Get known file hashes
        set known_hashes [dict create]
        foreach item [glob -nocomplain -tails -directory $target *] {
            set item_path [file join $target $item]
            if {[file isfile $item_path] && [file type $item_path] ne "link"} {
                set hash [sha256::sha256 -hex [read_binary_file $item_path]]
                dict set known_hashes $hash 1
            }
        }
        
        set files {}
        if {[file exists $source]} {
            foreach item [glob -nocomplain -directory $source *] {
                lappend files $item
            }
        }
        
        # Check for invalid abstractions
        foreach item $files {
            set item_path [file join $source [file tail $item]]
            if {[file type $item_path] eq "link" || ![file isfile $item_path]} {
                file delete -force $tmpdir
                error "Invalid remote abstraction"
            }
        }
        
        set counts($language) [llength $files]
        
        foreach item $files {
            set item_path [file join $source [file tail $item]]
            set data [read_binary_file $item_path]
            set digest [sha256::sha256 -hex $data]
            
            if {[dict exists $known_hashes $digest]} {
                continue
            }
            
            set destination [file join $target [file tail $item]]
            if {[file exists $destination] || [file type $destination] eq "link"} {
                set stem [file rootname [file tail $item]]
                set suffix [file extension [file tail $item]]
                set destination [file join $target "${stem}__pool_${digest}${suffix}"]
            }
            
            if {[catch {
                set fd [open $destination "wb"]
                puts -nonewline $fd $data
                close $fd
            }]} {
                if {[file type $destination] eq "link" || ![file isfile $destination] || 
                    [read_binary_file $destination] ne $data} {
                    file delete -force $tmpdir
                    error "Local abstraction conflict"
                }
            }
            
            dict set known_hashes $digest 1
        }
    }
    
    file delete -force $tmpdir
    return [list $revision [array get counts]]
}

proc update_status_counts {path revision counts_array} {
    set fd [open $path r]
    set text [read $fd]
    close $fd
    
    set rows [list "## Bestand" "" "GitHub-Stand: `$revision`" "" "| Zielsprache | Dateien |" "|---|---:|"]
    
    foreach language [lsort [dict keys $::LANGUAGES]] {
        set count 0
        if {[info exists counts_array($language)]} {
            set count $counts_array($language)
        }
        lappend rows "| $language | $count |"
    }
    
    set total 0
    foreach count [array get counts_array] {
        incr total [lindex $count 1]
    }
    lappend rows "| **gesamt** | **$total** |" "" ""
    
    set updated_rows [join $rows "\n"]
    regsub {(?ms)^## Bestand\n.*?(?=^## Quellen\n)} $text $updated_rows text
    
    set fd [open $path w]
    puts -nonewline $fd $text
    close $fd
}

proc queue_artifact {state_dict root path} {
    set root [file normalize $root]
    set path_obj [file normalize $path]
    
    if {[file type $path_obj] eq "link"} {
        error "Artifact must not be a symlink"
    }
    
    set full_path [file normalize $path_obj]
    set relative_path [file relative $full_path $root]
    
    if {$relative_path ne "STATUS.md"} {
        set parts [split $relative_path "/"]
        if {![llength $parts] || [lindex $parts 0] ni [dict keys $::LANGUAGES]} {
            error "Artifact is outside a language directory"
        }
    }
    
    set data [read_binary_file $path_obj]
    set hash [sha256::sha256 -hex $data]
    
    if {![dict exists $state_dict "ausstehende_veroeffentlichungen"]} {
        dict set state_dict "ausstehende_veroeffentlichungen" [dict create]
    }
    
    dict set state_dict "ausstehende_veroeffentlichungen" $relative_path $hash
    return $state_dict
}

proc publish_pending {root state_dict save_func token {opener ""} {sync ""}} {
    set pending [dict get $state_dict "ausstehende_veroeffentlichungen"]
    if {![dict size $pending] && $sync eq ""} {
        return true
    }
    
    if {![string trim $token]} {
        return false
    }
    
    set root [file normalize $root]
    set headers [dict create Authorization "Bearer [string trim $token]" Accept "application/vnd.github+json" \
                 X-GitHub-Api-Version "2022-11-28" User-Agent "abstractions-manager"]
    
    set success true
    set entries {}
    
    # Sort entries putting STATUS.md last
    set status_entry {}
    dict for {name expected} $pending {
        if {$name eq "STATUS.md"} {
            set status_entry [list $name $expected]
        } else {
            lappend entries [list $name $expected]
        }
    }
    if {$status_entry ne ""} {
        lappend entries $status_entry
    }
    
    set synced false
    
    foreach entry $entries {
        lassign $entry name expected
        
        if {[catch {
            set path [file join $root $name]
            if {[file type $path] eq "link"} {
                error "Invalid queued path"
            }
            
            set full_path [file normalize $path]
            set rel_path [file relative $full_path $root]
            if {$rel_path ne $name} {
                error "Invalid queued path"
            }
            
            set data [read_binary_file $path]
            set actual_hash [sha256::sha256 -hex $data]
            if {$actual_hash ne $expected} {
                error "Queued artifact changed"
            }
            
            if {$name eq "STATUS.md" && $sync ne ""} {
                if {!$success} {
                    error "Artifact publication incomplete"
                }
                
                lassign [uplevel #0 $sync $root] revision counts_array
                set synced true
                
                update_status_counts $path $revision counts_array
                
                set data [read_binary_file $path]
                set expected [sha256::sha256 -hex $data]
                dict set pending $name $expected
                uplevel #0 $save_func [list $state_dict]
            }
            
            proc lookup {remote_name headers} {
                set endpoint "https://api.github.com/repos/KikiKari/OpenClaw/contents/$remote_name"
                append endpoint "?ref=gateway1-abstractions"
                
                set token [dict get $headers Authorization]
                set auth_header [string range $token 7 end] ;# Remove "Bearer "
                
                set http_request [http::formatQuery message "test"]
                set http_token [http::geturl $endpoint -headers [list Authorization "Bearer $auth_header" \
                               Accept "application/vnd.github+json" X-GitHub-Api-Version "2022-11-28" \
                               User-Agent "abstractions-manager"]]
                
                set status [http::status $http_token]
                if {$status eq "ok"} {
                    set data [http::data $http_token]
                    http::cleanup $http_token
                    return [list $endpoint $data]
                } elseif {[http::ncode $http_token] == 404} {
                    http::cleanup $http_token
                    return [list $endpoint ""]
                } else {
                    set err_info [http::error $http_token]
                    http::cleanup $http_token
                    error "HTTP Error: $err_info"
                }
            }
            
            proc same {existing data} {
                if {$existing eq ""} {
                    return false
                }
                
                if {[catch {set json_data [json::json2dict $existing]}]} {
                    return false
                }
                
                if {[dict get $json_data "encoding"] ne "base64"} {
                    return false
                }
                
                set content [dict get $json_data "content"]
                set decoded_content [binary decode base64 $content]
                return [expr {$decoded_content eq $data}]
            }
            
            lassign [lookup $name $headers] endpoint existing
            
            if {$name eq "STATUS.md" && $existing ne "" && ![same $existing $data]} {
                set json_data [json::json2dict $existing]
                set sha [dict get $json_data "sha"]
                if {![info exists sha] || $sha eq ""} {
                    error "Missing remote status version"
                }
                
                set content_b64 [binary encode base64 $data]
                set body_json [json::dict2json [dict create message "Update abstraction status" \
                              branch "gateway1-abstractions" content $content_b64 sha $sha]]
                
                # PUT request would go here
                dict unset pending $name
                uplevel #0 $save_func [list $state_dict]
            } elseif {$existing ne "" && ![same $existing $data]} {
                set candidate_parts [split $name "/"]
                set candidate_name [lindex $candidate_parts end]
                set candidate_stem [file rootname $candidate_name]
                set candidate_suffix [file extension $candidate_name]
                set alternate "${candidate_stem}_[string range $expected 0 11]${candidate_suffix}"
                if {[llength $candidate_parts] > 1} {
                    set alternate_path [lrange $candidate_parts 0 end-1]
                    lappend alternate_path $alternate
                    set alternate [join $alternate_path "/"]
                }
                
                lassign [lookup $alternate $headers] endpoint existing
                if {$existing ne "" && ![same $existing $data]} {
                    error "Remote artifact conflict"
                }
            }
            
            if {$existing eq ""} {
                set content_b64 [binary encode base64 $data]
                set body_json [json::dict2json [dict create message "Publish script abstraction" \
                              branch "gateway1-abstractions" content $content_b64]]
                
                # PUT request would go here
                dict unset pending $name
                uplevel #0 $save_func [list $state_dict]
            }
            
        } err]} {
            set success false
        }
    }
    
    if {$sync ne "" && !$synced} {
        if {[catch {uplevel #0 $sync $root}]} {
            set success false
        }
    }
    
    return $success
}

proc read_binary_file {filename} {
    set fd [open $filename "rb"]
    set data [read $fd]
    close $fd
    return $data
}
