#!/usr/bin/env bash
# test_external_speech_filter.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Funktion zur Normalisierung von externen Sprachauslöserzeichen
normalize_external_speech_trigger_characters() {
    local input="$1"
    
    # undefined wird zu '.'
    if [[ "$input" == "undefined" ]]; then
        echo "."
        return
    fi
    
    # Leerer String bleibt leer
    if [[ -z "$input" ]]; then
        echo ""
        return
    fi
    
    # Entferne alle Zeichen außer .,-;:! und Emoji (begrenzt auf die ersten 5)
    # Für dieses Beispiel beschränken wir uns auf ASCII-Zeichen
    local result=""
    local valid_chars=".,-;:!"
    local count=0
    
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        if [[ "$valid_chars" == *"$char"* ]] && [[ $count -lt 5 ]]; then
            result+="$char"
            ((count++))
        fi
    done
    
    # Bei Leerzeichen am Anfang/Ende entfernen
    result="$(echo "$result" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    
    echo "$result"
}

# Funktion zum Prüfen, ob ein Text gefiltert werden soll
should_filter_external_speech_trigger() {
    local text="$1"
    local enabled="$2"
    local prefixes="${3:-}" # Standardmäßig leer
    
    # Wenn nicht aktiviert, immer false
    if [[ "$enabled" != "true" ]]; then
        echo "false"
        return
    fi
    
    # Text trimmen (Leerzeichen am Anfang entfernen)
    local trimmed_text="${text#"${text%%[![:space:]]*}"}"
    
    # Prüfe, ob der Text mit einem der Prefixe beginnt
    if [[ -n "$prefixes" ]]; then
        for (( i=0; i<${#prefixes}; i++ )); do
            prefix="${prefixes:$i:1}"
            if [[ "$trimmed_text" == "$prefix"* ]]; then
                echo "true"
                return
            fi
        done
        echo "false"
        return
    else
        # Standardverhalten: Prüfe, ob mit '.' beginnend
        if [[ "$trimmed_text" == .* ]]; then
            echo "true"
            return
        fi
    fi
    
    echo "false"
}

# Testfälle ausführen
run_tests() {
    local test_count=0
    local passed=0
    
    # Erster Testsatz
    for enabled in false true; do
        for text in ".Text" ". Text" "  .Text" $'\t\n. Text' "Normal" "Ein Satz. Noch einer" ""; do
            expected="false"
            if [[ "$enabled" == "true" ]] && [[ "${text#"${text%%[![:space:]]*}"}" == .* ]]; then
                expected="true"
            fi
            
            result=$(should_filter_external_speech_trigger "$text" "$enabled")
            
            if [[ "$result" == "$expected" ]]; then
                ((passed++))
            else
                echo "FEHLER: should_filter_external_speech_trigger('$text', $enabled) = $result, erwartet: $expected"
            fi
            ((test_count++))
        done
    done
    
    # Zweiter Testsatz (0PE-187)
    for enabled in false true; do
        # Positiv-Tests
        for text in ".Hallo" ",Hallo" "- Hallo" "  , Hallo"; do
            result=$(should_filter_external_speech_trigger "$text" "$enabled" ".,-")
            expected="false"
            if [[ "$enabled" == "true" ]]; then
                expected="true"
            fi
            
            if [[ "$result" == "$expected" ]]; then
                ((passed++))
            else
                echo "FEHLER: should_filter_external_speech_trigger('$text', $enabled, '.,-') = $result, erwartet: $expected"
            fi
            ((test_count++))
        done
        
        # Negativ-Tests
        for text in "Hallo, zusammen." "Normal-Text" "Hallo" "."; do
            result=$(should_filter_external_speech_trigger "$text" "$enabled" ",-")
            expected="false"
            
            if [[ "$result" == "$expected" ]]; then
                ((passed++))
            else
                echo "FEHLER: should_filter_external_speech_trigger('$text', $enabled, ',-') = $result, erwartet: $expected"
            fi
            ((test_count++))
        done
        
        # Spezielle Zeichen
        result=$(should_filter_external_speech_trigger ";Hallo" "$enabled" ";")
        expected="false"
        if [[ "$enabled" == "true" ]]; then
            expected="true"
        fi
        
        if [[ "$result" == "$expected" ]]; then
            ((passed++))
        else
            echo "FEHLER: should_filter_external_speech_trigger(';Hallo', $enabled, ';') = $result, erwartet: $expected"
        fi
        ((test_count++))
        
        result=$(should_filter_external_speech_trigger "[Hallo" "$enabled" "[")
        expected="false"
        if [[ "$enabled" == "true" ]]; then
            expected="true"
        fi
        
        if [[ "$result" == "$expected" ]]; then
            ((passed++))
        else
            echo "FEHLER: should_filter_external_speech_trigger('[Hallo', $enabled, '[') = $result, erwartet: $expected"
        fi
        ((test_count++))
        
        result=$(should_filter_external_speech_trigger "Hallo" "$enabled" "[")
        expected="false"
        
        if [[ "$result" == "$expected" ]]; then
            ((passed++))
        else
            echo "FEHLER: should_filter_external_speech_trigger('Hallo', $enabled, '[') = $result, erwartet: $expected"
        fi
        ((test_count++))
    done
    
    # Dritter Testsatz (0PE-187)
    # normalize tests
    result=$(normalize_external_speech_trigger_characters "undefined")
    expected="."
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: normalize_external_speech_trigger_characters(undefined) = '$result', erwartet: '$expected'"
    fi
    ((test_count++))
    
    result=$(normalize_external_speech_trigger_characters "")
    expected=""
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: normalize_external_speech_trigger_characters('') = '$result', erwartet: '$expected'"
    fi
    ((test_count++))
    
    result=$(normalize_external_speech_trigger_characters ".,-;:!")
    expected=".,-;:"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: normalize_external_speech_trigger_characters('.,-;:!') = '$result', erwartet: '$expected'"
    fi
    ((test_count++))
    
    result=$(normalize_external_speech_trigger_characters " a1 \"'.,- ")
    expected=".,-"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: normalize_external_speech_trigger_characters(' a1 \"'.,- ') = '$result', erwartet: '$expected'"
    fi
    ((test_count++))
    
    # Emoji-Test (vereinfacht)
    result=$(normalize_external_speech_trigger_characters "😀😁😂😃😄😅")
    expected="😀😁😂😃😄"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: normalize_external_speech_trigger_characters('😀😁😂😃😄😅') = '$result', erwartet: '$expected'"
    fi
    ((test_count++))
    
    # Filter-Tests mit Emojis
    result=$(should_filter_external_speech_trigger "😀Hallo" "true" "😀")
    expected="true"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: should_filter_external_speech_trigger('😀Hallo', true, '😀') = $result, erwartet: $expected"
    fi
    ((test_count++))
    
    result=$(should_filter_external_speech_trigger ".Hallo" "true" "")
    expected="false"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: should_filter_external_speech_trigger('.Hallo', true, '') = $result, erwartet: $expected"
    fi
    ((test_count++))
    
    result=$(should_filter_external_speech_trigger ".Hallo" "true" ",")
    expected="false"
    if [[ "$result" == "$expected" ]]; then
        ((passed++))
    else
        echo "FEHLER: should_filter_external_speech_trigger('.Hallo', true, ',') = $result, erwartet: $expected"
    fi
    ((test_count++))
    
    echo "Tests durchgeführt: $test_count, Erfolgreich: $passed"
    if [[ $passed -eq $test_count ]]; then
        echo "Alle Tests erfolgreich!"
        return 0
    else
        echo "Einige Tests sind fehlgeschlagen!"
        return 1
    fi
}

# Hauptprogramm
run_tests
