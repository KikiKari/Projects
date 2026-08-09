#!/usr/bin/env tclsh
# collect_ist_gateway_b.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Setzen der Umgebungsvariablen und Zeitstempel
set BASE_DIR [file normalize "$env(HOME)/.openclaw"]
set OUT_DIR [file normalize "$BASE_DIR/workspace/vscode"]
set NOW_UTC [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
set NOW_LOCAL [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"]
set TS [clock format [clock seconds] -format "%Y%m%d-%H%M%S"]

# Erstellen des Ausgabeverzeichnisses
file mkdir $OUT_DIR

# Dateinamen definieren
set IST_FILE [file join $OUT_DIR "IST-ZUSTAND_GATEWAY-B_NODE7.md"]
set INV_FILE [file join $OUT_DIR "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"]
set CFG_FILE [file join $OUT_DIR "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"]
set ENV_FILE [file join $OUT_DIR "ENV-STATUS_GATEWAY-B_NODE7.md"]
set RUN_FILE [file join $OUT_DIR "RUN-$TS.md"]

# Dateipfade
set OPENCLAW_JSON [file join $BASE_DIR "openclaw.json"]
set ENV_DOT [file join $BASE_DIR ".env"]
set ENV_SYSTEMD [file join $BASE_DIR "gateway.systemd.env"]
set VSCODE_DIR [file join $BASE_DIR ".vscode"]

# Systeminformationen sammeln
set HOSTNAME_FQDN [exec hostname -f]
if {[catch {exec hostname -f} result]} {
    set HOSTNAME_FQDN [exec hostname]
}
set HOSTNAME_SHORT [exec hostname]
set ARCH [exec uname -m]
set KERNEL [exec uname -r]
set OS_PRETTY ""
if {[file exists "/etc/os-release"]} {
    set fd [open "/etc/os-release" r]
    set content [read $fd]
    close $fd
    foreach line [split $content "\n"] {
        if {[string match "PRETTY_NAME=*" $line]} {
            set OS_PRETTY [string range $line 12 end]
            set OS_PRETTY [string trim $OS_PRETTY "\""]
            break
        }
    }
}
set IPV4_ALL ""
if {[catch {exec hostname -I} result]} {
    set IPV4_ALL ""
} else {
    set IPV4_ALL [string trim $result]
}
set PUBLIC_IP ""
if {[catch {exec curl -4 -s --max-time 4 ifconfig.me} result]} {
    set PUBLIC_IP "(nicht ermittelt)"
} else {
    set PUBLIC_IP $result
}
set TAILSCALE_IP ""
if {[catch {exec tailscale ip -4} result]} {
    set TAILSCALE_IP "(nicht ermittelt)"
} else {
    set lines [split $result "\n"]
    set TAILSCALE_IP [lindex $lines 0]
}
set OPENCLAW_VER ""
if {[catch {exec openclaw --version} result]} {
    set OPENCLAW_VER "(nicht ermittelt)"
} else {
    set OPENCLAW_VER $result
}
set NODE_VER ""
if {[catch {exec node -v} result]} {
    set NODE_VER "(nicht ermittelt)"
} else {
    set NODE_VER $result
}

# Fallbacks für leere Werte
if {$PUBLIC_IP eq ""} {set PUBLIC_IP "(nicht ermittelt)"}
if {$TAILSCALE_IP eq ""} {set TAILSCALE_IP "(nicht ermittelt)"}
if {$OPENCLAW_VER eq ""} {set OPENCLAW_VER "(nicht ermittelt)"}
if {$NODE_VER eq ""} {set NODE_VER "(nicht ermittelt)"}

# Erstellen der IST-Datei
set fd [open $IST_FILE w]
puts $fd "# IST-Zustand: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand (lokal): $NOW_LOCAL  "
puts $fd "Stand (UTC): $NOW_UTC"
puts $fd ""
puts $fd "## 1) Identität & System"
puts $fd ""
puts $fd "- Gateway: **B**"
puts $fd "- Node: **7**"
puts $fd "- Hostname (short): \\`${HOSTNAME_SHORT}\\`"
puts $fd "- Hostname (FQDN): \\`${HOSTNAME_FQDN}\\`"
puts $fd "- Architektur: \\`${ARCH}\\`"
puts $fd "- Kernel: \\`${KERNEL}\\`"
puts $fd "- OS: \\`${OS_PRETTY}\\`"
puts $fd "- IPv4 (lokal): \\`${IPV4_ALL}\\`"
puts $fd "- Public IPv4: \\`${PUBLIC_IP}\\`"
puts $fd "- Tailscale IPv4: \\`${TAILSCALE_IP}\\`"
puts $fd "- OpenClaw Version: \\`${OPENCLAW_VER}\\`"
puts $fd "- Node.js Version: \\`${NODE_VER}\\`"
puts $fd ""
puts $fd "## 2) Arbeitsverzeichnisse"
puts $fd ""
puts $fd "- Basis: \\`${BASE_DIR}\\`"
puts $fd "- Funktionell VSCode: \\`${VSCODE_DIR}\\`"
puts $fd "- Workspace Doku: \\`${OUT_DIR}\\`"
puts $fd ""
puts $fd "## 3) Kernartefakte (Existenz)"
puts $fd ""

set openclaw_json_status "fehlt"
if {[file exists $OPENCLAW_JSON]} {
    set openclaw_json_status "vorhanden"
}
puts $fd "- \\`${OPENCLAW_JSON}\\`: $openclaw_json_status"

set env_dot_status "fehlt"
if {[file exists $ENV_DOT]} {
    set env_dot_status "vorhanden"
}
puts $fd "- \\`${ENV_DOT}\\`: $env_dot_status"

set env_systemd_status "fehlt"
if {[file exists $ENV_SYSTEMD]} {
    set env_systemd_status "vorhanden"
}
puts $fd "- \\`${ENV_SYSTEMD}\\`: $env_systemd_status"

set installs_json_status "fehlt"
set installs_json_path [file join $BASE_DIR "plugins" "installs.json"]
if {[file exists $installs_json_path]} {
    set installs_json_status "vorhanden"
}
puts $fd "- \\`${installs_json_path}\\`: $installs_json_status"

set plugin_skills_status "fehlt"
set plugin_skills_path [file join $BASE_DIR "plugin-skills"]
if {[file isdirectory $plugin_skills_path]} {
    set plugin_skills_status "vorhanden"
}
puts $fd "- \\`${plugin_skills_path}\\`: $plugin_skills_status"

puts $fd ""
puts $fd "## 4) Hinweis"
puts $fd ""
puts $fd "Diese Datei wird bei jedem Lauf neu geschrieben."
puts $fd "Zusätzlich wird ein Laufprotokoll als \\`RUN-*.md\\` erzeugt."
close $fd

# Erstellen der Inventar-Datei
set fd [open $INV_FILE w]
puts $fd "# Artefakt-Inventar: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Top-Level in ~/.openclaw"
puts $fd ""
puts $fd "```text"
if {[catch {exec ls -1 $BASE_DIR} result]} {
    # Ignorieren von Fehlern
} else {
    puts $fd $result
}
puts $fd "```"
puts $fd ""
puts $fd "## ~/.openclaw/.vscode"
puts $fd ""
puts $fd "```text"
if {[file isdirectory $VSCODE_DIR]} {
    if {[catch {exec ls -la $VSCODE_DIR} result]} {
        # Ignorieren von Fehlern
    } else {
        puts $fd $result
    }
} else {
    puts $fd "(nicht vorhanden)"
}
puts $fd "```"
puts $fd ""
puts $fd "## plugin-skills/"
puts $fd ""
puts $fd "```text"
if {[file isdirectory $plugin_skills_path]} {
    if {[catch {exec ls -1 $plugin_skills_path} result]} {
        # Ignorieren von Fehlern
    } else {
        puts $fd $result
    }
} else {
    puts $fd "(nicht vorhanden)"
}
puts $fd "```"
puts $fd ""
puts $fd "## openclaw.json Backups"
puts $fd ""
puts $fd "```text"
set backup_files [glob -nocomplain [file join $BASE_DIR "openclaw.json.bak*"]]
if {[llength $backup_files] > 0} {
    foreach file $backup_files {
        puts $fd [file tail $file]
    }
} else {
    puts $fd "(keine gefunden)"
}
puts $fd "```"
close $fd

# Erstellen der Config-Snapshot-Datei
set fd [open $CFG_FILE w]
puts $fd "# OpenClaw Config Snapshot: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Schlüsselpositionen (grep)"
puts $fd ""
puts $fd "```text"
if {[file exists $OPENCLAW_JSON]} {
    if {[catch {exec grep -nE {"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"} $OPENCLAW_JSON} result]} {
        # Ignorieren von Fehlern
    } else {
        puts $fd $result
    }
} else {
    puts $fd "openclaw.json fehlt"
}
puts $fd "```"
puts $fd ""
puts $fd "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)"
puts $fd ""
puts $fd "```json"
if {[file exists $OPENCLAW_JSON]} {
    set fd2 [open $OPENCLAW_JSON r]
    set lines [split [read $fd2] "\n"]
    close $fd2
    set start 579
    set end 779
    set total [llength $lines]
    if {$start < $total} {
        if {$end >= $total} {
            set end [expr {$total - 1}]
        }
        for {set i $start} {$i <= $end} {incr i} {
            puts $fd [lindex $lines $i]
        }
    }
} else {
    puts $fd "{ \"error\": \"openclaw.json fehlt\" }"
}
puts $fd "```"
close $fd

# Erstellen der ENV-Status-Datei
set fd [open $ENV_FILE w]
puts $fd "# ENV-Status: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Dateien"
puts $fd ""
puts $fd "```text"
if {[catch {exec ls -la $ENV_DOT $ENV_SYSTEMD} result]} {
    # Ignorieren von Fehlern
} else {
    puts $fd $result
}
puts $fd "```"
puts $fd ""
puts $fd "## .env (vollständig, ungefiltert)"
puts $fd ""
puts $fd "```dotenv"
if {[file exists $ENV_DOT]} {
    set fd2 [open $ENV_DOT r]
    set content [read $fd2]
    close $fd2
    puts $fd $content
} else {
    puts $fd "# .env fehlt"
}
puts $fd "```"
puts $fd ""
puts $fd "## gateway.systemd.env (vollständig, ungefiltert)"
puts $fd ""
puts $fd "```dotenv"
if {[file exists $ENV_SYSTEMD]} {
    set fd2 [open $ENV_SYSTEMD r]
    set content [read $fd2]
    close $fd2
    puts $fd $content
} else {
    puts $fd "# gateway.systemd.env fehlt"
}
puts $fd "```"
close $fd

# Erstellen der Laufprotokoll-Datei
set fd [open $RUN_FILE w]
puts $fd "# Laufprotokoll Gateway B / Node 7"
puts $fd ""
puts $fd "- Zeit (lokal): $NOW_LOCAL"
puts $fd "- Zeit (UTC): $NOW_UTC"
puts $fd "- Script: [file normalize $argv0]"
puts $fd ""
puts $fd "## Erzeugte Dateien"
puts $fd ""
puts $fd "- [file tail $IST_FILE]"
puts $fd "- [file tail $INV_FILE]"
puts $fd "- [file tail $CFG_FILE]"
puts $fd "- [file tail $ENV_FILE]"
close $fd

# Ausgabe
puts "OK: IST-Zustand erfasst."
puts "Ausgabeordner: $OUT_DIR"
puts "Dateien:"
if {[catch {exec ls -1 $OUT_DIR} result]} {
    # Ignorieren von Fehlern
} else {
    set files [split $result "\n"]
    foreach file $files {
        if {$file ne ""} {
            puts "- $file"
        }
    }
}
