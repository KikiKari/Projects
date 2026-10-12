#!/usr/bin/env python3
# peak-limiter.html — portiert nach python
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import math
import json
import sys
from typing import List, Dict, Any, Optional, Tuple

def limiter_strength_to_dbfs(strength: int) -> float:
    """Convert limiter strength to dBFS threshold"""
    return -0.01 * strength - 40.0

def limiter_makeup_compensation(threshold_db: float, ratio: float) -> float:
    """Calculate makeup gain compensation"""
    return pow(10, -threshold_db/20 * (1 - 1/ratio))

def peak_db(values: List[float]) -> float:
    """Calculate peak level in dBFS"""
    max_val = max(abs(v) for v in values) if values else 1e-10
    return 20 * math.log10(max(max_val, 1e-10))

class DynamicsCompressor:
    """Simplified dynamics compressor implementation"""
    def __init__(self):
        self.threshold = -24.0
        self.knee = 0.5
        self.ratio = 20.0
        self.attack = 0.0015
        self.release = 0.08
    
    def process(self, input_data: List[float]) -> List[float]:
        # Simplified compressor processing
        output = input_data.copy()
        # This is a very simplified approximation - real compressor would be much more complex
        threshold_linear = pow(10, self.threshold/20)
        
        for i in range(len(output)):
            sample = abs(output[i])
            if sample > threshold_linear:
                # Apply compression ratio
                compressed = threshold_linear + (sample - threshold_linear) / self.ratio
                output[i] = output[i] * (compressed / sample) if sample > 0 else 0
        
        return output

class PeakLimiterNode:
    """Simplified peak limiter node"""
    def __init__(self):
        self.enabled = False
        self.strength = 100
    
    def set_protection(self, config: Dict[str, Any]):
        self.enabled = config.get('enabled', False)
        self.strength = config.get('strength', 100)
    
    def process(self, input_data: List[float]) -> List[float]:
        if not self.enabled:
            return input_data.copy()
            
        # Simplified lookahead limiting
        threshold_db = limiter_strength_to_dbfs(self.strength)
        threshold_linear = pow(10, threshold_db/20)
        
        output = input_data.copy()
        for i in range(len(output)):
            if abs(output[i]) > threshold_linear:
                output[i] = math.copysign(threshold_linear, output[i])
        
        return output

def create_test_signal(kind: str, rate: int, length: int) -> List[float]:
    """Create test signal based on type"""
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
    """Render audio with specified settings"""
    rate = 48000
    length = rate
    
    # Create input signal
    data = create_test_signal(kind, rate, length)
    
    # Process through limiter/compressor if enabled
    if strength is None:
        processed = data
        path = 'off'
    elif legacy:
        # Use dynamics compressor
        compressor = DynamicsCompressor()
        threshold = limiter_strength_to_dbfs(strength)
        compressor.threshold = threshold
        compressor.knee = 0.5
        compressor.ratio = 20
        compressor.attack = 0.0015
        compressor.release = 0.08
        
        makeup_gain = limiter_makeup_compensation(threshold, 20)
        processed = compressor.process(data)
        
        # Apply makeup gain
        for i in range(len(processed)):
            processed[i] *= makeup_gain
            
        path = '0.8.2-compressor'
    else:
        # Use peak limiter
        node = PeakLimiterNode()
        node.set_protection({'enabled': True, 'strength': strength})
        processed = node.process(data)
        path = 'candidate-lookahead'
    
    return {
        'kind': kind,
        'strength': strength,
        'path': path,
        'inputDbfs': peak_db(data),
        'outputDbfs': peak_db(processed)
    }

async def run_audio_test() -> Dict[str, Any]:
    """Run the complete audio test suite"""
    print("Running audio test...")
    
    rows = []
    kinds = ['impulse', 'short-high-tone', 'level-step', 'speech-band']
    
    for kind in kinds:
        rows.append(await render(kind, None, False))
        for strength in [25, 75, 100]:
            rows.append(await render(kind, strength, True))
            rows.append(await render(kind, strength, False))
    
    # Check for failures
    failures = []
    for row in rows:
        if row['path'] == 'candidate-lookahead':
            threshold = limiter_strength_to_dbfs(row['strength']) if row['strength'] is not None else 0
            if row['outputDbfs'] > threshold + 0.05:
                failures.append(row)
            elif row['kind'] == 'speech-band' and abs(row['outputDbfs'] - row['inputDbfs']) > 0.05:
                failures.append(row)
    
    return {
        'passed': len(failures) == 0,
        'failures': failures,
        'rows': rows
    }

def generate_html_content(results: Dict[str, Any]) -> str:
    """Generate the HTML content with results"""
    return f'''<!doctype html>
<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>
<style>body{{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}}pre{{white-space:pre-wrap}}button{{padding:12px}}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button><pre id="result">{json.dumps(results, indent=2, ensure_ascii=False)}</pre>
<script src="../browser-extension/content-core.js"></script>
<script>
const core = TLC_CONTENT_CORE;
const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));
async function render(kind, strength, legacy) {{
  const rate = 48000, length = rate;
  const context = new OfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  for (let i = 0; i < length; i++) {{
    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
  }}
  if (kind === 'impulse') data[5000] = 0.95;
  const source = context.createBufferSource(); source.buffer = buffer;
  if (strength === null) source.connect(context.destination);
  else if (legacy) {{
    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();
    const threshold = core.limiterStrengthToDbfs(strength);
    compressor.threshold.value = threshold; compressor.knee.value = 0.5;
    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;
    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    source.connect(compressor).connect(makeup).connect(context.destination);
  }} else {{
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({{enabled:true, strength}});
    source.connect(node).connect(context.destination);
  }}
  source.start();
  const rendered = await context.startRendering();
  return {{kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))}};
}}
document.getElementById('run').onclick = async () => {{
  const output = document.getElementById('result'); output.textContent = 'Läuft';
  try {{
    const rows = [];
    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {{
      rows.push(await render(kind, null, false));
      for (const strength of [25,75,100]) {{
        rows.push(await render(kind, strength, true));
        rows.push(await render(kind, strength, false));
      }}
    }}
    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&
      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));
    output.textContent = JSON.stringify({{passed: failures.length === 0, failures, rows}}, null, 2);
  }} catch(error) {{ output.textContent = 'FEHLER: ' + error.stack; }}
}};
</script></html>'''

async def main():
    """Main function to run the test and generate HTML"""
    if len(sys.argv) != 2:
        print("Usage: python script.py <output_file>")
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    try:
        results = await run_audio_test()
        html_content = generate_html_content(results)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
        
        print(f"Results written to {output_file}")
        
    except Exception as e:
        print(f"ERROR: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
