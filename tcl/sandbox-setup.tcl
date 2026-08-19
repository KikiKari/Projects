#!/usr/bin/env tclsh8.6
# sandbox-setup.sh — portiert nach tcl
# Quelle: shell, Onboarding@main:scripts/sandbox-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Provisioniert die Claude-Code-Sandbox (Remote-Umgebung) reproduzierbar:
#   - Node-Dependencies (Frontend, npm)
#   - Python-Dependencies (Backend inkl. pytest)
#   - Medien-Tools: ffmpeg, ImageMagick, GIMP, Blender headless (apt) —
#     Fehlschlag blockiert die Session nicht; --skip-heavy laesst GIMP/Blender aus
# Idempotent: bereits Vorhandenes wird uebersprungen; der Container-Cache der
# Umgebung macht die apt-Installation zum Einmal-Aufwand.

set SKIP_HEAVY 0
if {[llength $argv] > 0 && [lindex $argv 0] eq "--skip-heavy"} {
    set SKIP_HEAVY 1
}

# Change to parent directory
set script_dir [file dirname [info script]]
cd [file join $script_dir ".."]

proc log {msg} {
    puts "\[sandbox-setup\] $msg"
}

proc execute_command {cmd} {
    if [catch {exec {*}$cmd} result] {
        return ""
    }
    return $result
}

proc command_exists {cmd} {
    if [catch {exec which $cmd} result] {
        return 0
    }
    return [string length $result] > 0
}

proc apt_install {pkg bin} {
    if {[command_exists $bin]} {
        set version_output [execute_command [list $bin -version]]
        if {$version_output eq ""} {
            set version_output [execute_command [list $bin --version]]
        }
        if {$version_output ne ""} {
            set first_line [lindex [split $version_output "\n"] 0]
            log "$pkg bereits vorhanden ($first_line)"
        } else {
            log "$pkg bereits vorhanden"
        }
        return
    }
    
    log "Installiere $pkg ..."
    global APT_UPDATED
    if {![info exists APT_UPDATED] || $APT_UPDATED == 0} {
        if [catch {exec env DEBIAN_FRONTEND=noninteractive apt-get update -qq} result] {
            log "WARNUNG: apt-get update fehlgeschlagen"
        } else {
            set APT_UPDATED 1
        }
    }
    
    if [catch {exec env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $pkg} result] {
        log "WARNUNG: $pkg konnte nicht installiert werden (Netzwerk-Policy?) — Medien-Schritte ggf. eingeschraenkt"
    }
}

log "Node-Dependencies (npm install) ..."
if [catch {exec npm install --no-audit --no-fund} result] {
    log "FEHLER: npm install fehlgeschlagen"
    exit 1
}

log "Python-Dependencies (backend/requirements-dev.txt) ..."
if [catch {exec pip3 install --quiet -r backend/requirements-dev.txt} result] {
    log "FEHLER: pip install fehlgeschlagen"
    exit 1
}

apt_install ffmpeg ffmpeg
apt_install imagemagick convert
if {$SKIP_HEAVY == 0} {
    apt_install gimp gimp
    apt_install blender blender
}

# Visual QA tools
apt_install xvfb Xvfb
apt_install x11-utils xdpyinfo
apt_install libnss3-tools certutil

if {![command_exists google-chrome-stable]} {
    log "Installiere Google Chrome Stable ..."
    set tmpdeb "/tmp/chrome.deb"
    if [catch {exec curl -fsSL -o $tmpdeb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb} result] {
        log "WARNUNG: Chrome-Download fehlgeschlagen (Netzwerk-Policy?)"
    } else {
        if [catch {exec env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $tmpdeb} result] {
            log "WARNUNG: Chrome-Installation fehlgeschlagen"
        } else {
            set chrome_version [execute_command [list google-chrome-stable --version]]
            if {$chrome_version ne ""} {
                log "Chrome installiert: $chrome_version"
            }
        }
        file delete $tmpdeb
    }
}

# Proxy-CA in Chromes NSS-DB
if {[command_exists certutil] && [file exists "/root/.ccr/ca-bundle.crt"]} {
    set nssdb_dir "$env(HOME)/.pki/nssdb"
    file mkdir $nssdb_dir
    catch {exec certutil -d sql:$nssdb_dir -N --empty-password}
    if [catch {exec certutil -d sql:$nssdb_dir -L} cert_list] {
        set cert_exists 0
    } else {
        if {[string first "ccr-proxy-ca" $cert_list] != -1} {
            set cert_exists 1
        } else {
            set cert_exists 0
        }
    }
    
    if {!$cert_exists} {
        if [catch {exec certutil -d sql:$nssdb_dir -A -t "C,," -n ccr-proxy-ca -i /root/.ccr/ca-bundle.crt} result] {
            # Ignore errors
        } else {
            log "Proxy-CA in Chrome-NSS-Store importiert"
        }
    }
}

# Playwright installation
if {[file isdirectory "node_modules"] && ![file exists "node_modules/playwright"]} {
    if {[command_exists npm]} {
        if [catch {exec npm install --no-audit --no-fund --no-save playwright} result] {
            log "WARNUNG: Playwright-npm-Install fehlgeschlagen"
        } else {
            log "Playwright (Node) installiert"
        }
    }
}

# Git configuration
if [catch {exec git rev-parse --is-inside-work-tree} result] {
    # Inside a git repository
    set pwd [pwd]
    exec git config credential."https://x-access-token@github.com".helper "!$pwd/.claude/git-credential-pat.sh"
    exec git remote set-url --push origin "https://x-access-token@github.com/KikiKari/Onboarding.git"
    log "Git-Push-Route: direkt zu github.com (PAT via Credential-Helper)"
}

# Docker daemon
if {[command_exists dockerd] && [catch {exec docker info} result]} {
    log "Starte Docker-Daemon (Registry-Mirror: mirror.gcr.io) ..."
    file mkdir "/etc/docker"
    set daemon_file "/etc/docker/daemon.json"
    if {![file exists $daemon_file]} {
        set fp [open $daemon_file w]
        puts $fp "{\"registry-mirrors\":[\"https://mirror.gcr.io\"]}"
        close $fp
    }
    
    # Start dockerd in background
    if [catch {exec dockerd > /tmp/dockerd.log 2>@1 &} result] {
        # Background process started
    }
    
    # Wait for docker to start
    set docker_started 0
    for {set i 0} {$i < 15} {incr i} {
        if [catch {exec docker info} result] {
            after 1000
        } else {
            set docker_started 1
            break
        }
    }
    
    if {$docker_started} {
        log "Docker-Daemon laeuft"
    } else {
        log "WARNUNG: Docker-Daemon nicht gestartet"
    }
}

log "Fertig. Versionen:"
set node_version [execute_command [list node --version]]
if {$node_version ne ""} {
    log "  node $node_version"
}

set python_version [execute_command [list python3 --version]]
if {$python_version ne ""} {
    log "  $python_version"
}

if {[command_exists ffmpeg]} {
    set ffmpeg_version [execute_command [list ffmpeg -version]]
    if {$ffmpeg_version ne ""} {
        set first_line [lindex [split $ffmpeg_version "\n"] 0]
        log "  $first_line"
    }
}

if {[command_exists convert]} {
    set convert_version [execute_command [list convert -version]]
    if {$convert_version ne ""} {
        set first_line [lindex [split $convert_version "\n"] 0]
        log "  $first_line"
    }
}

if {[command_exists gimp] && $SKIP_HEAVY == 0} {
    set gimp_version [execute_command [list gimp --version]]
    if {$gimp_version ne ""} {
        set first_line [lindex [split $gimp_version "\n"] 0]
        log "  $first_line"
    }
}

if {[command_exists blender] && $SKIP_HEAVY == 0} {
    set blender_version [execute_command [list blender --version]]
    if {$blender_version ne ""} {
        set first_line [lindex [split $blender_version "\n"] 0]
        log "  $first_line"
    }
}

exit 0
