#!/usr/bin/env tclsh
# update-nodes-report.js — portiert nach tcl
# Quelle: javascript, OpenClaw@gateway1:scripts/update-nodes-report.js
# auch in: OpenClaw@gateway2:scripts/update-nodes-report.js
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

package require json
package require fileutil

# Pfade
set DASHBOARD_PATH [file normalize [file join [file dirname $argv0] ../dashboards/nodes-overview.md]]

# Farbcodes für Konsole
array set C [list \
    green  "\033\[32m" \
    yellow "\033\[33m" \
    red    "\033\[31m" \
    blue   "\033\[34m" \
    reset  "\033\[0m" \
]

proc getNodeStatus {} {
    global C
    if {[catch {exec openclaw nodes status --json} result]} {
        puts stderr "${C(red)}❌ Fehler beim Abrufen des Node-Status:${C(reset)} $result"
        return {}
    }
    
    if {[catch {::json::json2dict $result} parsed]} {
        puts stderr "${C(red)}❌ Fehler beim Parsen des JSON:${C(reset)} $parsed"
        return {}
    }
    
    return $parsed
}

proc updateDashboard {nodes} {
    global DASHBOARD_PATH C
    
    # Aktuelles Datum
    set now [clock format [clock seconds] -format "%d.%m.%Y, %H:%M:%S" -timezone :Europe/Berlin]
    
    # Manuelle Ergänzung statischer Konfigurationen (da nicht alle Infos über CLI)
    array set nodeConfig {
        1 {name "Gateway" os "Ubuntu 22.04" ip "152.53.145.65" wg "10.10.0.1" tunnel "–" mode "Gateway"}
        2 {name "Netcup Server" os "Ubuntu 22.04" ip "78.46.123.10" wg "10.10.0.2" tunnel "–" mode "Node"}
        3 {name "xNetX VPS" os "Debian 11" ip "5.45.105.20" wg "–" tunnel "Port 18794" mode "Node"}
        4 {name "Webhosting" os "Shared Linux" ip "–" wg "–" tunnel "–" mode "–"}
        5 {name "Redmi Note 11" os "Android" ip "–" wg "10.10.0.5" tunnel "–" mode "Node"}
        6 {name "Lenovo (Win)" os "Windows 11" ip "–" wg "–" tunnel "–" mode "Node"}
    }
    
    set rows {}
    foreach nodeId [lsort -integer [array names nodeConfig]] {
        set cfg $nodeConfig($nodeId)
        
        # Suche passenden Node in der Liste
        set node {}
        foreach n $nodes {
            if {[dict get $n nodeId] eq $nodeId} {
                set node $n
                break
            }
            if {[dict exists $n name] && [string match *[lindex $cfg 1]* [dict get $n name]]} {
                set node $n
                break
            }
        }
        
        # Status bestimmen
        set statusVPN "⚠️"
        if {$node ne ""} {
            if {[dict get $node status] eq "paired"} {
                set statusVPN "✅"
            } else {
                set statusVPN "🔴"
            }
        }
        
        set statusSSH "❌"
        if {[lindex $cfg 5] ne "–"} {
            set statusSSH "✅"
        }
        
        set sshKey "❌"
        switch $nodeId {
            1 {set sshKey "Local (id_ed25519)"}
            2 - 3 {set sshKey "❌ (Pending)"}
        }
        
        set lastCheck "–"
        if {$node ne "" && [dict exists $node lastSeen]} {
            set timestamp [expr {[dict get $node lastSeen] * 1000}]
            set lastCheck [clock format [expr {$timestamp / 1000}] -format "%d.%m.%Y, %H:%M:%S" -timezone :Europe/Berlin]
        }
        
        lappend rows "| $nodeId    | [lindex $cfg 1] | [lindex $cfg 3] | [lindex $cfg 7] | [lindex $cfg 11]       | [lindex $cfg 9]             | [lindex $cfg 5] | $statusVPN | $statusSSH | $sshKey | $lastCheck |"
    }
    
    set content "# Nodes Overview (Network Status)

| Node | Name          | OS           | IP             | Mode       | Primär WG IP       | Sekundär/SSH Tunnel | StatusVPN | StatusSSH | SSH Key (Deployed) | Letzter Check       |
|------|---------------|--------------|----------------|------------|--------------------|---------------------|-----------|-----------|---------------------|---------------------|
[join $rows \n]

> 💡 **Legende:** 
> - **Primär WG IP**: Die WireGuard-VPN-IP des Nodes
> - **Sekundär/SSH Tunnel**: Fallback-Mechanismus (z. B. Reverse-Tunnel)
> - **StatusVPN**: Verbunden über OpenClaw/WireGuard
> - **StatusSSH**: SSH-Zugriff via Reverse-Tunnel aktiv
> - **SSH Key (Deployed)**: Zeigt an, ob der Gateway-Schlüssel (\`id_ed25519\`) auf dem Ziel bereitgestellt ist
> - Letzter Stand: **$now CET**

*Größe: ~1.8 KB | Automatisch aktualisiert via \`update-nodes-report.js\`*"
    
    if {[catch {::fileutil::writeFile $DASHBOARD_PATH $content} error]} {
        puts stderr "${C(red)}❌ Fehler beim Schreiben der Datei:${C(reset)} $error"
    } else {
        puts "${C(green)}✅ Dashboard aktualisiert:${C(reset)} $DASHBOARD_PATH"
    }
}

# Hauptausführung
puts "${C(blue)}🔄 Aktualisiere Nodes-Übersicht...${C(reset)}"
set nodes [getNodeStatus]
updateDashboard $nodes]
