#!/usr/bin/env tclsh8.6
# abstraction-provenance: {"artifact_sha256": "707fdb6843507a15a8bdf4de88120bdb13e9e499f0ae4a31e935c3be7d4d9cd9", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "tcl"}
# collect_ist_gateway_a.sh — portiert nach tcl
# Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package require Tcl 8.6
package require http 2.7

proc exec_with_fallback {cmd fallback} {
    if {[catch {exec {*}$cmd} result]} {
        return $fallback
    }
    return [string trim $result]
}

proc file_exists_status {filepath} {
    if {[file exists $filepath]} {
        return "vorhanden"
    } else {
        return "fehlt"
    }
}

proc list_directory_safe {dir} {
    if {[file isdirectory $dir]} {
        if {[catch {glob -nocomplain -dir $dir *} files]} {
            return ""
        }
        set result {}
        foreach f [lsort $files] {
            lappend result [file tail $f]
        }
        return [join $result "\n"]
    } else {
        return "(nicht vorhanden)"
    }
}

proc list_directory_detailed_safe {dir} {
    if {[file isdirectory $dir]} {
        if {[catch {exec ls -la $dir} result]} {
            return "(konnte nicht auflisten)"
        }
        return $result
    } else {
        return "(nicht vorhanden)"
    }
}

proc get_public_ip {} {
    if {[catch {exec curl -4 -s --max-time 4 ifconfig.me} ip]} {
        return "(nicht ermittelt)"
    }
    if {$ip eq ""} {
        return "(nicht ermittelt)"
    }
    return [string trim $ip]
}

proc get_tailscale_ip {} {
    if {[catch {exec tailscale ip -4} ip]} {
        return "(nicht ermittelt)"
    }
    set lines [split [string trim $ip] "\n"]
    if {[llength $lines] > 0} {
        return [lindex $lines 0]
    } else {
        return "(nicht ermittelt)"
    }
}

proc read_file_safe {filepath} {
    if {[file exists $filepath] && [file readable $filepath]} {
        if {[catch {read [open $filepath r]} content]} {
            return "# Fehler beim Lesen der Datei"
        }
        return [string trim $content]
    } else {
        if {[file extension $filepath] eq ".env"} {
            return "# [file tail $filepath] fehlt"
        } else {
            return "{ \"error\": \"[file tail $filepath] fehlt\" }"
        }
    }
}

proc grep_json_keys {filepath} {
    if {![file exists $filepath]} {
        return "openclaw.json fehlt"
    }
    
    set patterns {"gateway" "session" "dmScope" "auth" "secrets" "tools" "plugins" "profile" "alsoAllow" "denyCommands"}
    set results {}
    
    if {[catch {open $filepath r} fh]} {
        return "Fehler beim Öffnen der Datei"
    }
    
    set line_num 1
    while {[gets $fh line] >= 0} {
        foreach pattern $patterns {
            if {[regexp "\"$pattern\"" $line]} {
                lappend results "$line_num:$line"
            }
        }
        incr line_num
    }
    close $fh
    
    if {[llength $results] > 0} {
        return [join $results "\n"]
    } else {
        return ""
    }
}

proc extract_json_section {filepath start end} {
    if {![file exists $filepath]} {
        return "{ \"error\": \"openclaw.json fehlt\" }"
    }
    
    if {[catch {open $filepath r} fh]} {
        return "{ \"error\": \"Fehler beim Öffnen der Datei\" }"
    }
    
    set lines {}
    set current_line 1
    while {[gets $fh line] >= 0 && $current_line <= $end} {
        if {$current_line >= $start} {
            lappend lines $line
        }
        incr current_line
    }
    close $fh
    
    return [join $lines "\n"]
}

proc format_datetime {format_type} {
    set now [clock seconds]
    switch $format_type {
        "utc" {
            return [clock format $now -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
        }
        "local" {
            return [clock format $now -format "%Y-%m-%d %H:%M:%S %Z"]
        }
        "timestamp" {
            return [clock format $now -format "%Y%m%d-%H%M%S"]
        }
    }
}

proc get_os_pretty_name {} {
    set os_release "/etc/os-release"
    if {[file exists $os_release]} {
        if {[catch {open $os_release r} fh]} {
            return ""
        }
        while {[gets $fh line] >= 0} {
            if {[regexp {^PRETTY_NAME=(.*)} $line match name]} {
                close $fh
                return [string trim $name "\""]
            }
        }
        close $fh
    }
    return ""
}

set BASE_DIR [file normalize "~/.openclaw"]
set OUT_DIR [file join $BASE_DIR "workspace" "vscode"]

set NOW_UTC [format_datetime "utc"]
set NOW_LOCAL [format_datetime "local"]
set TS [format_datetime "timestamp"]

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

set HOSTNAME_FQDN [exec_with_fallback {hostname -f} [exec hostname]]
set HOSTNAME_SHORT [exec hostname]
set ARCH [exec uname -m]
set KERNEL [exec uname -r]
set OS_PRETTY [get_os_pretty_name]
set IPV4_ALL [exec_with_fallback {hostname -I} ""]
set PUBLIC_IP [get_public_ip]
set TAILSCALE_IP [get_tailscale_ip]

if {[catch {exec openclaw --version} OPENCLAW_VER]} {
    set OPENCLAW_VER "(nicht ermittelt)"
}
if {[catch {exec node -v} NODE_VER]} {
    set NODE_VER "(nicht ermittelt)"
}

set ist_content "# IST-Zustand: Gateway A / Node 1

Stand (lokal): $NOW_LOCAL  
Stand (UTC): $NOW_UTC

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
- Hostname (short): `$HOSTNAME_SHORT`
- Hostname (FQDN): `$HOSTNAME_FQDN`
- Architektur: `$ARCH`
- Kernel: `$KERNEL`
- OS: `$OS_PRETTY`
- IPv4 (lokal): `$IPV4_ALL`
- Public IPv4: `$PUBLIC_IP`
- Tailscale IPv4: `$TAILSCALE_IP`
- OpenClaw Version: `$OPENCLAW_VER`
- Node.js Version: `$NODE_VER`

## 2) Arbeitsverzeichnisse

- Basis: `$BASE_DIR`
- Funktionell VSCode: `$VSCODE_DIR`
- Workspace Doku: `$OUT_DIR`

## 3) Kernartefakte (Existenz)

- `$OPENCLAW_JSON`: [file_exists_status $OPENCLAW_JSON]
- `$ENV_DOT`: [file_exists_status $ENV_DOT]
- `$ENV_SYSTEMD`: [file_exists_status $ENV_SYSTEMD]
- `[file join $BASE_DIR plugins installs.json]`: [file_exists_status [file join $BASE_DIR "plugins" "installs.json"]]
- `[file join $BASE_DIR plugin-skills]`: [file_exists_status [file join $BASE_DIR "plugin-skills"]]
"

set fh [open $IST_FILE w]
puts -nonewline $fh $ist_content
close $fh

set inv_content "# Artefakt-Inventar: Gateway A / Node 1

Stand: $NOW_LOCAL

## Top-Level in ~/.openclaw

```text
[list_directory_safe $BASE_DIR]
```

## ~/.openclaw/.vscode

```text
[list_directory_detailed_safe $VSCODE_DIR]
```

## plugin-skills/

```text
[list_directory_safe [file join $BASE_DIR "plugin-skills"]]
```

## openclaw.json Backups

```text
[exec_with_fallback [list ls -1 [file join $BASE_DIR "openclaw.json.bak*"]] "(keine gefunden)"]
```
"

set fh [open $INV_FILE w]
puts -nonewline $fh $inv_content
close $fh

set cfg_content "# OpenClaw Config Snapshot: Gateway A / Node 1

Stand: $NOW_LOCAL

## Schluesselpositionen (grep)

```text
[grep_json_keys $OPENCLAW_JSON]
```

## Ausschnitt gateway/session/auth

```json
[extract_json_section $OPENCLAW_JSON 580 780]
```
"

set fh [open $CFG_FILE w]
puts -nonewline $fh $cfg_content
close $fh

set env_content "# ENV-Status: Gateway A / Node 1

Stand: $NOW_LOCAL

## Dateien

```text
[exec_with_fallback [list ls -la $ENV_DOT $ENV_SYSTEMD] ""]
```

## .env (vollstaendig)

```dotenv
[read_file_safe $ENV_DOT]
```

## gateway.systemd.env (vollstaendig)

```dotenv
[read_file_safe $ENV_SYSTEMD]
```
"

set fh [open $ENV_FILE w]
puts -nonewline $fh $env_content
close $fh

set script_path [info script]
set run_content "# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): $NOW_LOCAL
- Zeit (UTC): $NOW_UTC
- Script: $script_path

## Erzeugte Dateien

- [file tail $IST_FILE]
- [file tail $INV_FILE]
- [file tail $CFG_FILE]
- [file tail $ENV_FILE]
"

set fh [open $RUN_FILE w]
puts -nonewline $fh $run_content
close $fh

puts "OK: IST-Zustand erfasst."
if {[catch {exec ls -1 $OUT_DIR} listing]} {
    puts "- Fehler beim Auflisten des Verzeichnisses"
} else {
    set files [split [string trim $listing] "\n"]
    foreach f $files {
        puts "- $f"
    }
}
