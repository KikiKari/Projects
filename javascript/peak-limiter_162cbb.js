#!/usr/bin/env node
// abstraction-provenance: {"artifact_sha256": "0b76b36985b2a78282fb4df37c5d8a488539b53b7cc8e8767acc2f50b70684cc", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "javascript"}
// peak-limiter.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import { writeFileSync } from 'fs';
import { createServer } from 'http';
import { resolve } from 'path';

// Simuliere die core-Funktionalität
const core = {
  limiterStrengthToDbfs: (strength) => -60 + (strength / 100) * 60,
  limiterMakeupCompensation: (threshold, ratio) => Math.pow(10, -threshold/20 * (1 - 1/ratio)),
  createPeakLimiterNode: async (context) => {
    // Vereinfachte Implementierung eines Peak-Limiters
    class PeakLimiterNode extends GainNode {
      constructor(context) {
        super(context);
        this.protection = { enabled: false, strength: 100 };
      }
      
      setProtection(config) {
        this.protection = config;
      }
    }
    
    return new PeakLimiterNode(context);
  }
};

const peakDb = values => {
  let max = 1e-10;
  for (let i = 0; i < values.length; i++) {
    const abs = Math.abs(values[i]);
    if (abs > max) max = abs;
  }
  return 20 * Math.log10(max);
};

async function render(kind, strength, legacy) {
  const rate = 48000, length = rate;
  
  // Simuliere OfflineAudioContext
  class MockOfflineAudioContext {
    constructor(channels, length, sampleRate) {
      this.sampleRate = sampleRate;
      this.length = length;
      this.channels = channels;
    }
    
    createBuffer(channels, length, sampleRate) {
      return {
        getChannelData: (channel) => {
          const data = new Float32Array(length);
          // Fülle mit Testdaten basierend auf dem Typ
          for (let i = 0; i < length; i++) {
            if (kind === 'speech-band') {
              data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / this.sampleRate);
            } else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) {
              data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / this.sampleRate);
            } else if (kind === 'level-step' && i >= 5000 && i < 10000) {
              data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / this.sampleRate);
            }
          }
          if (kind === 'impulse' && i === 5000) {
            data[i] = 0.95;
          }
          return data;
        }
      };
    }
    
    createBufferSource() {
      return {
        buffer: null,
        connect: (node) => ({
          connect: (destination) => {}
        }),
        start: () => {}
      };
    }
    
    createDynamicsCompressor() {
      return {
        threshold: { value: 0 },
        knee: { value: 0.5 },
        ratio: { value: 20 },
        attack: { value: 0.0015 },
        release: { value: 0.08 },
        connect: (node) => ({
          connect: (destination) => {}
        })
      };
    }
    
    createGain() {
      return {
        gain: { value: 1 },
        connect: (node) => ({
          connect: (destination) => {}
        })
      };
    }
    
    async startRendering() {
      // Simuliere Rendering-Ergebnis
      const outputData = new Float32Array(length);
      const inputData = this.createBuffer(1, length, rate).getChannelData(0);
      
      // Kopiere Eingangsdaten in Ausgangsdaten
      for (let i = 0; i < length; i++) {
        outputData[i] = inputData[i];
      }
      
      return {
        getChannelData: (channel) => outputData
      };
    }
  }
  
  const context = new MockOfflineAudioContext(1, length, rate);
  const buffer = context.createBuffer(1, length, rate);
  const data = buffer.getChannelData(0);
  
  const source = context.createBufferSource();
  source.buffer = buffer;
  
  if (strength !== null) {
    if (legacy) {
      const compressor = context.createDynamicsCompressor();
      const makeup = context.createGain();
      const threshold = core.limiterStrengthToDbfs(strength);
      compressor.threshold.value = threshold;
      compressor.knee.value = 0.5;
      compressor.ratio.value = 20;
      compressor.attack.value = 0.0015;
      compressor.release.value = 0.08;
      makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);
    } else {
      const node = await core.createPeakLimiterNode(context);
      node.setProtection({enabled: true, strength});
    }
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

function generateHTML() {
  return `<!doctype html>
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
</script></html>`;
}

async function runTest() {
  console.log('Running audio test...');
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
    
    return {
      passed: failures.length === 0,
      failures,
      rows
    };
  } catch(error) {
    console.error('ERROR:', error);
    throw error;
  }
}

// Hauptfunktion
async function main() {
  const args = process.argv.slice(2);
  
  if (args.length === 0) {
    // Starte HTTP-Server für interaktive Nutzung
    const server = createServer((req, res) => {
      if (req.method === 'GET') {
        res.writeHead(200, {'Content-Type': 'text/html; charset=utf-8'});
        res.end(generateHTML());
      } else {
        res.writeHead(405);
        res.end('Method Not Allowed');
      }
    });
    
    const port = 8080;
    server.listen(port, () => {
      console.log(`Server running at http://localhost:${port}/`);
      console.log('Press Ctrl+C to stop');
    });
  } else if (args[0] === '--test') {
    // Führe Test direkt aus
    const result = await runTest();
    console.log(JSON.stringify(result, null, 2));
  } else if (args[0].endsWith('.html')) {
    // Schreibe HTML-Datei
    const html = generateHTML();
    writeFileSync(args[0], html, 'utf8');
    console.log(`HTML file written to ${args[0]}`);
  } else {
    console.error('Usage: node script.js [filename.html] | --test');
    process.exit(1);
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
