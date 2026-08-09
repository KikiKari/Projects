#!/usr/bin/env tclsh
# gemini-ask.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

# gemini-ask.tcl - CLI tool for Google Gemini API
# 
# Usage:
#   tclsh gemini-ask.tcl "Your question here"
#   echo "Your question" | tclsh gemini-ask.tcl
#   tclsh gemini-ask.tcl --file prompt.txt
#   tclsh gemini-ask.tcl --model gemini-pro "Your question"
# 
# Environment:
#   GEMINI_API_KEY - Required API key
#   GEMINI_MODEL   - Optional default model (default: gemini-pro)

package require http
package require json
package require fileutil

# Set default model from environment or default value
set DEFAULT_MODEL [expr {[info exists ::env(GEMINI_MODEL)] ? $::env(GEMINI_MODEL) : "gemini-pro"}]

# Function to show usage and exit
proc show_usage {} {
    puts stderr "Error: No prompt provided"
    puts stderr "Usage: gemini-ask \"your question\""
    puts stderr "       gemini-ask --model gemini-pro \"your question\""
    puts stderr "       echo \"your question\" | gemini-ask"
    exit 1
}

# Function to make API call to Gemini
proc call_gemini_api {api_key model_name prompt system_prompt} {
    set url "https://generativelanguage.googleapis.com/v1beta/models/${model_name}:generateContent?key=${api_key}"
    
    # Prepare request body
    if {$system_prompt ne ""} {
        set json_data [::json::write object \
            contents [::json::write array \
                [::json::write object \
                    role "user" \
                    parts [::json::write array [::json::write object text $system_prompt]]] \
                [::json::write object \
                    role "model" \
                    parts [::json::write array [::json::write object text "Understood. I will follow that instruction."]]] \
                [::json::write object \
                    role "user" \
                    parts [::json::write array [::json::write object text $prompt]]]] \
            generationConfig [::json::write object \
                maxOutputTokens 8192 \
                temperature 0.7 \
                topP 0.95]]
    } else {
        set json_data [::json::write object \
            contents [::json::write array \
                [::json::write object \
                    role "user" \
                    parts [::json::write array [::json::write object text $prompt]]]] \
            generationConfig [::json::write object \
                maxOutputTokens 8192 \
                temperature 0.7 \
                topP 0.95]]
    }
    
    # Make HTTP POST request
    set token [::http::geturl $url -method POST -headers [list Content-Type application/json] -query $json_data]
    set status [::http::status $token]
    set code [::http::ncode $token]
    set data [::http::data $token]
    ::http::cleanup $token
    
    if {$status eq "ok" && $code == 200} {
        return $data
    } else {
        error "HTTP Error: $code - $data"
    }
}

# Main procedure
proc main {} {
    global DEFAULT_MODEL
    
    # Check API key
    if {![info exists ::env(GEMINI_API_KEY)] || $::env(GEMINI_API_KEY) eq ""} {
        puts stderr "Error: GEMINI_API_KEY environment variable is required"
        exit 1
    }
    
    set api_key $::env(GEMINI_API_KEY)
    
    # Parse arguments
    set prompt ""
    set modelName $DEFAULT_MODEL
    set args $::argv
    set systemPrompt ""
    
    # Check for --model flag
    set modelIndex [lsearch -exact $args "--model"]
    if {$modelIndex == -1} {
        set modelIndex [lsearch -exact $args "-m"]
    }
    
    if {$modelIndex != -1 && [expr {$modelIndex + 1}] < [llength $args]} {
        set modelName [lindex $args [expr {$modelIndex + 1}]]
        set args [lreplace $args $modelIndex [expr {$modelIndex + 1}]]
    }
    
    # Check for --system flag
    set systemIndex [lsearch -exact $args "--system"]
    if {$systemIndex == -1} {
        set systemIndex [lsearch -exact $args "-s"]
    }
    
    if {$systemIndex != -1 && [expr {$systemIndex + 1}] < [llength $args]} {
        set systemPrompt [lindex $args [expr {$systemIndex + 1}]]
        set args [lreplace $args $systemIndex [expr {$systemIndex + 1}]]
    }
    
    # Check for --file flag
    set fileIndex [lsearch -exact $args "--file"]
    if {$fileIndex == -1} {
        set fileIndex [lsearch -exact $args "-f"]
    }
    
    if {$fileIndex != -1} {
        if {[expr {$fileIndex + 1}] >= [llength $args]} {
            puts stderr "Error: No file specified"
            exit 1
        }
        set filePath [lindex $args [expr {$fileIndex + 1}]]
        if {[catch {::fileutil::cat $filePath} prompt]} {
            puts stderr "Error reading file: $prompt"
            exit 1
        }
        set args [lreplace $args $fileIndex [expr {$fileIndex + 1}]]
    } elseif {[llength $args] > 0} {
        set prompt [join $args " "]
    } elseif {[info exists ::env(STDIN_IS_TTY)] && $::env(STDIN_IS_TTY) eq "0"} {
        # Read from stdin when not a TTY
        set prompt [read stdin]
    } else {
        # Try to read from stdin if available
        if {[catch {read stdin 0} stdin_data]} {
            set stdin_data ""
        }
        if {$stdin_data ne ""} {
            set prompt $stdin_data
        }
    }
    
    if {[string trim $prompt] eq ""} {
        show_usage
    }
    
    # Call API and handle response
    if {[catch {call_gemini_api $api_key $modelName $prompt $systemPrompt} result]} {
        puts stderr "Error: $result"
        if {[string match "*API key*" $result]} {
            puts stderr "Make sure GEMINI_API_KEY is set correctly"
        }
        exit 1
    }
    
    # Parse JSON response
    if {[catch {::json::json2dict $result} response_dict]} {
        puts stderr "Error parsing response: $response_dict"
        exit 1
    }
    
    # Extract text from response
    if {[dict exists $response_dict candidates 0 content parts 0 text]} {
        set text [dict get $response_dict candidates 0 content parts 0 text]
        puts $text
    } else {
        puts stderr "Error: Could not extract text from response"
        puts stderr $result
        exit 1
    }
}

# Run main
main
