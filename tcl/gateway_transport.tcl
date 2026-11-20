#!/usr/bin/env tclsh
# gateway_transport.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
# Erzeugt: 2026-11-20 durch ABSTRACTIONS_MANAGER.py

# Gateway-authenticated transport with manager-owned attempt records.
#
# An attempt is saved before submission. If its outcome is uncertain, subsequent
# calls only query the same node and attempt; they do not submit it again.

package require http
package require json
package require uuid

namespace eval gateway_transport {
    variable version 1.0
    
    # Exception class for unresolved transport issues
    proc TransportUnresolved {msg} {
        error "TransportUnresolved: $msg"
    }
    
    # Use the local Gateway credential without changing its configuration.
    proc gateway_token {} {
        set token [expr {[info exists ::env(OPENCLAW_GATEWAY_TOKEN)] ? $::env(OPENCLAW_GATEWAY_TOKEN) : ""}]
        if {[string trim $token] ne ""} {
            return [string trim $token]
        }
        
        set config_path ""
        if {[info exists ::env(OPENCLAW_CONFIG_PATH)] && $::env(OPENCLAW_CONFIG_PATH) ne ""} {
            set config_path $::env(OPENCLAW_CONFIG_PATH)
        } else {
            if {$::tcl_platform(platform) eq "windows"} {
                set home_dir $::env(USERPROFILE)
            } else {
                set home_dir $::env(HOME)
            }
            set config_path [file join $home_dir .openclaw openclaw.json]
        }
        
        if {![file exists $config_path]} {
            return ""
        }
        
        if {[catch {set fp [open $config_path r]}] || [catch {set content [read $fp]}] || [catch {close $fp}]} {
            return ""
        }
        
        if {[catch {set config [::json::json2dict $content]}]} {
            return ""
        }
        
        if {[dict exists $config gateway auth token]} {
            set token [dict get $config gateway auth token]
            if {[string is alnum $token] && ![string match "\${*" $token]} {
                return [string trim $token]
            }
        }
        return ""
    }
    
    # GatewayTransport class implementation
    oo::class create GatewayTransport {
        variable state save url token timeout interval opener clock sleep
        
        constructor {state_ref save_proc url_val token_val {timeout_val 3900} {interval_val 3} {opener_val ""} {clock_val ""} {sleep_val ""}} {
            # Parse URL
            if {![regexp {^(https?)://([^/]+)(/.*)?$} $url_val -> scheme hostname path]} {
                error "invalid Gateway URL"
            }
            
            if {$scheme eq "http" && ![string match {*127.0.0.1*} $hostname] && ![string match {*localhost*} $hostname] && ![string match {*::1*} $hostname]} {
                error "unencrypted Gateway must use loopback"
            }
            
            if {[string trim $token_val] eq "" || $timeout_val <= 0 || $interval_val <= 0} {
                error "Gateway token and positive timeouts required"
            }
            
            set state $state_ref
            set save $save_proc
            set url $url_val
            set token [string trim $token_val]
            set timeout $timeout_val
            set interval $interval_val
            
            if {$opener_val eq ""} {
                set opener gateway_transport::_default_opener
            } else {
                set opener $opener_val
            }
            
            if {$clock_val eq ""} {
                set clock gateway_transport::_default_clock
            } else {
                set clock $clock_val
            }
            
            if {$sleep_val eq ""} {
                set sleep gateway_transport::_default_sleep
            } else {
                set sleep $sleep_val
            }
        }
        
        # Default HTTP opener using Tcl's http package
        method _default_opener {req timeout} {
            set url [dict get $req url]
            set headers [dict get $req headers]
            set data [dict get $req data]
            
            set http_token [::http::geturl $url -headers $headers -query $data -timeout [expr {$timeout * 1000}]]
            set status [::http::status $http_token]
            if {$status ne "ok"} {
                ::http::cleanup $http_token
                error "HTTP request failed: $status"
            }
            set body [::http::data $http_token]
            ::http::cleanup $http_token
            return $body
        }
        
        # Default monotonic clock
        method _default_clock {} {
            return [clock seconds]
        }
        
        # Default sleep function
        method _default_sleep {seconds} {
            after [expr {int($seconds * 1000)}]
        }
        
        # Make a request to the gateway
        method _request {node request {device_id ""}} {
            set payload [::json::dict2json [dict create node $node device_id $device_id request $request]]
            set headers [list Authorization "Bearer $token" Content-Type "application/json"]
            
            set req_timeout 40
            if {$node eq "node4"} {
                set req_timeout 150
            }
            
            set req_dict [dict create url $url headers $headers data $payload]
            
            if {[catch {set raw [$opener $req_dict $req_timeout]} error]} {
                gateway_transport::TransportUnresolved "Gateway request failed"
            }
            
            if {[string length $raw] > 4000000} {
                error "response too large"
            }
            
            if {[catch {set data [::json::json2dict $raw]}]} {
                error "invalid gateway response"
            }
            
            if {![dict exists $data result]} {
                error "invalid gateway response"
            }
            
            if {$device_id ne "" && [dict exists $data device_id] && [dict get $data device_id] ne $device_id} {
                error "gateway device identity mismatch"
            }
            
            return [dict get $data result]
        }
        
        # Check node availability
        method available {} {
            set result [my _request node1 [dict create operation availability]]
            if {![dict size $result]} {
                gateway_transport::TransportUnresolved "invalid node availability"
            }
            return $result
        }
        
        # Release a completed job
        method _release {original entry} {
            if {[dict exists $entry released] && [dict get $entry released]} {
                return
            }
            
            if {[catch {
                set result [my _request [dict get $original selected_node] \
                    [dict create operation release \
                        job_id [dict get $original job_id] \
                        attempt_id [dict get $original attempt_id]] \
                    [dict get $original selected_device_id]]
            }]} {
                return ;# Retry cleanup later
            }
            
            if {[dict exists $result status] && [dict get $result status] eq "released" &&
                [dict get $result job_id] eq [dict get $original job_id] &&
                [dict get $result attempt_id] eq [dict get $original attempt_id] &&
                [dict get $result selected_node] eq [dict get $original selected_node] &&
                [dict get $result target_language] eq [dict get $original target_language]} {
                
                dict set entry released true
                $save $state
            }
        }
        
        # Release pending jobs
        method release_pending {} {
            if {![dict exists $state auftraege]} {
                return
            }
            
            set auftraege [dict get $state auftraege]
            dict for {key entry} $auftraege {
                if {[dict exists $entry status] && 
                    ([dict get $entry status] in {completed rejected failed}) &&
                    [dict exists $entry job]} {
                    
                    my _release [dict get $entry job] $entry
                }
            }
        }
        
        # Record a rejected job
        method reject {job reason} {
            if {![dict exists $job source_sha256] || ![dict exists $job target_language]} {
                return
            }
            
            set key [format "%s:%s" [dict get $job source_sha256] [dict get $job target_language]]
            
            if {![dict exists $state auftraege $key]} {
                return
            }
            
            set entry [dict get $state auftraege $key]
            if {![dict size $entry] || [dict get $entry status] ne "completed"} {
                return
            }
            
            if {![dict exists $entry job attempt_id] || 
                [dict get $entry job attempt_id] ne [dict get $job attempt_id]} {
                gateway_transport::TransportUnresolved "rejected attempt identity mismatch"
            }
            
            dict set entry status rejected
            dict set entry validation_error [string range [toString $reason] 0 499]
            $save $state
        }
        
        # Main transport method
        method call {job} {
            if {![dict exists $job source_sha256] || ![dict exists $job target_language] || 
                ![dict exists $job selected_device_id]} {
                error "missing source identity"
            }
            
            set key [format "%s:%s" [dict get $job source_sha256] [dict get $job target_language]]
            
            if {![dict exists $state auftraege]} {
                dict set state auftraege [dict create]
            }
            
            set entries [dict get $state auftraege]
            set entry {}
            
            if {[dict exists $entries $key]} {
                set entry [dict get $entries $key]
            }
            
            set fresh false
            if {[dict size $entry] && [dict get $entry status] eq "rejected"} {
                my _release [dict get $entry job] $entry
                if {![dict exists $entry released] || ![dict get $entry released]} {
                    gateway_transport::TransportUnresolved "rejected attempt release is unresolved"
                }
                
                set previous $entry
                set original [dict merge $job [dict create attempt_id [::uuid::uuid generate]]]
                set entry [dict create job $original status submitted]
                
                set prev_attempts {}
                if {[dict exists $previous previous_attempts]} {
                    set prev_attempts [dict get $previous previous_attempts]
                }
                
                lappend prev_attempts [dict create \
                    job_id [dict get $previous job attempt_id] \
                    attempt_id [dict get $previous job attempt_id] \
                    selected_node [dict get $previous job selected_node] \
                    validation_error [dict get $previous validation_error]]
                
                dict set entry previous_attempts $prev_attempts
                dict set entries $key $entry
                dict set state auftraege $entries
                $save $state
                set fresh true
            } else {
                set fresh [expr {$entry eq ""}]
            }
            
            if {$entry eq ""} {
                set original [dict merge $job [dict create attempt_id [::uuid::uuid generate]]]
                set entry [dict create job $original status submitted]
                dict set entries $key $entry
                dict set state auftraege $entries
                # If this write fails there must be no remote submission.
                $save $state
            } else {
                set original [dict get $entry job]
            }
            
            # Update job with original values
            dict for {k v} $original {
                dict set job $k $v
            }
            
            if {[dict exists $entry response]} {
                my _release $original $entry
                return [dict get $entry response]
            }
            
            if {[dict exists $entry status] && [dict get $entry status] in {failed unknown}} {
                gateway_transport::TransportUnresolved "attempt requires reconciliation"
            }
            
            set status {}
            if {$fresh} {
                if {[catch {
                    set status [my _request [dict get $original selected_node] \
                        [dict create operation execute job $original] \
                        [dict get $original selected_device_id]]
                }]} {
                    # The request may have been accepted. Query, never resend.
                    set status {}
                }
            }
            
            set deadline [expr {[$clock] + $timeout}]
            while {true} {
                if {$status eq ""} {
                    set status [my _request [dict get $original selected_node] \
                        [dict create operation status \
                            job_id [dict get $original job_id] \
                            attempt_id [dict get $original attempt_id]] \
                        [dict get $original selected_device_id]]
                }
                
                if {![dict size $status]} {
                    gateway_transport::TransportUnresolved "attempt is not known by the node"
                }
                
                if {[dict get $status job_id] ne [dict get $original job_id] ||
                    [dict get $status attempt_id] ne [dict get $original attempt_id] ||
                    [dict get $status selected_node] ne [dict get $original selected_node] ||
                    [dict get $status target_language] ne [dict get $original target_language]} {
                    gateway_transport::TransportUnresolved "status identity mismatch"
                }
                
                set state_val [dict get $status status]
                if {$state_val eq "completed"} {
                    set response [dict get $status response]
                    if {![dict size $response] || [dict get $response status] ne "ok" ||
                        [dict get $response job_id] ne [dict get $original job_id] ||
                        [dict get $response selected_node] ne [dict get $original selected_node] ||
                        [dict get $response target_language] ne [dict get $original target_language] ||
                        ![dict exists $response code] || [string trim [dict get $response code]] eq ""} {
                        gateway_transport::TransportUnresolved "invalid translation result"
                    }
                    
                    dict set entry response $response
                    dict set entry status completed
                    $save $state
                    my _release $original $entry
                    return $response
                }
                
                if {$state_val in {failed unknown}} {
                    dict set entry status $state_val
                    $save $state
                    if {$state_val eq "failed"} {
                        my _release $original $entry
                    }
                    gateway_transport::TransportUnresolved "attempt requires reconciliation"
                }
                
                if {$state_val ne "running" || [$clock] >= $deadline} {
                    gateway_transport::TransportUnresolved "attempt is unresolved"
                }
                
                $sleep $interval
                set status {}
            }
        }
    }
}

# Helper procedure to convert any value to string
proc toString {value} {
    return $value
}
