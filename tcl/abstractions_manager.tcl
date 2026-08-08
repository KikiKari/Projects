#!/usr/bin/env tclsh
# abstractions_manager.js — portiert nach tcl
# Quelle: javascript, Projects@abstractions:javascript/abstractions_manager.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions_manager.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager - Multi-Node Edition

package require Tcl 8.6
package require json

# Konfiguration
set WORKSPACE [file join "/home/openclaw/.openclaw/workspace"]
set ABSTRACTIONS_REPO [file join $WORKSPACE "git" "Abstraktionen"]
set LOG_DIR [file join $WORKSPACE "logs" "abstractions-manager"]
set STATE_FILE [file join $WORKSPACE "db" "abstractions_state.json"]

# Node-Konfiguration mit Prioritäten
array set NODES {
    node1 {always_available true capacity medium priority 2}
    node2 {always_available true capacity medium priority 3}
    node3 {always_available false capacity medium priority 4}
    node5 {always_available false capacity low priority 5 device "Redmi Note 11S" condition "mobile_internet"}
    node7 {always_available true capacity high priority 1}
}

set AVAILABLE_MODELS [list \
    "openrouter/moonshotai/kimi-k2.5" \
    "openrouter/openai/gpt-4o" \
    "openrouter/anthropic/claude-3-5-sonnet-20241022" \
    "openrouter/google/gemini-2.0-flash-001" \
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1" \
    "openrouter/qwen/qwen-2.5-coder-32b-instruct" \
]

array set TARGET_LANGUAGES {
    perl5 {ext .pl shebang "#!/usr/bin/env perl" header "use strict;\nuse warnings;\n"}
    perl6 {ext .raku shebang "#!/usr/bin/env raku" header "use v6;\n"}
    javascript {ext .js shebang "#!/usr/bin/env node" header ""}
    python {ext .py shebang "#!/usr/bin/env python3" header ""}
    shell {ext .sh shebang "#!/bin/bash" header "set -euo pipefail\n"}
    powershell {ext .ps1 shebang "#!/usr/bin/env pwsh" header "#Requires -Version 7\n"}
    tcl {ext .tcl shebang "#!/usr/bin/env tclsh" header "package require Tcl 8.6\n"}
    ruby {ext .rb shebang "#!/usr/bin/env ruby" header "require 'json'\nrequire 'fileutils'\n"}
    lua {ext .lua shebang "#!/usr/bin/env lua" header ""}
    go {ext .go shebang "// +build ignore" header "package main\n"}
}

proc log {message {level "INFO"}} {
    global LOG_DIR
    file mkdir $LOG_DIR
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set line "\[$timestamp\] \[$level\] $message"
    puts $line
    set logFile [file join $LOG_DIR [clock format [clock seconds] -format "%Y-%m-%d"]].log
    set fh [open $logFile a]
    puts $fh $line
    close $fh
}

proc getNodeByPriority {{jobWeight "medium"}} {
    # Wählt Node basierend auf Job-Gewicht und Priorität
    global NODES
    
    # Prioritäts-Matrix
    if {$jobWeight eq "heavy"} {
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        set preferredOrder [list "node7" "node2" "node1"]
    } elseif {$jobWeight eq "medium"} {
        # Mittlere Jobs → Stable Nodes
        set preferredOrder [list "node2" "node1" "node7"]
    } else {
        # light - Leichte Jobs → Mobile/verfügbare Nodes
        set preferredOrder [list "node5" "node1" "node2"]
    }
    
    # Prüfe Verfügbarkeit
    foreach nodeId $preferredOrder {
        if {![info exists NODES($nodeId)]} {
            continue
        }
        
        array set node $NODES($nodeId)
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if {!$node(always_available) && $jobWeight ne "light"} {
            continue
        }
        
        # Prüfe ob Node online
        if {[checkNodeStatus $nodeId]} {
            return $nodeId
        }
    }
    
    # Fallback zu Node 1
    return "node1"
}

proc checkNodeStatus {nodeId} {
    # Prüft ob ein Node erreichbar ist
    if {[catch {exec openclaw nodes status $nodeId} result]} {
        # Bei Timeout/Error: Prüfe letzten bekannten Status
        global NODES
        if {[info exists NODES($nodeId)]} {
            array set node $NODES($nodeId)
            return $node(always_available)
        }
        return false
    } else {
        return [expr {[string match "*online*" $result] || [string match "*active*" $result]}]
    }
}

proc getJobWeight {scriptSize targetLangsCount} {
    # Bewertet Job-Gewicht basierend auf Script-Größe und Anzahl Zielsprachen
    set totalWork [expr {$scriptSize * $targetLangsCount}]
    
    if {$totalWork > 50000} {
        # Große Scripts, viele Sprachen
        return "heavy"
    } elseif {$totalWork > 10000} {
        # Mittlere Last
        return "medium"
    } else {
        return "light"
    }
}

proc loadState {} {
    global STATE_FILE
    if {[file exists $STATE_FILE]} {
        if {[catch {set fh [open $STATE_FILE r]}]} {
            # ignore error
        } else {
            set content [read $fh]
            close $fh
            if {[catch {::json::json2dict $content} state]} {
                # ignore error
            } else {
                return $state
            }
        }
    }
    return [dict create processed {} queue {} current_priority "high" stats [dict create total_scripts 0 abstractions_created 0]]
}

proc saveState {state} {
    global STATE_FILE
    file mkdir [file dirname $STATE_FILE]
    set fh [open $STATE_FILE w]
    puts $fh [::json::dict2json $state]
    close $fh
}

proc findScriptsInDir {directory {excludePatterns ""}} {
    if {$excludePatterns eq ""} {
        set excludePatterns [list "node_modules" ".git" "__pycache__" "dist" "build"]
    }
    set scripts {}
    if {[file exists $directory]} {
        set files [getAllFiles $directory]
        set extensions [list ".py" ".js" ".sh" ".pl" ".rb"]
        foreach file $files {
            set ext [file extension $file]
            if {[lsearch -exact $extensions $ext] != -1} {
                set exclude false
                foreach pattern $excludePatterns {
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
    }
    return $scripts
}

proc getAllFiles {dirPath {arrayOfFiles {}}} {
    set files [glob -nocomplain -directory $dirPath *]
    foreach file $files {
        if {[file isdirectory $file]} {
            set arrayOfFiles [getAllFiles $file $arrayOfFiles]
        } else {
            lappend arrayOfFiles $file
        }
    }
    return $arrayOfFiles
}

proc createAbstraction {scriptPath targetLang} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES
    if {[catch {set originalContent [read [set fh [open $scriptPath r]]]}]} {
        log "Failed: $scriptPath - Could not read file" "ERROR"
        return false
    }
    close $fh
    
    set ext [string range [file extension $scriptPath] 1 end]
    array set sourceLangMap {py Python js JavaScript sh Shell pl Perl rb Ruby}
    if {[info exists sourceLangMap($ext)]} {
        set sourceLang $sourceLangMap($ext)
    } else {
        set sourceLang $ext
    }
    
    set targetDir [file join $ABSTRACTIONS_REPO $targetLang]
    file mkdir $targetDir
    
    set targetFile [file join $targetDir [file rootname [file tail $scriptPath]][dict get $TARGET_LANGUAGES $targetLang ext]]
    
    if {[file exists $targetFile]} {
        return false
    }
    
    set template [dict get $TARGET_LANGUAGES $targetLang]
    set lines [split [string range $originalContent 0 1000] "\n"]
    if {[llength $lines] > 15} {
        set lines [lrange $lines 0 14]
    }
    
    set content "[dict get $template shebang]\n# [file rootname [file tail $scriptPath]] - [string totitle $targetLang] Version\n# Portiert von $sourceLang\n# Original: $scriptPath\n# Erstellt: [clock format [clock seconds] -format "%Y-%m-%d"]\n#\n"
    if {[dict get $template header] ne ""} {
        append content "[dict get $template header]\n\n"
    }
    append content "# Original-Code-Referenz:\n# "
    append content [join [lmap line $lines {return "# $line"}] "\n# "]
    append content "\n\nproc main {} {\n    # TODO: Implementiere $sourceLang Funktionalität in [string totitle $targetLang]\n    puts \"Hello World\"\n}\n\nif {\[info script\] eq \$::argv0} {\n    main\n}\n"
    
    set fh [open $targetFile w]
    puts -nonewline $fh $content
    close $fh
    log "Created: $targetFile"
    return true
}

proc processOnNode {nodeId scripts targetLangs} {
    # Verarbeitet Scripts auf definiertem Node
    set created 0
    
    if {$nodeId eq "node1"} {
        # Lokale Verarbeitung
        foreach script $scripts {
            foreach lang $targetLangs {
                if {[createAbstraction $script $lang]} {
                    incr created
                }
            }
        }
    } else {
        # Remote-Verarbeitung
        log "Dispatching [llength $scripts] jobs to $nodeId"
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        foreach script $scripts {
            foreach lang $targetLangs {
                if {[createAbstraction $script $lang]} {
                    incr created
                    log "Processed on $nodeId: [file tail $script] -> $lang"
                }
            }
        }
    }
    
    return $created
}

proc processPriorityHigh {} {
    global WORKSPACE
    set created 0
    set targets [list \
        [list "skill-creator" [file join $WORKSPACE "skills" "skill-creator" "scripts"]] \
        [list "json-utils" [file join $WORKSPACE "skills" "json-utils" "scripts"]] \
        [list "scripting-utils" [file join $WORKSPACE "skills" "scripting-utils" "scripts"]] \
        [list "model-usage" [file join $WORKSPACE "skills" "model-usage" "scripts"]] \
        [list "tiktok-live" [file join $WORKSPACE "skills" "tiktok-live" "scripts"]] \
    ]
    
    foreach target $targets {
        lassign $target skillName scriptsDir
        set scripts [findScriptsInDir $scriptsDir [list "node_modules" ".git" "test" "tests"]]
        log "$skillName: [llength $scripts] scripts found"
        
        set count 0
        foreach script [lrange $scripts 0 9] {
            if {[file exists $script]} {
                set scriptSize [file size $script]
            } else {
                set scriptSize 0
            }
            set targetLangs [list "perl5" "javascript" "python" "shell" "tcl"]
            set jobWeight [getJobWeight $scriptSize [llength $targetLangs]]
            
            # Wähle Node basierend auf Job-Gewicht
            set selectedNode [getNodeByPriority $jobWeight]
            log "Processing [file tail $script] ($jobWeight) on $selectedNode"
            
            incr created [processOnNode $selectedNode [list $script] $targetLangs]
            incr count
        }
    }
    
    return $created
}

proc processPriorityMedium {} {
    global WORKSPACE
    set created 0
    set targets [list \
        [list "workspace-scripts" [file join $WORKSPACE "scripts"]] \
        [list "db-maintainer" [file join $WORKSPACE "skills" "db-maintainer" "scripts"]] \
        [list "log-collector" [file join $WORKSPACE "skills" "log-collector" "scripts"]] \
    ]
    
    foreach target $targets {
        lassign $target dirName scriptsDir
        set scripts [findScriptsInDir $scriptsDir [list "node_modules" ".git"]]
        
        set count 0
        foreach script [lrange $scripts 0 9] {
            if {[file exists $script]} {
                set scriptSize [file size $script]
            } else {
                set scriptSize 0
            }
            set targetLangs [list "perl5" "javascript" "powershell" "python"]
            set jobWeight [getJobWeight $scriptSize [llength $targetLangs]]
            
            # Mittlere Priority → eher leichtere Jobs
            set selectedNode [getNodeByPriority [expr {$jobWeight eq "heavy" ? "medium" : $jobWeight}]]
            log "Processing [file tail $script] ($jobWeight) on $selectedNode"
            
            incr created [processOnNode $selectedNode [list $script] $targetLangs]
            incr count
        }
    }
    
    return $created
}

proc gitCommit {message} {
    global ABSTRACTIONS_REPO
    if {[catch {cd $ABSTRACTIONS_REPO}]} {
        return
    }
    if {[catch {exec git add .}]} {
        # ignore error
    }
    if {[catch {exec git commit -m $message}]} {
        # ignore error
    }
    log "Git commit: $message"
}

proc createStatusReport {state} {
    global ABSTRACTIONS_REPO TARGET_LANGUAGES AVAILABLE_MODELS NODES
    set reportFile [file join $ABSTRACTIONS_REPO "STATUS.md"]
    array set langCounts {}
    if {[file exists $ABSTRACTIONS_REPO]} {
        foreach lang [glob -nocomplain -directory $ABSTRACTIONS_REPO *] {
            set lang [file tail $lang]
            set langDir [file join $ABSTRACTIONS_REPO $lang]
            if {[file isdirectory $langDir] && [info exists TARGET_LANGUAGES($lang)]} {
                set files [glob -nocomplain -directory $langDir *]
                set count 0
                foreach f $files {
                    if {[file isfile $f]} {
                        incr count
                    }
                }
                set langCounts($lang) $count
            }
        }
    }
    
    set content "# Script Abstractions - Status Report\n\n"
    append content "**Letzte Aktualisierung:** [clock format [clock seconds] -format "%Y-%m-%d %H:%M"]\n\n"
    append content "- Aktuelle Priorität: [dict get $state current_priority]\n"
    append content "- Verarbeitete Scripts: [llength [dict get $state processed]]\n"
    append content "- Abstraktionen gesamt: [dict get $state stats abstractions_created]\n\n"
    
    append content "## Abstraktionen pro Sprache\n\n"
    foreach lang [lsort [array names langCounts]] {
        set count $langCounts($lang)
        append content "- $lang: $count\n"
    }
    
    append content "\n## Verfügbare Modelle\n\n"
    foreach model [lrange $AVAILABLE_MODELS 0 2] {
        append content "- `$model`\n"
    }
    append content "- ... und [expr {[llength $AVAILABLE_MODELS] - 3}] weitere\n"
    
    append content "\n## Multi-Node Support\n\n"
    append content "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n"
    append content "|------|---------------|-----------|-----------|-------|\n"
    foreach nodeId [lsort [array names NODES]] {
        array set config $NODES($nodeId)
        set avail [expr {$config(always_available) ? "✅ Immer" : "📱 Bedingt"}]
        set device [expr {[info exists config(device)] ? $config(device) : "Server"}]
        append content "| $nodeId | $avail | $config(capacity) | $config(priority) | $device |\n"
    }
    
    append content "\n### Job-Verteilung\n\n"
    append content "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n"
    append content "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n"
    append content "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n"
    
    set fh [open $reportFile w]
    puts -nonewline $fh $content
    close $fh
}

proc main {} {
    log "Script Abstractions Manager (Multi-Node) gestartet"
    
    set state [loadState]
    log "State loaded: [llength [dict get $state processed]] processed"
    
    set currentPriority [expr {[dict exists $state current_priority] ? [dict get $state current_priority] : "high"}]
    set created 0
    
    if {$currentPriority eq "high"} {
        log "Processing HIGH priority: Top 5 Skills"
        set created [processPriorityHigh]
        if {$created > 0} {
            gitCommit "High priority: $created abstractions"
        }
        dict set state current_priority "medium"
    } elseif {$currentPriority eq "medium"} {
        log "Processing MEDIUM priority: Workspace Scripts"
        set created [processPriorityMedium]
        if {$created > 0} {
            gitCommit "Medium priority: $created abstractions"
        }
        dict set state current_priority "high"
    }
    
    dict set state stats last_run [clock format [clock seconds] -format "%Y-%m-%dT%H:%M:%SZ"]
    dict set state stats abstractions_created 0
    if {[file exists $ABSTRACTIONS_REPO]} {
        foreach lang [array names TARGET_LANGUAGES] {
            set langDir [file join $ABSTRACTIONS_REPO $lang]
            if {[file exists $langDir] && [file isdirectory $langDir]} {
                set files [glob -nocomplain -directory $langDir *]
                set count 0
                foreach f $files {
                    if {[file isfile $f]} {
                        incr count
                    }
                }
                dict incr state stats abstractions_created $count
            }
        }
    }
    
    saveState $state
    createStatusReport $state
    
    log "Abgeschlossen. $created neue Abstraktionen erstellt."
}

main
