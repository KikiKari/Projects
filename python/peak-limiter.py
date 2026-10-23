#!/usr/bin/env python3
# peak-limiter.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import json
import math
import sys
from typing import List, Dict, Any, Optional, Tuple


def limiter_strength_to_dbfs(strength: int) -> float:
    """Convert limiter strength to dBFS threshold."""
    return -0.02 * strength - 6


def limiter_makeup_compensation(threshold: float, knee: float) -> float:
    """Calculate makeup gain compensation."""
    # Simplified version based on the original JS logic
    return -threshold * 0.5  # Approximation


class AudioBuffer:
    """Represents an audio buffer with channel data."""
    
    def __init__(self, channels: int, length: int, sample_rate: int):
        self.channels = channels
        self.length = length
        self.sample_rate = sample_rate
        self._channel_data = [[0.0] * length for _ in range(channels)]
    
    def get_channel_data(self, channel: int) -> List[float]:
        """Get channel data as a list of floats."""
        return self._channel_data[channel]


class DynamicsCompressor:
    """Simplified dynamics compressor implementation."""
    
    def __init__(self):
        self.threshold = 0.0
        self.knee = 0.0
        self.ratio = 1.0
        self.attack = 0.0
        self.release = 0.0
        self._makeup_gain = 1.0
    
    def set_makeup_gain(self, gain_db: float):
        """Set makeup gain in dB."""
        self._makeup_gain = 10 ** (gain_db / 20)
    
    def process(self, input_data: List[float]) -> List[float]:
        """Process audio data through compressor."""
        # Simplified processing - this is not accurate but serves the test purpose
        output = []
        for sample in input_data:
            # Apply compression curve
            abs_sample = abs(sample)
            if abs_sample > 10**(self.threshold/20):
                # Simple compression approximation
                compressed = sample * (10**(self.threshold/20) / abs_sample) if abs_sample > 0 else 0
                output.append(compressed * self._makeup_gain)
            else:
                output.append(sample * self._makeup_gain)
        return output


class PeakLimiterNode:
    """Simplified peak limiter node implementation."""
    
    def __init__(self, context):
        self.context = context
        self.enabled = False
        self.strength = 100
    
    def set_protection(self, config: Dict[str, Any]):
        """Configure protection settings."""
        self.enabled = config.get('enabled', False)
        self.strength = config.get('strength', 100)
    
    def process(self, input_data: List[float]) -> List[float]:
        """Process audio data through limiter."""
        if not self.enabled:
            return input_data[:]
        
        threshold = limiter_strength_to_dbfs(self.strength)
        threshold_linear = 10 ** (threshold / 20)
        
        output = []
        for sample in input_data:
            if abs(sample) > threshold_linear:
                # Hard limiting
                sign = 1 if sample >= 0 else -1
                output.append(sign * threshold_linear)
            else:
                output.append(sample)
        return output


def peak_db(values: List[float]) -> float:
    """Calculate peak level in dBFS."""
    max_val = max(abs(v) for v in values) if values else 1e-10
    return 20 * math.log10(max(max_val, 1e-10))


def create_buffer_source(buffer: AudioBuffer) -> 'AudioBufferSource':
    """Create a buffer source."""
    return AudioBufferSource(buffer)


class AudioBufferSource:
    """Audio buffer source."""
    
    def __init__(self, buffer: AudioBuffer):
        self.buffer = buffer
        self._connections = []
    
    def connect(self, destination):
        """Connect to destination."""
        self._connections.append(destination)
        return destination


def create_dynamics_compressor() -> DynamicsCompressor:
    """Create a dynamics compressor."""
    return DynamicsCompressor()


def create_gain() -> 'GainNode':
    """Create a gain node."""
    return GainNode()


class GainNode:
    """Simple gain node."""
    
    def __init__(self):
        self.gain = 1.0
        self._connections = []
    
    def connect(self, destination):
        """Connect to destination."""
        self._connections.append(destination)
        return destination


class OfflineAudioContext:
    """Offline audio context for rendering audio."""
    
    def __init__(self, channels: int, length: int, sample_rate: int):
        self.channels = channels
        self.length = length
        self.sample_rate = sample_rate
    
    def create_buffer(self, channels: int, length: int, sample_rate: int) -> AudioBuffer:
        """Create an audio buffer."""
        return AudioBuffer(channels, length, sample_rate)
    
    def create_dynamics_compressor(self) -> DynamicsCompressor:
        """Create a dynamics compressor."""
        return create_dynamics_compressor()
    
    def create_gain(self) -> GainNode:
        """Create a gain node."""
        return create_gain()
    
    async def start_rendering(self) -> AudioBuffer:
        """Start rendering and return result buffer."""
        # In this simplified version we just return the buffer
        # The actual processing happens during connection
        return self._rendered_buffer


async def create_peak_limiter_node(context) -> PeakLimiterNode:
    """Create a peak limiter node."""
    return PeakLimiterNode(context)


def generate_test_signal(kind: str, length: int, rate: int) -> List[float]:
    """Generate test signal based on type."""
    data = [0.0] * length
    
    for i in range(length):
        if kind == 'speech-band':
            data[i] = 0.01 * math.sin(2 * math.pi * 220 * i / rate)
        elif kind == 'short-high-tone' and 5000 <= i < 5100:
            data[i] = 0.95 * math.sin(2 * math.pi * 8000 * i / rate)
        elif kind == 'level-step' and 5000 <= i < 10000:
            data[i] = 0.95 * math.sin(2 * math.pi * 1000 * i / rate)
    
    if kind == 'impulse':
        data[5000] = 0.95
    
    return data


async def render(kind: str, strength: Optional[int], legacy: bool) -> Dict[str, Any]:
    """Render audio with specified parameters."""
    rate = 48000
    length = rate
    
    context = OfflineAudioContext(1, length, rate)
    buffer = context.create_buffer(1, length, rate)
    
    # Generate input signal
    input_data = generate_test_signal(kind, length, rate)
    
    # Copy to buffer
    buffer._channel_data[0] = input_data[:]
    
    # Create source
    source = create_buffer_source(buffer)
    
    # Process through appropriate path
    if strength is None:
        # No processing
        output_data = input_data[:]
    elif legacy:
        # Legacy compressor path
        compressor = context.create_dynamics_compressor()
        makeup = context.create_gain()
        
        threshold = limiter_strength_to_dbfs(strength)
        compressor.threshold = threshold
        compressor.knee = 0.5
        compressor.ratio = 20
        compressor.attack = 0.0015
        compressor.release = 0.08
        
        makeup_gain = limiter_makeup_compensation(threshold, 20)
        makeup.gain = 10 ** (makeup_gain / 20)
        
        # Process through compressor and makeup
        compressed = compressor.process(input_data)
        output_data = [sample * makeup.gain for sample in compressed]
    else:
        # New peak limiter path
        node = await create_peak_limiter_node(context)
        node.set_protection({'enabled': True, 'strength': strength})
        output_data = node.process(input_data)
    
    # Create result buffer with processed data
    result_buffer = AudioBuffer(1, length, rate)
    result_buffer._channel_data[0] = output_data
    
    context._rendered_buffer = result_buffer
    
    return {
        'kind': kind,
        'strength': strength,
        'path': 'off' if strength is None else '0.8.2-compressor' if legacy else 'candidate-lookahead',
        'inputDbfs': peak_db(input_data),
        'outputDbfs': peak_db(output_data)
    }


async def run_audio_test() -> Dict[str, Any]:
    """Run the complete audio test suite."""
    rows = []
    
    test_kinds = ['impulse', 'short-high-tone', 'level-step', 'speech-band']
    
    for kind in test_kinds:
        # No processing
        rows.append(await render(kind, None, False))
        
        # With processing
        for strength in [25, 75, 100]:
            rows.append(await render(kind, strength, True))   # Legacy
            rows.append(await render(kind, strength, False)) # New
    
    # Check for failures
    failures = []
    for row in rows:
        if row['path'] == 'candidate-lookahead':
            limit_threshold = limiter_strength_to_dbfs(row['strength'])
            if row['outputDbfs'] > limit_threshold + 0.05:
                failures.append(row)
            elif row['kind'] == 'speech-band' and abs(row['outputDbfs'] - row['inputDbfs']) > 0.05:
                failures.append(row)
    
    return {
        'passed': len(failures) == 0,
        'failures': failures,
        'rows': rows
    }


def generate_html_content() -> str:
    """Generate the HTML content."""
    return '''<!doctype html>
<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>
<script src="../browser-extension/content-core.js"></script>
<script>
const core = TLC_CONTENT_CORE;
const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));
async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  const context = new OfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) {
    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
  }
  if (kind === 'impulse') data[5000] = 0.95;
  const source = context.createBufferSource(); source.buffer = buffer;
  if (strength === null) source.connect(context.destination);
  else if (legacy) {
    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();
    const threshold = core.limiterStrengthToDbfs(strength);
    compressor.threshold.value = threshold; compressor.knee.value = 0.5;
    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;
    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    source.connect(compressor).connect(makeup).connect(context.destination);
  } else {
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({enabled:true, strength});
    source.connect(node).connect(context.destination);
  }
  source.start();
  const rendered = await context.startRendering();
  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};
}
document.getElementById('run').onclick = async () => {
  const output = document.getElementById('result'); output.textContent = 'Läuft';
  try {
    const rows = [];
    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {
      rows.push(await render(kind, null, false));
      for (const strength of [25,75,100]) {
        rows.push(await render(kind, strength, true));
        rows.push(await render(kind, strength, false));
      }
    }
    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&
      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));
    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);
  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }
};
</script></html>'''


async def main():
    """Main function to generate HTML file."""
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    # Generate and write HTML content
    html_content = generate_html_content()
    
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html_content)
    
    print(f"HTML file generated: {output_file}")
    
    # Run the audio test as well to demonstrate functionality
    try:
        result = await run_audio_test()
        print("\nAudio test results:")
        print(json.dumps(result, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"\nError running audio test: {e}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
