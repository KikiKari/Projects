#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "27099f4b1e9960b0140bee5be0a81ab1c1d94921611609b289327fc2445e24aa", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "javascript"}
// peak-limiter.html — portiert nach javascript
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

const fs = require('fs');
const path = require('path');

// Core functionality from content-core.js (simulated)
const core = {
  limiterStrengthToDbfs: (strength) => {
    return -60 + (strength / 100) * 60;
  },
  
  limiterMakeupCompensation: (threshold, ratio) => {
    return Math.pow(10, -threshold * (1 - 1/ratio) / 20);
  },
  
  createPeakLimiterNode: async (context) => {
    // Simplified implementation of the peak limiter
    const node = context.createScriptProcessor(1024, 1, 1);
    let protectionEnabled = false;
    let protectionStrength = 100;
    
    node.setProtection = ({enabled, strength}) => {
      protectionEnabled = enabled;
      protectionStrength = strength;
    };
    
    const threshold = Math.pow(10, core.limiterStrengthToDbfs(protectionStrength) / 20);
    
    node.onaudioprocess = (e) => {
      const input = e.inputBuffer.getChannelData(0);
      const output = e.outputBuffer.getChannelData(0);
      
      if (!protectionEnabled) {
        for (let i = 0; i < input.length; i++) {
          output[i] = input[i];
        }
        return;
      }
      
      for (let i = 0; i < input.length; i++) {
        let sample = input[i];
        if (Math.abs(sample) > threshold) {
          sample = sample > 0 ? threshold : -threshold;
        }
        output[i] = sample;
      }
    };
    
    return node;
  }
};

const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));

async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  const context = new (require('web-audio-api').OfflineAudioContext)(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  
  for (let i = 0; i < length; i++) {
    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
  }
  
  if (kind === 'impulse') data[5000] = 0.95;
  
  const source = context.createBufferSource();
  source.buffer = buffer;
  
  if (strength === null) {
    source.connect(context.destination);
  } else if (legacy) {
    const compressor = context.createDynamicsCompressor();
    const makeup = context.createGain();
    const threshold = core.limiterStrengthToDbfs(strength);
    
    compressor.threshold.value = threshold;
    compressor.knee.value = 0.5;
    compressor.ratio.value = 20;
    compressor.attack.value = 0.0015;
    compressor.release.value = 0.08;
    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    
    source.connect(compressor);
    compressor.connect(makeup);
    makeup.connect(context.destination);
  } else {
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({enabled: true, strength});
    source.connect(node);
    node.connect(context.destination);
  }
  
  source.start();
  const rendered = await context.startRendering();
  return {
    kind, 
    strength, 
    path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(data), 
    outputDbfs: peakDb(rendered.getChannelData(0))
  };
}

async function runTest() {
  const rows = [];
  
  for (const kind of ['impulse', 'short-high-tone', 'level-step', 'speech-band']) {
    rows.push(await render(kind, null, false));
    for (const strength of [25, 75, 100]) {
      rows.push(await render(kind, strength, true));
      rows.push(await render(kind, strength, false));
    }
  }
  
  const failures = rows.filter(row => 
    row.path === 'candidate-lookahead' &&
    (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
     (row.kind === 'speech-band' && Math.abs(row.outputDbfs - row.inputDbfs) > 0.05))
  );
  
  return {passed: failures.length === 0, failures, rows};
}

function generateHTML(results) {
  return `<!doctype html>
<html lang="de">
<meta charset="utf-8">
<title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button>
<pre id="result">${JSON.stringify(results, null, 2)}</pre>
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
</script>
</html>`;
}

async function main() {
  const outputFile = process.argv[2];
  
  if (!outputFile) {
    console.error('Usage: node script.js <output-file>');
    process.exit(1);
  }
  
  try {
    const results = await runTest();
    const htmlContent = generateHTML(results);
    
    fs.writeFileSync(outputFile, htmlContent);
    console.log(`HTML file generated: ${outputFile}`);
  } catch (error) {
    console.error('Error:', error.stack);
    process.exit(1);
  }
}

main();
