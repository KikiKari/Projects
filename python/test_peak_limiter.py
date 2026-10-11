#!/usr/bin/env python3
# test_peak_limiter.cjs — portiert nach python
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

import math
import unittest
from typing import List, Tuple, Optional
import numpy as np

# Assuming content_core.py exists with equivalent functions
from content_core import createPeakLimiter, limiterStrengthToDbfs


def render(signal: List[List[float]], strength: int, rate: int = 48000, enabled: bool = True) -> dict:
    """Process the signal through the peak limiter."""
    kernel = createPeakLimiter(rate)
    
    # Create output arrays with padding for delay
    output = []
    for channel in signal:
        output.append([0.0] * (len(channel) + kernel.delaySamples))
    
    # Process in chunks of 128 samples
    start = 0
    while start < len(output[0]):
        length = min(128, len(output[0]) - start)
        
        # Prepare input chunk
        input_chunk = []
        for ch in signal:
            chunk = []
            for i in range(length):
                idx = start + i
                if idx < len(ch):
                    chunk.append(ch[idx])
                else:
                    chunk.append(0.0)
            input_chunk.append(chunk)
            
        # Prepare output subarrays
        output_chunks = []
        for ch in output:
            output_chunks.append(ch[start:start+length])
            
        # Process the chunk
        kernel.process(input_chunk, output_chunks, enabled, strength)
        start += length
        
    return {"output": output, "delay": kernel.delaySamples}


def peak(channel: List[float]) -> float:
    """Find the maximum absolute value in a channel."""
    return max(abs(value) for value in channel)


class TestPeakLimiter(unittest.TestCase):
    
    def test_isolated_and_high_frequency_peaks_bounded(self):
        for rate in [44100, 48000, 96000]:
            with self.subTest(rate=rate):
                signal = [0.0] * rate
                signal[1] = 1.0
                signal[127] = -1.0
                
                # Add high frequency sine wave
                for i in range(1000, 1100):
                    signal[i] = math.sin(2 * math.pi * 8000 * i / rate)
                    
                previous = 1.0
                for strength in [25, 75, 100]:
                    result = render([signal], strength, rate)
                    output = result["output"]
                    delay = result["delay"]
                    
                    measured = peak(output[0])
                    ceiling = 10 ** (limiterStrengthToDbfs(strength) / 20)
                    
                    self.assertTrue(measured <= ceiling + 1e-7, 
                                  f"{measured} exceeds {ceiling}")
                    self.assertTrue(measured < previous, 
                                  "higher strength must attenuate more")
                    self.assertTrue(delay / rate <= 0.01)
                    previous = measured

    def test_bypass_preserves_every_sample_with_documented_delay(self):
        signal = [math.sin(i * 0.7) * 0.8 for i in range(10000)]
        result = render([signal], 100, 48000, False)
        output = result["output"]
        delay = result["delay"]
        
        # Compare delayed output with original signal
        output_slice = output[0][delay:]
        self.assertEqual(len(output_slice), len(signal))
        for i in range(len(signal)):
            self.assertAlmostEqual(output_slice[i], signal[i], places=10)

    def test_quiet_speech_band_signal_not_permanently_attenuated(self):
        signal = [0.01 * math.sin(i * 2 * math.pi * 200 / 48000) for i in range(48000)]
        result = render([signal], 100)
        output = result["output"]
        delay = result["delay"]
        
        # Compare delayed output with original signal
        output_slice = output[0][delay:]
        self.assertEqual(len(output_slice), len(signal))
        for i in range(len(signal)):
            self.assertAlmostEqual(output_slice[i], signal[i], places=10)

    def test_linked_stereo_gain_preserves_balance_and_limits_either_channel(self):
        left = [0.0] * 1000
        left[127] = 0.5
        right = [0.0] * 1000
        right[127] = 1.0
        
        result = render([left, right], 100)
        output = result["output"]
        delay = result["delay"]
        
        # Check balance preservation
        self.assertAlmostEqual(output[0][127 + delay] * 2, output[1][127 + delay], places=10)
        
        # Check limiting (should be below -30dBFS)
        measured_peak = peak(output[1])
        expected_ceiling = 10 ** (-30 / 20)
        self.assertTrue(measured_peak <= expected_ceiling + 1e-7)

    def test_gain_recovers_after_transient_and_invalid_samples_handled(self):
        signal = [0.0] * 48000
        signal[10] = 1.0
        signal[100] = float('nan')
        signal[200] = float('inf')
        
        # Add quiet steady signal after transient
        for i in range(24000, len(signal)):
            signal[i] = 0.01
            
        result = render([signal], 100)
        output = result["output"][0]
        
        # All values should be finite
        self.assertTrue(all(math.isfinite(x) for x in output))
        
        # Gain should recover (check later part of signal)
        recovered_section = output[40000:]
        self.assertTrue(any(x > 0.00999 for x in recovered_section))

    def test_empty_input_drains_delayed_audio_and_returns_to_silence(self):
        kernel = createPeakLimiter(48000)
        block = [0.01] * 128
        out = [0.0] * 128
        
        # Process initial block
        kernel.process([block], [out], True, 100)
        
        # Drain with empty inputs
        for _ in range(4):
            kernel.process([[]], [out], True, 100)
            
        # Should return to silence
        self.assertEqual(peak(out), 0.0)


if __name__ == "__main__":
    unittest.main()
