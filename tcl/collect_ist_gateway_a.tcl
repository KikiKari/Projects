#!/usr/bin/env tclsh
# collect_ist_gateway_a.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Set variables
set BASE_DIR [file join $env(HOME) .openclaw]
set OUT_DIR [file join $BASE_DIR workspace vscode]
set NOW_UTC [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
set NOW_LOCAL [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"]
set TS [clock format [clock seconds] -format "%Y%m%d-%H%M%S"]

# Create output directory
file mkdir $OUT_DIR

set IST_FILE [file join $OUT_DIR "IST-ZUSTAND_GATEWAY-A_NODE1.md"]
set INV_FILE [file join $OUT_DIR "ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md"]
set CFG_FILE [file join $OUT_DIR "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md"]
set ENV_FILE [file join $OUT_DIR "ENV-STATUS_GATEWAY-A_NODE1.md"]
set RUN_FILE [file join $OUT_DIR "RUN-$TS.md"]

set OPENCLAW_JSON [file join $BASE_DIR "openclaw.json"]
set ENV_DOT [file join $BASE_DIR ".env"]
set ENV_SYSTEMD [file join $BASE_DIR "gateway.systemd.env"]
set VSCODE_DIR [file join $BASE_DIR ".vscode"]

# Get system information
set HOSTNAME_FQDN [exec hostname -f]
if {[catch {set HOSTNAME_FQDN}]} {
    set HOSTNAME_FQDN [exec hostname]
}
set HOSTNAME_SHORT [exec hostname]
set ARCH [exec uname -m]
set KERNEL [exec uname -r]
set OS_PRETTY ""
if {[file exists "/etc/os-release"]} {
    set fd [open "/etc/os-release" r]
    while {[gets $fd line] != -1} {
        if {[string match "PRETTY_NAME=*" $line]} {
            set OS_PRETTY [string range $line 12 end]
            set OS_PRETTY [string trim $OS_PRETTY "\""]
            break
        }
    }
    close $fd
}
set IPV4_ALL ""
if {[catch {set IPV4_ALL [exec hostname -I]}]} {
    set IPV4_ALL ""
} else {
    set IPV4_ALL [string trim $IPV4_ALL]
}
set PUBLIC_IP ""
if {[catch {set PUBLIC_IP [exec curl -4 -s --max-time 4 ifconfig.me]}]} {
    set PUBLIC_IP "(nicht ermittelt)"
}
set TAILSCALE_IP ""
if {[catch {set TAILSCALE_IP [exec tailscale ip -4]}]} {
    set TAILSCALE_IP "(nicht ermittelt)"
} else {
    set TAILSCALE_IP [lindex [split $TAILSCALE_IP "\n"] 0]
}
set OPENCLAW_VER ""
if {[catch {set OPENCLAW_VER [exec openclaw --version]}]} {
    set OPENCLAW_VER "(nicht ermittelt)"
}
set NODE_VER ""
if {[catch {set NODE_VER [exec node -v]}]} {
    set NODE_VER "(nicht ermittelt)"
}

# Create IST file
set fd [open $IST_FILE w]
puts $fd "# IST-Zustand: Gateway A / Node 1"
puts $fd ""
puts $fd "Stand (lokal): $NOW_LOCAL  "
puts $fd "Stand (UTC): $NOW_UTC"
puts $fd ""
puts $fd "## 1) Identitaet & System"
puts $fd ""
puts $fd "- Gateway: **A**"
puts $fd "- Node: **1**"
puts $fd "- Hostname (short): `$HOSTNAME_SHORT`"
puts $fd "- Hostname (FQDN): `$HOSTNAME_FQDN`"
puts $fd "- Architektur: `$ARCH`"
puts $fd "- Kernel: `$KERNEL`"
puts $fd "- OS: `$OS_PRETTY`"
puts $fd "- IPv4 (lokal): `$IPV4_ALL`"
puts $fd "- Public IPv4: `$PUBLIC_IP`"
puts $fd "- Tailscale IPv4: `$TAILSCALE_IP`"
puts $fd "- OpenClaw Version: `$OPENCLAW_VER`"
puts $fd "- Node.js Version: `$NODE_VER`"
puts $fd ""
puts $fd "## 2) Arbeitsverzeichnisse"
puts $fd ""
puts $fd "- Basis: `$BASE_DIR`"
puts $fd "- Funktionell VSCode: `$VSCODE_DIR`"
puts $fd "- Workspace Doku: `$OUT_DIR`"
puts $fd ""
puts $fd "## 3) Kernartefakte (Existenz)"
puts $fd ""
set openclaw_json_status "fehlt"
if {[file exists $OPENCLAW_JSON]} {
    set openclaw_json_status "vorhanden"
}
puts $fd "- `$OPENCLAW_JSON`: $openclaw_json_status"

set env_dot_status "fehlt"
if {[file exists $ENV_DOT]} {
    set env_dot_status "vorhanden"
}
puts $fd "- `$ENV_DOT`: $env_dot_status"

set env_systemd_status "fehlt"
if {[file exists $ENV_SYSTEMD]} {
    set env_systemd_status "vorhanden"
}
puts $fd "- `$ENV_SYSTEMD`: $env_systemd_status"

set installs_json_status "fehlt"
if {[file exists [file join $BASE_DIR plugins installs.json]]} {
    set installs_json_status "vorhanden"
}
puts $fd "- `[file join $BASE_DIR plugins installs.json]`: $installs_json_status"

set plugin_skills_status "fehlt"
if {[file isdirectory [file join $BASE_DIR plugin-skills]]} {
    set plugin_skills_status "vorhanden"
}
puts $fd "- `[file join $BASE_DIR plugin-skills]`: $plugin_skills_status"
close $fd

# Create inventory file
set fd [open $INV_FILE w]
puts $fd "# Artefakt-Inventar: Gateway A / Node 1"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Top-Level in ~/.openclaw"
puts $fd ""
puts $fd "```text"
if {[file isdirectory $BASE_DIR]} {
    set files [glob -nocomplain -directory $BASE_DIR *]
    foreach f $files {
        puts $fd [file tail $f]
    }
}
puts $fd "```"
puts $fd ""
puts $fd "## ~/.openclaw/.vscode"
puts $fd ""
puts $fd "```text"
if {[file isdirectory $VSCODE_DIR]} {
    if {[catch {exec ls -la $VSCODE_DIR} result]} {
        puts $fd $result
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
if {[file isdirectory [file join $BASE_DIR plugin-skills]]} {
    set files [glob -nocomplain -directory [file join $BASE_DIR plugin-skills] *]
    foreach f $files {
        puts $fd [file tail $f]
    }
} else {
    puts $fd "(nicht vorhanden)"
}
puts $fd "```"
puts $fd ""
puts $fd "## openclaw.json Backups"
puts $fd ""
puts $fd "```text"
set backup_files [glob -nocomplain [file join $BASE_DIR openclaw.json.bak*]]
if {[llength $backup_files] > 0} {
    foreach f $backup_files {
        puts $fd [file tail $f]
    }
} else {
    puts $fd "(keine gefunden)"
}
puts $fd "```"
close $fd

# Create config snapshot file
set fd [open $CFG_FILE w]
puts $fd "# OpenClaw Config Snapshot: Gateway A / Node 1"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Schluesselpositionen (grep)"
puts $fd ""
puts $fd "```text"
if {[file exists $OPENCLAW_JSON]} {
    if {[catch {exec grep -nE {"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"} $OPENCLAW_JSON} result]} {
        # Ignore error
    } else {
        puts $fd $result
    }
} else {
    puts $fd "openclaw.json fehlt"
}
puts $fd "```"
puts $fd ""
puts $fd "## Ausschnitt gateway/session/auth"
puts $fd ""
puts $fd "```json"
if {[file exists $OPENCLAW_JSON]} {
    if {[catch {exec sed -n {580,780p} $OPENCLAW_JSON} result]} {
        # Ignore error
    } else {
        puts $fd $result
    }
} else {
    puts $fd "{ \"error\": \"openclaw.json fehlt\" }"
}
puts $fd "```"
close $fd

# Create env status file
set fd [open $ENV_FILE w]
puts $fd "# ENV-Status: Gateway A / Node 1"
puts $fd ""
puts $fd "Stand: $NOW_LOCAL"
puts $fd ""
puts $fd "## Dateien"
puts $fd ""
puts $fd "```text"
if {[file exists $ENV_DOT] || [file exists $ENV_SYSTEMD]} {
    if {[catch {exec ls -la $ENV_DOT $ENV_SYSTEMD} result]} {
        # Ignore error
    } else {
        puts $fd $result
    }
}
puts $fd "```"
puts $fd ""
puts $fd "## .env (vollstaendig)"
puts $fd ""
puts $fd "```dotenv"
if {[file exists $ENV_DOT]} {
    set env_fd [open $ENV_DOT r]
    while {[gets $env_fd line] != -1} {
        puts $fd $line
    }
    close $env_fd
} else {
    puts $fd "# .env fehlt"
}
puts $fd "```"
puts $fd ""
puts $fd "## gateway.systemd.env (vollstaendig)"
puts $fd ""
puts $fd "```dotenv"
if {[file exists $ENV_SYSTEMD]} {
    set systemd_fd [open $ENV_SYSTEMD r]
    while {[gets $systemd_fd line] != -1} {
        puts $fd $line
    }
    close $systemd_fd
} else {
    puts $fd "# gateway.systemd.env fehlt"
}
puts $fd "```"
close $fd

# Create run file
set fd [open $RUN_FILE w]
puts $fd "# Laufprotokoll Gateway A / Node 1"
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

# Print success message
puts "OK: IST-Zustand erfasst."
if {[catch {exec ls -1 $OUT_DIR} result]} {
    # Ignore error
} else {
    set lines [split $result "\n"]
    foreach line $lines {
        if {$line ne ""} {
            puts "- $line"
        }
    }
}
