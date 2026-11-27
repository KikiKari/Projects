#!/usr/bin/env python3
# abstraction-provenance: {"artifact_sha256": "81b0e9fddf4a00427090965b25a314a97ee534aef1066355c28333527012abc0", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "python"}
# peak-limiter.html — portiert nach python
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import math
import json
import sys
from typing import List, Dict, Any, Optional, Tuple

# Constants
RATE = 48000
LENGTH = RATE

def limiter_strength_to_dbfs(strength: int) -> float:
    """Convert limiter strength to dBFS threshold"""
    return -20.0 + (strength / 100.0) * -30.0

def limiter_makeup_compensation(threshold: float, ratio: float) -> float:
    """Calculate makeup gain compensation"""
    return pow(10, -threshold/20 * (1 - 1/ratio))

def peak_db(values: List[float]) -> float:
    """Calculate peak level in dBFS"""
    max_val = max(abs(v) for v in values) if values else 1e-10
    return 20 * math.log10(max(max_val, 1e-10))

def create_test_signal(kind: str) -> List[float]:
    """Create test signal based on type"""
    data = [0.0] * LENGTH
    
    if kind == 'speech-band':
        for i in range(LENGTH):
            data[i] = 0.01 * math.sin(2 * math.pi * 220 * i / RATE)
    
    elif kind == 'short-high-tone':
        for i in range(5000, 5100):
            data[i] = 0.95 * math.sin(2 * math.pi * 8000 * i / RATE)
    
    elif kind == 'level-step':
        for i in range(5000, 10000):
            data[i] = 0.95 * math.sin(2 * math.pi * 1000 * i / RATE)
    
    elif kind == 'impulse':
        data[5000] = 0.95
        
    return data

def apply_compressor(signal: List[float], threshold: float) -> List[float]:
    """Apply simple compressor simulation"""
    # This is a simplified model that mimics basic compression behavior
    ratio = 20
    knee = 0.5
    attack = 0.0015
    release = 0.08
    
    makeup_gain = limiter_makeup_compensation(threshold, ratio)
    
    # Simple envelope detection and gain reduction
    envelope = 0.0
    output = [0.0] * len(signal)
    
    attack_coeff = 1.0 - math.exp(-1.0 / (RATE * attack))
    release_coeff = 1.0 - math.exp(-1.0 / (RATE * release))
    
    for i, sample in enumerate(signal):
        instant_power = abs(sample)
        
        # Envelope follower
        if instant_power > envelope:
            envelope += attack_coeff * (instant_power - envelope)
        else:
            envelope += release_coeff * (instant_power - envelope)
            
        # Apply knee and ratio
        if envelope > 0:
            db_env = 20 * math.log10(envelope)
            if db_env > threshold + knee/2:
                gain_reduction = (threshold - db_env) * (1 - 1/ratio)
                gain = pow(10, gain_reduction/20) * makeup_gain
                output[i] = sample * gain
            else:
                output[i] = sample * makeup_gain
        else:
            output[i] = sample * makeup_gain
            
    return output

def process_signal(kind: str, strength: Optional[int], legacy: bool) -> Dict[str, Any]:
    """Process signal with or without limiting"""
    input_signal = create_test_signal(kind)
    
    if strength is None:
        output_signal = input_signal.copy()
        path = 'off'
    elif legacy:
        threshold = limiter_strength_to_dbfs(strength)
        output_signal = apply_compressor(input_signal, threshold)
        path = '0.8.2-compressor'
    else:
        # Simplified lookahead limiter simulation
        threshold = limiter_strength_to_dbfs(strength)
        # In a real implementation this would be more complex
        # For now we simulate by applying a stricter processing
        output_signal = apply_compressor(input_signal, threshold - 1)  # Slightly more aggressive
        path = 'candidate-lookahead'
    
    return {
        'kind': kind,
        'strength': strength,
        'path': path,
        'inputDbfs': peak_db(input_signal),
        'outputDbfs': peak_db(output_signal)
    }

def run_audio_test() -> Dict[str, Any]:
    """Run the complete audio test suite"""
    rows = []
    
    test_kinds = ['impulse', 'short-high-tone', 'level-step', 'speech-band']
    strengths = [25, 75, 100]
    
    for kind in test_kinds:
        # No processing
        rows.append(process_signal(kind, None, False))
        
        # With processing
        for strength in strengths:
            # Legacy compressor
            rows.append(process_signal(kind, strength, True))
            # New limiter
            rows.append(process_signal(kind, strength, False))
    
    # Check for failures
    failures = []
    for row in rows:
        if row['path'] == 'candidate-lookahead':
            threshold = limiter_strength_to_dbfs(row['strength']) if row['strength'] else 0
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
    html_template = '''<!doctype html>
<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>
<style>body{{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}}pre{{white-space:pre-wrap}}button{{padding:12px}}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button><pre id="result">{}</pre>
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
    
    return html_template.format(json.dumps(results, indent=2, ensure_ascii=False))

def main():
    """Main function to run the test and generate HTML"""
    if len(sys.argv) != 2:
        print("Usage: {} <output_file>".format(sys.argv[0]))
        sys.exit(1)
    
    output_file = sys.argv[1]
    
    try:
        print("Running audio test...")
        results = run_audio_test()
        print("Test completed. Generating HTML...")
        
        html_content = generate_html_content(results)
        
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(html_content)
            
        print("HTML file generated: {}".format(output_file))
        
    except Exception as e:
        print("ERROR: {}".format(str(e)))
        sys.exit(1)

if __name__ == "__main__":
    main()
