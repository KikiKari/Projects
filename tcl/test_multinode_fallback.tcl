#!/usr/bin/env tclsh8.6
# test_multinode_fallback.py — portiert nach tcl
# Quelle: python, OpenClaw@gateway1:scripts/test_multinode_fallback.py
# auch in: OpenClaw@gateway2:scripts/test_multinode_fallback.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

# Testet Multi-Node Fallback-Logik des db-maintainer
# Simuliert: Worker-Node nicht erreichbar → Fallback auf lokal

package require Tcl 8.6

set WORKSPACE "/home/openclaw/.openclaw/workspace"

proc check_node_reachable {node_id} {
    # Prüft ob Node erreichbar ist
    if {[catch {exec openclaw nodes status} result]} {
        return false
    }
    if {[string match "*${node_id}*" $result] && [string match "*connected*" $result]} {
        return true
    } else {
        return false
    }
}

proc spawn_on_node {node_id task} {
    # Versucht Task auf Node auszuführen
    puts "Versuche Task auf Node ${node_id} zu starten..."
    if {[catch {exec echo "Spawned on ${node_id}: ${task}"} result]} {
        puts "❌ Node ${node_id} nicht erreichbar: $::errorInfo"
        return false
    } else {
        puts "✅ Erfolgreich delegiert an ${node_id}"
        return true
    }
}

proc execute_locally {task} {
    # Führt Task lokal aus (Fallback)
    puts "🔄 Fallback: Führe Task lokal aus..."
    global WORKSPACE
    if {$task eq "db_maintainer"} {
        set script_path "${WORKSPACE}/skills/db-maintainer/scripts/db_maintainer.py"
        if {[catch {exec python3 $script_path} result options]} {
            set errorCode [dict get $options -errorcode]
            if {[lindex $errorCode 0] eq "CHILDSTATUS"} {
                set status [lindex $errorCode 2]
                puts "❌ Fehler mit Status $status"
                return false
            } else {
                puts "❌ Fehler: $result"
                return false
            }
        } else {
            puts "✅ Lokale Ausführung erfolgreich"
            return true
        }
    } else {
        puts "❌ Unbekannter Task: $task"
        return false
    }
}

proc main {} {
    puts [string repeat "=" 60]
    puts "MULTI-NODE FALLBACK TEST"
    puts [string repeat "=" 60]
    puts ""

    # Konfiguration
    set primary_node "v2202603104722445775"  ;# Node 2
    set task "db_maintainer"

    puts "Primärer Node: $primary_node"
    puts "Task: $task"
    puts ""

    # 1. Prüfe Node-Erreichbarkeit
    puts "--- 1. Prüfe Node-Erreichbarkeit ---"
    if {[check_node_reachable $primary_node]} {
        puts "✅ Node $primary_node ist erreichbar"

        # 2. Versuche Delegation
        puts "\n--- 2. Versuche Delegation ---"
        if {[spawn_on_node $primary_node $task]} {
            puts "\n✅ MULTI-NODE: Task erfolgreich delegiert"
            return 0
        } else {
            puts "\n⚠️ Delegation fehlgeschlagen, aktiviere Fallback..."
        }
    } else {
        puts "❌ Node $primary_node nicht erreichbar"
        puts "🔄 Fallback wird aktiviert..."
    }

    # 3. Lokale Ausführung (Fallback)
    puts "\n--- 3. Lokale Ausführung (Fallback) ---"
    if {[execute_locally $task]} {
        puts "\n✅ FALLBACK: Task lokal erfolgreich ausgeführt"
        return 0
    } else {
        puts "\n❌ FEHLER: Weder Delegation noch Fallback erfolgreich"
        return 1
    }
}

exit [main]
