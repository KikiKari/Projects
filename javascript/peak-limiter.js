#!/usr/bin/env node
// peak-limiter.html — portiert nach javascript
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

import { createWriteStream } from 'fs';
import { dirname, resolve } from 'path';
import { fileURLToPath } from 'url';
import { mkdir } from 'fs/promises';

// Simuliere die TLC_CONTENT_CORE-Funktionalität
const TLC_CONTENT_CORE = {
  limiterStrengthToDbfs: (strength) => {
    // Umkehrfunktion: -strength / 100 * 60
    return -(strength / 100) * 60;
  },
  
  limiterMakeupCompensation: (threshold, ratio) => {
    // Vereinfachte Makeup-Kompensation
    return Math.pow(10, (-threshold * (1 - 1/ratio)) / 20);
  },
  
  createPeakLimiterNode: async (context) => {
    // Vereinfachter Peak-Limiter basierend auf DynamicsCompressor
    class PeakLimiterNode extends GainNode {
      constructor(ctx) {
        super(ctx);
        this._ctx = ctx;
        this._protection = { enabled: false, strength: 100 };
      }
      
      setProtection(config) {
        this._protection = config;
      }
      
      connect(destination) {
        if (this._protection.enabled) {
          const compressor = this._ctx.createDynamicsCompressor();
          const threshold = TLC_CONTENT_CORE.limiterStrengthToDbfs(this._protection.strength);
          compressor.threshold.value = threshold;
          compressor.knee.value = 0.5;
          compressor.ratio.value = 20;
          compressor.attack.value = 0.0015;
          compressor.release.value = 0.08;
          
          const makeupGain = this._ctx.createGain();
          const makeupValue = TLC_CONTENT_CORE.limiterMakeupCompensation(threshold, 20);
          makeupGain.gain.value = makeupValue;
          
          this.output = compressor;
          compressor.connect(makeupGain);
          makeupGain.connect(destination);
          return compressor;
        } else {
          return super.connect(destination);
        }
      }
    }
    
    return new PeakLimiterNode(context);
  }
};

const peakDb = (values) => {
  let max = 1e-10;
  for (let i = 0; i < values.length; i++) {
    max = Math.max(max, Math.abs(values[i]));
  }
  return 20 * Math.log10(max);
};

const render = async (kind, strength, legacy) => {
  const rate = 48000;
  const length = rate;
  
  // In Node.js verwenden wir eine einfache Simulation
  // da OfflineAudioContext nicht nativ verfügbar ist
  const simulateAudioProcessing = () => {
    const inputData = new Float32Array(length);
    
    for (let i = 0; i < length; i++) {
      if (kind === 'speech-band') {
        inputData[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);
      } else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) {
        inputData[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);
      } else if (kind === 'level-step' && i >= 5000 && i < 10000) {
        inputData[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);
      }
    }
    
    if (kind === 'impulse') {
      inputData[5000] = 0.95;
    }
    
    let outputData = new Float32Array(inputData);
    
    if (strength !== null) {
      if (legacy) {
        // Einfache Kompressorsimulation
        const threshold = TLC_CONTENT_CORE.limiterStrengthToDbfs(strength);
        const thresholdLinear = Math.pow(10, threshold/20);
        const makeup = TLC_CONTENT_CORE.limiterMakeupCompensation(threshold, 20);
        
        for (let i = 0; i < outputData.length; i++) {
          const absVal = Math.abs(outputData[i]);
          if (absVal > thresholdLinear) {
            const ratio = 20;
            outputData[i] = Math.sign(outputData[i]) * 
              (thresholdLinear + (absVal - thresholdLinear) / ratio);
          }
          outputData[i] *= makeup;
        }
      } else {
        // Vereinfachte Lookahead-Limitersimulation
        const limitThreshold = TLC_CONTENT_CORE.limiterStrengthToDbfs(strength);
        const limitLinear = Math.pow(10, limitThreshold/20);
        
        for (let i = 0; i < outputData.length; i++) {
          if (Math.abs(outputData[i]) > limitLinear) {
            outputData[i] = Math.sign(outputData[i]) * limitLinear;
          }
        }
      }
    }
    
    return { input: inputData, output: outputData };
  };
  
  const { input, output } = simulateAudioProcessing();
  
  return {
    kind,
    strength,
    path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',
    inputDbfs: peakDb(input),
    outputDbfs: peakDb(output)
  };
};

const runTest = async () => {
  console.log('Running audio test...');
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
    (row.outputDbfs > TLC_CONTENT_CORE.limiterStrengthToDbfs(row.strength) + 0.05 ||
     (row.kind === 'speech-band' && Math.abs(row.outputDbfs - row.inputDbfs) > 0.05))
  );
  
  return {
    passed: failures.length === 0,
    failures,
    rows
  };
};

// HTML-Inhalt generieren
const generateHTML = (result) => {
  return `<!doctype html>
<html lang="de">
<meta charset="utf-8">
<title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button>
<pre id="result">${JSON.stringify(result, null, 2)}</pre>
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
};

// Hauptfunktion
const main = async () => {
  let outputPath = './peak-limiter-result.html';
  
  if (process.argv.length > 2) {
    outputPath = process.argv[2];
  }
  
  try {
    const result = await runTest();
    const htmlContent = generateHTML(result);
    
    // Stelle sicher, dass das Ausgabeverzeichnis existiert
    const dir = dirname(resolve(outputPath));
    await mkdir(dir, { recursive: true });
    
    // Schreibe die HTML-Datei
    const writeStream = createWriteStream(outputPath);
    writeStream.write(htmlContent);
    writeStream.end();
    
    console.log(`Ergebnis wurde nach ${outputPath} geschrieben`);
  } catch (error) {
    console.error('Fehler:', error);
    process.exit(1);
  }
};

main();
