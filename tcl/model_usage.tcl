#!/usr/bin/env tclsh8.6
# model_usage.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# Summarize CodexBar local cost usage by model.
#
# Defaults to current model (most recent daily entry), or list all models.

proc eprint {msg} {
    puts stderr $msg
}

proc run_codexbar_cost {provider} {
    set cmd [list codexbar cost --format json --provider $provider]
    if {[catch {exec {*}$cmd} output]} {
        if {[string match "*not found*" $output]} {
            error "codexbar not found on PATH. Install CodexBar CLI first."
        } else {
            error "codexbar cost failed: $output"
        }
    }
    
    if {[catch {::json::json2dict $output} data]} {
        error "Failed to parse codexbar JSON output: $data"
    }
    
    return $data
}

proc load_payload {input_path provider} {
    if {$input_path ne ""} {
        if {$input_path eq "-"} {
            set raw [read stdin]
        } else {
            set fp [open $input_path r]
            set raw [read $fp]
            close $fp
        }
        set data [::json::json2dict $raw]
    } else {
        set data [run_codexbar_cost $provider]
    }
    
    if {[dict size $data] > 0 && [dict get $data provider] eq $provider} {
        return $data
    }
    
    if {[llength $data] > 0} {
        foreach entry $data {
            if {[dict exists $entry provider] && [dict get $entry provider] eq $provider} {
                return $entry
            }
        }
        error "Provider '$provider' not found in codexbar payload."
    }
    
    error "Unsupported JSON input format."
}

proc parse_daily_entries {payload} {
    if {![dict exists $payload daily]} {
        return {}
    }
    
    set daily [dict get $payload daily]
    if {![string is list $daily]} {
        return {}
    }
    
    set result {}
    foreach entry $daily {
        if {[string is dict $entry]} {
            lappend result $entry
        }
    }
    return $result
}

proc parse_date {value} {
    if {[catch {clock scan $value -format "%Y-%m-%d"} timestamp]} {
        return ""
    }
    return [clock format $timestamp -format "%Y-%m-%d"]
}

proc filter_by_days {entries days} {
    if {$days eq "" || $days <= 0} {
        return $entries
    }
    
    set cutoff [clock scan [clock format [clock seconds] -format "%Y-%m-%d"] -format "%Y-%m-%d"]
    set cutoff [clock add $cutoff -[expr {$days - 1}] days]
    
    set filtered {}
    foreach entry $entries {
        if {![dict exists $entry date]} continue
        set day [dict get $entry date]
        if {![string is string $day]} continue
        
        if {[catch {clock scan $day -format "%Y-%m-%d"} parsed]} continue
        if {$parsed >= $cutoff} {
            lappend filtered $entry
        }
    }
    return $filtered
}

proc aggregate_costs {entries} {
    set totals [dict create]
    foreach entry $entries {
        if {![dict exists $entry modelBreakdowns]} continue
        set breakdowns [dict get $entry modelBreakdowns]
        if {![string is list $breakdowns]} continue
        
        foreach item $breakdowns {
            if {![string is dict $item]} continue
            if {![dict exists $item modelName] || ![dict exists $item cost]} continue
            
            set model [dict get $item modelName]
            set cost [dict get $item cost]
            if {![string is string $model] || ![string is double $cost]} continue
            
            if {[dict exists $totals $model]} {
                set current [dict get $totals $model]
                dict set totals $model [expr {$current + $cost}]
            } else {
                dict set totals $model $cost
            }
        }
    }
    return $totals
}

proc pick_current_model {entries} {
    if {[llength $entries] == 0} {
        return [list "" ""]
    }
    
    # Sort entries by date
    set sorted_entries {}
    foreach entry $entries {
        set date_val ""
        if {[dict exists $entry date]} {
            set date_val [dict get $entry date]
        }
        lappend sorted_entries [list $date_val $entry]
    }
    set sorted_entries [lsort -index 0 -dictionary $sorted_entries]
    
    # Process in reverse order (most recent first)
    foreach item [lreverse $sorted_entries] {
        set entry [lindex $item 1]
        
        if {[dict exists $entry modelBreakdowns]} {
            set breakdowns [dict get $entry modelBreakdowns]
            if {[string is list $breakdowns] && [llength $breakdowns] > 0} {
                set scored {}
                foreach item $breakdowns {
                    if {![string is dict $item]} continue
                    if {![dict exists $item modelName] || ![dict exists $item cost]} continue
                    
                    set model [dict get $item modelName]
                    set cost [dict get $item cost]
                    if {[string is string $model] && [string is double $cost]} {
                        lappend scored [list $model $cost]
                    }
                }
                
                if {[llength $scored] > 0} {
                    set scored [lsort -real -index 1 -decreasing $scored]
                    set model [lindex $scored 0 0]
                    set date_val ""
                    if {[dict exists $entry date] && [string is string [dict get $entry date]]} {
                        set date_val [dict get $entry date]
                    }
                    return [list $model $date_val]
                }
            }
        }
        
        if {[dict exists $entry modelsUsed]} {
            set models_used [dict get $entry modelsUsed]
            if {[string is list $models_used] && [llength $models_used] > 0} {
                set last [lindex $models_used end]
                if {[string is string $last]} {
                    set date_val ""
                    if {[dict exists $entry date] && [string is string [dict get $entry date]]} {
                        set date_val [dict get $entry date]
                    }
                    return [list $last $date_val]
                }
            }
        }
    }
    return [list "" ""]
}

proc usd {value} {
    if {$value eq ""} {
        return "—"
    }
    return [format "$%.2f" $value]
}

proc latest_day_cost {entries model} {
    if {[llength $entries] == 0} {
        return [list "" ""]
    }
    
    # Sort entries by date
    set sorted_entries {}
    foreach entry $entries {
        set date_val ""
        if {[dict exists $entry date]} {
            set date_val [dict get $entry date]
        }
        lappend sorted_entries [list $date_val $entry]
    }
    set sorted_entries [lsort -index 0 -dictionary $sorted_entries]
    
    # Process in reverse order (most recent first)
    foreach item [lreverse $sorted_entries] {
        set entry [lindex $item 1]
        if {![dict exists $entry modelBreakdowns]} continue
        set breakdowns [dict get $entry modelBreakdowns]
        if {![string is list $breakdowns]} continue
        
        foreach item $breakdowns {
            if {![string is dict $item]} continue
            if {![dict exists $item modelName]} continue
            if {[dict get $item modelName] eq $model} {
                set cost ""
                if {[dict exists $item cost] && [string is double [dict get $item cost]]} {
                    set cost [dict get $item cost]
                }
                set day ""
                if {[dict exists $entry date] && [string is string [dict get $entry date]]} {
                    set day [dict get $entry date]
                }
                return [list $day $cost]
            }
        }
    }
    return [list "" ""]
}

proc render_text_current {provider model latest_date total_cost latest_cost latest_cost_date entry_count} {
    set lines [list "Provider: $provider" "Current model: $model"]
    if {$latest_date ne ""} {
        lappend lines "Latest model date: $latest_date"
    }
    lappend lines "Total cost (rows): [usd $total_cost]"
    if {$latest_cost_date ne ""} {
        lappend lines "Latest day cost: [usd $latest_cost] ($latest_cost_date)"
    }
    lappend lines "Daily rows: $entry_count"
    return [join $lines "\n"]
}

proc render_text_all {provider totals} {
    set lines [list "Provider: $provider" "Models:"]
    # Sort by cost (descending)
    set sorted_items {}
    dict for {model cost} $totals {
        lappend sorted_items [list $model $cost]
    }
    set sorted_items [lsort -real -index 1 -decreasing $sorted_items]
    
    foreach item $sorted_items {
        set model [lindex $item 0]
        set cost [lindex $item 1]
        lappend lines "- $model: [usd $cost]"
    }
    return [join $lines "\n"]
}

proc build_json_current {provider model latest_date total_cost latest_cost latest_cost_date entry_count} {
    set result [dict create]
    dict set result provider $provider
    dict set result mode "current"
    dict set result model $model
    dict set result latestModelDate $latest_date
    dict set result totalCostUSD $total_cost
    dict set result latestDayCostUSD $latest_cost
    dict set result latestDayCostDate $latest_cost_date
    dict set result dailyRowCount $entry_count
    return $result
}

proc build_json_all {provider totals} {
    set result [dict create]
    dict set result provider $provider
    dict set result mode "all"
    
    # Sort by cost (descending)
    set sorted_items {}
    dict for {model cost} $totals {
        lappend sorted_items [list $model $cost]
    }
    set sorted_items [lsort -real -index 1 -decreasing $sorted_items]
    
    set models_list {}
    foreach item $sorted_items {
        set model_dict [dict create]
        dict set model_dict model [lindex $item 0]
        dict set model_dict totalCostUSD [lindex $item 1]
        lappend models_list $model_dict
    }
    dict set result models $models_list
    return $result
}

proc main {} {
    package require json
    package require cmdline
    
    set options {
        {provider.arg "codex" "Provider (codex or claude)"}
        {mode.arg "current" "Mode (current or all)"}
        {model.arg "" "Explicit model name to report instead of auto-current"}
        {input.arg "" "Path to codexbar cost JSON (or '-' for stdin)"}
        {days.arg "" "Limit to last N days (based on daily rows)"}
        {format.arg "text" "Output format (text or json)"}
        {pretty "Pretty-print JSON output"}
    }
    
    if {[catch {array set opts [cmdline::getoptions argv $options]} result]} {
        eprint $result
        return 1
    }
    
    # Validate provider
    if {$opts(provider) ni {"codex" "claude"}} {
        eprint "Invalid provider: $opts(provider)"
        return 1
    }
    
    # Validate mode
    if {$opts(mode) ni {"current" "all"}} {
        eprint "Invalid mode: $opts(mode)"
        return 1
    }
    
    # Validate format
    if {$opts(format) ni {"text" "json"}} {
        eprint "Invalid format: $opts(format)"
        return 1
    }
    
    # Parse days if provided
    set days_val ""
    if {$opts(days) ne ""} {
        if {![string is integer -strict $opts(days)] || $opts(days) <= 0} {
            eprint "Invalid days value: $opts(days)"
            return 1
        }
        set days_val $opts(days)
    }
    
    if {[catch {load_payload $opts(input) $opts(provider)} payload]} {
        eprint $payload
        return 1
    }
    
    set entries [parse_daily_entries $payload]
    set entries [filter_by_days $entries $days_val]
    
    if {$opts(mode) eq "current"} {
        set model $opts(model)
        set latest_date ""
        if {$model eq ""} {
            foreach {model latest_date} [pick_current_model $entries] break
        }
        if {$model eq ""} {
            eprint "No model data found in codexbar cost payload."
            return 2
        }
        set totals [aggregate_costs $entries]
        set total_cost ""
        if {[dict exists $totals $model]} {
            set total_cost [dict get $totals $model]
        }
        foreach {latest_cost_date latest_cost} [latest_day_cost $entries $model] break
        
        if {$opts(format) eq "json"} {
            set payload_out [build_json_current \
                $opts(provider) \
                $model \
                $latest_date \
                $total_cost \
                $latest_cost \
                $latest_cost_date \
                [llength $entries]]
            if {$opts(pretty)} {
                puts [::json::dict2json $payload_out]
            } else {
                puts [::json::dict2json $payload_out]
            }
        } else {
            puts [render_text_current \
                $opts(provider) \
                $model \
                $latest_date \
                $total_cost \
                $latest_cost \
                $latest_cost_date \
                [llength $entries]]
        }
        return 0
    }
    
    set totals [aggregate_costs $entries]
    if {[dict size $totals] == 0} {
        eprint "No model breakdowns found in codexbar cost payload."
        return 2
    }
    
    if {$opts(format) eq "json"} {
        set payload_out [build_json_all $opts(provider) $totals]
        if {$opts(pretty)} {
            puts [::json::dict2json $payload_out]
        } else {
            puts [::json::dict2json $payload_out]
        }
    } else {
        puts [render_text_all $opts(provider) $totals]
    }
    return 0
}

if {[info exists argv0] && [file tail $argv0] eq [file tail [info script]]} {
    exit [main]
}
