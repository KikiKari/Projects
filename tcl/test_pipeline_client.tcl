#!/usr/bin/env tclsh
# test_pipeline_client.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require sha256
package require json

# Einfache assertion-Funktion
proc assert_equal {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: expected '$expected', got '$actual'"
    }
}

proc assert_deep_equal {actual expected} {
    if {$actual ne $expected} {
        error "Deep assertion failed: expected '$expected', got '$actual'"
    }
}

proc assert_not_equal {actual expected} {
    if {$actual eq $expected} {
        error "Assertion not equal failed: both are '$actual'"
    }
}

# Strukturierte Daten kopieren
proc structured_clone {data} {
    return $data
}

# Asynchrone Operationen simulieren
proc set_immediate {script} {
    after 0 $script
}

# Client-Umgebung erstellen
proc client {} {
    # Lokale Speicherdaten
    array set local_data {tlc-settings(universalCaptionApiKey) "universal-secret" tlc-settings(pairingCode) "pair-secret"}
    array set session_data {}
    
    # Datenbank-Simulation
    array set rows {}
    set received {}
    
    # Storage-Objekt simulieren
    proc create_storage {data_array_name} {
        return [list \
            get [list get_proc $data_array_name] \
            set [list set_proc $data_array_name] \
        ]
    }
    
    proc get_proc {data_array_name keys} {
        upvar #$data_array_name data
        set result {}
        foreach key $keys {
            if {[info exists data($key)]} {
                lappend result [list $key $data($key)]
            } else {
                lappend result [list $key ""]
            }
        }
        return $result
    }
    
    proc set_proc {data_array_name values} {
        upvar #$data_array_name data
        dict for {key value} $values {
            set data($key) $value
        }
        return {}
    }
    
    # IndexedDB-Transaktion simulieren
    proc transaction {} {
        return [dict create \
            objectStore [list object_store_proc] \
        ]
    }
    
    proc object_store_proc {args} {
        switch [lindex $args 0] {
            put {
                set row [lindex $args 1]
                set ::rows([dict get $row eventId]) [structured_clone $row]
                return [dict create result "" onsuccess ""]
            }
            delete {
                set id [lindex $args 1]
                unset -nocomplain ::rows($id)
                return [dict create result "" onsuccess ""]
            }
            getAll {
                set all_rows {}
                foreach row [array names ::rows] {
                    lappend all_rows [structured_clone $::rows($row)]
                }
                return [dict create result $all_rows onsuccess ""]
            }
        }
    }
    
    # Fetch-Funktion simulieren
    proc fetch {url options} {
        if {[string match "*events" $url]} {
            lappend ::received [dict get $options body]
            return [dict create ok 1 json [list json_proc [expr {[llength $::received]}]]]
        }
        return [dict create ok 1 json [list json_proc {}]]
    }
    
    proc json_proc {cursor_val} {
        return [dict create cursor $cursor_val]
    }
    
    # Crypto-API simulieren
    proc crypto_get_random_values {array} {
        # Dummy-Implementierung
        return $array
    }
    
    # Globale Variablen für den Kontext
    set ::local [array get local_data]
    set ::session [array get session_data]
    set ::rows [array get rows]
    set ::received $received
    
    # Pipeline-Client laden und ausführen
    set script_path [file join [file dirname $::argv0] ".." "browser-extension" "pipeline-client.js"]
    if {[file exists $script_path]} {
        source $script_path
    } else {
        error "Pipeline client script not found: $script_path"
    }
    
    return [dict create \
        api $::TLCPipelines \
        local [array get local_data] \
        session [array get session_data] \
        received $::received \
        rows [array get rows] \
    ]
}

# Testfall
proc test_one_key_two_tabs {} {
    set c [client]
    set api [dict get $c api]
    
    # Start calls
    ${api}::start 1 "doc-a"
    ${api}::start 2 "doc-b"
    
    # Publish calls
    ${api}::publish 1 "chat" "{\"text\": \"first\"}" "pair-secret" "chat" "doc-a"
    ${api}::start 1 "doc-c"
    ${api}::publish 1 "chat" "{\"text\": \"late\"}" "late" "chat" "doc-a"
    ${api}::publish 1 "chat" "{\"text\": \"current\"}" "current" "chat"
    
    # Flush loop
    for {set i 0} {$i < 30} {incr i} {
        after 0 update
        ${api}::flush
    }
    
    # Assertions
    set rows_dict [dict get $c rows]
    assert_equal [dict size $rows_dict] 0
    
    set received_list [dict get $c received]
    set chats {}
    foreach row $received_list {
        if {[dict get $row pipeline] eq "chat" && [dict get $row availability] eq "available"} {
            lappend chats $row
        }
    }
    
    set doc_ids {}
    foreach chat $chats {
        lappend doc_ids [dict get $chat documentId]
    }
    assert_deep_equal $doc_ids [list "doc-a" "doc-a" "doc-c"]
    
    if {[llength $chats] > 0} {
        assert_equal [dict get [lindex $chats 0] raw] "[credential removed]"
        assert_equal [dict get [lindex $chats 0] credentialsRedacted] true
    }
    
    set b {}
    foreach row $received_list {
        if {[dict get $row documentId] eq "doc-b"} {
            set b $row
            break
        }
    }
    
    if {[llength $chats] > 0 && $b ne ""} {
        assert_not_equal [dict get [lindex $chats 0] tabId] [dict get $b tabId]
        assert_equal [dict get [lindex $chats 0] clientId] [dict get $b clientId]
    }
    
    set event_ids {}
    foreach row $received_list {
        lappend event_ids [dict get $row eventId]
    }
    set unique_event_ids [lsort -unique $event_ids]
    assert_equal [llength $unique_event_ids] [llength $event_ids]
    
    puts "Test passed!"
}

# Test ausführen
test_one_key_two_tabs
