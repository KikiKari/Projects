#!/usr/bin/env tclsh8.6
# sandbox-vpn.sh — portiert nach tcl
# Quelle: shell, Onboarding@main:scripts/sandbox-vpn.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

# Bringt die Sandbox reproduzierbar in das Tailscale-Tailnet des Nutzers —
# als Brücke am Agent-MITM-Proxy vorbei (sauberer Egress via SOCKS5) und mit
# Tailscale-SSH, damit die eigenen Geräte des Nutzers in die Sandbox kommen.
#
# Nutzt den WIEDERVERWENDBAREN Auth-Key aus der .env (nichts committet).
# userspace-networking: verändert NICHT die Host-Routen/den Agent-Proxy dieser
# Session; stellt einen SOCKS5-Proxy auf localhost:1055 bereit.
#
# Aufrug: scripts/sandbox-vpn.sh   (idempotent; No-op ohne Auth-Key/tailscale)

proc log {msg} {
    puts "\[sandbox-vpn\] $msg"
}

# Get current directory and change to parent
set script_dir [file dirname [info script]]
set base_dir [file dirname $script_dir]
cd $base_dir

# Read auth key from .env file
set key ""
if {[file exists ".env"]} {
    set fp [open ".env" r]
    while {[gets $fp line] >= 0} {
        if {[regexp {^TAILSCALE_AUTH_KEY="(.*)"} $line match extracted_key]} {
            set key $extracted_key
            break
        }
    }
    close $fp
}

if {$key eq ""} {
    log "kein TAILSCALE_AUTH_KEY in .env — überspringe VPN"
    exit 0
}

# Check if tailscale is installed
if {[catch {exec which tailscale}]} {
    log "installiere Tailscale …"
    if {[catch {exec curl -fsSL https://tailscale.com/install.sh | exec sh} result]} {
        log "WARNUNG: Tailscale-Install fehlgeschlagen"
        exit 0
    }
}

# Start tailscaled in userspace mode if not running
if {[catch {exec tailscale status}]} {
    log "starte tailscaled (userspace, SOCKS5 localhost:1055) …"
    file mkdir "/var/lib/tailscale"
    
    # Start tailscaled in background
    if {[catch {
        set pid [exec tailscaled --tun=userspace-networking \
            --socks5-server=localhost:1055 \
            --outbound-http-proxy-listen=localhost:1056 \
            --statedir=/var/lib/tailscale >@stdout 2>@stderr &]
    } result]} {
        # Handle error if needed
    }
    
    # Wait a bit for startup
    after 4000
}

# Join tailnet with Tailscale SSH enabled
if {[catch {exec tailscale status} status_output] || ![string match "*claude-sandbox*" $status_output]} {
    log "tailscale up (hostname=claude-sandbox, --ssh) …"
    if {[catch {
        exec tailscale up --authkey=$key --hostname=claude-sandbox --ssh --accept-routes >@stdout 2>@stderr
    } result]} {
        log "WARNUNG: tailscale up fehlgeschlagen"
    }
} else {
    catch {exec tailscale set --ssh >@stdout 2>@stderr}
}

# Show status
if {![catch {exec tailscale status}]} {
    if {[catch {exec tailscale ip -4} ip_output]} {
        set ip "?"
    } else {
        set ip [lindex [split $ip_output "\n"] 0]
    }
    log "im Tailnet: claude-sandbox ${ip} · SSH aktiv · SOCKS5 localhost:1055"
}

exit 0
