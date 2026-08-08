#!/usr/bin/env tclsh
# ABSTRACTIONS_MANAGER.py — portiert nach tcl
# Quelle: python, Projects@abstractions:abstractions/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Script Abstractions Manager
# 
# Uebersetzt jede Quelldatei aus den drei Repositories KikiKari/OpenClaw,
# KikiKari/Projects und KikiKari/Onboarding in sechs Zielsprachen und legt
# das Ergebnis in den Sprachverzeichnissen des Abstraktions-Repositories ab.
# 
# Es entstehen vollstaendige Uebersetzungen, keine Ruempfe: jede Datei geht
# als Ganzes an ein Sprachmodell, das lauffaehigen Code in der Zielsprache
# zurueckgibt. Erzeugnisse, deren Syntax sich nicht pruefen laesst oder die
# erkennbar unfertig sind, werden verworfen statt abgelegt.
# 
# Verwendung:
#     tclsh ABSTRACTIONS_MANAGER.tcl [--prioritaet high|medium|low|alle]
#                                    [--anzahl N] [--probelauf]
# 
# Umgebung:
#     OPENROUTER_API_KEY      Pflicht. Schluessel fuer die Uebersetzung.
#     ABSTRACTIONS_WORKSPACE  Arbeitsverzeichnis, Vorgabe
#                             /home/openclaw/.openclaw/workspace
#     ABSTRACTIONS_MODELL     Modellkennung, Vorgabe siehe MODELLE
#     ABSTRACTIONS_ANZAHL     Quelldateien je Lauf, Vorgabe 40

package require Tcl 8.6
package require http
package require json
package require fileutil

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

set WORKSPACE [expr {[info exists ::env(ABSTRACTIONS_WORKSPACE)] ? $::env(ABSTRACTIONS_WORKSPACE) : "/home/openclaw/.openclaw/workspace"}]
set ABSTRACTIONS_REPO [file join $WORKSPACE git Abstraktionen]
set QUELLEN_DIR [file join $WORKSPACE git quellen]
set LOG_DIR [file join $WORKSPACE logs abstractions-manager]
set STATE_FILE [file join $WORKSPACE db abstractions_state.json]

set GITHUB_BENUTZER "KikiKari"

# Herkunft der Quelldateien. Projects wird ueber alle Branches gelesen, weil
# dort jedes Projekt in einem eigenen verwaisten Branch liegt.
array set QUELLEN {
    0 {repo OpenClaw branches {main gateway1 gateway2}}
    1 {repo Projects branches alle}
    2 {repo Onboarding branches {main}}
}

# Dateiendung -> Quellsprache. Bestimmt zugleich, was eingelesen wird.
array set QUELLSPRACHEN {
    .pl perl5
    .pm perl5
    .ps1 powershell
    .psm1 powershell
    .sh shell
    .bash shell
    .tcl tcl
    .html html
    .htm html
    .js javascript
    .mjs javascript
    .cjs javascript
    .py python
    .css css
}

# Die sechs Zielverzeichnisse, nach der Vorlage aus
# OpenClaw@gateway1-abstractions. Sie liegen im Wurzelverzeichnis des
# Abstraktions-Repositories.
array set ZIELSPRACHEN {
    javascript {ext .js bezeichnung {JavaScript fuer Node 20}}
    perl5 {ext .pl bezeichnung {Perl 5 mit use strict und use warnings}}
    powershell {ext .ps1 bezeichnung {PowerShell 7}}
    python {ext .py bezeichnung {Python 3.12}}
    shell {ext .sh bezeichnung {Bash 5 mit set -euo pipefail}}
    tcl {ext .tcl bezeichnung {Tcl 8.6}}
}

# Verzeichnisse und Muster, die nie eingelesen werden.
set AUSSCHLUSS [list node_modules/ /.git/ __pycache__/ dist/ build/ vendor/ .venv/ site-packages/ python-hardener-workspace/ .artifacts/ coverage/ .next/ target/]
set MAX_BYTES 200000

# Reihenfolge der Ausweichmodelle. Geprueft gegen das Konto: die Anbieter von
# OpenAI und Anthropic sind dort ueber die Privatsphaere-Einstellung
# ausgeschlossen ("All providers have been ignored"), diese hier antworten.
set MODELLE [list \
    qwen/qwen3-coder \
    deepseek/deepseek-chat-v3.1 \
    z-ai/glm-4.6 \
    mistralai/codestral-2508 \
    qwen/qwen-2.5-coder-32b-instruct \
]

set API_URL "https://openrouter.ai/api/v1/chat/completions"
set ZEITLIMIT 240
set VERSUCHE 3

# ---------------------------------------------------------------------------
# Protokoll
# ---------------------------------------------------------------------------

proc _protokoll {} {
    # Richtet die Protokollierung nach stdout und, wenn moeglich, in eine Datei ein.
    global LOG_DIR
    if {![info exists ::logger]} {
        set ::logger stdout
        if {[catch {file mkdir $LOG_DIR}]} {
            puts "Protokolldatei nicht verfuegbar — es wird nur nach stdout geschrieben"
        } else {
            set logFile [open [file join $LOG_DIR manager.log] a]
            fconfigure $logFile -encoding utf-8
            set ::logger $logFile
        }
    }
    return $::logger
}

proc logger {level func line message args} {
    set timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    set formatted_message [format "%s | %-7s | %s:%s | $message" $timestamp [string toupper $level] $func $line]
    if {[llength $args] > 0} {
        set formatted_message [format $formatted_message {*}$args]
    }
    puts $::logger $formatted_message
    flush $::logger
}

# ---------------------------------------------------------------------------
# Zustand
# ---------------------------------------------------------------------------

proc zustand_laden {} {
    # Liest den Zustand. Er merkt sich je Quelldatei-Hash die bereits
    # erzeugten Zielsprachen, damit ein erneuter Lauf nichts doppelt uebersetzt.
    global STATE_FILE
    if {[file exists $STATE_FILE]} {
        if {[catch {set fp [open $STATE_FILE r]}]} {
            logger warning zustand_laden 0 "Zustand unlesbar (%s) — es wird neu begonnen" $fehler
            return [dict create erledigt [dict create] statistik [dict create]]
        }
        set content [read $fp]
        close $fp
        if {[catch {set state [::json::json2dict $content]}]} {
            logger warning zustand_laden 0 "Zustand unlesbar (%s) — es wird neu begonnen" $fehler
            return [dict create erledigt [dict create] statistik [dict create]]
        }
        return $state
    }
    return [dict create erledigt [dict create] statistik [dict create]]
}

proc zustand_speichern {zustand} {
    # Schreibt den Zustand atomar, damit ein Abbruch ihn nicht zerstoert.
    global STATE_FILE
    set tempFile [file join [file dirname $STATE_FILE] .zustand_[pid]]
    if {[catch {set fp [open $tempFile w]} fehler]} {
        logger error zustand_speichern 0 "Zustand konnte nicht gespeichert werden: %s" $fehler
        return
    }
    puts $fp [::json::dict2json $zustand]
    close $fp
    file rename -force $tempFile $STATE_FILE
}

# ---------------------------------------------------------------------------
# Quellen holen
# ---------------------------------------------------------------------------

proc _git {args} {
    # Fuehrt einen Git-Befehl aus und gibt das Ergebnis zurueck, ohne zu werfen.
    set cmd [list git {*}$args]
    if {[catch {set result [exec {*}$cmd]} output]} {
        return [list returncode 1 stderr $output stdout ""]
    }
    return [list returncode 0 stderr "" stdout $output]
}

proc quellen_holen {} {
    # Holt oder aktualisiert die Quell-Repositories und legt fuer jeden Branch
    # einen Arbeitsbaum an.
    # 
    # Alle drei Repositories sind oeffentlich, es wird daher kein Token benoetigt.
    # 
    # Returns:
    #     Liste aus (Repo, Branch, Pfad zum Arbeitsbaum).
    global QUELLEN_DIR GITHUB_BENUTZER QUELLEN
    file mkdir $QUELLEN_DIR
    set baeume {}

    dict for {key eintrag} $QUELLEN {
        set repo [dict get $eintrag repo]
        set spiegel [file join $QUELLEN_DIR ${repo}.git]
        set url https://github.com/$GITHUB_BENUTZER/${repo}.git

        if {![file exists $spiegel]} {
            logger info quellen_holen 0 "%s wird geholt" $repo
            set ergebnis [_git clone --mirror --filter=blob:none $url $spiegel]
            if {[dict get $ergebnis returncode] != 0} {
                logger error quellen_holen 0 "%s konnte nicht geholt werden: %s" $repo [string range [dict get $ergebnis stderr] 0 199]
                continue
            }
        } else {
            set ergebnis [_git -C $spiegel remote update --prune]
            if {[dict get $ergebnis returncode] != 0} {
                logger warning quellen_holen 0 "%s konnte nicht aktualisiert werden: %s" $repo [string range [dict get $ergebnis stderr] 0 199]
            }
        }

        set gewuenscht [dict get $eintrag branches]
        if {$gewuenscht eq "alle"} {
            set aus [_git -C $spiegel for-each-ref --format=%(refname:short) refs/heads]
            set branches {}
            foreach z [split [dict get $aus stdout] \n] {
                if {[string trim $z] ne ""} {
                    lappend branches [string trim $z]
                }
            }
        } else {
            set branches $gewuenscht
        }

        foreach branch $branches {
            set baum [file join $QUELLEN_DIR baeume $repo [string map {/ _} $branch]]
            file mkdir $baum
            set ergebnis [_git --work-tree $baum checkout -f $branch -- . -C $spiegel]
            if {[dict get $ergebnis returncode] != 0} {
                logger warning quellen_holen 0 "%s@%s: Arbeitsbaum fehlgeschlagen: %s" $repo $branch [string range [dict get $ergebnis stderr] 0 159]
                continue
            }
            lappend baeume [list $repo $branch $baum]
        }
    }

    logger info quellen_holen 0 "Quellen bereit: %d Arbeitsbaeume" [llength $baeume]
    return $baeume
}

# ---------------------------------------------------------------------------
# Inventar
# ---------------------------------------------------------------------------

proc _prioritaet {pfad sprache} {
    # Ordnet einer Quelldatei ihre Dringlichkeit zu.
    # 
    # high   Betriebsscripte — alles unterhalb eines scripts-Verzeichnisses.
    # medium uebriger ausfuehrbarer Code.
    # low    Markup und Stilvorlagen, die nur der Vollstaendigkeit halber
    #        mituebersetzt werden.
    if {$sprache in {html css}} {
        return "low"
    }
    if {[string match "scripts/*" $pfad] || [string match "*/scripts/*" $pfad]} {
        return "high"
    }
    return "medium"
}

proc inventar_bauen {baeume} {
    # Erfasst alle Quelldateien und fasst inhaltsgleiche Fundstellen zusammen.
    # 
    # Deduplizierung geschieht ueber den SHA-256 des Inhalts. Eine Datei, die in
    # mehreren Branches identisch vorliegt, wird genau einmal uebersetzt; alle
    # Fundstellen bleiben als Herkunft vermerkt.
    # 
    # Returns:
    #     Nach Dringlichkeit und Name sortierte Liste von Eintraegen.
    global AUSSCHLUSS QUELLSPRACHEN MAX_BYTES
    array set dateien {}

    foreach {repo branch baum} $baeume {
        foreach pfad [glob -nocomplain -directory $baum -types f **] {
            set rel [string map {\\ /} [fileutil::stripPath $baum $pfad]]
            set ausschliessen 0
            foreach muster $AUSSCHLUSS {
                if {[string match "*$muster*" "/$rel"]} {
                    set ausschliessen 1
                    break
                }
            }
            if {$ausschliessen} {
                continue
            }
            set sprache ""
            if {[info exists QUELLSPRACHEN([file extension $pfad])]} {
                set sprache $QUELLSPRACHEN([file extension $pfad])
            }
            if {$sprache eq ""} {
                continue
            }
            if {[catch {set roh [read -nonewline [open $pfad rb]]}]} {
                continue
            }
            if {[string trim $roh] eq "" || [string length $roh] > $MAX_BYTES} {
                continue
            }

            set schluessel [string range [::sha2::sha256 -bin $roh] 0 15]
            if {![info exists dateien($schluessel)]} {
                set dateien($schluessel) [dict create \
                    hash $schluessel \
                    name [file tail $pfad] \
                    stamm [file rootname [file tail $pfad]] \
                    sprache $sprache \
                    bytes [string length $roh] \
                    pfad $pfad \
                    herkunft [list] \
                    prioritaet [_prioritaet $rel $sprache] \
                ]
            }
            dict lappend dateien($schluessel) herkunft ${repo}@${branch}:${rel}
        }
    }

    set liste {}
    foreach key [array names dateien] {
        lappend liste $dateien($key)
    }
    
    set rang [dict create high 0 medium 1 low 2]
    set sorted_list {}
    foreach eintrag $liste {
        lappend sorted_list [list [dict get $rang [dict get $eintrag prioritaet]] [dict get $eintrag name] $eintrag]
    }
    set sorted_list [lsort -index {0 1} $sorted_list]
    
    set result_list {}
    foreach item $sorted_list {
        lappend result_list [lindex $item 2]
    }
    
    set herkunft_count 0
    foreach e $result_list {
        incr herkunft_count [llength [dict get $e herkunft]]
    }
    logger info inventar_bauen 0 "Inventar: %d eindeutige Quelldateien aus %d Fundstellen" [llength $result_list] $herkunft_count
    return $result_list
}

# ---------------------------------------------------------------------------
# Uebersetzung
# ---------------------------------------------------------------------------

set ANWEISUNG {Du portierst Quellcode zwischen Programmiersprachen.

Regeln:
1. Gib ausschliesslich den vollstaendigen Code der Zielsprache aus. Keine
   Erklaerung davor oder danach, keine Code-Zaeune.
2. Uebersetze die gesamte Funktionalitaet. Kein TODO, kein "hier waere",
   kein leerer Rumpf, kein Platzhalter.
3. Erhalte Verhalten, Ein- und Ausgaben, Aufrufparameter und Rueckgabewerte.
4. Verwende die Mittel der Zielsprache statt einer woertlichen Abschrift.
   Wo eine Bibliothek fehlt, loese es mit Bordmitteln der Zielsprache.
5. Kommentare uebernimmst du sinngemaess in der Sprache des Originals.
6. Beginne mit der passenden Shebang-Zeile.}

set MARKUP_HINWEIS {Das Original ist {sprache}. Erzeuge ein Programm in der
Zielsprache, das dieses Dokument erzeugt und ueber einen Parameter in eine
Datei schreibt — kein blosses Einbetten als Zeichenkette, sondern eine
nachvollziehbare Erzeugung der Struktur.}

proc _zaeune_entfernen {text} {
    # Loest Code aus Markdown-Zaeunen, falls das Modell welche gesetzt hat.
    set zeilen [split [string trim $text] \n]
    if {[llength $zeilen] > 0 && [string match "```*" [lindex $zeilen 0]]} {
        set zeilen [lrange $zeilen 1 end]
        while {[llength $zeilen] > 0 && ![string match "```*" [lindex $zeilen end]]} {
            if {[string trim [lindex $zeilen end]] ne ""} {
                break
            }
            set zeilen [lrange $zeilen 0 end-1]
        }
        if {[llength $zeilen] > 0 && [string match "```*" [lindex $zeilen end]]} {
            set zeilen [lrange $zeilen 0 end-1]
        }
    }
    return [string trim [join $zeilen \n]]\n
}

proc modell_fragen {quelle quellsprache zielsprache name schluessel} {
    # Laesst eine Quelldatei in die Zielsprache uebersetzen.
    # 
    # Bei Fehlschlag wird mit wachsender Wartezeit wiederholt und danach auf
    # das naechste Modell der Liste ausgewichen.
    # 
    # Returns:
    #     Der uebersetzte Code, oder None wenn kein Modell geantwortet hat.
    global ZIELSPRACHEN ANWEISUNG MARKUP_HINWEIS MODELLE API_URL ZEITLIMIT VERSUCHE
    set ziel [dict get $ZIELSPRACHEN($zielsprache) bezeichnung]
    set auftrag "Portiere die folgende Datei $name von $quellsprache nach $ziel.\n"
    if {$quellsprache in {html css}} {
        set auftrag "$auftrag[subst $MARKUP_HINWEIS]\n"
    }
    set auftrag "$auftrag\n----- Beginn $name -----\n$quelle\n----- Ende $name -----"

    set modelle [expr {[info exists ::env(ABSTRACTIONS_MODELL)] ? [list $::env(ABSTRACTIONS_MODELL)] : $MODELLE}]

    foreach modell $modelle {
        for {set versuch 1} {$versuch <= $VERSUCHE} {incr versuch} {
            set rumpf [::json::dict2json [dict create \
                model $modell \
                messages [list \
                    [dict create role system content $ANWEISUNG] \
                    [dict create role user content $auftrag] \
                ] \
                temperature 0.1 \
                max_tokens 8000 \
            ]]
            set token "Bearer $schluessel"
            set headers [list \
                Authorization $token \
                Content-Type application/json \
                HTTP-Referer "https://github.com/KikiKari/Projects" \
                X-Title "Abstractions Manager" \
            ]
            
            if {[catch {set tok [::http::geturl $API_URL -headers $headers -query $rumpf -timeout [expr {$ZEITLIMIT * 1000}]]}]} {
                logger warning modell_fragen 0 "%s -> %s: %s bei %s" $name $zielsprache $::errorInfo $modell
                after [expr {min(pow(2, $versuch), 20) * 1000}]
                continue
            }
            
            set status [::http::status $tok]
            if {$status ne "ok"} {
                set code [::http::code $tok]
                set data [::http::data $tok]
                ::http::cleanup $tok
                set text [string range $data 0 199]
                logger warning modell_fragen 0 "%s -> %s: HTTP %s von %s (%s)" $name $zielsprache $code $modell $text
                if {$code in {400 401 402 404}} {
                    break
                }
                after [expr {min(pow(2, $versuch), 20) * 1000}]
                continue
            }
            
            set data [::http::data $tok]
            ::http::cleanup $tok
            if {[catch {set daten [::json::json2dict $data]}]} {
                logger warning modell_fragen 0 "%s -> %s: JSON decode error bei %s" $name $zielsprache $modell
                after [expr {min(pow(2, $versuch), 20) * 1000}]
                continue
            }
            
            set inhalt [dict get $daten choices 0 message content]
            if {$inhalt ne "" && [string trim $inhalt] ne ""} {
                return [_zaeune_entfernen $inhalt]
            }
            logger warning modell_fragen 0 "%s -> %s: leere Antwort von %s" $name $zielsprache $modell
            after [expr {min(pow(2, $versuch), 20) * 1000}]
        }
    }

    logger error modell_fragen 0 "%s -> %s: kein Modell hat geliefert" $name $zielsprache
    return ""
}

# ---------------------------------------------------------------------------
# Pruefung der Erzeugnisse
# ---------------------------------------------------------------------------

array set PRUEFBEFEHLE {
    javascript {node --check}
    perl5 {perl -c}
    powershell {pwsh -NoProfile -Command}
    shell {bash -n}
    tcl {tclsh}
}

set VERDACHT [list "TODO: Implementiere" "TODO: implement" "not implemented" "hier waere" "Platzhalter" "your code here" "pass  # TODO"]

proc erzeugnis_pruefen {code zielsprache {quelle ""}} {
    # Prueft ein Erzeugnis auf Brauchbarkeit.
    # 
    # Zuerst inhaltlich: erkennbar Unfertiges wird abgelehnt, ebenso ein
    # Erzeugnis, das gegenueber der Quelle auffaellig zusammengeschrumpft ist.
    # Die Mindestlaenge richtet sich nach der Quelle — ein dreizeiliger Aufrufer
    # darf auch in der Zielsprache drei Zeilen haben.
    # 
    # Danach, wenn der passende Interpreter vorhanden ist, die Syntax. Fehlt er,
    # gilt die inhaltliche Pruefung als ausreichend.
    # 
    # Returns:
    #     (angenommen, Begruendung)
    global PRUEFBEFEHLE VERDACHT ZIELSPRACHEN
    set quellzeilen [llength [split $quelle \n]]
    set zeilen [llength [lsearch -all -inline -not [split [string trim $code] \n] ""]]
    set mindestens [expr {max(2, min(6, $quellzeilen / 3))}]
    if {$quellzeilen == 0} {set mindestens 5}
    if {$zeilen < $mindestens} {
        return [list 0 "zu kurz ($zeilen statt mindestens $mindestens Zeilen)"]
    }

    # Ein Platzhalter zaehlt nur dann als Mangel, wenn er nicht schon im
    # Original steht. Sonst faellt jede treue Uebersetzung einer Datei durch,
    # die selbst Vorlagen mit TODO erzeugt.
    set niedrig [string tolower $quelle]
    foreach muster $VERDACHT {
        if {[string first [string tolower $muster] [string tolower $code]] >= 0 && [string first [string tolower $muster] $niedrig] < 0} {
            return [list 0 "unfertig ($muster)"]
        }
    }

    if {$zielsprache eq "python"} {
        if {[catch {exec python3 -c "compile(open(\"/dev/stdin\").read(), \"<erzeugnis>\", \"exec\")" << $code}]} {
            set fehler $::errorInfo
            if {[regexp {line (\d+)} $fehler match lineno]} {
                return [list 0 "Syntaxfehler Zeile $lineno"]
            } else {
                return [list 0 "Syntaxfehler"]
            }
        }
        return [list 1 "syntax ok"]
    }

    if {![info exists PRUEFBEFEHLE($zielsprache)]} {
        return [list 1 "ohne Syntaxpruefung angenommen"]
    }

    set endung [dict get $ZIELSPRACHEN($zielsprache) ext]
    set tempFile [fileutil::tempfile $endung]
    set fp [open $tempFile w]
    puts $fp $code
    close $fp

    if {$zielsprache eq "powershell"} {
        set aufruf [concat $PRUEFBEFEHLE($zielsprache) "\$null = \[ScriptBlock\]::Create((Get-Content -Raw '$tempFile'))"]
    } elseif {$zielsprache eq "tcl"} {
        set aufruf [list tclsh]
        if {[catch {exec tclsh << "if {\[catch {info complete \[read \[open $tempFile\]\]}\]} {exit 1}"} result]} {
            file delete $tempFile
            return [list 0 "Syntaxfehler"]
        }
        file delete $tempFile
        return [list 1 "syntax ok"]
    } else {
        set aufruf [concat $PRUEFBEFEHLE($zielsprache) $tempFile]
    }

    if {[catch {exec {*}$aufruf} result]} {
        set meldung $result
        file delete $tempFile
        # Eine fehlende Fremdbibliothek ist kein Mangel des Erzeugnisses,
        # sondern eine Luecke dieser Pruefumgebung. perl -c und node --check
        # brechen dann ab, obwohl die Syntax stimmt.
        if {[string first "Can't locate" $meldung] >= 0 || [string first "Cannot find module" $meldung] >= 0} {
            return [list 1 "Fremdmodul fehlt hier — Syntax nicht abschliessend geprueft"]
        }
        set erste [lindex [split $meldung \n] 0]
        if {[string length $erste] > 90} {
            set erste [string range $erste 0 89]
        }
        return [list 0 "Syntaxfehler: $erste"]
    }

    file delete $tempFile
    return [list 1 "syntax ok"]
}

# ---------------------------------------------------------------------------
# Ablage
# ---------------------------------------------------------------------------

proc _zieldatei {eintrag zielsprache belegt} {
    # Bestimmt den Dateinamen im Sprachverzeichnis.
    # 
    # Zwei verschiedene Quelldateien koennen denselben Stamm tragen — etwa
    # db_manager.py in OpenClaw und in Projects. In dem Fall wird der zweite
    # Name um die ersten sechs Stellen des Inhalts-Hashes ergaenzt, damit
    # nichts still ueberschrieben wird.
    global ABSTRACTIONS_REPO ZIELSPRACHEN
    set endung [dict get $ZIELSPRACHEN($zielsprache) ext]
    set stamm [dict get $eintrag stamm]
    set schluessel "$zielsprache/$stamm"
    if {[dict exists $belegt $schluessel] && [dict get $belegt $schluessel] ne [dict get $eintrag hash]} {
        set stamm "${stamm}_[string range [dict get $eintrag hash] 0 5]"
    } else {
        dict set belegt $schluessel [dict get $eintrag hash]
    }
    return [file join $ABSTRACTIONS_REPO $zielsprache ${stamm}${endung}]
}

proc _kopf {eintrag zielsprache} {
    # Setzt den Herkunftsvermerk als Kommentar in der Zielsprache.
    set zeichen [expr {$zielsprache eq "javascript" ? "//" : "#"}]
    set heute [clock format [clock seconds] -format "%Y-%m-%d" -timezone :UTC]
    set zeilen [list \
        "$zeichen [dict get $eintrag name] — portiert nach $zielsprache" \
        "$zeichen Quelle: [dict get $eintrag sprache], [lindex [dict get $eintrag herkunft] 0]" \
    ]
    foreach weitere [lrange [dict get $eintrag herkunft] 1 3] {
        lappend zeilen "$zeichen auch in: $weitere"
    }
    if {[llength [dict get $eintrag herkunft]] > 4} {
        lappend zeilen "$zeichen auch in: [expr {[llength [dict get $eintrag herkunft]] - 4}] weiteren Fundstellen"
    }
    lappend zeilen "$zeichen Erzeugt: $heute durch ABSTRACTIONS_MANAGER.py"
    return [join $zeilen \n]\n
}

proc ablegen {eintrag zielsprache code belegt} {
    # Schreibt ein geprueftes Erzeugnis atomar in sein Sprachverzeichnis.
    global ABSTRACTIONS_REPO ZIELSPRACHEN
    set ziel [_zieldatei $eintrag $zielsprache $belegt]
    if {[catch {file mkdir [file dirname $ziel]}]} {
        logger error ablegen 0 "%s konnte nicht abgelegt werden: %s" $ziel $::errorInfo
        return ""
    }
    
    set zeilen [split $code \n]
    if {[llength $zeilen] > 0 && [string match "#!*" [lindex $zeilen 0]]} {
        set inhalt "[lindex $zeilen 0]\n[_kopf $eintrag $zielsprache]\n[join [lrange $zeilen 1 end] \n]\n"
    } else {
        set inhalt "[_kopf $eintrag $zielsprache]\n$code"
    }
    
    set tempFile [fileutil::tempfile [dict get $ZIELSPRACHEN($zielsprache) ext]]
    set fp [open $tempFile w]
    puts -nonewline $fp $inhalt
    close $fp
    file rename -force $tempFile $ziel
    return $ziel
}

# ---------------------------------------------------------------------------
# Durchlauf
# ---------------------------------------------------------------------------

proc uebersetzen {inventar zustand prioritaet anzahl probelauf schluessel} {
    # Arbeitet das Inventar ab und erzeugt fehlende Uebersetzungen.
    # 
    # Jede Quelldatei wird in alle Zielsprachen ausser ihrer eigenen portiert.
    # Bereits erledigte Paare aus dem Zustand werden uebersprungen, ebenso
    # Zieldateien, die schon vorliegen.
    # 
    # Returns:
    #     Zaehlwerk mit erzeugt, uebersprungen und verworfen.
    global ZIELSPRACHEN
    set zaehler [dict create erzeugt 0 uebersprungen 0 verworfen 0 dateien 0]
    set belegt [dict create]
    set erledigt [dict get $zustand erledigt]

    set offen {}
    foreach e $inventar {
        if {$prioritaet eq "alle" || [dict get $e prioritaet] eq $prioritaet} {
            lappend offen $e
        }
    }
    logger info uebersetzen 0 "Prioritaet %s: %d Quelldateien im Bestand" $prioritaet [llength $offen]

    foreach eintrag $offen {
        if {[dict get $zaehler dateien] >= $anzahl} {
            logger info uebersetzen 0 "Kontingent von %d Quelldateien erreicht" $anzahl
            break
        }

        set fertig [dict get $erledigt [dict get $eintrag hash] {}]
        set ziele {}
        foreach z [array names ZIELSPRACHEN] {
            if {$z ne [dict get $eintrag sprache] && $z ni $fertig} {
                lappend ziele $z
            }
        }
        if {[llength $ziele] == 0} {
            continue
        }

        if {[catch {set quelle [read -nonewline [open [dict get $eintrag pfad] r]]} fehler]} {
            logger warning uebersetzen 0 "%s nicht lesbar: %s" [dict get $eintrag name] $fehler
            continue
        }

        dict incr zaehler dateien
        logger info uebersetzen 0 "\[%s\] %s (%s, %d B) -> %s" [dict get $eintrag prioritaet] [dict get $eintrag name] [dict get $eintrag sprache] [dict get $eintrag bytes] [join $ziele ", "]

        foreach zielsprache $ziele {
            if {$probelauf} {
                logger info uebersetzen 0 "  %s: Probelauf, nichts gesendet" $zielsprache
                dict incr zaehler uebersprungen
                continue
            }

            set code [modell_fragen $quelle [dict get $eintrag sprache] $zielsprache [dict get $eintrag name] $schluessel]
            if {$code eq ""} {
                dict incr zaehler verworfen
                continue
            }

            lassign [erzeugnis_pruefen $code $zielsprache $quelle] angenommen grund
            if {!$angenommen} {
                logger warning uebersetzen 0 "  %s: verworfen — %s" $zielsprache $grund
                dict incr zaehler verworfen
                continue
            }

            set ziel [ablegen $eintrag $zielsprache $code $belegt]
            if {$ziel eq ""} {
                dict incr zaehler verworfen
                continue
            }

            logger info uebersetzen 0 "  %s: %s (%s)" $zielsprache [file tail $ziel] $grund
            dict incr zaehler erzeugt
            lappend fertig $zielsprache
        }

        dict set erledigt [dict get $eintrag hash
