#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "096a90dbce8f0249e015863a7417f078db2b26ab22e433d5ccc2f7abde99816a", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "python"}
# peak-limiter.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import json
import math
import sys
from typing import List, Dict, Any, Optional


def limiter_strength_to_dbfs(strength: int) -> float:
    """Convert limiter strength to dBFS threshold."""
    return -0.01 * strength ** 2


def limiter_makeup_compensation(threshold_db: float, ratio: float) -> float:
    """Calculate makeup gain compensation."""
    # Simplified makeup gain calculation
    return 10 ** ((threshold_db * (ratio - 1) / ratio) / 20)


def peak_db(values: List[float]) -> float:
    """Calculate peak level in dBFS."""
    max_val = max(abs(v) for v in values) if values else 1e-10
    return 20 * math.log10(max(max_val, 1e-10))


class AudioBuffer:
    def __init__(self, channels: int, length: int, sample_rate: int):
        self.channels = channels
        self.length = length
        self.sample_rate = sample_rate
        self.data = [[0.0 for _ in range(length)] for _ in range(channels)]
    
    def get_channel_data(self, channel: int) -> List[float]:
        return self.data[channel]


class DynamicsCompressor:
    def __init__(self):
        self.threshold = 0.0
        self.knee = 0.0
        self.ratio = 1.0
        self.attack = 0.0
        self.release = 0.0


class GainNode:
    def __init__(self):
        self.gain = 1.0


class PeakLimiterNode:
    def __init__(self):
        self.enabled = False
        self.strength = 0
    
    def set_protection(self, config: Dict[str, Any]):
        self.enabled = config.get('enabled', False)
        self.strength = config.get('strength', 0)


class OfflineAudioContext:
    def __init__(self, channels: int, length: int, sample_rate: int):
        self.channels = channels
        self.length = length
        self.sample_rate = sample_rate
        self.destination = None
    
    def create_buffer(self, channels: int, length: int, sample_rate: int) -> AudioBuffer:
        return AudioBuffer(channels, length, sample_rate)
    
    def create_buffer_source(self) -> 'AudioBufferSourceNode':
        return AudioBufferSourceNode()
    
    def create_dynamics_compressor(self) -> DynamicsCompressor:
        return DynamicsCompressor()
    
    def create_gain(self) -> GainNode:
        return GainNode()
    
    async def create_peak_limiter_node(self) -> PeakLimiterNode:
        return PeakLimiterNode()
    
    async def start_rendering(self) -> AudioBuffer:
        # In a real implementation this would process the audio graph
        # For simulation we just return a buffer with the same size
        return AudioBuffer(self.channels, self.length, self.sample_rate)


class AudioBufferSourceNode:
    def __init__(self):
        self.buffer = None
        self.connections = []
    
    def connect(self, destination):
        self.connections.append(destination)
        return self


async def render(kind: str, strength: Optional[int], legacy: bool) -> Dict[str, Any]:
    """Render audio and apply processing."""
    rate = 48000
    length = rate
    context = OfflineAudioContext(1, length, rate)
    buffer = context.create_buffer(1, length, rate)
    data = buffer.get_channel_data(0)
    
    # Generate test signal based on kind
    for i in range(length):
        if kind == 'speech-band':
            data[i] = 0.01 * math.sin(2 * math.pi * 220 * i / rate)
        elif kind == 'short-high-tone' and 5000 <= i < 5100:
            data[i] = 0.95 * math.sin(2 * math.pi * 8000 * i / rate)
        elif kind == 'level-step' and 5000 <= i < 10000:
            data[i] = 0.95 * math.sin(2 * math.pi * 1000 * i / rate)
    
    if kind == 'impulse':
        data[5000] = 0.95
    
    source = context.create_buffer_source()
    source.buffer = buffer
    
    if strength is None:
        # No processing
        pass
    elif legacy:
        # Use dynamics compressor approach
        compressor = context.create_dynamics_compressor()
        makeup = context.create_gain()
        threshold = limiter_strength_to_dbfs(strength)
        compressor.threshold = threshold
        compressor.knee = 0.5
        compressor.ratio = 20
        compressor.attack = 0.0015
        compressor.release = 0.08
        makeup.gain = limiter_makeup_compensation(threshold, 20)
        source.connect(compressor).connect(makeup).connect(context)
    else:
        # Use peak limiter approach
        node = await context.create_peak_limiter_node()
        node.set_protection({'enabled': True, 'strength': strength})
        source.connect(node).connect(context)
    
    # Simulate rendering result
    # In a real implementation this would actually process the audio
    rendered = await context.start_rendering()
    output_data = rendered.get_channel_data(0)
    
    # For simulation purposes, we'll modify the output based on our processing
    if strength is not None:
        threshold = limiter_strength_to_dbfs(strength)
        # Apply simple limiting simulation
        for i in range(len(output_data)):
            if abs(output_data[i]) > 10**(threshold/20):
                output_data[i] = math.copysign(10**(threshold/20), output_data[i])
    
    path = 'off' if strength is None else '0.8.2-compressor' if legacy else 'candidate-lookahead'
    
    return {
        'kind': kind,
        'strength': strength,
        'path': path,
        'inputDbfs': peak_db(data),
        'outputDbfs': peak_db(output_data)
    }


async def run_test() -> Dict[str, Any]:
    """Run the complete audio test suite."""
    rows = []
    kinds = ['impulse', 'short-high-tone', 'level-step', 'speech-band']
    
    for kind in kinds:
        rows.append(await render(kind, None, False))
        for strength in [25, 75, 100]:
            rows.append(await render(kind, strength, True))
            rows.append(await render(kind, strength, False))
    
    failures = []
    for row in rows:
        if row['path'] == 'candidate-lookahead':
            threshold = limiter_strength_to_dbfs(row['strength'])
            if row['outputDbfs'] > threshold + 0.05:
                failures.append(row)
            elif row['kind'] == 'speech-band' and abs(row['outputDbfs'] - row['inputDbfs']) > 0.05:
                failures.append(row)
    
    return {
        'passed': len(failures) == 0,
        'failures': failures,
        'rows': rows
    }


def generate_html() -> str:
    """Generate the complete HTML document."""
    html_content = '''<!doctype html>
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
    
    return html_content


async def main():
    """Main function to generate HTML or run tests."""
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        html_content = generate_html()
        
        with open(filename, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"HTML file generated: {filename}")
    else:
        # Run the test directly
        try:
            result = await run_test()
            print(json.dumps(result, indent=2))
        except Exception as e:
            print(f"ERROR: {str(e)}")


if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
