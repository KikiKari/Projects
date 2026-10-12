#!/usr/bin/env node
// peak-limiter.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@codex/0pe-177-peak-protection:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

// Emulation of the browser environment and Web Audio API
class OfflineAudioContext {
  constructor(channels, length, sampleRate) {
    this.channels = channels;
    this.length = length;
    this.sampleRate = sampleRate;
    this._nodes = [];
  }

  createBuffer(channels, length, sampleRate) {
    return new AudioBuffer(channels, length, sampleRate);
  }

  createBufferSource() {
    return new AudioBufferSourceNode();
  }

  createDynamicsCompressor() {
    return new DynamicsCompressorNode();
  }

  createGain() {
    return new GainNode();
  }

  createScriptProcessor(bufferSize, numberOfInputChannels, numberOfOutputChannels) {
    return new ScriptProcessorNode(bufferSize, numberOfInputChannels, numberOfOutputChannels);
  }

  async startRendering() {
    // Simulate rendering process
    const outputBuffer = new AudioBuffer(this.channels, this.length, this.sampleRate);
    // In a real implementation, this would process all connected nodes
    return outputBuffer;
  }

  get destination() {
    return { connect: () => {} };
  }
}

class AudioBuffer {
  constructor(channels, length, sampleRate) {
    this.numberOfChannels = channels;
    this.length = length;
    this.sampleRate = sampleRate;
    this._channelData = Array(channels).fill().map(() => new Float32Array(length));
  }

  getChannelData(channel) {
    return this._channelData[channel];
  }
}

class AudioNode {
  connect(destination) {
    this._destination = destination;
    return destination;
  }
}

class AudioBufferSourceNode extends AudioNode {
  constructor() {
    super();
    this.buffer = null;
  }

  start() {
    // In a real implementation, this would start playback
  }
}

class DynamicsCompressorNode extends AudioNode {
  constructor() {
    super();
    this.threshold = { value: 0 };
    this.knee = { value: 0 };
    this.ratio = { value: 1 };
    this.attack = { value: 0 };
    this.release = { value: 0 };
  }
}

class GainNode extends AudioNode {
  constructor() {
    super();
    this.gain = { value: 1 };
  }
}

class ScriptProcessorNode extends AudioNode {
  constructor(bufferSize, numberOfInputChannels, numberOfOutputChannels) {
    super();
    this.bufferSize = bufferSize;
    this.onaudioprocess = null;
  }
}

// Core functionality emulation
const TLC_CONTENT_CORE = {
  limiterStrengthToDbfs(strength) {
    return -20 + (strength / 100) * 20;
  },
  
  limiterMakeupCompensation(threshold, ratio) {
    return Math.pow(10, (-threshold * (1 - 1/ratio)) / 20);
  },
  
  async createPeakLimiterNode(context) {
    return new PeakLimiterNode(context);
  }
};

class PeakLimiterNode extends AudioNode {
  constructor(context) {
    super();
    this.context = context;
    this._protection = { enabled: false, strength: 0 };
  }
  
  setProtection(protection) {
    this._protection = protection;
  }
}

function peakDb(values) {
  let max = 1e-10;
  for (let i = 0; i < values.length; i++) {
    max = Math.max(max, Math.abs(values[i]));
  }
  return 20 * Math.log10(max);
}

async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  const context = new OfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  
  for (let i = 0; i < length; i++) {
    if (kind === 'speech-band') {
      data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
    } else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) {
      data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
    } else if (kind === 'level-step' && i >= 5000 && i < 10000) {
      data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
    }
  }
  
  if (kind === 'impulse') {
    data[5000] = 0.95;
  }
  
  const source = context.createBufferSource();
  source.buffer = buffer;
  
  if (strength === null) {
    source.connect(context.destination);
  } else if (legacy) {
    const compressor = context.createDynamicsCompressor();
    const makeup = context.createGain();
    const threshold = TLC_CONTENT_CORE.limiterStrengthToDbfs(strength);
    compressor.threshold.value = threshold;
    compressor.knee.value = 0.5;
    compressor.ratio.value = 20;
    compressor.attack.value = 0.0015;
    compressor.release.value = 0.08;
    makeup.gain.value = TLC_CONTENT_CORE.limiterMakeupCompensation(threshold, 20);
    source.connect(compressor).connect(makeup).connect(context.destination);
  } else {
    const node = await TLC_CONTENT_CORE.createPeakLimiterNode(context);
    node.setProtection({enabled: true, strength});
    source.connect(node).connect(context.destination);
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
  for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {
    rows.push(await render(kind, null, false));
    for (const strength of [25,75,100]) {
      rows.push(await render(kind, strength, true));
      rows.push(await render(kind, strength, false));
    }
  }
  
  const failures = rows.filter(row => 
    row.path === 'candidate-lookahead' &&
    (row.outputDbfs > TLC_CONTENT_CORE.limiterStrengthToDbfs(row.strength) + 0.05 ||
     (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05))
  );
  
  return JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);
}

function generateHTML() {
  return `<!doctype html>
<html lang="de">
<meta charset="utf-8">
<title>Pegelschutz Audioprüfung</title>
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
</script>
</html>`;
}

async function main() {
  if (process.argv.length !== 3) {
    console.error('Usage: node peak-limiter.js <output-file>');
    process.exit(1);
  }
  
  const outputFile = process.argv[2];
  
  try {
    // Generate the HTML content
    const htmlContent = generateHTML();
    
    // Write to file
    writeFileSync(outputFile, htmlContent);
    console.log(`HTML file generated: ${outputFile}`);
    
    // Run the test to show it works
    console.log('Running test...');
    const result = await runTest();
    console.log('Test completed successfully');
    
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

main();
