#!/bin/bash
# test_external_speech_filter.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Funktion zur Überprüfung, ob ein externer Sprachauslöser gefiltert werden soll
shouldFilterExternalSpeechTrigger() {
    local text="$1"
    local enabled="$2"
    
    # Wenn nicht aktiviert, dann nicht filtern
    if [[ "$enabled" != "true" ]]; then
        echo "false"
        return
    fi
    
    # Text trimmen und prüfen, ob er mit einem Punkt beginnt
    local trimmed_text="${text#"${text%%[![:space:]]*}"}"  # ltrim
    if [[ "$trimmed_text" == .* ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Testfälle definieren
test_cases() {
    local enabled_values=("false" "true")
    local text_values=(".Text" ". Text" "  .Text" $'\t\n. Text' "Normal" "Ein Satz. Noch einer" "")
    
    for enabled in "${enabled_values[@]}"; do
        for text in "${text_values[@]}"; do
            # JSON-artigen String für die Testbezeichnung erstellen
            printf '{enabled:%s,text:%s}' "$enabled" "$(printf '%q' "$text")"
            echo
        done
    done
}

# Tests durchführen
while IFS= read -r testcase; do
    # Extrahiere enabled und text aus dem Testfall (rudimentärer Parser)
    enabled=$(echo "$testcase" | sed -n 's/.*{enabled:\([^,]*\),text:.*/\1/p')
    text=$(echo "$testcase" | sed -n 's/.*text:\(.*\)}.*/\1/p' | sed 's/\\//g')
    
    # Sonderfälle für Whitespace behandeln
    case "$testcase" in
        *'\\t\\n. Text'*)
            text=$'\t\n. Text'
            ;;
    esac
    
    # Ergebnis berechnen
    result=$(shouldFilterExternalSpeechTrigger "$text" "$enabled")
    
    # Erwartetes Ergebnis bestimmen
    expected="false"
    if [[ "$enabled" == "true" ]]; then
        # Prüfe, ob der Text mit einem Punkt beginnt (nach Trim)
        trimmed_text="${text#"${text%%[![:space:]]*}"}"
        if [[ "$trimmed_text" == .* ]]; then
            expected="true"
        fi
    fi
    
    # Testergebnis ausgeben
    if [[ "$result" == "$expected" ]]; then
        echo "PASS: $testcase -> $result"
    else
        echo "FAIL: $testcase -> expected $expected, got $result"
        exit 1
    fi
done < <(test_cases)
