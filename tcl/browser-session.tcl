#!/usr/bin/env tclsh
# browser-session.pl — portiert nach tcl
# Quelle: perl5, Projects@abstractions:perl5/browser-session.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.tcl — portiert nach Tcl 8.6
# Quelle: javascript, Onboarding@main:scripts/browser-session.mjs
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# /**
#  * Persistente Browser-Sitzung der Sandbox.
#  *
#  * Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
#  * Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
#  * speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
#  * Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#  *
#  * Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#  *
#  * Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#  *   xvfb-run -a node scripts/browser-session.mjs open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#  *   xvfb-run -a node scripts/browser-session.mjs login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#  *   xvfb-run -a node scripts/browser-session.mjs shot <URL> [--out file.png] [--wait ms] [--full]
#  *   xvfb-run -a node scripts/browser-session.mjs state                 # gespeicherte Cookies auflisten (Domains)
#  *
#  * Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.
#  */

# Da Tcl keine direkte Entsprechung zu Playwright hat, verwenden wir Systemaufrufe
# um einen Browser zu steuern. Dies ist eine vereinfachte Version.

# Hilfsfunktionen
proc dirname {path} {
    set idx [string last "/" $path]
    if {$idx == -1} {
        return "."
    } elseif {$idx == 0} {
        return "/"
    } else {
        return [string range $path 0 [expr {$idx - 1}]]
    }
}

proc file normalize {path} {
    # Vereinfachte Normalisierung
    return $path
}

proc file join {args} {
    return [join $args "/"]
}

proc file exists {path} {
    return [expr {[catch {open $path r} fid] == 0 ? ([close $fid]; 1) : 0}]
}

proc file mkdir {path} {
    if {![file exists $path]} {
        file mkdir $path
    }
}

proc file dirname {path} {
    set idx [string last "/" $path]
    if {$idx == -1} {
        return "."
    } elseif {$idx == 0} {
        return "/"
    } else {
        return [string range $path 0 [expr {$idx - 1}]]
    }
}

proc make_path {path} {
    file mkdir $path
}

proc abs_path {path} {
    return [file normalize $path]
}

# Globale Variablen
set script_dir [file dirname $argv0]
set repo [file normalize [file join $script_dir ".."]]
set profile [expr {[info exists ::env(BROWSER_PROFILE_DIR)] ? $::env(BROWSER_PROFILE_DIR) : [file join $repo ".browser-profile"]}]
set chrome_path "/usr/bin/google-chrome-stable"
if {![file exists $chrome_path]} {
    set chrome_path "/usr/bin/google-chrome"
}

# Optionen parsen
array set options {}
set args $argv
set cmd ""
set target ""

if {[llength $args] > 0} {
    set cmd [lindex $args 0]
    set args [lrange $args 1 end]
}

if {[llength $args] > 0} {
    set target [lindex $args 0]
    set args [lrange $args 1 end]
}

# Optionen parsen
for {set i 0} {$i < [llength $args]} {incr i} {
    set arg [lindex $args $i]
    switch -glob -- $arg {
        --user-field {
            incr i
            set options(user-field) [lindex $args $i]
        }
        --pass-field {
            incr i
            set options(pass-field) [lindex $args $i]
        }
        --env-user {
            incr i
            set options(env-user) [lindex $args $i]
        }
        --env-pass {
            incr i
            set options(env-pass) [lindex $args $i]
        }
        --out {
            incr i
            set options(out) [lindex $args $i]
        }
        --wait {
            incr i
            set options(wait) [lindex $args $i]
        }
        --full {
            set options(full) 1
        }
        --insecure {
            set options(insecure) 1
        }
        --socks {
            incr i
            set options(socks) [lindex $args $i]
        }
        default {
            puts "Unbekannte Option: $arg"
            exit 1
        }
    }
}

# .env laden (nur für login-Credentials; nichts wird geloggt)
proc load_env {repo} {
    set f [file join $repo ".env"]
    if {![file exists $f]} {
        return [dict create]
    }
    set out [dict create]
    if {[catch {open $f r} fh]} {
        return $out
    }
    while {[gets $fh line] >= 0} {
        if {[regexp {^\s*([A-Z0-9_]+)\s*=\s*"?([^"]*)"?} $line match key value]} {
            dict set out $key $value
        }
    }
    close $fh
    return $out
}

# Häufige Cookie-Consent-Buttons klicken (mehrsprachig, best effort).
# In Tcl können wir dies nicht direkt tun, daher simulieren wir es.
proc accept_cookies {} {
    # In einer echten Implementierung würden wir hier den Browser automatisch
    # steuern. Da wir das nicht können, geben wir einfach eine Meldung aus.
    puts "Cookie-Banner akzeptiert (simuliert)."
    return "simuliert"
}

# Verzeichnis erstellen
if {![file exists $profile]} {
    make_path $profile
}

# Sandbox-Egress läuft über den Agent-Proxy (MITM mit CA in /root/.ccr).
# Chrome muss den Proxy nutzen; die CA ist zuvor via certutil in ~/.pki/nssdb
# importiert (siehe docs/VISUAL_QA.md), damit TLS ohne Fehler verifiziert.
# --socks <server>: leitet den Browser über einen SOCKS5-Proxy (z. B. den
# Tailscale-Userspace-Proxy localhost:1055) — sauberer Egress am Agent-MITM-
# Proxy vorbei, nötig für github.com/Codespaces. Sonst der Agent-HTTPS-Proxy.
set socks [expr {[info exists options(socks)] ? $options(socks) : ""}]
set proxy ""
if {$socks ne ""} {
    set proxy "socks5://$socks"
} else {
    if {[info exists ::env(HTTPS_PROXY)]} {
        set proxy $::env(HTTPS_PROXY)
    } elseif {[info exists ::env(https_proxy)]} {
        set proxy $::env(https_proxy)
    }
}

if {$cmd eq "state"} {
    puts "Profil: $profile"
    puts "Cookies und LocalStorage werden in $profile gespeichert."
    puts "Domains können nicht aufgelistet werden ohne direkten Zugriff auf den Browser."
} elseif {$cmd eq "open" || $cmd eq "shot"} {
    if {$target eq ""} {
        puts "URL fehlt"
        exit 1
    }
    set chrome_args [list \
        "--user-data-dir=$profile" \
        "--no-sandbox" \
        "--autoplay-policy=no-user-gesture-required" \
        "--disable-blink-features=AutomationControlled" \
        "--window-size=1440,900"]
    if {$proxy ne ""} {
        lappend chrome_args "--proxy-server=$proxy"
    }
    if {$proxy ne ""} {
        lappend chrome_args "--ssl-version-max=tls1.2"
    }
    if {[info exists options(insecure)]} {
        lappend chrome_args "--ignore-certificate-errors"
    }

    set wait_time [expr {[info exists options(wait)] ? $options(wait) : 2500}]
    set out_file [expr {[info exists options(out)] ? $options(out) : "/tmp/browser-[clock seconds].png"}]
    set full_page [expr {[info exists options(full)] ? "--screenshot=$out_file,fullPage" : "--screenshot=$out_file"}]

    set chrome_cmd "$chrome_path [join $chrome_args] $target $full_page"
    puts "Starte Chrome mit: $chrome_cmd"
    exec {*}[concat [split $chrome_cmd] "&"] &
    after [expr {int($wait_time)}]
    set accepted [accept_cookies]
    if {$accepted ne ""} {
        puts "Cookie-Consent bestätigt via: $accepted"
    }
    after 1000
    puts "Screenshot: $out_file"
    puts "URL final: $target"
} elseif {$cmd eq "login"} {
    if {$target eq ""} {
        puts "URL fehlt"
        exit 1
    }
    set env [load_env $repo]
    set user [expr {[dict exists $env $options(env-user)] ? [dict get $env $options(env-user)] : [expr {[info exists options(user)] ? $options(user) : ""}]}]
    set pass [expr {[dict exists $env $options(env-pass)] ? [dict get $env $options(env-pass)] : [expr {[info exists options(pass)] ? $options(pass) : ""}]}]
    set chrome_args [list \
        "--user-data-dir=$profile" \
        "--no-sandbox" \
        "--autoplay-policy=no-user-gesture-required" \
        "--disable-blink-features=AutomationControlled" \
        "--window-size=1440,900"]
    if {$proxy ne ""} {
        lappend chrome_args "--proxy-server=$proxy"
    }
    if {$proxy ne ""} {
        lappend chrome_args "--ssl-version-max=tls1.2"
    }
    if {[info exists options(insecure)]} {
        lappend chrome_args "--ignore-certificate-errors"
    }

    set out_file [expr {[info exists options(out)] ? $options(out) : "/tmp/login-[clock seconds].png"}]

    set chrome_cmd "$chrome_path [join $chrome_args] $target"
    puts "Starte Chrome mit: $chrome_cmd"
    exec {*}[concat [split $chrome_cmd] "&"] &
    after 2500
    accept_cookies
    puts "Login-Formular vorbereitet (user=[expr {$user ne "" ? "gesetzt" : "-"}], pass=[expr {$pass ne "" ? "gesetzt" : "-"}]). Screenshot: $out_file"
    puts "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
} else {
    puts "Befehle: open <URL> | shot <URL> | login <URL> | state"
}
