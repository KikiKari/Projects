#!/usr/bin/env python3
# test_native_peak_limiter.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

import sys
import struct
import subprocess
import math
from typing import List, Tuple

# Importiere das createPeakLimiter Modul (muss als Python-Modul verfügbar sein)
# Beispiel: content_core.py mit einer Funktion createPeakLimiter
try:
    from content_core import createPeakLimiter
except ImportError:
    raise ImportError("Konnte content_core.createPeakLimiter nicht importieren")

def float_array_to_bytes(arr: List[float]) -> bytes:
    """Konvertiert ein Array von Floats in Bytes im Little Endian Format."""
    return struct.pack('<' + 'f' * len(arr), *arr)

def bytes_to_float_array(data: bytes) -> List[float]:
    """Konvertiert Bytes im Little Endian Format in ein Array von Floats."""
    count = len(data) // 4
    return list(struct.unpack('<' + 'f' * count, data))

def main():
    if len(sys.argv) < 2:
        print("Pass compiled mobile/shared/native/limiter_trace.c executable", file=sys.stderr)
        sys.exit(1)

    executable = sys.argv[1]
    cases = 0

    for rate in [44100, 48000, 96000]:
        for channels in [1, 2, 6]:
            for enabled, strength in [[False, 100], [True, 25], [True, 75], [True, 100]]:
                frames = round(rate * 0.25)
                input_channels = []
                
                # Erzeuge Eingabesignale für jeden Kanal
                for c in range(channels):
                    channel_data = []
                    for i in range(frames):
                        if i == 5 or i == 129:
                            value = -0.95 if c % 2 else 0.95
                        elif i == 300:
                            value = float('nan')
                        elif i == 301:
                            value = float('inf')
                        else:
                            freq = 8000 if i < 2000 else 220
                            amp = 0.9 if i < 2000 else 0.01
                            value = (c + 1) / channels * math.sin(i * 2 * math.pi * freq / rate) * amp
                        channel_data.append(value)
                    input_channels.append(channel_data)

                # Erzeuge Kernel
                kernel = createPeakLimiter(rate)
                
                # Berechne Gesamtanzahl an Frames inklusive Delay
                count = frames + kernel['delaySamples']
                
                # Erzeuge Wire-Daten (Bytes)
                wire = bytearray(count * channels * 4)
                for i in range(count):
                    for c in range(channels):
                        idx = (i * channels + c) * 4
                        sample = input_channels[c][i] if i < len(input_channels[c]) else 0.0
                        # Packe den Float-Wert in Little Endian in die Bytes
                        struct.pack_into('<f', wire, idx, sample)

                # Führe das externe Programm aus
                result = subprocess.run(
                    [executable] + [str(x) for x in [rate, channels, int(enabled), strength]],
                    input=wire,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    check=False
                )

                # Überprüfe den Exit-Status
                if result.returncode != 0:
                    error_msg = result.stderr.decode() if result.stderr else "Unknown error"
                    raise AssertionError(f"Process failed with exit code {result.returncode}: {error_msg}")

                # Überprüfe die Länge der Ausgabe
                expected_length = len(wire)
                if len(result.stdout) != expected_length:
                    raise AssertionError(f"Output length mismatch: expected {expected_length}, got {len(result.stdout)}")

                # Überprüfe die Genauigkeit
                max_error = 0.0
                for start in range(0, count, 127):
                    size = min(127, count - start)
                    
                    # Erzeuge Block und Output Arrays
                    block = []
                    output = []
                    for c in range(channels):
                        channel_block = []
                        for i in range(size):
                            if start + i < len(input_channels[c]):
                                channel_block.append(input_channels[c][start + i])
                            else:
                                channel_block.append(0.0)
                        block.append(channel_block)
                        output.append([0.0] * size)
                    
                    # Verarbeite den Block
                    kernel['process'](block, output, enabled, strength)
                    
                    # Vergleiche die Ergebnisse
                    for i in range(size):
                        for c in range(channels):
                            # Lies den tatsächlichen Wert aus dem stdout
                            idx = ((start + i) * channels + c) * 4
                            actual_bytes = result.stdout[idx:idx+4]
                            if len(actual_bytes) < 4:
                                raise AssertionError("Unexpected end of stdout")
                            actual = struct.unpack('<f', actual_bytes)[0]
                            
                            # Überprüfe, ob der Wert endlich ist
                            if not math.isfinite(actual):
                                raise AssertionError(f"Non-finite value encountered: {actual}")
                            
                            # Berechne den Fehler
                            error = abs(actual - output[c][i])
                            max_error = max(max_error, error)

                # Überprüfe den maximalen Fehler
                if max_error > 1e-7:
                    raise AssertionError(f"{rate}/{channels}/{enabled}/{strength}: {max_error}")

                cases += 1

    print(f"{cases} native/JavaScript PCM equivalence cases passed (error <= 1e-7).")

if __name__ == "__main__":
    main()
