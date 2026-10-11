#!/usr/bin/env tclsh
# test_peak_limiter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Load required packages
package require Tcl 8.6

# Mock assert functionality
proc assert_equal {actual expected msg} {
    if {$actual != $expected} {
        error "$msg: expected $expected, got $actual"
    }
}

proc assert_ok {condition msg} {
    if {![expr $condition]} {
        error $msg
    }
}

proc assert_deep_equal {actual expected msg} {
    if {[llength $actual] != [llength $expected]} {
        error "$msg: arrays have different lengths"
    }
    foreach a $actual e $expected {
        if {$a != $e} {
            error "$msg: arrays differ at element"
        }
    }
}

# Source the content-core implementation
source ../browser-extension/content-core.tcl

# Helper functions
proc render {signal strength {rate 48000} {enabled true}} {
    set kernel [createPeakLimiter $rate]
    set delay_samples [$kernel cget -delaySamples]
    
    # Create output arrays with padding for delay
    set output {}
    foreach channel $signal {
        lappend output [list]
    }
    
    # Process in chunks of 128 samples
    set chunk_size 128
    set total_length [llength [lindex $signal 0]]
    set padded_length [expr {$total_length + $delay_samples}]
    
    # Initialize output arrays with zeros
    set output_arrays {}
    for {set ch 0} {$ch < [llength $output]} {incr ch} {
        set arr {}
        for {set i 0} {$i < $padded_length} {incr i} {
            lappend arr 0.0
        }
        lappend output_arrays $arr
    }
    
    # Process in chunks
    for {set start 0} {$start < $padded_length} {incr start $chunk_size} {
        set length [expr {min($chunk_size, $padded_length - $start)}]
        
        # Prepare input chunk
        set input_chunk {}
        foreach channel $signal {
            set chunk {}
            for {set i 0} {$i < $length} {incr i} {
                set idx [expr {$start + $i}]
                if {$idx < [llength $channel]} {
                    lappend chunk [lindex $channel $idx]
                } else {
                    lappend chunk 0.0
                }
            }
            lappend input_chunk $chunk
        }
        
        # Prepare output subarrays
        set output_subarrays {}
        for {set ch 0} {$ch < [llength $output_arrays]} {incr ch} {
            set arr [lindex $output_arrays $ch]
            set subarr [list]
            for {set i $start} {$i < $start + $length && $i < [llength $arr]} {incr i} {
                lappend subarr [lindex $arr $i]
            }
            lappend output_subarrays $subarr
        }
        
        # Process chunk
        $kernel process $input_chunk output_subarrays $enabled $strength
        
        # Update output arrays with processed data
        for {set ch 0} {$ch < [llength $output_arrays]} {incr ch} {
            set arr [lindex $output_arrays $ch]
            set subarr [lindex $output_subarrays $ch]
            for {set i 0} {$i < [llength $subarr]} {incr i} {
                set idx [expr {$start + $i}]
                if {$idx < [llength $arr]} {
                    set arr [lreplace $arr $idx $idx [lindex $subarr $i]]
                }
            }
            set output_arrays [lreplace $output_arrays $ch $ch $arr]
        }
    }
    
    return [list output $output_arrays delay $delay_samples]
}

proc peak {channel} {
    set max_val 0.0
    foreach val $channel {
        set abs_val [expr {abs($val)}]
        if {$abs_val > $max_val} {
            set max_val $abs_val
        }
    }
    return $max_val
}

# Test cases
foreach rate {44100 48000 96000} {
    puts "Testing isolated and high-frequency peaks at $rate Hz"
    
    # Create signal array
    set signal {}
    for {set i 0} {$i < $rate} {incr i} {
        lappend signal 0.0
    }
    
    # Set specific values
    set signal [lreplace $signal 1 1 1.0]
    set signal [lreplace $signal 127 127 -1.0]
    
    # Add sine wave
    for {set i 1000} {$i < 1100} {incr i} {
        set val [expr {sin(2 * 3.141592653589793 * 8000 * $i / $rate)}]
        set signal [lreplace $signal $i $i $val]
    }
    
    set previous 1.0
    foreach strength {25 75 100} {
        set result [render [list $signal] $strength $rate]
        set output [dict get $result output]
        set delay [dict get $result delay]
        
        set measured [peak [lindex $output 0]]
        set ceiling [expr {pow(10, [limiterStrengthToDbfs $strength] / 20)}]
        
        assert_ok [expr {$measured <= $ceiling + 1e-7}] "$measured exceeds $ceiling"
        assert_ok [expr {$measured < $previous}] "higher strength must attenuate more"
        assert_ok [expr {double($delay) / $rate <= 0.01}] ""
        
        set previous $measured
    }
}

puts "Testing bypass preserves every sample with documented delay"
set signal {}
for {set i 0} {$i < 10000} {incr i} {
    lappend signal [expr {sin($i * 0.7) * 0.8}]
}
set result [render [list $signal] 100 48000 false]
set output [dict get $result output]
set delay [dict get $result delay]

# Compare delayed output with original
set output_delayed [lrange [lindex $output 0] $delay end]
assert_deep_equal $output_delayed $signal "Bypass test failed"

puts "Testing quiet speech-band signal is not permanently attenuated"
set signal {}
for {set i 0} {$i < 48000} {incr i} {
    lappend signal [expr {0.01 * sin($i * 2 * 3.141592653589793 * 200 / 48000)}]
}
set result [render [list $signal] 100]
set output [dict get $result output]
set delay [dict get $result delay]

set output_delayed [lrange [lindex $output 0] $delay end]
assert_deep_equal $output_delayed $signal "Quiet speech test failed"

puts "Testing linked stereo gain preserves balance and limits either channel"
set left {}
set right {}
for {set i 0} {$i < 1000} {incr i} {
    lappend left 0.0
    lappend right 0.0
}
set left [lreplace $left 127 127 0.5]
set right [lreplace $right 127 127 1.0]

set result [render [list $left $right] 100]
set output [dict get $result output]
set delay [dict get $result delay]

set left_val [lindex [lindex $output 0] [expr {127 + $delay}]]
set right_val [lindex [lindex $output 1] [expr {127 + $delay}]]
assert_equal [expr {$left_val * 2}] $right_val "Stereo balance test failed"

set peak_right [peak [lindex $output 1]]
assert_ok [expr {$peak_right <= pow(10, -30 / 20) + 1e-7}] "Right channel limiting test failed"

puts "Testing gain recovery after transient and invalid samples handling"
set signal {}
for {set i 0} {$i < 48000} {incr i} {
    lappend signal 0.0
}
set signal [lreplace $signal 10 10 1.0]
set signal [lreplace $signal 100 100 nan]
set signal [lreplace $signal 200 200 inf]
for {set i 24000} {$i < [llength $signal]} {incr i} {
    set signal [lreplace $signal $i $i 0.01]
}

set result [render [list $signal] 100]
set output [dict get $result output]

# Check all values are finite
foreach val [lindex $output 0] {
    assert_ok [expr {[string is double -strict $val] && $val != "inf" && $val != "-inf"}] "Non-finite value detected"
}

# Check recovery
set recovered_val [lindex [lindex $output 0] 40000]
assert_ok [expr {$recovered_val > 0.00999}] "Gain recovery test failed"

puts "Testing empty input drains delayed audio and returns to silence"
set kernel [createPeakLimiter 48000]
set block {}
for {set i 0} {$i < 128} {incr i} {
    lappend block 0.01
}
set out {}
for {set i 0} {$i < 128} {incr i} {
    lappend out 0.0
}

$kernel process [list $block] [list $out] true 100
for {set n 0} {$n < 4} {incr n} {
    $kernel process {} [list $out] true 100
}

set peak_out [peak $out]
assert_equal $peak_out 0.0 "Empty input drain test failed"

puts "All tests passed!"
