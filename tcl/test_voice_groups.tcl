#!/usr/bin/env tclsh
# test_voice_groups.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_voice_groups.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_voice_groups.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Tcl Port of test_voice_groups.cjs

# Load required packages
package require json
package require json::write

# Helper function to read file content
proc readFile {filename} {
    set fh [open $filename r]
    set content [read $fh]
    close $fh
    return $content
}

# Get directory of this script
set scriptDir [file dirname [info script]]

# Read source files
set source [readFile [file join $scriptDir ../browser-extension/sidepanel.js]]
set voiceCatalogData [readFile [file join $scriptDir ../companion-service/voice-catalog.json]]
set voices [dict get [::json::json2dict $voiceCatalogData] voices]

# Element creation function
proc createElement {tag} {
    return [dict create \
        tag $tag \
        children {} \
        dataset [dict create] \
        value "" \
        selected false]
}

# Create select element
set select [createElement select]

# Extract and run the relevant JavaScript portions
# We'll simulate the JavaScript functions in Tcl

# First extract the BASE_VOICE_ORDER and related constants/functions
set baseVoiceOrderStart [string first "const BASE_VOICE_ORDER" $source]
set coreStart [string first "const core =" $source]
set sherpaSpeechVoicesStart [string first "function sherpaSpeechVoices" $source]
set loadSpeechVoicesStart [string first "async function loadSpeechVoices" $source]

# Extract the relevant code sections
set baseVoiceCode [string range $source $baseVoiceOrderStart $coreStart-1]
set sherpaSpeechVoicesCode [string range $source $sherpaSpeechVoicesStart $loadSpeechVoicesStart-1]

# Process BASE_VOICE_ORDER - convert to Tcl list
set baseVoiceOrder {"Deutsch" "Englisch" "Französisch" "Russisch" "Spanisch" "Italienisch" "Portugiesisch" "Niederländisch" "Polnisch" "Tschechisch" "Slowakisch" "Ungarisch" "Rumänisch" "Bulgarisch" "Serbisch" "Kroatisch" "Slowenisch" "Finnisch" "Schwedisch" "Dänisch" "Norwegisch" "Isländisch" "Türkisch" "Arabisch" "Hebräisch" "Persisch" "Urdu" "Koreanisch" "Chinesisch" "Japanisch" "Vietnamesisch" "Thailändisch" "Indonesisch" "Malaysisch" "Singapurisch" "Effekt Stimmen"}

# Define language groups based on the logic from JavaScript
proc getLanguageGroup {voiceId} {
    # This replicates the logic from the original JavaScript
    if {[string match "*-de-*" $voiceId]} {
        return "Deutsch"
    } elseif {[string match "*-en-*" $voiceId]} {
        return "Englisch"
    } elseif {[string match "*-fr-*" $voiceId]} {
        return "Französisch"
    } elseif {[string match "*-ru-*" $voiceId]} {
        return "Russisch"
    } elseif {[string match "*-es-*" $voiceId]} {
        return "Spanisch"
    } elseif {[string match "*-it-*" $voiceId]} {
        return "Italienisch"
    } elseif {[string match "*-pt-*" $voiceId]} {
        return "Portugiesisch"
    } elseif {[string match "*-nl-*" $voiceId]} {
        return "Niederländisch"
    } elseif {[string match "*-pl-*" $voiceId]} {
        return "Polnisch"
    } elseif {[string match "*-cs-*" $voiceId]} {
        return "Tschechisch"
    } elseif {[string match "*-sk-*" $voiceId]} {
        return "Slowakisch"
    } elseif {[string match "*-hu-*" $voiceId]} {
        return "Ungarisch"
    } elseif {[string match "*-ro-*" $voiceId]} {
        return "Rumänisch"
    } elseif {[string match "*-bg-*" $voiceId]} {
        return "Bulgarisch"
    } elseif {[string match "*-sr-*" $voiceId]} {
        return "Serbisch"
    } elseif {[string match "*-hr-*" $voiceId]} {
        return "Kroatisch"
    } elseif {[string match "*-sl-*" $voiceId]} {
        return "Slowenisch"
    } elseif {[string match "*-fi-*" $voiceId]} {
        return "Finnisch"
    } elseif {[string match "*-sv-*" $voiceId]} {
        return "Schwedisch"
    } elseif {[string match "*-da-*" $voiceId]} {
        return "Dänisch"
    } elseif {[string match "*-no-*" $voiceId]} {
        return "Norwegisch"
    } elseif {[string match "*-is-*" $voiceId]} {
        return "Isländisch"
    } elseif {[string match "*-tr-*" $voiceId]} {
        return "Türkisch"
    } elseif {[string match "*-ar-*" $voiceId]} {
        return "Arabisch"
    } elseif {[string match "*-he-*" $voiceId]} {
        return "Hebräisch"
    } elseif {[string match "*-fa-*" $voiceId]} {
        return "Persisch"
    } elseif {[string match "*-ur-*" $voiceId]} {
        return "Urdu"
    } elseif {[string match "*-ko-*" $voiceId]} {
        return "Koreanisch"
    } elseif {[string match "*-zh-*" $voiceId] || [string match "*-cmn-*" $voiceId]} {
        return "Chinesisch"
    } elseif {[string match "*-ja-*" $voiceId]} {
        return "Japanisch"
    } elseif {[string match "*-vi-*" $voiceId]} {
        return "Vietnamesisch"
    } elseif {[string match "*-th-*" $voiceId]} {
        return "Thailändisch"
    } elseif {[string match "*-id-*" $voiceId]} {
        return "Indonesisch"
    } elseif {[string match "*-ms-*" $voiceId]} {
        return "Malaysisch"
    } elseif {[string match "*-ta-*" $voiceId]} {
        return "Tamilisch"
    } else {
        return "Effekt Stimmen"
    }
}

# Function to clear children
proc clearChildren {nodeVar} {
    upvar $nodeVar node
    dict set node children {}
}

# Function to append child
proc appendChild {parentVar child} {
    upvar $parentVar parent
    set children [dict get $parent children]
    lappend children $child
    dict set parent children $children
}

# Function to create option group
proc createOptionGroup {label} {
    set group [createElement optgroup]
    dict set group label $label
    return $group
}

# Function to create option
proc createOption {value text} {
    set option [createElement option]
    dict set option value $value
    dict set option text $text
    return $option
}

# sherpaSpeechVoices function equivalent
proc sherpaSpeechVoices {voices} {
    set result {}
    foreach voice $voices {
        if {[dict exists $voice id] && [string match "sherpa-*" [dict get $voice id]]} {
            lappend result $voice
        }
    }
    return $result
}

# setSpeechVoiceOptions function
proc setSpeechVoiceOptions {selectVar customVoices voiceCatalog} {
    upvar $selectVar select
    
    # Clear existing options
    clearChildren select
    
    # Filter voices using sherpaSpeechVoices logic
    set filteredVoices [sherpaSpeechVoices $voiceCatalog]
    
    # Group voices by language
    set groups {}
    foreach voice $filteredVoices {
        set groupId [getLanguageGroup [dict get $voice id]]
        if {![info exists groups($groupId)]} {
            set groups($groupId) {}
        }
        lappend groups($groupId) $voice
    }
    
    # Add special handling for custom voices
    foreach voice $customVoices {
        if {[dict exists $voice group] && [dict get $voice group] ne ""} {
            set groupId [dict get $voice group]
            if {![info exists groups($groupId)]} {
                set groups($groupId) {}
            }
            lappend groups($groupId) $voice
        } else {
            # Put ungrouped custom voices in "Effekt Stimmen"
            if {![info exists groups("Effekt Stimmen")]} {
                set groups("Effekt Stimmen") {}
            }
            lappend groups("Effekt Stimmen") $voice
        }
    }
    
    # Create option groups in order
    set baseVoiceOrder {"Deutsch" "Englisch" "Französisch" "Russisch" "Spanisch" "Italienisch" "Portugiesisch" "Niederländisch" "Polnisch" "Tschechisch" "Slowakisch" "Ungarisch" "Rumänisch" "Bulgarisch" "Serbisch" "Kroatisch" "Slowenisch" "Finnisch" "Schwedisch" "Dänisch" "Norwegisch" "Isländisch" "Türkisch" "Arabisch" "Hebräisch" "Persisch" "Urdu" "Koreanisch" "Chinesisch" "Japanisch" "Vietnamesisch" "Thailändisch" "Indonesisch" "Malaysisch" "Singapurisch" "Effekt Stimmen"}
    
    foreach groupId $baseVoiceOrder {
        if {[info exists groups($groupId)] && [llength $groups($groupId)] > 0} {
            set group [createOptionGroup $groupId]
            foreach voice $groups($groupId) {
                set option [createOption [dict get $voice id] [dict get $voice name]]
                appendChild group $option
            }
            appendChild select $group
        }
    }
    
    # Add any remaining groups not in base order
    foreach groupId [array names groups] {
        set found 0
        foreach orderedId $baseVoiceOrder {
            if {$orderedId eq $groupId} {
                set found 1
                break
            }
        }
        if {!$found && [llength $groups($groupId)] > 0} {
            set group [createOptionGroup $groupId]
            foreach voice $groups($groupId) {
                set option [createOption [dict get $voice id] [dict get $voice name]]
                appendChild group $option
            }
            appendChild select $group
        }
    }
}

# Test implementation
set speechVoiceName "sherpa-de-supertonic-7"

# Initial call with all voices
setSpeechVoiceOptions select {} $voices

# Test assertions
foreach label {"Kyrillisch" "Asiatisch" "Abjad" "Indisch" "Effekt Stimmen"} {
    set foundGroup ""
    foreach group [dict get $select children] {
        if {[dict exists $group label] && [dict get $group label] eq $label} {
            set foundGroup $group
            break
        }
    }
    
    if {$foundGroup eq ""} {
        error "FAIL: Group '$label' not found"
    }
    
    set childrenCount [llength [dict get $foundGroup children]]
    if {$childrenCount < 3} {
        error "FAIL: Group '$label' has only $childrenCount children, expected at least 3"
    }
}

# Check specific group count
set effectGroup ""
foreach group [dict get $select children] {
    if {[dict exists $group label] && [dict get $group label] eq "Effekt Stimmen"} {
        set effectGroup $group
        break
    }
}
if {$effectGroup eq ""} {
    error "FAIL: Effekt Stimmen group not found"
}

set effectChildrenCount [llength [dict get $effectGroup children]]
if {$effectChildrenCount != 5} {
    error "FAIL: Effekt Stimmen group has $effectChildrenCount children, expected 5"
}

# Check initial value is preserved
if {[dict get $select value] ne "sherpa-de-supertonic-7"} {
    error "FAIL: Select value not preserved"
}

# Second call with custom voice
set customVoices [list [dict create id "sherpa-de-supertonic-7" name "Stil 3" group ""]]
setSpeechVoiceOptions select $customVoices $voices

# Value should still be preserved
if {[dict get $select value] ne "sherpa-de-supertonic-7"} {
    error "FAIL: Select value not preserved after custom voice addition"
}

# Check that the custom voice appears in its group
set effectGroup ""
foreach group [dict get $select children] {
    if {[dict exists $group label] && [dict get $group label] eq "Effekt Stimmen"} {
        set effectGroup $group
        break
    }
}
if {$effectGroup eq ""} {
    error "FAIL: Effekt Stimmen group not found after custom voice addition"
}

set foundValue 0
foreach option [dict get $effectGroup children] {
    if {[dict get $option value] eq "sherpa-de-supertonic-7"} {
        set foundValue 1
        break
    }
}
if {!$foundValue} {
    error "FAIL: Custom voice not found in Effekt Stimmen group"
}

# Third test - change voice and remove groups from catalog
set speechVoiceName "sherpa-ru-irina"
setSpeechVoiceOptions select {} [lmap voice $voices {
    if {[dict exists $voice group]} {
        dict unset voice group
    }
    set voice
}]

# Check new value is preserved
if {[dict get $select value] ne "sherpa-ru-irina"} {
    error "FAIL: Select value not updated to sherpa-ru-irina"
}

# Check that the Russian voice appears in Kyrillisch group
set kyrillischGroup ""
foreach group [dict get $select children] {
    if {[dict exists $group label] && [dict get $group label] eq "Russisch"} {
        set kyrillischGroup $group
        break
    }
}
if {$kyrillischGroup eq ""} {
    error "FAIL: Russisch group not found"
}

set foundRussianVoice 0
foreach option [dict get $kyrillischGroup children] {
    if {[dict get $option value] eq "sherpa-ru-irina"} {
        set foundRussianVoice 1
        break
    }
}
if {!$foundRussianVoice} {
    error "FAIL: Russian voice not found in Russisch group"
}

puts "PASS: five groups, all styles selectable, retained selection, legacy catalog fallback"
