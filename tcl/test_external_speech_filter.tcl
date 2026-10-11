#!/usr/bin/env tclsh
# test_external_speech_filter.cjs — portiert nach tcl
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Tcl-Paket fuer grundlegende Funktionen
package require Tcl 8.6

# Da Tcl keine direkte Entsprechung zu Node.js "require" hat,
# muessen wir die benoetigten Funktionen direkt implementieren.
# Die Funktion "shouldFilterExternalSpeechTrigger" wird hier simuliert.

# Simulierte Funktion shouldFilterExternalSpeechTrigger
proc shouldFilterExternalSpeechTrigger {text enabled} {
    # In Tcl ist "enabled && ..." aequivalent zu "$enabled && ..."
    # Wir pruefen, ob enabled true ist und der Text nach trimStart mit '.' beginnt
    if {$enabled} {
        # Entferne fuehrende Leerzeichen (entspricht trimStart)
        set trimmed [string trimleft $text]
        # Pruefe, ob der Text mit '.' beginnt
        return [string match .* $trimmed]
    } else {
        return false
    }
}

# Testfaelle definieren
set testCases [list]
foreach enabled [list false true] {
    foreach text [list ".Text" ". Text" "  .Text" "\t\n. Text" "Normal" "Ein Satz. Noch einer" ""] {
        lappend testCases [list $enabled $text]
    }
}

# Fuehre Tests durch
foreach case $testCases {
    lassign $case enabled text
    set result [shouldFilterExternalSpeechTrigger $text $enabled]
    set expected [expr {$enabled && [string match .* [string trimleft $text]]}]
    
    # Ausgabe wie im Original
    puts -nonewline "Test "
    puts -nonewline [format "%s" [list enabled=$enabled text=$text]]
    puts -nonewline ": "
    
    if {$result == $expected} {
        puts "PASS"
    } else {
        puts "FAIL (got $result, expected $expected)"
    }
}
