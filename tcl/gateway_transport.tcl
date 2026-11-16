#!/usr/bin/env tclsh8.6
# gateway_transport.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-16 durch ABSTRACTIONS_MANAGER.py

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

package require http
package require json
package require uuid

# Custom exception class equivalent
proc TransportUnresolved {msg} {
    error "TransportUnresolved: $msg"
}

proc gateway_token {} {
    # Use the local Gateway credential without changing its configuration.
    set token [string trim [expr {[info exists ::env(OPENCLAW_GATEWAY_TOKEN)] ? $::env(OPENCLAW_GATEWAY_TOKEN) : ""}]]
    if {$token ne ""} {
        return $token
    }
    
    set configPath ""
    if {[info exists ::env(OPENCLAW_CONFIG_PATH)] && $::env(OPENCLAW_CONFIG_PATH) ne ""} {
        set configPath $::env(OPENCLAW_CONFIG_PATH)
    } else {
        if {$::tcl_platform(platform) eq "windows"} {
            set homeDir $::env(USERPROFILE)
        } else {
            set homeDir $::env(HOME)
        }
        set configPath [file join $homeDir ".openclaw" "openclaw.json"]
    }
    
    if {![file exists $configPath]} {
        return ""
    }
    
    if {[catch {set fp [open $configPath r]}] || [catch {set content [read $fp]}] || [catch {close $fp}]} {
        return ""
    }
    
    if {[catch {set config [::json::json2dict $content]}]} {
        return ""
    }
    
    if {[dict exists $config gateway auth token]} {
        set token [dict get $config gateway auth token]
        if {[string match -nocase "\${*" $token]} {
            return ""
        }
        return [string trim $token]
    }
    
    return ""
}

proc validate_url {url} {
    if {![regexp {^(https?)://([^/]+)(.*)$} $url -> scheme hostname path]} {
        error "invalid Gateway URL"
    }
    
    if {$scheme ni {"http" "https"}} {
        error "invalid Gateway URL"
    }
    
    if {$scheme eq "http" && $hostname ni {"127.0.0.1" "localhost" "::1"}} {
        error "unencrypted Gateway must use loopback"
    }
    
    return [list $scheme $hostname $path]
}

proc GatewayTransport {stateVar saveCmd url token args} {
    upvar $stateVar state
    
    array set opts [list timeout 3900 interval 3 opener "" clock "" sleep ""]
    array set opts $args
    
    lassign [validate_url $url] scheme hostname path
    
    if {[string trim $token] eq "" || $opts(timeout) <= 0 || $opts(interval) <= 0} {
        error "Gateway token and positive timeouts required"
    }
    
    # Create namespace for instance variables
    set ns [namespace current]::[namespace qualifiers [namespace current]]_[uuid::uuid generate]
    namespace eval $ns {}
    
    set ${ns}::stateVar $stateVar
    set ${ns}::saveCmd $saveCmd
    set ${ns}::url $url
    set ${ns}::token [string trim $token]
    set ${ns}::timeout $opts(timeout)
    set ${ns}::interval $opts(interval)
    set ${ns}::opener $opts(opener)
    set ${ns}::clock $opts(clock)
    set ${ns}::sleep $opts(sleep)
    
    if {$opts(opener) eq ""} {
        set ${ns}::opener ::GatewayTransport_request
    }
    
    if {$opts(clock) eq ""} {
        set ${ns}::clock ::GatewayTransport_monotonic_time
    }
    
    if {$opts(sleep) eq ""} {
        set ${ns}::sleep ::after
    }
    
    # Return command that will call methods on this instance
    return [list ::GatewayTransport_instance $ns]
}

proc GatewayTransport_instance {ns method args} {
    switch $method {
        request {
            set node [lindex $args 0]
            set request [lindex $args 1]
            set device_id [lindex $args 2]
            return [GatewayTransport_request_method $ns $node $request $device_id]
        }
        available {
            return [GatewayTransport_available_method $ns]
        }
        release {
            set original [lindex $args 0]
            set entry [lindex $args 1]
            return [GatewayTransport_release_method $ns $original $entry]
        }
        release_pending {
            return [GatewayTransport_release_pending_method $ns]
        }
        call {
            set job [lindex $args 0]
            return [GatewayTransport_call_method $ns $job]
        }
    }
}

proc GatewayTransport_request_method {ns node request {device_id ""}} {
    upvar ${ns}::stateVar stateVar
    upvar ${ns}::saveCmd saveCmd
    upvar ${ns}::url url
    upvar ${ns}::token token
    upvar ${ns}::opener opener
    
    set payload [::json::dict2json [dict create node $node device_id $device_id request $request]]
    
    set headers [list Authorization "Bearer $token" Content-Type "application/json"]
    
    if {[catch {set result [$opener $url $payload $headers [expr {$node eq "node4" ? 150000 : 40000}]]} error]} {
        TransportUnresolved "Gateway request failed: $error"
    }
    
    set raw $result
    if {[string length $raw] > 4000000} {
        TransportUnresolved "response too large"
    }
    
    if {[catch {set data [::json::json2dict $raw]} error]} {
        TransportUnresolved "invalid gateway response: $error"
    }
    
    if {![dict exists $data result]} {
        TransportUnresolved "invalid gateway response"
    }
    
    if {$device_id ne "" && [dict get $data device_id] ne $device_id} {
        TransportUnresolved "gateway device identity mismatch"
    }
    
    return [dict get $data result]
}

proc GatewayTransport_available_method {ns} {
    set result [GatewayTransport_request_method $ns "node1" [dict create operation "availability"]]
    if {![dict size $result]} {
        TransportUnresolved "invalid node availability"
    }
    return $result
}

proc GatewayTransport_release_method {ns original entry} {
    upvar ${ns}::stateVar stateVar
    upvar ${ns}::saveCmd saveCmd
    
    if {[dict get $entry released]} {
        return
    }
    
    if {[catch {
        set result [GatewayTransport_request_method $ns [dict get $original selected_node] \
            [dict create operation "release" job_id [dict get $original job_id] attempt_id [dict get $original attempt_id]] \
            [dict get $original selected_device_id]]
    } error]} {
        return ;# Retry cleanup later; the result is durable in manager state.
    }
    
    if {[dict get $result status] eq "released" &&
        [dict get $result job_id] eq [dict get $original job_id] &&
        [dict get $result attempt_id] eq [dict get $original attempt_id] &&
        [dict get $result selected_node] eq [dict get $original selected_node] &&
        [dict get $result target_language] eq [dict get $original target_language]} {
        
        dict set entry released true
        uplevel #0 $saveCmd
    }
}

proc GatewayTransport_release_pending_method {ns} {
    upvar ${ns}::stateVar stateVar
    upvar $stateVar state
    
    foreach {key entry} [dict get $state auftraege] {
        if {[dict get $entry status] in {"completed" "failed" "unknown"} &&
            [dict exists $entry job]} {
            GatewayTransport_release_method $ns [dict get $entry job] $entry
        }
    }
}

proc GatewayTransport_call_method {ns jobDict} {
    upvar ${ns}::stateVar stateVar
    upvar ${ns}::saveCmd saveCmd
    upvar ${ns}::timeout timeout
    upvar ${ns}::interval interval
    upvar ${ns}::clock clock
    upvar ${ns}::sleep sleep
    upvar $stateVar state
    
    if {![dict exists $jobDict source_sha256] || ![dict exists $jobDict target_language] || 
        ![dict exists $jobDict selected_device_id]} {
        error "missing source identity"
    }
    
    set key "[dict get $jobDict source_sha256]:[dict get $jobDict target_language]"
    
    if {![dict exists $state auftraege]} {
        dict set state auftraege [dict create]
    }
    
    set entries [dict get $state auftraege]
    
    if {[dict exists $entries $key]} {
        set entry [dict get $entries $key]
        set fresh false
    } else {
        set original [dict merge $jobDict [dict create attempt_id [uuid::uuid generate]]]
        set entry [dict create job $original status "submitted"]
        dict set entries $key $entry
        dict set state auftraege $entries
        
        # If this write fails there must be no remote submission.
        uplevel #0 $saveCmd
        set fresh true
    }
    
    set original [dict get $entry job]
    
    # Update the passed job dictionary
    foreach {k v} $original {
        dict set jobDict $k $v
    }
    
    if {[dict exists $entry response]} {
        GatewayTransport_release_method $ns $original $entry
        return [dict get $entry response]
    }
    
    if {[dict get $entry status] in {"failed" "unknown"}} {
        TransportUnresolved "attempt requires reconciliation"
    }
    
    set status ""
    if {$fresh} {
        if {[catch {
            set status [GatewayTransport_request_method $ns [dict get $original selected_node] \
                [dict create operation "execute" job $original] [dict get $original selected_device_id]]
        } error]} {
            # The request may have been accepted. Query, never resend.
        }
    }
    
    set deadline [expr {[$clock] + $timeout}]
    
    while {true} {
        if {$status eq ""} {
            set status [GatewayTransport_request_method $ns [dict get $original selected_node] \
                [dict create operation "status" job_id [dict get $original job_id] attempt_id [dict get $original attempt_id]] \
                [dict get $original selected_device_id]]
        }
        
        if {![dict size $status]} {
            TransportUnresolved "attempt is not known by the node"
        }
        
        if {[dict get $status job_id] ne [dict get $original job_id] ||
            [dict get $status attempt_id] ne [dict get $original attempt_id] ||
            [dict get $status selected_node] ne [dict get $original selected_node] ||
            [dict get $status target_language] ne [dict get $original target_language]} {
            TransportUnresolved "status identity mismatch"
        }
        
        set state_val [dict get $status status]
        if {$state_val eq "completed"} {
            set response [dict get $status response]
            
            if {![dict exists $response status] || [dict get $response status] ne "ok" ||
                [dict get $response job_id] ne [dict get $original job_id] ||
                [dict get $response selected_node] ne [dict get $original selected_node] ||
                [dict get $response target_language] ne [dict get $original target_language] ||
                ![dict exists $response code] || [string trim [dict get $response code]] eq ""} {
                TransportUnresolved "invalid translation result"
            }
            
            dict set entry response $response
            dict set entry status "completed"
            dict set state auftraege $entries
            uplevel #0 $saveCmd
            
            GatewayTransport_release_method $ns $original $entry
            return $response
        }
        
        if {$state_val in {"failed" "unknown"}} {
            dict set entry status $state_val
            dict set state auftraege $entries
            uplevel #0 $saveCmd
            
            GatewayTransport_release_method $ns $original $entry
            TransportUnresolved "attempt requires reconciliation"
        }
        
        if {$state_val ne "running" || [expr {[$clock]}] >= $deadline} {
            TransportUnresolved "attempt is unresolved"
        }
        
        # Sleep for interval seconds
        if {[info commands $sleep] eq $sleep} {
            $sleep [expr {int($interval * 1000)}]
        } else {
            after [expr {int($interval * 1000)}]
        }
        
        set status ""
    }
}

# Helper procedures for HTTP requests and timing
proc GatewayTransport_request {url payload headers timeout} {
    package require http
    
    set tok [http::geturl $url -headers $headers -query $payload -timeout $timeout]
    set status [http::status $tok]
    set body [http::data $tok]
    http::cleanup $tok
    
    if {$status ne "ok"} {
        error "HTTP request failed with status: $status"
    }
    
    return $body
}

proc GatewayTransport_monotonic_time {} {
    # Return time in seconds since epoch (approximation of monotonic time)
    return [expr {[clock seconds] + [clock microseconds]/1000000.0}]
}
