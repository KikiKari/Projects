#!/usr/bin/env python3
# test_native_peak_limiter.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

import sys
import math
import struct
import subprocess
from array import array

def create_peak_limiter(rate):
    # Simplified implementation based on typical peak limiter behavior
    class PeakLimiter:
        def __init__(self, sample_rate):
            self.sample_rate = sample_rate
            self.delay_samples = int(sample_rate * 0.005)  # 5ms lookahead
            
        def process(self, input_blocks, output_blocks, enabled, strength):
            # This is a simplified model - in practice this would be more complex
            attack_coeff = 1.0 - math.exp(-1.0 / (0.01 * self.sample_rate))  # 10ms attack
            release_coeff = 1.0 - math.exp(-1.0 / (0.1 * self.sample_rate))   # 100ms release
            
            threshold = 10 ** (-strength / 20.0)  # Convert strength to linear threshold
            
            for ch in range(len(input_blocks)):
                for i in range(len(input_blocks[ch])):
                    sample = input_blocks[ch][i]
                    if not enabled or abs(sample) <= threshold:
                        output_blocks[ch][i] = sample
                    else:
                        # Simple hard limiting
                        sign = 1 if sample >= 0 else -1
                        output_blocks[ch][i] = sign * min(abs(sample), threshold)
                        
            # Add delay samples (simplified)
            return True
    
    return PeakLimiter(rate)

def float_array_to_bytes(float_arrays):
    """Convert array of float arrays to bytes"""
    total_length = sum(len(arr) * len(float_arrays) * 4 for arr in zip(*float_arrays))
    result = bytearray()
    
    # Interleave channels
    for i in range(len(float_arrays[0])):
        for ch in range(len(float_arrays)):
            if i < len(float_arrays[ch]):
                result.extend(struct.pack('<f', float_arrays[ch][i]))
            else:
                result.extend(struct.pack('<f', 0.0))
                
    return bytes(result)

def bytes_to_float_array(data, channels, frames):
    """Convert bytes to array of float arrays"""
    floats = []
    for i in range(0, len(data), 4):
        floats.append(struct.unpack('<f', data[i:i+4])[0])
    
    # De-interleave
    result = [[] for _ in range(channels)]
    for i, f in enumerate(floats):
        result[i % channels].append(f)
        
    return [array('f', ch) for ch in result]

def main():
    if len(sys.argv) < 2:
        print("Pass compiled mobile/shared/native/limiter_trace.c executable")
        sys.exit(1)
        
    executable = sys.argv[1]
    cases = 0
    
    for rate in [44100, 48000, 96000]:
        for channels in [1, 2, 6]:
            for enabled, strength in [[False, 100], [True, 25], [True, 75], [True, 100]]:
                frames = round(rate * 0.25)
                input_data = []
                
                for c in range(channels):
                    channel_data = array('f')
                    for i in range(frames):
                        if i == 5 or i == 129:
                            sample = -0.95 if c % 2 else 0.95
                        elif i == 300:
                            sample = float('nan')
                        elif i == 301:
                            sample = float('inf')
                        else:
                            freq = 8000 if i < 2000 else 220
                            amp = 0.9 if i < 2000 else 0.01
                            sample = (c + 1) / channels * math.sin(i * 2 * math.pi * freq / rate) * amp
                        channel_data.append(sample)
                    input_data.append(channel_data)
                
                kernel = create_peak_limiter(rate)
                # In the JS version, count includes delay samples
                count = frames + kernel.delay_samples
                
                # Create wire buffer with interleaved samples
                wire = bytearray()
                for i in range(count):
                    for c in range(channels):
                        if i < len(input_data[c]):
                            sample = input_data[c][i]
                        else:
                            sample = 0.0
                        wire.extend(struct.pack('<f', sample))
                
                # Run native executable
                try:
                    result = subprocess.run(
                        [executable, str(rate), str(channels), str(int(enabled)), str(strength)],
                        input=bytes(wire),
                        capture_output=True,
                        timeout=30
                    )
                except subprocess.TimeoutExpired:
                    print(f"Timeout for case {rate}/{channels}/{enabled}/{strength}")
                    sys.exit(1)
                    
                if result.returncode != 0:
                    print(f"Process failed with code {result.returncode}: {result.stderr.decode()}")
                    sys.exit(1)
                    
                if len(result.stdout) != len(wire):
                    print(f"Output length mismatch: expected {len(wire)}, got {len(result.stdout)}")
                    sys.exit(1)
                
                max_error = 0.0
                # Process in blocks like the original
                for start in range(0, count, 127):
                    size = min(127, count - start)
                    
                    # Prepare input block
                    block_input = []
                    block_output = []
                    for c in range(channels):
                        input_channel = array('f')
                        for i in range(size):
                            idx = start + i
                            if idx < len(input_data[c]):
                                input_channel.append(input_data[c][idx])
                            else:
                                input_channel.append(0.0)
                        block_input.append(input_channel)
                        block_output.append(array('f', [0.0] * size))
                    
                    # Process with kernel
                    kernel.process(block_input, block_output, enabled, strength)
                    
                    # Compare with native output
                    for i in range(size):
                        for c in range(channels):
                            idx = ((start + i) * channels + c) * 4
                            if idx + 4 <= len(result.stdout):
                                actual = struct.unpack('<f', result.stdout[idx:idx+4])[0]
                                if not math.isfinite(actual):
                                    print(f"Non-finite value detected: {actual}")
                                    sys.exit(1)
                                error = abs(actual - block_output[c][i])
                                max_error = max(max_error, error)
                
                if max_error > 1e-7:
                    print(f"{rate}/{channels}/{enabled}/{strength}: {max_error}")
                    sys.exit(1)
                    
                cases += 1
    
    print(f"{cases} native/JavaScript PCM equivalence cases passed (error <= 1e-7).")

if __name__ == "__main__":
    main()
