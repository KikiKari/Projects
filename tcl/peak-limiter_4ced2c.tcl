#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "7a21f7e1542490eabb5ca86ef82171702ad91f2b58ff7cf112102e5eac2718e7", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "tcl"}
# peak-limiter.html — portiert nach tcl
# Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl/Tk port of the peak limiter audio test HTML page
# Generates the same HTML content and functionality using Tcl 8.6

package require http
package require json
package require json::write

proc generateHTML {} {
    set html {<!doctype html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Pegelschutz Audioprüfung</title>
<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>
</head>
<body>
<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>
<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>
<button id="run">Audioprüfung starten</button>
<pre id="result">Bereit</pre>

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
    source.connect(compressor).connect(makeup).connect(context.destination);
  } else {
    const node = await core.createPeakLimiterNode(context);
    node.setProtection({enabled:true, strength});
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

document.getElementById('run').onclick = async () => {
  const output = document.getElementById('result'); 
  output.textContent = 'Läuft';
  
  try {
    const rows = [];
    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {
      rows.push(await render(kind, null, false));
      for (const strength of [25, 75, 100]) {
        rows.push(await render(kind, strength, true));
        rows.push(await render(kind, strength, false));
      }
    }
    
    const failures = rows.filter(row => 
      row.path === 'candidate-lookahead' &&
      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||
       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05))
    );
    
    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);
  } catch(error) { 
    output.textContent = 'FEHLER: ' + error.stack; 
  }
};
</script>
</body>
</html>}
    return $html
}

# Main execution
if {$argc != 1} {
    puts stderr "Usage: $argv0 <output-file>"
    exit 1
}

set outputFile [lindex $argv 0]
set htmlContent [generateHTML]

if {[catch {open $outputFile w} fileId]} {
    puts stderr "Error: Could not write to file '$outputFile'"
    exit 1
}

puts -nonewline $fileId $htmlContent
close $fileId

puts "HTML file generated successfully: $outputFile"
