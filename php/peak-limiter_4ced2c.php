<?php
// abstraction-provenance: {"artifact_sha256": "2598f82051cddc8f0a159d1c5e78a3c5fd992f008d3f5ea9a6bece5c49a137a3", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "php"}
// peak-limiter.html — portiert nach php
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
// Pegelschutz Audioprüfung
// Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.

function generate_peak_limiter_html($output_file) {
    $html = '<!doctype html>' . "\n";
    $html .= '<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>' . "\n";
    $html .= '<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>' . "\n";
    $html .= '<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>' . "\n";
    $html .= '<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>' . "\n";
    $html .= '<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>' . "\n";
    $html .= '<script src="../browser-extension/content-core.js"></script>' . "\n";
    $html .= '<script>' . "\n";
    $html .= 'const core = TLC_CONTENT_CORE;' . "\n";
    $html .= 'const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));' . "\n";
    $html .= 'async function render(kind, strength, legacy) {' . "\n";
    $html .= '  const rate = 48000, length = rate;' . "\n";
    $html .= '  const context = new OfflineAudioContext(1, length, rate);' . "\n";
    $html .= '  const buffer = context.createBuffer(1, length, rate);' . "\n";
    $html .= '  const data = buffer.getChannelData(0);' . "\n";
    $html .= '  for (let i = 0; i < length; i++) {' . "\n";
    $html .= '    if (kind === \'speech-band\') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);' . "\n";
    $html .= '    else if (kind === \'short-high-tone\' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);' . "\n";
    $html .= '    else if (kind === \'level-step\' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);' . "\n";
    $html .= '  }' . "\n";
    $html .= '  if (kind === \'impulse\') data[5000] = 0.95;' . "\n";
    $html .= '  const source = context.createBufferSource(); source.buffer = buffer;' . "\n";
    $html .= '  if (strength === null) source.connect(context.destination);' . "\n";
    $html .= '  else if (legacy) {' . "\n";
    $html .= '    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();' . "\n";
    $html .= '    const threshold = core.limiterStrengthToDbfs(strength);' . "\n";
    $html .= '    compressor.threshold.value = threshold; compressor.knee.value = 0.5;' . "\n";
    $html .= '    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;' . "\n";
    $html .= '    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);' . "\n";
    $html .= '    source.connect(compressor).connect(makeup).connect(context.destination);' . "\n";
    $html .= '  } else {' . "\n";
    $html .= '    const node = await core.createPeakLimiterNode(context);' . "\n";
    $html .= '    node.setProtection({enabled:true, strength});' . "\n";
    $html .= '    source.connect(node).connect(context.destination);' . "\n";
    $html .= '  }' . "\n";
    $html .= '  source.start();' . "\n";
    $html .= '  const rendered = await context.startRendering();' . "\n";
    $html .= '  return {kind, strength, path: strength === null ? \'off\' : legacy ? \'0.8.2-compressor\' : \'candidate-lookahead\',' . "\n";
    $html .= '    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};' . "\n";
    $html .= '}' . "\n";
    $html .= 'document.getElementById(\'run\').onclick = async () => {' . "\n";
    $html .= '  const output = document.getElementById(\'result\'); output.textContent = \'Läuft\';' . "\n";
    $html .= '  try {' . "\n";
    $html .= '    const rows = [];' . "\n";
    $html .= '    for (const kind of [\'impulse\',\'short-high-tone\',\'level-step\',\'speech-band\']) {' . "\n";
    $html .= '      rows.push(await render(kind, null, false));' . "\n";
    $html .= '      for (const strength of [25,75,100]) {' . "\n";
    $html .= '        rows.push(await render(kind, strength, true));' . "\n";
    $html .= '        rows.push(await render(kind, strength, false));' . "\n";
    $html .= '      }' . "\n";
    $html .= '    }' . "\n";
    $html .= '    const failures = rows.filter(row => row.path === \'candidate-lookahead\' &&' . "\n";
    $html .= '      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||' . "\n";
    $html .= '       (row.kind === \'speech-band\' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));' . "\n";
    $html .= '    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);' . "\n";
    $html .= '  } catch(error) { output.textContent = \'FEHLER: \' + error.stack; }' . "\n";
    $html .= '};' . "\n";
    $html .= '</script></html>' . "\n";

    file_put_contents($output_file, $html);
}

// Wenn diese Datei direkt aufgerufen wird, erzeuge die HTML-Datei
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    $output_file = isset($argv[1]) ? $argv[1] : 'peak-limiter.html';
    generate_peak_limiter_html($output_file);
    echo "HTML-Dokument wurde in $output_file erstellt.\n";
}
?>
