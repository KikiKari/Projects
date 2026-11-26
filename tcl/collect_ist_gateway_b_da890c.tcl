#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "b31a2fff16db97eaa6798232efd218cee5c1a21d32791add7d55e4b05578ec57", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "tcl"}
# collect_ist_gateway_b.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6

# Hilfsfunktion für Shell-Kommandos
proc exec_safe {cmd} {
    if {[catch {exec {*}$cmd} result]} {
        return ""
    }
    return $result
}

# Hilfsfunktion für Datei-Check
proc file_status {filepath} {
    if {[file exists $filepath]} {
        if {[file isdirectory $filepath]} {
            return "vorhanden"
        } else {
            return "vorhanden"
        }
    } else {
        return "fehlt"
    }
}

# Variablen setzen
set BASE_DIR [file normalize "$env(HOME)/.openclaw"]
set OUT_DIR [file normalize "$BASE_DIR/workspace/vscode"]

# Zeitstempel
set now_utc [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
set now_local [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %Z"]
set ts [clock format [clock seconds] -format "%Y%m%d-%H%M%S"]

# Ausgabeverzeichnis erstellen
file mkdir $OUT_DIR

# Dateipfade
set IST_FILE [file join $OUT_DIR "IST-ZUSTAND_GATEWAY-B_NODE7.md"]
set INV_FILE [file join $OUT_DIR "ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"]
set CFG_FILE [file join $OUT_DIR "OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"]
set ENV_FILE [file join $OUT_DIR "ENV-STATUS_GATEWAY-B_NODE7.md"]
set RUN_FILE [file join $OUT_DIR "RUN-$ts.md"]

# Konfigurationspfade
set OPENCLAW_JSON [file join $BASE_DIR "openclaw.json"]
set ENV_DOT [file join $BASE_DIR ".env"]
set ENV_SYSTEMD [file join $BASE_DIR "gateway.systemd.env"]
set VSCODE_DIR [file join $BASE_DIR ".vscode"]

# Systeminformationen sammeln
set HOSTNAME_FQDN [exec_safe {hostname -f}]
if {$HOSTNAME_FQDN eq ""} {
    set HOSTNAME_FQDN [exec_safe {hostname}]
}
set HOSTNAME_SHORT [exec_safe {hostname}]
set ARCH [exec_safe {uname -m}]
set KERNEL [exec_safe {uname -r}]

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

set IPV4_ALL [exec_safe {hostname -I}]
if {$IPV4_ALL ne ""} {
    set IPV4_ALL [string trim $IPV4_ALL]
}

set PUBLIC_IP [exec_safe {curl -4 -s --max-time 4 ifconfig.me}]
if {$PUBLIC_IP eq ""} {
    set PUBLIC_IP "(nicht ermittelt)"
}

set TAILSCALE_IP [exec_safe {tailscale ip -4}]
if {$TAILSCALE_IP ne ""} {
    # Nur erste Zeile nehmen
    set TAILSCALE_IP [lindex [split $TAILSCALE_IP "\n"] 0]
} else {
    set TAILSCALE_IP "(nicht ermittelt)"
}

set OPENCLAW_VER [exec_safe {openclaw --version}]
if {$OPENCLAW_VER eq ""} {
    set OPENCLAW_VER "(nicht ermittelt)"
}

set NODE_VER [exec_safe {node -v}]
if {$NODE_VER eq ""} {
    set NODE_VER "(nicht ermittelt)"
}

# IST-Zustand Datei schreiben
set fd [open $IST_FILE w]
puts $fd "# IST-Zustand: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand (lokal): $now_local  "
puts $fd "Stand (UTC): $now_utc"
puts $fd ""
puts $fd "## 1) Identität & System"
puts $fd ""
puts $fd "- Gateway: **B**"
puts $fd "- Node: **7**"
puts $fd "- Hostname (short): \\`$HOSTNAME_SHORT\\`"
puts $fd "- Hostname (FQDN): \\`$HOSTNAME_FQDN\\`"
puts $fd "- Architektur: \\`$ARCH\\`"
puts $fd "- Kernel: \\`$KERNEL\\`"
puts $fd "- OS: \\`$OS_PRETTY\\`"
puts $fd "- IPv4 (lokal): \\`$IPV4_ALL\\`"
puts $fd "- Public IPv4: \\`$PUBLIC_IP\\`"
puts $fd "- Tailscale IPv4: \\`$TAILSCALE_IP\\`"
puts $fd "- OpenClaw Version: \\`$OPENCLAW_VER\\`"
puts $fd "- Node.js Version: \\`$NODE_VER\\`"
puts $fd ""
puts $fd "## 2) Arbeitsverzeichnisse"
puts $fd ""
puts $fd "- Basis: \\`$BASE_DIR\\`"
puts $fd "- Funktionell VSCode: \\`$VSCODE_DIR\\`"
puts $fd "- Workspace Doku: \\`$OUT_DIR\\`"
puts $fd ""
puts $fd "## 3) Kernartefakte (Existenz)"
puts $fd ""
puts $fd "- \\`$OPENCLAW_JSON\\`: [file_status $OPENCLAW_JSON]"
puts $fd "- \\`$ENV_DOT\\`: [file_status $ENV_DOT]"
puts $fd "- \\`$ENV_SYSTEMD\\`: [file_status $ENV_SYSTEMD]"
puts $fd "- \\`${BASE_DIR}/plugins/installs.json\\`: [file_status ${BASE_DIR}/plugins/installs.json]"
puts $fd "- \\`${BASE_DIR}/plugin-skills\\`: [file_status ${BASE_DIR}/plugin-skills]"
puts $fd ""
puts $fd "## 4) Hinweis"
puts $fd ""
puts $fd "Diese Datei wird bei jedem Lauf neu geschrieben."
puts $fd "Zusätzlich wird ein Laufprotokoll als \\`RUN-*.md\\` erzeugt."
close $fd

# Artefakt-Inventar Datei schreiben
set fd [open $INV_FILE w]
puts $fd "# Artefakt-Inventar: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $now_local"
puts $fd ""
puts $fd "## Top-Level in ~/.openclaw"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[file exists $BASE_DIR] && [file isdirectory $BASE_DIR]} {
    if {[catch {glob -nocomplain -dir $BASE_DIR *} files]} {
        puts $fd ""
    } else {
        foreach file [lsort $files] {
            puts $fd [file tail $file]
        }
    }
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## ~/.openclaw/.vscode"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[file exists $VSCODE_DIR] && [file isdirectory $VSCODE_DIR]} {
    if {[catch {exec ls -la $VSCODE_DIR} result]} {
        puts $fd ""
    } else {
        puts $fd $result
    }
} else {
    puts $fd "(nicht vorhanden)"
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## plugin-skills/"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[file exists ${BASE_DIR}/plugin-skills] && [file isdirectory ${BASE_DIR}/plugin-skills]} {
    if {[catch {glob -nocomplain -dir ${BASE_DIR}/plugin-skills *} files]} {
        puts $fd ""
    } else {
        foreach file [lsort $files] {
            puts $fd [file tail $file]
        }
    }
} else {
    puts $fd "(nicht vorhanden)"
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## openclaw.json Backups"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[catch {glob -nocomplain ${BASE_DIR}/openclaw.json.bak*} backups]} {
    puts $fd "(keine gefunden)"
} else {
    if {[llength $backups] == 0} {
        puts $fd "(keine gefunden)"
    } else {
        foreach backup $backups {
            puts $fd [file tail $backup]
        }
    }
}
puts $fd "\\`\\`\\`"
close $fd

# Config Snapshot Datei schreiben
set fd [open $CFG_FILE w]
puts $fd "# OpenClaw Config Snapshot: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $now_local"
puts $fd ""
puts $fd "## Schlüsselpositionen (grep)"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[file exists $OPENCLAW_JSON]} {
    if {![catch {exec grep -nE {"gateway"|\"session\"|\"dmScope\"|\"auth\"|\"secrets\"|\"tools\"|\"plugins\"|\"profile\"|\"alsoAllow\"|\"denyCommands\"} $OPENCLAW_JSON} result]} {
        puts $fd $result
    }
} else {
    puts $fd "openclaw.json fehlt"
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)"
puts $fd ""
puts $fd "\\`\\`\\`json"

if {[file exists $OPENCLAW_JSON]} {
    if {![catch {exec sed -n {580,780p} $OPENCLAW_JSON} result]} {
        puts $fd $result
    }
} else {
    puts $fd "{ \"error\": \"openclaw.json fehlt\" }"
}
puts $fd "\\`\\`\\`"
close $fd

# ENV-Status Datei schreiben
set fd [open $ENV_FILE w]
puts $fd "# ENV-Status: Gateway B / Node 7"
puts $fd ""
puts $fd "Stand: $now_local"
puts $fd ""
puts $fd "## Dateien"
puts $fd ""
puts $fd "\\`\\`\\`text"

if {[catch {exec ls -la $ENV_DOT $ENV_SYSTEMD} result]} {
    # Ignorieren, wenn Dateien nicht existieren
} else {
    puts $fd $result
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## .env (vollständig, ungefiltert)"
puts $fd ""
puts $fd "\\`\\`\\`dotenv"

if {[file exists $ENV_DOT]} {
    set env_fd [open $ENV_DOT r]
    while {[gets $env_fd line] != -1} {
        puts $fd $line
    }
    close $env_fd
} else {
    puts $fd "# .env fehlt"
}
puts $fd "\\`\\`\\`"
puts $fd ""
puts $fd "## gateway.systemd.env (vollständig, ungefiltert)"
puts $fd ""
puts $fd "\\`\\`\\`dotenv"

if {[file exists $ENV_SYSTEMD]} {
    set env_fd [open $ENV_SYSTEMD r]
    while {[gets $env_fd line] != -1} {
        puts $fd $line
    }
    close $env_fd
} else {
    puts $fd "# gateway.systemd.env fehlt"
}
puts $fd "\\`\\`\\`"
close $fd

# Laufprotokoll Datei schreiben
set fd [open $RUN_FILE w]
puts $fd "# Laufprotokoll Gateway B / Node 7"
puts $fd ""
puts $fd "- Zeit (lokal): $now_local"
puts $fd "- Zeit (UTC): $now_utc"
puts $fd "- Script: [info script]"
puts $fd ""
puts $fd "## Erzeugte Dateien"
puts $fd ""
puts $fd "- [file tail $IST_FILE]"
puts $fd "- [file tail $INV_FILE]"
puts $fd "- [file tail $CFG_FILE]"
puts $fd "- [file tail $ENV_FILE]"
close $fd

# Abschlussmeldung
puts "OK: IST-Zustand erfasst."
puts "Ausgabeordner: $OUT_DIR"
puts "Dateien:"

if {[catch {glob -nocomplain -dir $OUT_DIR *} files]} {
    # Leerer Ordner
} else {
    foreach file [lsort $files] {
        puts "- [file tail $file]"
    }
}
