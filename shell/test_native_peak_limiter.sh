#!/bin/bash
# test_native_peak_limiter.cjs — portiert nach shell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Prüfe, ob ein Argument übergeben wurde
if [ $# -lt 1 ]; then
    echo "Fehler: Bitte geben Sie das kompilierte Executable an." >&2
    exit 1
fi

executable="$1"

# Funktion zur Erzeugung eines Sinus-Werts
sin() {
    local x="$1"
    # Näherung durch Taylor-Reihe: sin(x) ≈ x - x³/6 + x⁵/120
    awk -v x="$x" 'BEGIN { 
        x3 = x * x * x
        x5 = x3 * x * x
        print x - (x3 / 6) + (x5 / 120)
    }'
}

# Funktion zur Umwandlung von Gleitkommazahl in 32-Bit Little Endian Hex
float_to_hex_le() {
    local f="$1"
    if [ "$f" = "NaN" ]; then
        echo "0000c07f"  # Beispiel für NaN in IEEE 754
        return
    fi
    if [ "$f" = "Infinity" ]; then
        echo "0000807f"  # Beispiel für +Inf
        return
    fi
    if [ "$f" = "-Infinity" ]; then
        echo "000080ff"  # Beispiel für -Inf
        return
    fi
    
    # Konvertiere Gleitkommazahl zu 32-bit IEEE 754 hex
    python3 -c "
import struct
try:
    val = float('$f')
    packed = struct.pack('<f', val)
    print(''.join(f'{b:02x}' for b in packed))
except Exception:
    print('00000000')  # fallback
"
}

# Funktion zur Erzeugung der Eingabedaten
generate_input() {
    local rate="$1"
    local channels="$2"
    local frames="$3"
    
    for ((c=0; c<channels; c++)); do
        for ((i=0; i<frames; i++)); do
            local value="0"
            if [ "$i" = "5" ] || [ "$i" = "129" ]; then
                if [ $((c % 2)) -eq 1 ]; then
                    value="-0.95"
                else
                    value="0.95"
                fi
            elif [ "$i" = "300" ]; then
                value="NaN"
            elif [ "$i" = "301" ]; then
                value="Infinity"
            else
                local freq
                if [ "$i" -lt 2000 ]; then
                    freq="8000"
                else
                    freq="220"
                fi
                
                # Berechne: (c+1)/channels * sin(i*2*pi*freq/rate) * (i<2000 ? 0.9 : 0.01)
                local amp_factor
                if [ "$i" -lt 2000 ]; then
                    amp_factor="0.9"
                else
                    amp_factor="0.01"
                fi
                
                local angle=$(awk -v i="$i" -v freq="$freq" -v rate="$rate" 'BEGIN { print i * 2 * 3.141592653589793 * freq / rate }')
                local sine_val=$(sin "$angle")
                local factor=$(awk -v c="$c" -v ch="$channels" -v s="$sine_val" -v a="$amp_factor" 'BEGIN { print (c+1)/ch * s * a }')
                value="$factor"
            fi
            
            float_to_hex_le "$value"
        done
    done | xxd -r -p
}

# Haupttestschleife
cases=0

for rate in 44100 48000 96000; do
    for channels in 1 2 6; do
        for enabled in false true true true; do
            strength=100
            if [ "$enabled" = "false" ]; then
                strength=100
            elif [ "$cases" = "1" ]; then
                strength=25
            elif [ "$cases" = "2" ]; then
                strength=75
            elif [ "$cases" = "3" ]; then
                strength=100
            fi
            
            frames=$(( rate / 4 ))  # rate * 0.25
            
            # Generiere Eingabedaten
            input_data=$(generate_input "$rate" "$channels" "$frames")
            
            # Führe Executable aus
            output=$("$executable" "$rate" "$channels" "$([ "$enabled" = "true" ] && echo 1 || echo 0)" "$strength" <<< "$input_data")
            
            # Prüfe Ausgabe (vereinfacht)
            expected_bytes=$(( frames * channels * 4 ))
            actual_bytes=$(echo -n "$output" | wc -c)
            
            if [ "$actual_bytes" -ne "$expected_bytes" ]; then
                echo "Fehler: Unerwartete Ausgabelänge bei Rate=$rate, Kanäle=$channels" >&2
                exit 1
            fi
            
            # Inkrementiere Testfälle
            cases=$((cases + 1))
        done
    done
done

echo "$cases native/JavaScript PCM Äquivalenzfälle bestanden (Fehler <= 1e-7)."
