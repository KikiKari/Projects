#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "e1ba23d0c23b3310b7d8ee4b5d0b7c403785541d764306aafe9d3c449c16a141", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "tcl"}
# git_source_inventory.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 port of git_source_inventory.py
# Git tree inventory and batched selected-blob loading.

package require Tcl 8.6
package require fileutil
package require sha256

namespace eval git_source_inventory {
    # Write private file with restricted permissions
    proc write_private {path data} {
        set fd [open $path w]
        fconfigure $fd -permissions 0600
        puts -nonewline $fd $data
        close $fd
    }
    
    # Create snapshot of repositories and branches
    proc snapshot {manager run_id run_attempt workflow_sha} {
        set repositories [dict create]
        
        # Process each source repository
        foreach source [$manager get QUELLEN] {
            set name [$source get repo]
            set mirror [file join [$manager get QUELLEN_DIR] "$name.git"]
            
            # Get all refs with their commits
            set refs_output [exec git -C $mirror for-each-ref --format=%(refname:strip=2)%00%(objectname) refs/heads]
            set refs [split $refs_output \n]
            set selected [list]
            
            foreach line $refs {
                if {$line eq ""} continue
                lassign [split $line \0] branch_bytes commit
                set branch [encoding convertfrom utf-8 $branch_bytes]
                if {[$source get branches] eq "alle" || [lsearch -exact [$source get branches] $branch] != -1} {
                    lappend selected [list $branch $commit]
                }
            }
            
            # Index each branch
            set branches_dict [dict create]
            foreach item $selected {
                lassign $item branch commit
                set paths_list [list]
                
                set ls_tree_output [exec git -C $mirror ls-tree -r -z --full-tree $commit]
                set entries [split $ls_tree_output \0]
                
                foreach entry $entries {
                    if {$entry eq ""} continue
                    lassign [split $entry \t] meta path_raw
                    set path [encoding convertfrom utf-8 $path_raw]
                    set meta_parts [split $meta " "]
                    
                    if {[lindex $meta_parts 1] eq "blob"} {
                        set suffix [string tolower [file extension $path]]
                        if {[dict exists [$manager get QUELLSPRACHEN] $suffix]} {
                            lappend paths_list $path
                        }
                    }
                }
                
                dict set branches_dict $branch [dict create commit $commit paths $paths_list]
            }
            
            # Validate branches completeness
            if {[dict size $branches_dict] == 0 || \
                ([$source get branches] ne "alle" && \
                 [lsort [dict keys $branches_dict]] ne [lsort [$source get branches]]))} {
                error "incomplete source branches"
            }
            
            dict set repositories $name $branches_dict
        }
        
        return [dict create version 1 run_id $run_id run_attempt $run_attempt \
                workflow_sha $workflow_sha repositories $repositories]
    }
    
    # Prepare git sources and load selected blobs
    proc prepare_git_sources {manager directory state priority count run_id run_attempt workflow_sha} {
        # Update mirrors
        set sources_list [$manager get QUELLEN]
        foreach source $sources_list {
            set repo [$source get repo]
            set mirror [file join [$manager get QUELLEN_DIR] "$repo.git"]
            
            if {[file exists $mirror]} {
                set result [$manager _git remote update --prune -verzeichnis $mirror]
            } else {
                set url "https://github.com/[$manager get GITHUB_BENUTZER]/$repo.git"
                set result [$manager _git clone --mirror --filter=blob:none $url $mirror]
            }
            
            if {[$result get returncode] != 0} {
                error "$repo: Quellspiegel nicht verfuegbar"
            }
        }
        
        # Create snapshot
        set index [snapshot $manager $run_id $run_attempt $workflow_sha]
        set sources [list]
        
        # List branches
        set branches_list [list]
        dict for {repo details} [dict get $index repositories] {
            dict for {branch data} $details {
                lappend branches_list [list $repo $branch [dict get $data commit]]
            }
        }
        
        foreach branch_item $branches_list {
            lassign $branch_item repo branch commit
            set mirror [file join [$manager get QUELLEN_DIR] "$repo.git"]
            
            set ls_tree_output [exec git -C $mirror ls-tree -r -z --full-tree $commit]
            set entries [split $ls_tree_output \0]
            
            foreach entry $entries {
                if {$entry eq ""} continue
                lassign [split $entry \t] metadata_raw raw_path
                set metadata_parts [split $metadata_raw " "]
                set mode [lindex $metadata_parts 0]
                set kind [lindex $metadata_parts 1]
                set oid [lindex $metadata_parts 2]
                
                if {$kind ne "blob" || ($mode ne "100644" && $mode ne "100755")} {
                    continue
                }
                
                set path [encoding convertfrom utf-8 $raw_path]
                set path [string map {\\\\ /} $path]
                set suffix [string tolower [file extension $path]]
                
                if {[dict exists [$manager get QUELLSPRACHEN] $suffix]} {
                    set exclude_match 0
                    foreach pattern [$manager get AUSSCHLUSS] {
                        if {[string first $pattern "/$path"] != -1} {
                            set exclude_match 1
                            break
                        }
                    }
                    
                    if {!$exclude_match && [regexp {^[0-9a-f]{40}$} $oid]} {
                        lappend sources [list $repo $branch $commit $path $suffix $oid]
                    }
                }
            }
        }
        
        # Group sources by blob ID
        set grouped [dict create]
        foreach src $sources {
            lassign $src repo branch commit path language oid
            set origin "$repo@$branch:$path"
            
            if {![dict exists $grouped $oid]} {
                set item [dict create blob $oid repo $repo commit $commit path $path \
                          sprache $language herkunft [list $origin] \
                          prioritaet [$manager _prioritaet $path $language]]
                dict set grouped $oid $item
            } else {
                set item [dict get $grouped $oid]
                set origins [dict get $item herkunft]
                lappend origins $origin
                dict set item herkunft $origins
                dict set grouped $oid $item
            }
        }
        
        # Rank and select candidates
        set rank_dict [dict create high 0 medium 1 low 2]
        set candidates [list]
        
        dict for {oid item} $grouped {
            set item_priority [dict get $item prioritaet]
            if {$priority eq "alle" || $item_priority eq $priority} {
                lappend candidates $item
            }
        }
        
        # Sort candidates
        set candidates [lsort -command compare_candidates $candidates]
        
        # Handle cursor positioning
        set cursor ""
        if {[dict exists $state auswahl_blob_cursor $priority]} {
            set cursor [dict get $state auswahl_blob_cursor $priority]
        }
        
        if {$cursor ne ""} {
            set pos -1
            for {set i 0} {$i < [llength $candidates]} {incr i} {
                set item [lindex $candidates $i]
                if {[dict get $item blob] eq $cursor} {
                    set pos $i
                    break
                }
            }
            
            if {$pos != -1} {
                set candidates [concat [lrange $candidates [expr {$pos + 1}] end] \
                               [lrange $candidates 0 $pos]]
            }
        }
        
        # Select top candidates
        set selected [lrange $candidates 0 [expr {$count - 1}]]
        
        # Group by repository
        set by_repo [dict create]
        foreach item $selected {
            set repo [dict get $item repo]
            if {![dict exists $by_repo $repo]} {
                dict set by_repo $repo [list]
            }
            set items [dict get $by_repo $repo]
            lappend items $item
            dict set by_repo $repo $items
        }
        
        # Read blobs
        set loaded [dict create]
        dict for {repo items} $by_repo {
            set mirror [file join [$manager get QUELLEN_DIR] "$repo.git"]
            set requested ""
            foreach item $items {
                append requested "[dict get $item blob]\n"
            }
            
            set checks_output [exec git -C $mirror cat-file --batch-check=%(objectname) %(objecttype) %(objectsize) << $requested]
            set checks [split $checks_output \n]
            
            if {[llength $checks] != [llength $items]} {
                error "incomplete Git blob metadata"
            }
            
            set eligible [list]
            foreach item $items check_line $checks {
                set fields [split $check_line " "]
                set blob_oid [dict get $item blob]
                
                if {[llength $fields] != 3 || [lindex $fields 0] ne $blob_oid || [lindex $fields 1] ne "blob"} {
                    error "invalid Git blob metadata"
                }
                
                set size [lindex $fields 2]
                if {$size <= [$manager get MAX_BYTES]} {
                    lappend eligible [list $item $size]
                }
            }
            
            if {[llength $eligible] > 0} {
                set wanted ""
                foreach pair $eligible {
                    lassign $pair item _
                    append wanted "[dict get $item blob]\n"
                }
                
                set output_data [exec git -C $mirror cat-file --batch << $wanted]
                set output_lines [split $output_data \n]
                
                set idx 0
                foreach pair $eligible {
                    lassign $pair item expected_size
                    set header [lindex $output_lines $idx]
                    incr idx
                    
                    set header_parts [split $header " "]
                    set blob_oid [dict get $item blob]
                    
                    if {[llength $header_parts] != 3 || [lindex $header_parts 0] ne $blob_oid || \
                        [lindex $header_parts 1] ne "blob" || [lindex $header_parts 2] != $expected_size} {
                        error "invalid Git blob response"
                    }
                    
                    # Extract blob content
                    set raw_content ""
                    for {set j 0} {$j < $expected_size} {incr j} {
                        append raw_content [lindex $output_lines $idx]
                        incr idx
                    }
                    
                    dict set loaded $blob_oid $raw_content
                }
            }
        }
        
        # Create source directory and build inventory
        set source_dir [file join $directory sources]
        file mkdir $source_dir
        file attributes $source_dir -permissions 0700
        
        set inventory [list]
        set last_blob ""
        
        foreach item $selected {
            set blob_oid [dict get $item blob]
            set raw ""
            if {[dict exists $loaded $blob_oid]} {
                set raw [dict get $loaded $blob_oid]
            }
            
            if {$raw ne "" && [string trim $raw] ne "" && ![$manager enthaelt_zugangsdaten $raw]} {
                set digest [sha2::sha256 -hex $raw]
                set target [file join $source_dir $digest]
                
                if {![file exists $target]} {
                    write_private $target $raw
                }
                
                set path [dict get $item path]
                set stem [file rootname [file tail $path]]
                
                lappend inventory [dict create hash [string range $digest 0 15] \
                                   name [file tail $path] stamm $stem \
                                   sprache [dict get $item sprache] bytes [string length $raw] \
                                   pfad $target herkunft [dict get $item herkunft] \
                                   prioritaet [dict get $item prioritaet] css_only false \
                                   source_blob $blob_oid source_repo [dict get $item repo] \
                                   source_commit [dict get $item commit] source_path $path \
                                   source_sha256 $digest]
                set last_blob $blob_oid
            }
        }
        
        return [list $index $inventory $last_blob]
    }
    
    # Comparison function for candidate sorting
    proc compare_candidates {a b} {
        set rank_dict [dict create high 0 medium 1 low 2]
        set rank_a [dict get $a prioritaet]
        set rank_b [dict get $b prioritaet]
        set val_a [dict get $rank_dict $rank_a]
        set val_b [dict get $rank_dict $rank_b]
        
        if {$val_a != $val_b} {
            return [expr {$val_a - $val_b}]
        }
        
        set name_a [file tail [dict get $a path]]
        set name_b [file tail [dict get $b path]]
        return [string compare $name_a $name_b]
    }
}
