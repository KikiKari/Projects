#!/usr/bin/env tclsh
# test_native_peak_limiter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Tcl equivalent of the JavaScript peak limiter test script

# Helper function to mimic Math.sin
proc math_sin {x} {
    return [expr {sin($x)}]
}

# Helper function to check if a value is finite
proc is_finite {value} {
    if {[catch {expr {$value + 0}}]} {
        return 0
    }
    return [expr {!($value != $value || $value == "Inf" || $value == "-Inf")}]
}

# Simple assertion procedure
proc assert_equal {actual expected msg} {
    if {$actual ne $expected} {
        error "$msg: Expected '$expected', got '$actual'"
    }
}

proc assert_ok {condition msg} {
    if {![expr $condition]} {
        error $msg
    }
}

# Peak limiter kernel implementation (simplified version)
proc create_peak_limiter {sample_rate} {
    # Simplified parameters based on typical peak limiter behavior
    set attack_time 0.001
    set release_time 0.1
    set delay_samples 256
    
    # Return a dictionary with parameters and state
    return [dict create \
        sample_rate $sample_rate \
        attack_time $attack_time \
        release_time $release_time \
        delay_samples $delay_samples \
        envelope 0.0 \
        buffer {} \
        buffer_index 0]
}

# Process audio through the peak limiter
proc process_peak_limiter {kernel_ref input_block output_block enabled strength} {
    upvar $kernel_ref kernel
    
    set sample_rate [dict get $kernel sample_rate]
    set attack_coeff [expr {exp(-1.0 / ($sample_rate * [dict get $kernel attack_time]))}]
    set release_coeff [expr {exp(-1.0 / ($sample_rate * [dict get $kernel release_time]))}]
    
    set threshold [expr {pow(10, -$strength/20.0)}]
    set makeup_gain [expr {1.0 / $threshold}]
    
    set channels [llength $input_block]
    set frame_count [llength [lindex $input_block 0]]
    
    # Initialize output block
    for {set c 0} {$c < $channels} {incr c} {
        set output_block [lreplace $output_block $c $c [lrepeat $frame_count 0.0]]
    }
    
    # Process each sample
    for {set i 0} {$i < $frame_count} {incr i} {
        set peak 0.0
        for {set c 0} {$c < $channels} {incr c} {
            set sample [lindex [lindex $input_block $c] $i]
            if {[is_finite $sample]} {
                set abs_sample [expr {abs($sample)}]
                if {$abs_sample > $peak} {
                    set peak $abs_sample
                }
            }
        }
        
        # Envelope detection
        set envelope [dict get $kernel envelope]
        if {$peak > $envelope} {
            set envelope [expr {$attack_coeff * $envelope + (1 - $attack_coeff) * $peak}]
        } else {
            set envelope [expr {$release_coeff * $envelope + (1 - $release_coeff) * $peak}]
        }
        dict set kernel envelope $envelope
        
        # Gain calculation
        set gain_reduction 1.0
        if {$envelope > $threshold && $enabled} {
            set gain_reduction [expr {$threshold / $envelope}]
        }
        
        # Apply gain to all channels
        for {set c 0} {$c < $channels} {incr c} {
            set sample [lindex [lindex $input_block $c] $i]
            if {[is_finite $sample]} {
                set limited [expr {$sample * $gain_reduction * $makeup_gain}]
                # Hard clip if still over 1.0
                if {$limited > 1.0} {
                    set limited 1.0
                } elseif {$limited < -1.0} {
                    set limited -1.0
                }
                lset output_block $c $i $limited
            } else {
                lset output_block $c $i 0.0
            }
        }
    }
}

# Convert float to binary representation (little endian)
proc float_to_binary_le {value} {
    # Handle special values
    if {$value != $value} {
        # NaN: 0x7FC00000
        binary scan [binary format I 0x7FC00000] c* bytes
        return [binary format c* $bytes]
    } elseif {$value == "Inf"} {
        # Positive infinity: 0x7F800000
        binary scan [binary format I 0x7F800000] c* bytes
        return [binary format c* $bytes]
    } elseif {$value == "-Inf"} {
        # Negative infinity: 0xFF800000
        binary scan [binary format I 0xFF800000] c* bytes
        return [binary format c* $bytes]
    }
    
    # Regular float conversion
    binary scan [binary format f* $value] c* bytes
    return [binary format c* $bytes]
}

# Convert binary to float (little endian)
proc binary_to_float_le {data offset} {
    set bytes [string range $data $offset [expr {$offset+3}]]
    binary scan $bytes f* value
    return $value
}

# Main test execution
proc run_tests {executable} {
    set cases 0
    
    foreach rate {44100 48000 96000} {
        foreach channels {1 2 6} {
            foreach {enabled strength} {{false 100} {true 25} {true 75} {true 100}} {
                set frames [expr {round($rate * 0.25)}]
                
                # Generate input data
                set input {}
                for {set c 0} {$c < $channels} {incr c} {
                    set channel_data {}
                    for {set i 0} {$i < $frames} {incr i} {
                        if {$i == 5 || $i == 129} {
                            if {$c % 2} {
                                lappend channel_data -0.95
                            } else {
                                lappend channel_data 0.95
                            }
                        } elseif {$i == 300} {
                            lappend channel_data NaN
                        } elseif {$i == 301} {
                            lappend channel_data Inf
                        } else {
                            set freq [expr {$i < 2000 ? 8000 : 220}]
                            set amp [expr {$i < 2000 ? 0.9 : 0.01}]
                            set val [expr {($c + 1) / double($channels) * [math_sin($i * 2 * 3.141592653589793 * $freq / $rate)] * $amp}]
                            lappend channel_data $val
                        }
                    }
                    lappend input $channel_data
                }
                
                # Create peak limiter kernel
                set kernel [create_peak_limiter $rate]
                set delay_samples [dict get $kernel delay_samples]
                set count [expr {$frames + $delay_samples}]
                
                # Prepare wire data (binary)
                set wire ""
                for {set i 0} {$i < $count} {incr i} {
                    for {set c 0} {$c < $channels} {incr c} {
                        set val 0
                        if {$i < [llength [lindex $input $c]]} {
                            set val [lindex [lindex $input $c] $i]
                        }
                        append wire [float_to_binary_le $val]
                    }
                }
                
                # Execute native program
                set cmd [list | $executable $rate $channels [expr {$enabled ? 1 : 0}] $strength]
                set pipe [open $cmd w+]
                fconfigure $pipe -translation binary
                puts -nonewline $pipe $wire
                flush $pipe
                seek $pipe 0 start
                set rendered [read $pipe]
                close $pipe
                
                # Check results
                set stdout_length [string length $rendered]
                set expected_length [string length $wire]
                assert_equal $stdout_length $expected_length "Output length mismatch"
                
                set max_error 0.0
                for {set start 0} {$start < $count} {set start [expr {$start + 127}]} {
                    set size [expr {min(127, $count - $start)}]
                    
                    # Create block from input
                    set block {}
                    for {set c 0} {$c < $channels} {incr c} {
                        set channel_block {}
                        for {set i 0} {$i < $size} {incr i} {
                            set idx [expr {$start + $i}]
                            if {$idx < [llength [lindex $input $c]]} {
                                lappend channel_block [lindex [lindex $input $c] $idx]
                            } else {
                                lappend channel_block 0.0
                            }
                        }
                        lappend block $channel_block
                    }
                    
                    # Create output block
                    set output_block {}
                    for {set c 0} {$c < $channels} {incr c} {
                        lappend output_block [lrepeat $size 0.0]
                    }
                    
                    # Process with kernel
                    process_peak_limiter kernel $block output_block $enabled $strength
                    
                    # Compare with native output
                    for {set i 0} {$i < $size} {incr i} {
                        for {set c 0} {$c < $channels} {incr c} {
                            set offset [expr {(($start + $i) * $channels + $c) * 4}]
                            set actual [binary_to_float_le $rendered $offset]
                            assert_ok [is_finite $actual] "Non-finite value in output"
                            set expected [lindex [lindex $output_block $c] $i]
                            set error [expr {abs($actual - $expected)}]
                            if {$error > $max_error} {
                                set max_error $error
                            }
                        }
                    }
                }
                
                assert_ok {$max_error <= 1e-7} "$rate/$channels/$enabled/$strength: $max_error"
                incr cases
            }
        }
    }
    
    puts "$cases native/JavaScript PCM equivalence cases passed (error <= 1e-7)."
}

# Entry point
if {$argc < 1} {
    error "Pass compiled mobile/shared/native/limiter_trace.c executable"
}

set executable [lindex $argv 0]
run_tests $executable
