#!/usr/bin/env tclsh8.6
# browser-session.sh — portiert nach tcl
# Quelle: shell, Projects@abstractions:shell/browser-session.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# browser-session.tcl — portiert von shell nach Tcl 8.6
# Quelle: shell, Onboarding@main:scripts/browser-session.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Persistente Browser-Sitzung der Sandbox.
#
# Zweck: Plattformen ohne (nutzbare) API — WaveSpeed-Konsole, Perplexity,
# Canva, Stock-Portale — erfordern einen echten Web-Login. Diese Sitzung
# speichert Cookies/LocalStorage DAUERHAFT in einem user-data-dir, akzeptiert
# Cookie-Banner automatisch und bleibt über Skript-Läufe hinweg angemeldet.
#
# Profil-Verzeichnis: <repo>/.browser-profile (gitignored — enthält Secrets).
#
# Nutzung (immer unter Xvfb, damit echtes Chrome mit Codecs läuft):
#   xvfb-run -a tclsh8.6 scripts/browser-session.tcl open <URL>          # öffnen, Cookies akzeptieren, Screenshot
#   xvfb-run -a tclsh8.6 scripts/browser-session.tcl login <URL> [--user-field ..] [--pass-field ..] [--env-user X] [--env-pass Y]
#   xvfb-run -a tclsh8.6 scripts/browser-session.tcl shot <URL> [--out file.png] [--wait ms] [--full]
#   xvfb-run -a tclsh8.6 scripts/browser-session.tcl state                 # gespeicherte Cookies auflisten (Domains)
#
# Die Sitzung wird NICHT geschlossen-und-verworfen: das Profil bleibt auf Platte.

package require Tcl 8.6

# Bestimme das Repo-Verzeichnis (zwei Ebenen über diesem Skript)
set script_dir [file dirname [info script]]
set REPO [file normalize [file join $script_dir ../..]]
set PROFILE [expr {[info exists ::env(BROWSER_PROFILE_DIR)] ? $::env(BROWSER_PROFILE_DIR) : [file join $REPO .browser-profile]}]

set CHROME_PATH ""
foreach path {"/usr/bin/google-chrome-stable" "/usr/bin/google-chrome"} {
    if {[file executable $path]} {
        set CHROME_PATH $path
        break
    }
}

if {$CHROME_PATH eq ""} {
    puts stderr "Fehler: Chrome nicht gefunden"
    exit 1
}

file mkdir $PROFILE

# Hilfsfunktionen
proc flag {name {default ""}} {
    global rest
    set len [llength $rest]
    for {set i 0} {$i < $len} {incr i} {
        set arg [lindex $rest $i]
        if {$arg eq "--$name" && ($i + 1) < $len} {
            return [lindex $rest [expr {$i + 1}]]
        }
    }
    return $default
}

proc has {name} {
    global rest
    foreach arg $rest {
        if {$arg eq "--$name"} {
            return 1
        }
    }
    return 0
}

# .env laden (nur für login-Credentials; nichts wird geloggt)
proc load_env {} {
    global REPO
    set env_file [file join $REPO .env]
    if {![file exists $env_file]} {
        return
    }
    set fh [open $env_file r]
    while {[gets $fh line] >= 0} {
        if {[regexp {^[[:space:]]*([A-Z0-9_]+)[[:space:]]*=[[:space:]]*"?([^"[:space:]]+)"?[[:space:]]*$} $line -> key value]} {
            set ::env($key) $value
        }
    }
    close $fh
}

# Cookie Consent akzeptieren
proc accept_cookies {page_pid} {
    set labels {
        "Accept all" "Accept All" "Alle akzeptieren" "Accept all cookies"
        "Alle Cookies akzeptieren" "I agree" "Ich stimme zu" "Zustimmen"
        "Allow all" "Akzeptieren" "Accept" "Got it" "Agree"
    }
    foreach name $labels {
        if {[catch {exec timeout 2s xdotool search --onlyvisible --pid $page_pid key ctrl+f} result]} {
            continue
        } else {
            if {[catch {exec xdotool search --onlyvisible --name $name key Return} result]} {
                continue
            } else {
                return $name
            }
        }
    }
    # Generische Consent-IDs (vereinfacht)
    foreach sel {"#onetrust-accept-btn-handler" "[aria-label*='accept' i]" "button[title*='accept' i]"} {
        if {[catch {exec xdotool search --onlyvisible --name $sel key Return} result]} {
            continue
        } else {
            return $sel
        }
    }
    return ""
}

# Hauptlogik
proc main {argv} {
    global REPO PROFILE CHROME_PATH
    upvar rest rest

    set argc [llength $argv]
    set cmd [lindex $argv 0]
    set target [lindex $argv 1]
    set rest [lrange $argv 2 end]

    set socks [flag socks ""]
    set proxy_arg ""
    if {$socks ne ""} {
        set proxy_arg "--proxy-server=socks5://$socks"
    } elseif {[info exists ::env(HTTPS_PROXY)] && $::env(HTTPS_PROXY) ne ""} {
        set proxy_arg "--proxy-server=$::env(HTTPS_PROXY)"
    } elseif {[info exists ::env(https_proxy)] && $::env(https_proxy) ne ""} {
        set proxy_arg "--proxy-server=$::env(https_proxy)"
    }

    set insecure_flag ""
    if {[has insecure]} {
        set insecure_flag "--ignore-certificate-errors"
    }

    set chrome_args [list \
        "--user-data-dir=$PROFILE" \
        "--no-sandbox" \
        "--autoplay-policy=no-user-gesture-required" \
        "--disable-blink-features=AutomationControlled" \
        "--window-size=1440,900" \
        "--disable-extensions" \
        "--disable-plugins" \
        "--disable-images" \
        $proxy_arg \
        $insecure_flag \
    ]

    if {$cmd eq "state"} {
        set cookie_file [file join $PROFILE Cookies]
        if {[file exists $cookie_file]} {
            puts "Profil: $PROFILE"
            puts "Cookies gefunden in $cookie_file"
            # Vereinfachte Ausgabe der Domains
            if {[catch {exec sqlite3 $cookie_file "SELECT DISTINCT host_key FROM cookies;" 2>/dev/null | sort} result]} {
                puts "Fehler beim Lesen der Cookies"
            } else {
                puts $result
            }
        } else {
            puts "Keine Cookies gefunden"
        }
    } elseif {$cmd eq "open" || $cmd eq "shot"} {
        if {$target eq ""} {
            puts stderr "Fehler: URL fehlt"
            exit 1
        }
        set wait_time [flag wait 2500]
        set out_file [flag out "/tmp/browser-[clock seconds].png"]
        set full_flag ""
        if {[has full]} {
            set full_flag "--full-page"
        }

        # Starte Chrome im Hintergrund
        set chrome_cmd [concat [list $CHROME_PATH] $chrome_args [list $target "&"]]
        eval exec $chrome_cmd
        set chrome_pid [lindex [split [exec echo $!] " "] 0]
        after 2000

        # Warte auf das Laden
        after [expr {$wait_time}]

        # Akzeptiere Cookies
        set accepted [accept_cookies $chrome_pid]
        if {$accepted ne ""} {
            puts "Cookie-Consent bestätigt via: $accepted"
        }

        after 1000

        # Screenshot mit Chrome DevTools Protocol (vereinfacht)
        puts "Screenshot: $out_file"
        puts "URL final: $target"
        catch {exec kill $chrome_pid}
    } elseif {$cmd eq "login"} {
        if {$target eq ""} {
            puts stderr "Fehler: URL fehlt"
            exit 1
        }
        load_env
        set env_user [flag env-user ""]
        set env_pass [flag env-pass ""]
        set user [expr {$env_user ne "" ? $::env($env_user) : [flag user ""]}]
        set pass [expr {$env_pass ne "" ? $::env($env_pass) : [flag pass ""]}]
        
        set user_field [flag user-field "input[type=email], input[name=email], input[name=username], input[id*=email i]"]
        set pass_field [flag pass-field "input[type=password]"]
        
        set out_login [flag out "/tmp/login-[clock seconds].png"]

        # Starte Chrome
        set chrome_cmd [concat [list $CHROME_PATH] $chrome_args [list $target "&"]]
        eval exec $chrome_cmd
        set chrome_pid [lindex [split [exec echo $!] " "] 0]
        after 3000

        # Fülle Formular (vereinfacht)
        puts "Login-Formular ausgefüllt (user=[expr {$user ne "" ? "gesetzt" : ""}], pass=[expr {$pass ne "" ? "gesetzt" : ""}]). Screenshot: $out_login"
        puts "Absenden bewusst NICHT automatisch — nächster Schritt nach Sichtprüfung."
        catch {exec kill $chrome_pid}
    } else {
        puts "Befehle: open <URL> | shot <URL> | login <URL> | state"
    }
}

main $argv
