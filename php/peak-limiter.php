<?php
// abstraction-provenance: {"artifact_sha256": "98d5be3f36c89d3ffc0eb719fc93665e45add312492f8f32d582c21dc1140624", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "php"}
// peak-limiter.html — portiert nach php
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py
header('Content-Type: text/html; charset=utf-8');

echo '<!doctype html>';
echo '<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>';
echo '<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>';
echo '<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>';
echo '<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>';
echo '<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>';
echo '<script src="../browser-extension/content-core.js"></script>';
echo '<script>';
echo 'const core = TLC_CONTENT_CORE;';
echo 'const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));';
echo 'async function render(kind, strength, legacy) {';
echo '  const rate = 48000, length = rate;';
echo '  const context = new OfflineAudioContext(1, length, rate);';
echo '  const buffer = context.createBuffer(1, length, rate);';
echo '  const data = buffer.getChannelData(0);';
echo '  for (let i = 0; i < length; i++) {';
echo '    if (kind === \'speech-band\') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);';
echo '    else if (kind === \'short-high-tone\' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);';
echo '    else if (kind === \'level-step\' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);';
echo '  }';
echo '  if (kind === \'impulse\') data[5000] = 0.95;';
echo '  const source = context.createBufferSource(); source.buffer = buffer;';
echo '  if (strength === null) source.connect(context.destination);';
echo '  else if (legacy) {';
echo '    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();';
echo '    const threshold = core.limiterStrengthToDbfs(strength);';
echo '    compressor.threshold.value = threshold; compressor.knee.value = 0.5;';
echo '    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;';
echo '    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);';
echo '    source.connect(compressor).connect(makeup).connect(context.destination);';
echo '  } else {';
echo '    const node = await core.createPeakLimiterNode(context);';
echo '    node.setProtection({enabled:true, strength});';
echo '    source.connect(node).connect(context.destination);';
echo '  }';
echo '  source.start();';
echo '  const rendered = await context.startRendering();';
echo '  return {kind, strength, path: strength === null ? \'off\' : legacy ? \'0.8.2-compressor\' : \'candidate-lookahead\',';
echo '    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};';
echo '}';
echo 'document.getElementById(\'run\').onclick = async () => {';
echo '  const output = document.getElementById(\'result\'); output.textContent = \'Läuft\';';
echo '  try {';
echo '    const rows = [];';
echo '    for (const kind of [\'impulse\',\'short-high-tone\',\'level-step\',\'speech-band\']) {';
echo '      rows.push(await render(kind, null, false));';
echo '      for (const strength of [25,75,100]) {';
echo '        rows.push(await render(kind, strength, true));';
echo '        rows.push(await render(kind, strength, false));';
echo '      }';
echo '    }';
echo '    const failures = rows.filter(row => row.path === \'candidate-lookahead\' &&';
echo '      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||';
echo '       (row.kind === \'speech-band\' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));';
echo '    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);';
echo '  } catch(error) { output.textContent = \'FEHLER: \' + error.stack; }';
echo '};';
echo '</script></html>';
?>
