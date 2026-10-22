#!/usr/bin/env tclsh
# test_peak_limiter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Load required packages
package require math::constants
package require math::statistics

namespace import ::math::constants::*

# Define helper functions
proc assert_equal {actual expected msg} {
    if {$actual != $expected} {
        error "$msg: expected $expected, got $actual"
    }
}

proc assert_true {condition msg} {
    if {![expr $condition]} {
        error "$msg"
    }
}

proc assert_ok {condition msg} {
    if {![expr $condition]} {
        error "$msg"
    }
}

proc float32_array {size} {
    return [list]
}

proc fill_array {arr size value} {
    set result {}
    for {set i 0} {$i < $size} {incr i} {
        lappend result $value
    }
    return $result
}

proc array_length {arr} {
    return [llength $arr]
}

proc array_get {arr index} {
    return [lindex $arr $index]
}

proc array_set {arr index value} {
    return [lreplace $arr $index $index $value]
}

proc array_slice {arr start end} {
    return [lrange $arr $start [expr {$end - 1}]]
}

proc array_map {func arr} {
    set result {}
    foreach item $arr {
        lappend result [$func $item]
    }
    return $result
}

proc array_reduce {func arr initial} {
    set result $initial
    foreach item $arr {
        set result [$func $result $item]
    }
    return $result
}

proc max_abs {a b} {
    set abs_a [expr {abs($a)}]
    set abs_b [expr {abs($b)}]
    return [expr {$abs_a > $abs_b ? $abs_a : $abs_b}]
}

proc peak {channel} {
    return [array_reduce max_abs $channel 0]
}

proc sin_func {x} {
    return [expr {sin($x)}]
}

proc pi {} {
    return 3.141592653589793
}

# Mocking node:test functionality
proc test {description script} {
    puts "Running test: $description"
    if [catch {eval $script} error] {
        puts "Test failed: $error"
    } else {
        puts "Test passed"
    }
}

# Ported functions from content-core.js (simplified versions)
proc createPeakLimiter {rate} {
    # Simplified implementation
    set delaySamples [expr {int(0.005 * $rate)}]  ;# 5ms delay
    return [list "delaySamples" $delaySamples]
}

proc limiterStrengthToDbfs {strength} {
    return [expr {-0.01 * $strength * $strength}]
}

proc process_kernel {kernel input output enabled strength} {
    # Simplified processing
    set delaySamples [dict get $kernel delaySamples]
    
    # Just copy input to output with some attenuation if enabled
    set channels [llength $input]
    for {set c 0} {$c < $channels} {incr c} {
        set in_channel [lindex $input $c]
        set out_channel [lindex $output $c]
        set len [llength $in_channel]
        
        for {set i 0} {$i < $len} {incr i} {
            set val [lindex $in_channel $i]
            if {$enabled} {
                set dbfs [limiterStrengthToDbfs $strength]
                set limit [expr {pow(10, $dbfs / 20)}]
                set val [expr {$val * $limit}]
            }
            set out_channel [lreplace $out_channel $i $i $val]
        }
    }
    return $output
}

proc render {signal strength {rate 48000} {enabled true}} {
    set kernel [createPeakLimiter $rate]
    set delaySamples [dict get $kernel delaySamples]
    
    # Create output arrays with padding
    set output {}
    foreach channel $signal {
        set padded {}
        for {set i 0} {$i < [expr {[llength $channel] + $delaySamples}]} {incr i} {
            if {$i < [llength $channel]} {
                lappend padded [lindex $channel $i]
            } else {
                lappend padded 0.0
            }
        }
        lappend output $padded
    }
    
    # Process in blocks of 128
    set total_length [llength [lindex $output 0]]
    for {set start 0} {$start < $total_length} {incr start 128} {
        set length [expr {min(128, $total_length - $start)}]
        
        # Prepare input block
        set input_block {}
        foreach channel $signal {
            set block {}
            for {set i 0} {$i < $length} {incr i} {
                set idx [expr {$start + $i}]
                if {$idx < [llength $channel]} {
                    lappend block [lindex $channel $idx]
                } else {
                    lappend block 0.0
                }
            }
            lappend input_block $block
        }
        
        # Prepare output subarrays
        set output_sub {}
        set idx 0
        foreach channel $output {
            set sub_start $start
            set sub_end [expr {$start + $length}]
            set subarray [array_slice $channel $sub_start $sub_end]
            lappend output_sub $subarray
            incr idx
        }
        
        # Process block
        set processed [process_kernel $kernel $input_block $output_sub $enabled $strength]
        
        # Copy back to output
        set ch_idx 0
        foreach proc_ch $processed {
            set out_ch [lindex $output $ch_idx]
            set out_pos $start
            foreach val $proc_ch {
                set out_ch [lreplace $out_ch $out_pos $out_pos $val]
                incr out_pos
            }
            set output [lreplace $output $ch_idx $ch_idx $out_ch]
            incr ch_idx
        }
    }
    
    return [list "output" $output "delay" $delaySamples]
}

# Test cases
foreach rate {44100 48000 96000} {
    test "isolated and high-frequency peaks are bounded at $rate Hz" {
        # Create signal array
        set signal {}
        for {set i 0} {$i < $rate} {incr i} {
            lappend signal 0.0
        }
        set signal [lreplace $signal 1 1 1.0]
        set signal [lreplace $signal 127 127 -1.0]
        
        for {set i 1000} {$i < 1100} {incr i} {
            set val [expr {sin(2 * [pi] * 8000 * $i / $rate)}]
            set signal [lreplace $signal $i $i $val]
        }
        
        set previous 1.0
        foreach strength {25 75 100} {
            set result [render [list $signal] $strength $rate]
            set output [dict get $result output]
            set delay [dict get $result delay]
            set measured [peak [lindex $output 0]]
            set dbfs [limiterStrengthToDbfs $strength]
            set ceiling [expr {pow(10, $dbfs / 20)}]
            
            assert_ok [expr {$measured <= $ceiling + 1e-7}] "$measured exceeds $ceiling"
            assert_ok [expr {$measured < $previous}] "higher strength must attenuate more"
            assert_ok [expr {$delay / $rate <= 0.01}] ""
            set previous $measured
        }
    }
}

test "bypass preserves every sample with the documented delay" {
    set signal {}
    for {set i 0} {$i < 10000} {incr i} {
        set val [expr {sin($i * 0.7) * 0.8}]
        lappend signal $val
    }
    
    set result [render [list $signal] 100 48000 false]
    set output [dict get $result output]
    set delay [dict get $result delay]
    
    set output_slice [array_slice [lindex $output 0] $delay [expr {$delay + [llength $signal]}]]
    
    # Compare arrays element by element
    set match 1
    for {set i 0} {$i < [llength $signal]} {incr i} {
        if {[lindex $output_slice $i] != [lindex $signal $i]} {
            set match 0
            break
        }
    }
    assert_true $match "Arrays should be equal"
}

test "quiet speech-band signal is not permanently attenuated" {
    set signal {}
    for {set i 0} {$i < 48000} {incr i} {
        set val [expr {0.01 * sin($i * 2 * [pi] * 200 / 48000)}]
        lappend signal $val
    }
    
    set result [render [list $signal] 100]
    set output [dict get $result output]
    set delay [dict get $result delay]
    
    set output_slice [array_slice [lindex $output 0] $delay [expr {$delay + [llength $signal]}]]
    
    # Compare arrays element by element
    set match 1
    for {set i 0} {$i < [llength $signal]} {incr i} {
        if {[lindex $output_slice $i] != [lindex $signal $i]} {
            set match 0
            break
        }
    }
    assert_true $match "Arrays should be equal"
}

test "linked stereo gain preserves balance and limits either channel" {
    set left {}
    for {set i 0} {$i < 1000} {incr i} {
        lappend left 0.0
    }
    set left [lreplace $left 127 127 0.5]
    
    set right {}
    for {set i 0} {$i < 1000} {incr i} {
        lappend right 0.0
    }
    set right [lreplace $right 127 127 1.0]
    
    set result [render [list $left $right] 100]
    set output [dict get $result output]
    set delay [dict get $result delay]
    
    set left_val [lindex [lindex $output 0] [expr {127 + $delay}]]
    set right_val [lindex [lindex $output 1] [expr {127 + $delay}]]
    
    assert_equal [expr {$left_val * 2}] $right_val "Left should be half of right"
    
    set measured [peak [lindex $output 1]]
    set limit [expr {pow(10, -30 / 20)}]
    assert_ok [expr {$measured <= $limit + 1e-7}] "Right channel should be limited"
}

test "gain recovers after a transient and invalid samples cannot poison the graph" {
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
    set all_finite 1
    foreach val [lindex $output 0] {
        if {![expr {isfinite($val)}]} {
            set all_finite 0
            break
        }
    }
    assert_true $all_finite "All values should be finite"
    
    # Check recovery at position 40000
    set recovered_val [lindex [lindex $output 0] 40000]
    assert_ok [expr {$recovered_val > 0.00999}] "Should recover to near original level"
}

test "empty input drains delayed audio and then returns to silence" {
    set kernel [createPeakLimiter 48000]
    set block {}
    for {set i 0} {$i < 128} {incr i} {
        lappend block 0.01
    }
    set out {}
    for {set i 0} {$i < 128} {incr i} {
        lappend out 0.0
    }
    
    # First process with signal
    set out [process_kernel $kernel [list $block] [list $out] true 100]
    
    # Then process empty inputs
    for {set n 0} {$n < 4} {incr n} {
        set out [process_kernel $kernel {} [list $out] true 100]
    }
    
    set measured [peak [lindex $out 0]]
    assert_equal $measured 0.0 "Output should be silent"
}
