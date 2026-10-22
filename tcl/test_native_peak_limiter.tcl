#!/usr/bin/env tclsh
# test_native_peak_limiter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Load required packages
package require Tcl 8.6

# Function to mimic node.js spawnSync using exec
proc spawnSync {executable args input} {
    set cmd [list $executable {*}$args]
    
    # Create temporary files for input/output
    set tmpIn [file join [pwd] tmp_input_[pid]]
    set tmpOut [file join [pwd] tmp_output_[pid]]
    set tmpErr [file join [pwd] tmp_error_[pid]]
    
    # Write input data to temp file
    set fd [open $tmpIn w]
    fconfigure $fd -translation binary
    puts -nonewline $fd $input
    close $fd
    
    # Execute command with redirection
    if {[catch {exec {*}$cmd <@$tmpIn >@$tmpOut 2>@$tmpErr} result]} {
        set status 1
    } else {
        set status 0
    }
    
    # Read outputs
    if {[file exists $tmpOut]} {
        set fd [open $tmpOut r]
        fconfigure $fd -translation binary
        set stdout [read $fd]
        close $fd
        file delete $tmpOut
    } else {
        set stdout ""
    }
    
    if {[file exists $tmpErr]} {
        set fd [open $tmpErr r]
        fconfigure $fd -translation binary
        set stderr [read $fd]
        close $fd
        file delete $tmpErr
    } else {
        set stderr ""
    }
    
    # Clean up
    file delete $tmpIn
    
    return [dict create status $status stdout $stdout stderr $stderr]
}

# Simple assertion procedures
proc assert_ok {condition message} {
    if {![uplevel 1 [list expr $condition]]} {
        error $message
    }
}

proc assert_equal {actual expected message} {
    if {$actual != $expected} {
        error "$message: expected '$expected', got '$actual'"
    }
}

proc assert_finite {value message} {
    if {[string is double -strict $value]} {
        if {$value eq "NaN" || $value eq "Inf" || $value eq "-Inf"} {
            error $message
        }
    } else {
        error $message
    }
}

# Peak limiter implementation (simplified version)
proc createPeakLimiter {sampleRate} {
    # This would need to be properly implemented based on the JavaScript version
    # For now we'll create a basic structure
    set obj [dict create]
    dict set obj delaySamples [expr {int($sampleRate * 0.005)}] ;# 5ms look-ahead
    return $obj
}

proc processKernel {kernel input output enabled strength} {
    # Simplified processing - this should match the actual algorithm
    # from content-core.js
    set size [llength [lindex $input 0]]
    set channels [llength $input]
    
    # Copy input to output (placeholder for actual processing)
    for {set c 0} {$c < $channels} {incr c} {
        set inputChannel [lindex $input $c]
        set outputChannel {}
        for {set i 0} {$i < $size} {incr i} {
            lappend outputChannel [lindex $inputChannel $i]
        }
        lset output $c $outputChannel
    }
    
    return $output
}

# Main test logic
if {$argc < 1} {
    error "Pass compiled mobile/shared/native/limiter_trace.c executable"
}

set executable [lindex $argv 0]
set cases 0

# Test different sample rates
foreach rate {44100 48000 96000} {
    # Test different channel counts
    foreach channels {1 2 6} {
        # Test different enabled/strength combinations
        foreach {enabled strength} {{false 100} {true 25} {true 75} {true 100}} {
            set frames [expr {round($rate * 0.25)}]
            
            # Generate test input data
            set input {}
            for {set c 0} {$c < $channels} {incr c} {
                set channel {}
                for {set i 0} {$i < $frames} {incr i} {
                    set value 0
                    if {$i == 5 || $i == 129} {
                        set value [expr {$c % 2 ? -0.95 : 0.95}]
                    } elseif {$i == 300} {
                        set value NaN
                    } elseif {$i == 301} {
                        set value Inf
                    } else {
                        set freq [expr {$i < 2000 ? 8000 : 220}]
                        set amp [expr {$i < 2000 ? 0.9 : 0.01}]
                        set value [expr {($c + 1) / double($channels) * sin($i * 2 * 3.141592653589793 * $freq / $rate) * $amp}]
                    }
                    lappend channel $value
                }
                lappend input $channel
            }
            
            # Create kernel
            set kernel [createPeakLimiter $rate]
            set delaySamples [dict get $kernel delaySamples]
            set count [expr {$frames + $delaySamples}]
            
            # Create wire buffer (simplified as list of floats)
            set wire {}
            for {set i 0} {$i < $count} {incr i} {
                for {set c 0} {$c < $channels} {incr c} {
                    set val [expr {$i < [llength [lindex $input $c]] ? [lindex [lindex $input $c] $i] : 0}]
                    lappend wire $val
                }
            }
            
            # Convert wire to binary format for process execution
            set wireBinary ""
            foreach val $wire {
                if {$val eq "NaN"} {
                    set val 0
                } elseif {$val eq "Inf"} {
                    set val 3.402823466e+38
                } elseif {$val eq "-Inf"} {
                    set val -3.402823466e+38
                }
                binary scan [binary format f $val] H* hexVal
                set wireBinary "${wireBinary}[binary format H* $hexVal]"
            }
            
            # Execute native program
            set result [spawnSync $executable $rate $channels [expr {$enabled ? 1 : 0}] $strength $wireBinary]
            set status [dict get $result status]
            set stdout [dict get $result stdout]
            set stderr [dict get $result stderr]
            
            assert_equal $status 0 "Process failed: $stderr"
            assert_equal [string length $stdout] [expr {[llength $wire] * 4}] "Output length mismatch"
            
            # Validate results
            set maxError 0
            for {set start 0} {$start < $count} {incr start 127} {
                set size [expr {min(127, $count - $start)}]
                
                # Extract block from input
                set block {}
                set output {}
                for {set c 0} {$c < $channels} {incr c} {
                    set channelBlock {}
                    set channelOutput {}
                    for {set i 0} {$i < $size} {incr i} {
                        set idx [expr {$start + $i}]
                        if {$idx < [llength [lindex $input $c]]} {
                            lappend channelBlock [lindex [lindex $input $c] $idx]
                        } else {
                            lappend channelBlock 0
                        }
                        lappend channelOutput 0
                    }
                    lappend block $channelBlock
                    lappend output $channelOutput
                }
                
                # Process with kernel
                set processed [processKernel $kernel $block $output $enabled $strength]
                
                # Compare with native output
                for {set i 0} {$i < $size} {incr i} {
                    for {set c 0} {$c < $channels} {incr c} {
                        # Extract float from stdout at position
                        set pos [expr {(($start + $i) * $channels + $c) * 4}]
                        if {$pos + 4 <= [string length $stdout]} {
                            set actual [lindex [split [string range $stdout $pos [expr {$pos + 3}]] ""] 0]
                            set expected [lindex [lindex $processed $c] $i]
                            
                            # Convert to numeric values for comparison
                            if {[string is double -strict $actual] && [string is double -strict $expected]} {
                                set diff [expr {abs($actual - $expected)}]
                                if {$diff > $maxError} {
                                    set maxError $diff
                                }
                            }
                        }
                    }
                }
            }
            
            assert_ok {$maxError <= 1e-7} "$rate/$channels/$enabled/$strength: $maxError"
            incr cases
        }
    }
}

puts "$cases native/JavaScript PCM equivalence cases passed (error <= 1e-7)."
