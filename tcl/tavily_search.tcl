#!/usr/bin/env tclsh
# tavily_search.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/tavily/scripts/tavily_search.py
# auch in: OpenClaw@gateway2:skills/tavily/scripts/tavily_search.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Tavily AI Search - Optimized search for LLMs and AI applications
# Requires: Tcl 8.6 with http, json, and tls packages

package require http
package require json
package require tls

# Initialize TLS for HTTPS support
http::register https 443 [list ::tls::socket]

proc search {
    query 
    api_key 
    {search_depth "basic"} 
    {topic "general"} 
    {max_results 5} 
    {include_answer true} 
    {include_raw_content false} 
    {include_images false} 
    {include_domains ""} 
    {exclude_domains ""}
} {
    # Check if API key is provided
    if {$api_key eq ""} {
        return [dict create \
            error "Tavily API key required. Get one at https://tavily.com" \
            setup_instructions "Set TAVILY_API_KEY environment variable or pass --api-key"]
    }

    # Build the request payload
    set payload [dict create \
        api_key $api_key \
        query $query \
        search_depth $search_depth \
        topic $topic \
        max_results $max_results \
        include_answer $include_answer \
        include_raw_content $include_raw_content \
        include_images $include_images]
    
    if {$include_domains ne ""} {
        dict set payload include_domains $include_domains
    }
    
    if {$exclude_domains ne ""} {
        dict set payload exclude_domains $exclude_domains
    }
    
    set json_payload [json::write object {*}$payload]
    
    # Make HTTP POST request to Tavily API
    set url "https://api.tavily.com/search"
    set token [http::geturl $url -method POST -headers [list Content-Type application/json] -query $json_payload]
    set status [http::status $token]
    set code [http::ncode $token]
    
    if {$status eq "ok" && $code == 200} {
        set data [http::data $token]
        http::cleanup $token
        set response [json::json2dict $data]
        
        # Process response into standardized format
        set results [dict get $response results]
        set processed_results {}
        foreach item $results {
            lappend processed_results [dict create \
                title [dict get $item title] \
                url [dict get $item url] \
                content [dict get $item content] \
                score [dict get $item score]]
        }
        
        set images_data {}
        if {[dict exists $response images]} {
            set images_data [dict get $response images]
        }
        
        set usage_data [dict get $response usage]
        
        return [dict create \
            success true \
            query $query \
            answer [dict get $response answer] \
            results $processed_results \
            images $images_data \
            response_time [dict get $response response_time] \
            usage $usage_data]
    } else {
        set error_msg "HTTP Error: $code"
        if {$status eq "error"} {
            set error_msg [http::error $token]
        }
        http::cleanup $token
        return [dict create error $error_msg query $query]
    }
}

proc format_output {result {raw_json false}} {
    if {$raw_json} {
        puts [json::write indented $result]
        return
    }
    
    if {[dict exists $result error]} {
        puts stderr "Error: [dict get $result error]"
        if {[dict exists $result install_command]} {
            puts stderr "\nTo install: [dict get $result install_command]"
        }
        if {[dict exists $result setup_instructions]} {
            puts stderr "\nSetup: [dict get $result setup_instructions]"
        }
        exit 1
    }
    
    # Format human-readable output
    puts "Query: [dict get $result query]"
    puts "Response time: [dict get $result response_time]s"
    set usage [dict get $result usage]
    puts "Credits used: [dict get $usage credits]\n"
    
    if {[dict exists $result answer] && [dict get $result answer] ne ""} {
        puts "=== AI ANSWER ==="
        puts [dict get $result answer]
        puts ""
    }
    
    if {[llength [dict get $result results]] > 0} {
        puts "=== RESULTS ==="
        set i 1
        foreach item [dict get $result results] {
            puts ""
            puts "$i. [dict get $item title]"
            puts "   URL: [dict get $item url]"
            puts "   Score: [format "%.3f" [dict get $item score]]"
            set content [dict get $item content]
            if {[string length $content] > 200} {
                set content [string range $content 0 199]...
            }
            puts "   $content"
            incr i
        }
    }
    
    set images [dict get $result images]
    if {[llength $images] > 0} {
        puts "\n=== IMAGES ([llength $images]) ==="
        set count 0
        foreach img_url $images {
            if {$count >= 5} break
            puts "   $img_url"
            incr count
        }
    }
}

proc main {} {
    global argv argc env
    
    # Parse command line arguments manually
    set args $argv
    set query ""
    set api_key ""
    set search_depth "basic"
    set topic "general"
    set max_results 5
    set include_answer true
    set include_raw_content false
    set include_images false
    set include_domains ""
    set exclude_domains ""
    set raw_json false
    
    # Simple argument parsing
    set i 0
    while {$i < [llength $args]} {
        set arg [lindex $args $i]
        switch -exact -- $arg {
            "--api-key" {
                incr i
                set api_key [lindex $args $i]
            }
            "--depth" {
                incr i
                set search_depth [lindex $args $i]
            }
            "--topic" {
                incr i
                set topic [lindex $args $i]
            }
            "--max-results" {
                incr i
                set max_results [lindex $args $i]
            }
            "--no-answer" {
                set include_answer false
            }
            "--raw-content" {
                set include_raw_content true
            }
            "--images" {
                set include_images true
            }
            "--include-domains" {
                incr i
                set include_domains [lindex $args $i]
            }
            "--exclude-domains" {
                incr i
                set exclude_domains [lindex $args $i]
            }
            "--json" {
                set raw_json true
            }
            default {
                if {$query eq "" && [string index $arg 0] ne "-"} {
                    set query $arg
                }
            }
        }
        incr i
    }
    
    # If no query provided in args, check if it's the only argument
    if {$query eq "" && [llength $args] == 1 && [string index [lindex $args 0] 0] ne "-"} {
        set query [lindex $args 0]
    }
    
    # Get API key from args or environment
    if {$api_key eq "" && [info exists env(TAVILY_API_KEY)]} {
        set api_key $env(TAVILY_API_KEY)
    }
    
    # Validate required arguments
    if {$query eq ""} {
        puts stderr "Usage: [file tail [info script]] <query> \[options\]"
        puts stderr "Run with --help for more information"
        exit 1
    }
    
    # Execute search
    set result [search \
        $query \
        $api_key \
        $search_depth \
        $topic \
        $max_results \
        $include_answer \
        $include_raw_content \
        $include_images \
        $include_domains \
        $exclude_domains]
    
    # Output results
    format_output $result $raw_json
}

# Handle direct execution
if {[info script] eq $argv0} {
    main
}
