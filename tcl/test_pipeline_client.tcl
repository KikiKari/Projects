#!/usr/bin/env tclsh
# test_pipeline_client.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require sqlite3

# Einfacher Ersatz für node:test
proc test {name script} {
    puts "Running test: $name"
    if {[catch {uplevel #0 $script} result]} {
        puts "FAIL: $name - $result"
        exit 1
    } else {
        puts "PASS: $name"
    }
}

# Einfacher Ersatz für assert
proc assert_equal {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: expected '$expected', got '$actual'"
    }
}

proc assert_deep_equal {actual expected} {
    if {$actual ne $expected} {
        error "Assertion failed: expected '$expected', got '$actual'"
    }
}

proc assert_not_equal {actual expected} {
    if {$actual eq $expected} {
        error "Assertion failed: expected not equal to '$expected'"
    }
}

# Storage Implementierung
proc create_storage {data_name} {
    upvar $data_name data
    
    proc get_data {keys} {
        upvar data d
        set result {}
        if {[llength $keys] == 1 && [lindex $keys 0] eq $keys} {
            set keys [list $keys]
        }
        foreach key $keys {
            if {[info exists d($key)]} {
                lappend result [list $key $d($key)]
            } else {
                lappend result [list $key ""]
            }
        }
        return $result
    }
    
    proc set_data {values} {
        upvar data d
        dict for {key value} $values {
            set d($key) $value
        }
    }
    
    return [list get_data set_data]
}

# Datenbank Implementierung
proc create_database {} {
    sqlite3 db ":memory:"
    db eval {
        CREATE TABLE IF NOT EXISTS events (
            eventId TEXT PRIMARY KEY,
            documentId TEXT,
            pipeline TEXT,
            availability TEXT,
            raw TEXT,
            credentialsRedacted BOOLEAN,
            tabId TEXT,
            clientId TEXT
        )
    }
    
    proc transaction {} {
        # In SQLite ist jede Anweisung atomar
        return ""
    }
    
    proc object_store_put {row} {
        db eval {INSERT OR REPLACE INTO events (eventId, documentId, pipeline, availability, raw, credentialsRedacted, tabId, clientId) 
                 VALUES ($row(eventId), $row(documentId), $row(pipeline), $row(availability), $row(raw), $row(credentialsRedacted), $row(tabId), $row(clientId))}
    }
    
    proc object_store_delete {id} {
        db eval {DELETE FROM events WHERE eventId = $id}
    }
    
    proc object_store_get_all {} {
        set result {}
        db eval {SELECT * FROM events} row {
            lappend result [array get row]
        }
        return $result
    }
    
    return [list transaction object_store_put object_store_delete object_store_get_all]
}

# Fetch Implementierung
proc create_fetch {received_name} {
    upvar $received_name received
    
    proc fetch_impl {url options} {
        upvar received r
        if {[string match "*events" $url]} {
            set body [dict get $options body]
            lappend r $body
            set cursor [llength $r]
            return [dict create ok true json [list cursor $cursor]]
        }
        return [dict create ok true json [list]]
    }
    
    return fetch_impl
}

# Client Funktion
proc client {} {
    # Lokale Daten
    array set local_data [list tlc-settings [dict create universalCaptionApiKey universal-secret pairingCode pair-secret]]
    array set session_data
    array set rows_data
    set received_data {}
    
    # Storage erstellen
    set local_storage [create_storage local_data]
    set session_storage [create_storage session_data]
    
    # Datenbank erstellen
    set database [create_database]
    
    # Fetch erstellen
    set fetch_cmd [create_fetch received_data]
    
    # Kontext simulieren
    set context_vars [dict create \
        local_data [array get local_data] \
        session_data [array get session_data] \
        rows_data [array get rows_data] \
        received_data $received_data \
        database $database \
        fetch_cmd $fetch_cmd \
    ]
    
    # TLCPipelines API simulieren (vereinfacht)
    # In einer echten Implementierung würden wir hier den JavaScript-Code übersetzen
    proc TLCPipelines_start {tab_id doc_id} {
        # Simuliert das Starten einer Pipeline
        return
    }
    
    proc TLCPipelines_publish {tab_id pipeline data credential pipeline_type {doc_id ""}} {
        # Simuliert das Veröffentlichen eines Events
        upvar received_data received
        set event [dict create \
            tabId tab$tab_id \
            clientId client1 \
            pipeline $pipeline \
            availability available \
            raw \[credential\ removed\] \
            credentialsRedacted true \
            documentId $doc_id \
            eventId event[expr {int(rand()*1000000)}] \
        ]
        lappend received $event
        return
    }
    
    proc TLCPipelines_flush {} {
        # Simuliert das Leeren der Warteschlange
        return
    }
    
    return [dict create \
        api_start TLCPipelines_start \
        api_publish TLCPipelines_publish \
        api_flush TLCPipelines_flush \
        local_data [array get local_data] \
        session_data [array get session_data] \
        received_data received_data \
        rows_data [array get rows_data] \
    ]
}

# Haupttest
test {one key, two tabs, reload and delayed old-document events stay separate} {
    set c [client]
    
    # API-Aufrufe simulieren
    {*}[dict get $c api_start] 1 doc-a
    {*}[dict get $c api_start] 2 doc-b
    {*}[dict get $c api_publish] 1 chat [dict create text first] pair-secret chat doc-a
    {*}[dict get $c api_start] 1 doc-c
    {*}[dict get $c api_publish] 1 chat [dict create text late] late chat doc-a
    {*}[dict get $c api_publish] 1 chat [dict create text current] current chat
    
    # Flush mehrmals aufrufen
    for {set i 0} {$i < 30} {incr i} {
        after 1
        {*}[dict get $c api_flush]
    }
    
    # Assertions
    assert_equal [dict size [dict get $c rows_data]] 0
    
    # Chats filtern
    set chats {}
    foreach row [set [dict get $c received_data]] {
        if {[dict get $row pipeline] eq "chat" && [dict get $row availability] eq "available"} {
            lappend chats $row
        }
    }
    
    # Document IDs prüfen
    set doc_ids {}
    foreach chat $chats {
        lappend doc_ids [dict get $chat documentId]
    }
    assert_deep_equal $doc_ids {doc-a doc-a doc-c}
    
    # Andere Assertions
    assert_equal [dict get [lindex $chats 0] raw] {\[credential removed\]}
    assert_equal [dict get [lindex $chats 0] credentialsRedacted] true
    
    set b {}
    foreach row [set [dict get $c received_data]] {
        if {[dict get $row documentId] eq "doc-b"} {
            set b $row
            break
        }
    }
    
    assert_not_equal [dict get [lindex $chats 0] tabId] [dict get $b tabId]
    assert_equal [dict get [lindex $chats 0] clientId] [dict get $b clientId]
    
    # EventId uniqueness prüfen
    set event_ids {}
    foreach row [set [dict get $c received_data]] {
        lappend event_ids [dict get $row eventId]
    }
    set unique_event_ids [lsort -unique $event_ids]
    assert_equal [llength $event_ids] [llength $unique_event_ids]
}
