#!/usr/bin/env tclsh
# abstractions_manager.sh — portiert nach tcl
# Quelle: shell, Projects@abstractions:shell/abstractions_manager.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach Tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require json
package require fileutil

# Konfiguration
set WORKSPACE "/home/openclaw/.openclaw/workspace"
set ABSTRACTIONS_REPO "$WORKSPACE/git/Abstraktionen"
set LOG_DIR "$WORKSPACE/logs/abstractions-manager"
set STATE_FILE "$WORKSPACE/db/abstractions_state.json"

# Node-Konfiguration mit Prioritäten
array set NODES {
  node1 "always_available:true,capacity:medium,priority:2"
  node2 "always_available:true,capacity:medium,priority:3"
  node3 "always_available:false,capacity:medium,priority:4"
  node5 "always_available:false,capacity:low,priority:5,device:Redmi Note 11S,condition:mobile_internet"
  node7 "always_available:true,capacity:high,priority:1"
}

# Verfügbare Modelle
set AVAILABLE_MODELS {
  "openrouter/moonshotai/kimi-k2.5"
  "openrouter/openai/gpt-4o"
  "openrouter/anthropic/claude-3-5-sonnet-20241022"
  "openrouter/google/gemini-2.0-flash-001"
  "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1"
  "openrouter/qwen/qwen-2.5-coder-32b-instruct"
}

# Zielsprachen-Konfiguration
array set TARGET_LANGUAGES {
  perl5 "ext:.pl,shebang:#!/usr/bin/env perl,header:use strict;\nuse warnings;\n"
  perl6 "ext:.raku,shebang:#!/usr/bin/env raku,header:use v6;\n"
  javascript "ext:.js,shebang:#!/usr/bin/env node,header:"
  python "ext:.py,shebang:#!/usr/bin/env python3,header:"
  shell "ext:.sh,shebang:#!/bin/bash,header:set -euo pipefail\n"
  powershell "ext:.ps1,shebang:#!/usr/bin/env pwsh,header:#Requires -Version 7\n"
  tcl "ext:.tcl,shebang:#!/usr/bin/env tclsh,header:package require Tcl 8.6\n"
  ruby "ext:.rb,shebang:#!/usr/bin/env ruby,header:require 'json'\nrequire 'fileutils'\n"
  lua "ext:.lua,shebang:#!/usr/bin/env lua,header:"
  go "ext:.go,shebang:// +build ignore,header:package main\n"
}

proc log {message {level INFO}} {
  global LOG_DIR
  file mkdir $LOG_DIR
  set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set line "\[$timestamp\] \[$level\] $message"
  puts $line
  set log_file "$LOG_DIR/[clock format [clock seconds] -format "%Y-%m-%d"].log"
  set fp [open $log_file a]
  puts $fp $line
  close $fp
}

proc get_node_by_priority {{job_weight medium}} {
  global NODES
  
  # Prioritäts-Matrix
  if {$job_weight eq "heavy"} {
    # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
    set preferred_order [list node7 node2 node1]
  } elseif {$job_weight eq "medium"} {
    # Mittlere Jobs → Stable Nodes
    set preferred_order [list node2 node1 node7]
  } else {  # light
    # Leichte Jobs → Mobile/verfügbare Nodes
    set preferred_order [list node5 node1 node2]
  }
  
  # Prüfe Verfügbarkeit
  foreach node_id $preferred_order {
    if {![info exists NODES($node_id)]} {
      continue
    }
    
    set node_config $NODES($node_id)
    set always_available [lindex [split [lsearch -inline [split $node_config ,] "always_available:*"] :] 1]
    
    # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
    if {$always_available ne "true" && $job_weight ne "light"} {
      continue
    }
    
    # Prüfe ob Node online
    if {[check_node_status $node_id]} {
      return $node_id
    }
  }
  
  # Fallback zu Node 1
  return "node1"
}

proc check_node_status {node_id} {
  global NODES
  if {[catch {exec which openclaw}]} {
    # openclaw nicht gefunden
    if {[info exists NODES($node_id)]} {
      set node_config $NODES($node_id)
      set always_available [lindex [split [lsearch -inline [split $node_config ,] "always_available:*"] :] 1]
      return [expr {$always_available eq "true"}]
    } else {
      return 0
    }
  } else {
    if {[catch {exec timeout 5 openclaw nodes status $node_id} result]} {
      # Bei Timeout/Error: Prüfe letzten bekannten Status
      if {[info exists NODES($node_id)]} {
        set node_config $NODES($node_id)
        set always_available [lindex [split [lsearch -inline [split $node_config ,] "always_available:*"] :] 1]
        return [expr {$always_available eq "true"}]
      } else {
        return 0
      }
    } else {
      return [regexp -nocase {(online|active)} $result]
    }
  }
}

proc get_job_weight {script_size target_langs_count} {
  set total_work [expr {$script_size * $target_langs_count}]
  
  if {$total_work > 50000} {  # Große Scripts, viele Sprachen
    return "heavy"
  } elseif {$total_work > 10000} {  # Mittlere Last
    return "medium"
  } else {
    return "light"
  }
}

proc load_state {} {
  global STATE_FILE
  if {[file exists $STATE_FILE]} {
    set fp [open $STATE_FILE r]
    set content [read $fp]
    close $fp
    return $content
  } else {
    return {
  "processed": {},
  "queue": [],
  "current_priority": "high",
  "stats": {
    "total_scripts": 0,
    "abstractions_created": 0
  }
}
  }
}

proc save_state {state} {
  global STATE_FILE
  file mkdir [file dirname $STATE_FILE]
  set fp [open $STATE_FILE w]
  puts $fp $state
  close $fp
}

proc find_scripts_in_dir {directory {exclude_patterns {node_modules .git __pycache__ dist build}}} {
  set scripts {}
  if {[file isdirectory $directory]} {
    set files [glob -nocomplain -dir $directory -types f *]
    foreach file $files {
      set exclude false
      foreach pattern $exclude_patterns {
        if {[string match "*$pattern*" $file]} {
          set exclude true
          break
        }
      }
      if {!$exclude} {
        lappend scripts $file
      }
    }
  }
  return $scripts
}

proc create_abstraction {script_path target_lang} {
  global ABSTRACTIONS_REPO TARGET_LANGUAGES
  
  if {![file exists $script_path]} {
    log "Script not found: $script_path" ERROR
    return 1
  }
  
  set original_content [read [open $script_path r]]
  
  set ext [file extension $script_path]
  set source_lang ""
  switch -exact -- $ext {
    .py { set source_lang "Python" }
    .js { set source_lang "JavaScript" }
    .sh { set source_lang "Shell" }
    .pl { set source_lang "Perl" }
    .rb { set source_lang "Ruby" }
    default { set source_lang [string trimleft $ext .] }
  }
  
  set target_dir "$ABSTRACTIONS_REPO/$target_lang"
  file mkdir $target_dir
  
  set ext_info [split $TARGET_LANGUAGES($target_lang) ,]
  set ext_val [lindex [split [lsearch -inline $ext_info "ext:*"] :] 1]
  set target_file "$target_dir/[file rootname [file tail $script_path]]$ext_val"
  
  if {[file exists $target_file]} {
    return 1
  }
  
  set shebang [lindex [split [lsearch -inline $ext_info "shebang:*"] :] 1]
  set header [lindex [split [lsearch -inline $ext_info "header:*"] :] 1]
  
  set lines ""
  set line_count 0
  foreach line [split $original_content \n] {
    if {$line_count >= 15} break
    append lines "# $line\n"
    incr line_count
  }
  
  set content "#!/bin/bash\n"
  append content "# [file rootname [file tail $script_path]] - [string totitle $target_lang] Version\n"
  append content "# Portiert von $source_lang\n"
  append content "# Original: $script_path\n"
  append content "# Erstellt: [clock format [clock seconds] -format "%Y-%m-%d"]\n"
  append content "#\n"
  append content "# $header\n"
  append content "# Original-Code-Referenz:\n"
  append content "# $lines\n"
  append content "# TODO: Implementiere $source_lang Funktionalität in [string totitle $target_lang]\n"
  append content "# exit 1\n"
  
  set fp [open $target_file w]
  puts -nonewline $fp $content
  close $fp
  log "Created: $target_file"
  return 0
}

proc process_on_node {node_id scripts target_langs} {
  set created 0
  
  if {$node_id eq "node1"} {
    # Lokale Verarbeitung
    foreach script $scripts {
      foreach lang $target_langs {
        if {[create_abstraction $script $lang] == 0} {
          incr created
        }
      }
    }
  } else {
    # Remote-Verarbeitung
    log "Dispatching [llength $scripts] jobs to $node_id"
    # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
    # Für jetzt: Lokale Verarbeitung mit Node-Logging
    foreach script $scripts {
      foreach lang $target_langs {
        if {[create_abstraction $script $lang] == 0} {
          incr created
          log "Processed on $node_id: [file tail $script] -> $lang"
        }
      }
    }
  }
  
  return $created
}

proc process_priority_high {} {
  global WORKSPACE
  set created 0
  set targets [list \
    "skill-creator:$WORKSPACE/skills/skill-creator/scripts" \
    "json-utils:$WORKSPACE/skills/json-utils/scripts" \
    "scripting-utils:$WORKSPACE/skills/scripting-utils/scripts" \
    "model-usage:$WORKSPACE/skills/model-usage/scripts" \
    "tiktok-live:$WORKSPACE/skills/tiktok-live/scripts"]
  
  foreach target $targets {
    set parts [split $target :]
    set skill_name [lindex $parts 0]
    set scripts_dir [lindex $parts 1]
    
    set scripts [find_scripts_in_dir $scripts_dir [list node_modules .git test tests]]
    
    log "$skill_name: [llength $scripts] scripts found"
    
    set count 0
    foreach script $scripts {
      if {$count >= 10} {
        break
      }
      
      set script_size 0
      if {[file exists $script]} {
        set script_size [file size $script]
      }
      
      set target_langs [list perl5 javascript python shell tcl]
      set job_weight [get_job_weight $script_size [llength $target_langs]]
      
      # Wähle Node basierend auf Job-Gewicht
      set selected_node [get_node_by_priority $job_weight]
      log "Processing [file tail $script] ($job_weight) on $selected_node"
      
      set result [process_on_node $selected_node [list $script] $target_langs]
      incr created $result
      incr count
    }
  }
  
  return $created
}

proc process_priority_medium {} {
  global WORKSPACE
  set created 0
  set targets [list \
    "workspace-scripts:$WORKSPACE/scripts" \
    "db-maintainer:$WORKSPACE/skills/db-maintainer/scripts" \
    "log-collector:$WORKSPACE/skills/log-collector/scripts"]
  
  foreach target $targets {
    set parts [split $target :]
    set dir_name [lindex $parts 0]
    set scripts_dir [lindex $parts 1]
    
    set scripts [find_scripts_in_dir $scripts_dir [list node_modules .git]]
    
    set count 0
    foreach script $scripts {
      if {$count >= 10} {
        break
      }
      
      set script_size 0
      if {[file exists $script]} {
        set script_size [file size $script]
      }
      
      set target_langs [list perl5 javascript powershell python]
      set job_weight [get_job_weight $script_size [llength $target_langs]]
      
      # Mittlere Priority → eher leichtere Jobs
      set adjusted_weight $job_weight
      if {$job_weight eq "heavy"} {
        set adjusted_weight "medium"
      }
      set selected_node [get_node_by_priority $adjusted_weight]
      log "Processing [file tail $script] ($job_weight) on $selected_node"
      
      set result [process_on_node $selected_node [list $script] $target_langs]
      incr created $result
      incr count
    }
  }
  
  return $created
}

proc git_commit {message} {
  global ABSTRACTIONS_REPO
  if {[file isdirectory $ABSTRACTIONS_REPO]} {
    if {![catch {exec git --git-dir=$ABSTRACTIONS_REPO/.git --work-tree=$ABSTRACTIONS_REPO add .}]} {
      if {![catch {exec git --git-dir=$ABSTRACTIONS_REPO/.git --work-tree=$ABSTRACTIONS_REPO commit -m $message}]} {
        log "Git commit: $message"
      }
    }
  }
}

proc create_status_report {state} {
  global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS
  set report_file "$ABSTRACTIONS_REPO/STATUS.md"
  
  set lang_counts {}
  if {[file isdirectory $ABSTRACTIONS_REPO]} {
    foreach lang_dir [glob -nocomplain -dir $ABSTRACTIONS_REPO *] {
      if {[file isdirectory $lang_dir]} {
        set lang_name [file tail $lang_dir]
        if {[info exists TARGET_LANGUAGES($lang_name)]} {
          set count 0
          foreach file [glob -nocomplain -dir $lang_dir *] {
            if {[file isfile $file]} {
              incr count
            }
          }
          lappend lang_counts "$lang_name:$count"
        }
      }
    }
  }
  
  set fp [open $report_file w]
  puts $fp "# Script Abstractions - Status Report"
  puts $fp ""
  puts $fp "**Letzte Aktualisierung:** [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]"
  puts $fp ""
  puts $fp "- Aktuelle Priorität: [dict get $state current_priority]"
  puts $fp "- Verarbeitete Scripts: [dict size [dict get $state processed]]"
  puts $fp "- Abstraktionen gesamt: [dict get $state stats abstractions_created]"
  puts $fp ""
  puts $fp "## Abstraktionen pro Sprache"
  puts $fp ""
  
  foreach lang_count $lang_counts {
    set parts [split $lang_count :]
    set lang [lindex $parts 0]
    set count [lindex $parts 1]
    puts $fp "- $lang: $count"
  }
  
  puts $fp ""
  puts $fp "## Verfügbare Modelle"
  puts $fp ""
  
  set i 0
  foreach model $AVAILABLE_MODELS {
    if {$i < 3} {
      puts $fp "- `$model`"
    }
    incr i
  }
  puts $fp "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere"
  
  puts $fp ""
  puts $fp "## Multi-Node Support"
  puts $fp ""
  puts $fp "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |"
  puts $fp "|------|---------------|-----------|-----------|-------|"
  
  global NODES
  foreach node_id [array names NODES] {
    set node_config $NODES($node_id)
    set always_available [lindex [split [lsearch -inline [split $node_config ,] "always_available:*"] :] 1]
    set capacity [lindex [split [lsearch -inline [split $node_config ,] "capacity:*"] :] 1]
    set priority [lindex [split [lsearch -inline [split $node_config ,] "priority:*"] :] 1]
    set device [lindex [split [lsearch -inline [split $node_config ,] "device:*"] :] 1]
    if {$device eq ""} {
      set device "Server"
    }
    
    set avail "✅ Immer"
    if {$always_available ne "true"} {
      set avail "📱 Bedingt"
    }
    
    puts $fp "| $node_id | $avail | $capacity | $priority | $device |"
  }
  
  puts $fp ""
  puts $fp "### Job-Verteilung"
  puts $fp ""
  puts $fp "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)"
  puts $fp "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)"
  puts $fp "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)"
  
  close $fp
}

proc main {} {
  log "Script Abstractions Manager (Multi-Node) gestartet"
  
  set state [load_state]
  set processed_count [dict size [dict get $state processed]]
  log "State loaded: $processed_count processed"
  
  set current_priority [dict get $state current_priority]
  set created 0
  
  if {$current_priority eq "high"} {
    log "Processing HIGH priority: Top 5 Skills"
    set created [process_priority_high]
    if {$created > 0} {
      git_commit "High priority: $created abstractions"
    }
    dict set state current_priority "medium"
  } elseif {$current_priority eq "medium"} {
    log "Processing MEDIUM priority: Workspace Scripts"
    set created [process_priority_medium]
    if {$created > 0} {
      git_commit "Medium priority: $created abstractions"
    }
    dict set state current_priority "high"  # Zyklus
  }
  
  set abstractions_count 0
  global TARGET_LANGUAGES ABSTRACTIONS_REPO
  foreach lang [array names TARGET_LANGUAGES] {
    if {[file isdirectory "$ABSTRACTIONS_REPO/$lang"]} {
      set count 0
      foreach file [glob -nocomplain -dir "$ABSTRACTIONS_REPO/$lang" *] {
        if {[file isfile $file]} {
          incr count
        }
      }
      incr abstractions_count $count
    }
  }
  
  dict set state stats last_run [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%S"]
  dict set state stats abstractions_created $abstractions_count
  save_state $state
  create_status_report $state
  
  log "Abgeschlossen. $created neue Abstraktionen erstellt."
}

main
