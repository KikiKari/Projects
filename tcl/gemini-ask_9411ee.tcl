#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "1695c21069b3ed6fb17ad251eedb34ebbf7e8c047bd943b816a438755168f874", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "tcl"}
# gemini-ask.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
# auch in: OpenClaw@gateway2:scripts/gemini-ask.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

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
#   GEMini_MODEL   - Optional default model (default: gemini-pro)

package require http
package require tls
package require json

# Initialize TLS for HTTPS support
http::register https 443 [list ::tls::socket]

set DEFAULT_MODEL [expr {[info exists env(GEMINI_MODEL)] ? $env(GEMINI_MODEL) : "gemini-pro"}]

proc main {} {
    global argv argc env DEFAULT_MODEL
    
    # Check API key
    if {![info exists env(GEMINI_API_KEY)] || $env(GEMINI_API_KEY) eq ""} {
        puts stderr "Error: GEMINI_API_KEY environment variable is required"
        exit 1
    }
    
    # Parse arguments
    set prompt ""
    set modelName $DEFAULT_MODEL
    set args $argv
    
    # Check for --model flag
    set modelIndex [lsearch -exact $args "--model"]
    if {$modelIndex == -1} {
        set modelIndex [lsearch -exact $args "-m"]
    }
    
    if {$modelIndex != -1 && [expr {$modelIndex + 1}] < [llength $args]} {
        set modelName [lindex $args [expr {$modelIndex + 1}]]
        set args [lreplace $args $modelIndex [expr {$modelIndex + 1}]]
    }
    
    # Check for --system flag (system prompt)
    set systemPrompt ""
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
        if {[catch {open $filePath r} fh]} {
            puts stderr "Error: Cannot read file $filePath: $fh"
            exit 1
        }
        set prompt [read $fh]
        close $fh
        set args [lreplace $args $fileIndex [expr {$fileIndex + 1}]]
    } elseif {[llength $args] > 0} {
        set prompt [join $args " "]
    } elseif {[info exists env(GEMINI_STDIN)] && $env(GEMINI_STDIN) eq "true"} {
        # Read from stdin when explicitly set
        set prompt [read stdin]
    } elseif {! [info exists env(GEMINI_STDIN)] && [llength $argv] == 0} {
        # Try to read from stdin if no args and not TTY
        if {[catch {gets stdin line}]} {
            # If we can't read from stdin, continue with empty prompt
        } else {
            append prompt $line "\n"
            while {[gets stdin line] >= 0} {
                append prompt $line "\n"
            }
        }
    }
    
    if {[string trim $prompt] eq ""} {
        puts stderr "Error: No prompt provided"
        puts stderr "Usage: gemini-ask \"your question\""
        puts stderr "       gemini-ask --model gemini-pro \"your question\""
        puts stderr "       echo \"your question\" | gemini-ask"
        exit 1
    }
    
    # Call Gemini API
    if {[catch {call_gemini_api $modelName $prompt $systemPrompt} result]} {
        puts stderr "Error: $result"
        if {[string first "API key" $result] != -1} {
            puts stderr "Make sure GEMINI_API_KEY is set correctly"
        }
        exit 1
    } else {
        puts $result
    }
}

proc call_gemini_api {modelName prompt systemPrompt} {
    global env
    
    set apiKey $env(GEMINI_API_KEY)
    set url "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey"
    
    # Prepare request body
    if {$systemPrompt ne ""} {
        # Create chat history with system prompt
        set requestBody [dict create contents [list \
            [dict create role user parts [list [dict create text $systemPrompt]]] \
            [dict create role model parts [list [dict create text "Understood. I will follow that instruction."]]] \
            [dict create role user parts [list [dict create text $prompt]]] \
        ]]
    } else {
        set requestBody [dict create contents [list \
            [dict create role user parts [list [dict create text $prompt]]] \
        ]]
    }
    
    # Add generation config
    dict set requestBody generationConfig [dict create \
        maxOutputTokens 8192 \
        temperature 0.7 \
        topP 0.95 \
    ]
    
    # Convert to JSON
    set jsonBody [::json::write object {*}$requestBody]
    
    # Make HTTP request
    set headers [list Content-Type application/json]
    set token [http::geturl $url -headers $headers -query $jsonBody -method POST]
    
    set status [http::status $token]
    set code [http::ncode $token]
    set body [http::data $token]
    
    http::cleanup $token
    
    if {$status != "ok" || $code != 200} {
        error "HTTP Error: Status $status, Code $code, Body: $body"
    }
    
    # Parse response
    if {[catch {::json::json2dict $body} responseDict]} {
        error "Failed to parse JSON response: $responseDict"
    }
    
    # Extract text from response
    if {[dict exists $responseDict candidates 0 content parts 0 text]} {
        return [dict get $responseDict candidates 0 content parts 0 text]
    } else {
        error "Unexpected response format"
    }
}

# Run main function
main
