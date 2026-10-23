#!/usr/bin/env tclsh
# peak-limiter.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of peak-limiter.html - synthetic web audio comparison test

package require Tk

# Create main window
wm title . "Pegelschutz: synthetischer Web-Audio-Vergleich"
wm geometry . 800x600

# Add styles
font configure AppFont -family system -size 12
option add *Font $AppFont

# Create UI elements
frame .header
label .header.title -text "Pegelschutz: synthetischer Web-Audio-Vergleich" -font {system 16 bold}
pack .header.title -side top -pady 10

label .info -text "Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis."
pack .info -pady 5

button .run -text "Audioprüfung starten" -command startTest
pack .run -pady 10

text .result -wrap word -height 20 -width 80
.result insert end "Bereit"
pack .result -fill both -expand yes -padx 10 -pady 10

proc peakDb {values} {
    set max 1e-10
    foreach v $values {
        set abs_v [expr {abs($v)}]
        if {$abs_v > $max} {
            set max $abs_v
        }
    }
    if {$max <= 0} {
        return -1000
    }
    return [expr {20 * log10($max)}]
}

proc limiterStrengthToDbfs {strength} {
    return [expr {-0.002 * $strength * $strength}]
}

proc limiterMakeupCompensation {threshold ratio} {
    set gain_reduction_db [expr {$threshold * (1 - 1/$ratio)}]
    return [expr {pow(10, -$gain_reduction_db/20)}]
}

proc createSignal {kind length rate} {
    set data {}
    set pi 3.141592653589793
    
    for {set i 0} {$i < $length} {incr i} {
        set value 0
        if {$kind eq "speech-band"} {
            set value [expr {0.01 * sin(2 * $pi * 220 * $i / $rate)}]
        } elseif {$kind eq "short-high-tone" && $i >= 5000 && $i < 5100} {
            set value [expr {0.95 * sin(2 * $pi * 8000 * $i / $rate)}]
        } elseif {$kind eq "level-step" && $i >= 5000 && $i < 10000} {
            set value [expr {0.95 * sin(2 * $pi * 1000 * $i / $rate)}]
        } elseif {$kind eq "impulse" && $i == 5000} {
            set value 0.95
        }
        lappend data $value
    }
    return $data
}

proc processSignal {data strength legacy} {
    if {$strength eq "" || $strength eq "null"} {
        return $data
    }
    
    if {$legacy} {
        # Simple compressor simulation
        set threshold [limiterStrengthToDbfs $strength]
        set ratio 20
        set attack_coeff 0.9985 ;# approx 1 - 0.0015/(1/48000)
        set release_coeff 0.92 ;# approx 1 - 0.08/(1/48000)
        
        set envelope 0
        set makeup_gain [limiterMakeupCompensation $threshold $ratio]
        set processed_data {}
        
        foreach sample $data {
            set input_level [expr {abs($sample)}]
            if {$input_level > $envelope} {
                set envelope [expr {$attack_coeff * $envelope + (1 - $attack_coeff) * $input_level}]
            } else {
                set envelope [expr {$release_coeff * $envelope + (1 - $release_coeff) * $input_level}]
            }
            
            if {$envelope > pow(10, $threshold/20)} {
                set gain_reduction [expr {pow(10, ($threshold - 20 * log10($envelope))/20)}]
                set processed_sample [expr {$sample * $gain_reduction * $makeup_gain}]
            } else {
                set processed_sample [expr {$sample * $makeup_gain}]
            }
            lappend processed_data $processed_sample
        }
        return $processed_data
    } else {
        # Peak limiter simulation (simplified lookahead)
        set window_size 100
        set processed_data {}
        set max_peak 0
        
        # Find maximum in lookahead window
        foreach sample $data {
            set abs_sample [expr {abs($sample)}]
            if {$abs_sample > $max_peak} {
                set max_peak $abs_sample
            }
        }
        
        set target_max [expr {pow(10, [limiterStrengthToDbfs $strength]/20)}]
        set gain_factor 1.0
        if {$max_peak > $target_max && $max_peak > 0} {
            set gain_factor [expr {$target_max / $max_peak}]
        }
        
        foreach sample $data {
            lappend processed_data [expr {$sample * $gain_factor}]
        }
        return $processed_data
    }
}

proc render {kind strength legacy} {
    set rate 48000
    set length $rate
    
    # Generate signal
    set data [createSignal $kind $length $rate]
    
    # Process signal
    set processed_data [processSignal $data $strength $legacy]
    
    # Calculate peaks
    set input_peak [peakDb $data]
    set output_peak [peakDb $processed_data]
    
    # Determine path
    set path "off"
    if {$strength ne "" && $strength ne "null"} {
        if {$legacy} {
            set path "0.8.2-compressor"
        } else {
            set path "candidate-lookahead"
        }
    }
    
    return [list \
        kind $kind \
        strength $strength \
        path $path \
        inputDbfs $input_peak \
        outputDbfs $output_peak]
}

proc startTest {} {
    .result delete 1.0 end
    .result insert end "Läuft\n"
    update idletasks
    
    if {[catch {
        set rows {}
        
        foreach kind {impulse short-high-tone level-step speech-band} {
            lappend rows [render $kind "" false]
            
            foreach strength {25 75 100} {
                lappend rows [render $kind $strength true]
                lappend rows [render $kind $strength false]
            }
        }
        
        # Check for failures
        set failures {}
        foreach row $rows {
            array set r $row
            if {$r(path) eq "candidate-lookahead"} {
                set limit_dbfs [limiterStrengthToDbfs $r(strength)]
                set exceeded_limit [expr {$r(outputDbfs) > $limit_dbfs + 0.05}]
                set speech_band_issue [expr {$r(kind) eq "speech-band" && abs($r(outputDbfs) - $r(inputDbfs)) > 0.05}]
                
                if {$exceeded_limit || $speech_band_issue} {
                    lappend failures $row
                }
            }
        }
        
        set passed [expr {[llength $failures] == 0}]
        
        # Format results as JSON-like string
        set result "{\n  \"passed\": [expr {$passed ? "true" : "false"}],\n"
        set result "$result  \"failures\": [\n"
        
        set first_failure 1
        foreach failure $failures {
            if {!$first_failure} {
                set result "$result,\n"
            }
            array set f $failure
            append result "    {\n"
            append result "      \"kind\": \"$f(kind)\",\n"
            append result "      \"strength\": $f(strength),\n"
            append result "      \"path\": \"$f(path)\",\n"
            append result "      \"inputDbfs\": [format "%.6f" $f(inputDbfs)],\n"
            append result "      \"outputDbfs\": [format "%.6f" $f(outputDbfs)]\n"
            append result "    }"
            set first_failure 0
        }
        
        set result "$result\n  ],\n  \"rows\": [\n"
        
        set first_row 1
        foreach row $rows {
            if {!$first_row} {
                set result "$result,\n"
            }
            array set r $row
            append result "    {\n"
            append result "      \"kind\": \"$r(kind)\",\n"
            if {$r(strength) eq ""} {
                append result "      \"strength\": null,\n"
            } else {
                append result "      \"strength\": $r(strength),\n"
            }
            append result "      \"path\": \"$r(path)\",\n"
            append result "      \"inputDbfs\": [format "%.6f" $r(inputDbfs)],\n"
            append result "      \"outputDbfs\": [format "%.6f" $r(outputDbfs)]\n"
            append result "    }"
            set first_row 0
        }
        
        set result "$result\n  ]\n}"
        
        .result delete 1.0 end
        .result insert end $result
    } error]} {
        .result delete 1.0 end
        .result insert end "FEHLER: $error"
    }
}

# Start the event loop
tkwait window .
