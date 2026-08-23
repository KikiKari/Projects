#!/usr/bin/env tclsh
# wavespeed-image.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/wavespeed-image.js
# auch in: OpenClaw@gateway2:wavespeed-image.js
# auch in: OpenClaw@gateway2:scripts/wavespeed-image.js
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

# WaveSpeed Image Analysis Tool
# User-Requested Only — kostenpflichtig ($0.14/Bild)

# Config
set API_BASE "https://api.wavespeed.ai/v1"
set MAX_IMAGES 7
set PRICE_PER_IMAGE 0.14

# Load token from env
if {[info exists ::env(BANANA_TOKEN)]} {
    set BANANA_TOKEN $::env(BANANA_TOKEN)
} else {
    set BANANA_TOKEN ""
}

proc showUsage {} {
    puts {
Usage: wavespeed-image <command> [options]

Commands:
  analyze <image...>    Analyze one or more images

Options:
  --prompt <text>       Analysis prompt (required)
  --dry-run             Show cost without executing
  -h, --help            Show this help

Examples:
  wavespeed-image analyze photo.jpg --prompt "What's in this image?"
  wavespeed-image analyze img1.jpg img2.jpg --prompt "Compare these"
}
}

proc showCostWarning {imageCount} {
    global PRICE_PER_IMAGE
    set totalCost [format "%.2f" [expr {$imageCount * $PRICE_PER_IMAGE}]]
    set countStr [format "%-44s" $imageCount]
    set priceStr [format "%-43s" $PRICE_PER_IMAGE]
    set costStr [format "%-44s" $totalCost]
    
    puts "
╔════════════════════════════════════════════════════════════╗
║  ⚠️  KOSTENHINWEIS — WaveSpeed Image Analysis              ║
╠════════════════════════════════════════════════════════════╣
║  Anzahl Bilder: $countStr║
║  Preis pro Bild: \$$priceStr║
║  Gesamtkosten: ~\$$costStr║
╠════════════════════════════════════════════════════════════╣
║  Abrechnung über dein WaveSpeed Guthaben                   ║
║  https://wavespeed.ai/account/billing                      ║
╚════════════════════════════════════════════════════════════╝
"
}

proc confirmExecution {} {
    # In OpenClaw context, this would be handled by the system
    # For CLI: require explicit --confirm flag
    global argv
    if {[lsearch -exact $argv "--confirm"] != -1} {
        return 1
    } else {
        return 0
    }
}

proc analyzeImages {imagePaths prompt} {
    puts "\n🖼️  Analysiere [llength $imagePaths] Bilder..."
    puts "📝 Prompt: \"$prompt\""
    puts "\n⏳ Anfrage wird gesendet...\n"
    
    # Simulate response
    set results {}
    foreach img $imagePaths {
        set basename [file tail $img]
        lappend results [dict create file $basename analysis "\[Analyse-Ergebnis für $basename würde hier stehen\]"]
    }
    
    return [dict create success 1 results $results]
}

proc main {} {
    global argv BANANA_TOKEN MAX_IMAGES
    
    if {[llength $argv] == 0 || [lsearch -exact $argv "-h"] != -1 || [lsearch -exact $argv "--help"] != -1} {
        showUsage
        exit 0
    }
    
    # Check auth
    if {$BANANA_TOKEN eq ""} {
        puts stderr "❌ Fehler: BANANA_TOKEN nicht gesetzt in ~/.config/openclaw/env"
        exit 1
    }
    
    set command [lindex $argv 0]
    
    if {$command eq "analyze"} {
        # Parse arguments
        set imagePaths {}
        set prompt ""
        set i 1
        
        while {$i < [llength $argv]} {
            set arg [lindex $argv $i]
            if {$arg eq "--prompt"} {
                incr i
                if {$i < [llength $argv]} {
                    set prompt [lindex $argv $i]
                }
            } elseif {$arg eq "--dry-run" || $arg eq "--confirm"} {
                # Skip
            } elseif {![string match "--*" $arg]} {
                lappend imagePaths $arg
            }
            incr i
        }
        
        # Validate
        if {[llength $imagePaths] == 0} {
            puts stderr "❌ Fehler: Mindestens ein Bild-Pfad erforderlich"
            exit 1
        }
        
        if {[llength $imagePaths] > $MAX_IMAGES} {
            puts stderr "❌ Fehler: Maximum $MAX_IMAGES Bilder erlaubt"
            exit 1
        }
        
        if {$prompt eq ""} {
            puts stderr "❌ Fehler: --prompt erforderlich"
            exit 1
        }
        
        # Validate files exist
        foreach img $imagePaths {
            if {![file exists $img]} {
                puts stderr "❌ Fehler: Datei nicht gefunden: $img"
                exit 1
            }
        }
        
        # Show cost warning
        showCostWarning [llength $imagePaths]
        
        # Dry run
        if {[lsearch -exact $argv "--dry-run"] != -1} {
            puts "✅ Dry-run: Keine API-Anfrage gesendet\n"
            exit 0
        }
        
        # Check for confirmation
        if {![confirmExecution]} {
            puts "\n⚠️  Hinweis: Füge --confirm hinzu um die Anfrage auszuführen"
            puts "   Befehl: wavespeed-image analyze [join $imagePaths " "] --prompt \"$prompt\" --confirm\n"
            exit 0
        }
        
        # Execute
        set result [analyzeImages $imagePaths $prompt]
        
        if {[dict get $result success]} {
            puts "✅ Analyse abgeschlossen\n"
            foreach r [dict get $result results] {
                set file [dict get $r file]
                set analysis [dict get $r analysis]
                puts "📄 $file:"
                puts "   $analysis\n"
            }
        }
    } else {
        puts stderr "❌ Unbekannter Befehl: $command"
        showUsage
        exit 1
    }
}

if {[catch {main} error]} {
    puts stderr "❌ Fehler: $error"
    exit 1
}
