#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "e6fd4d18e54e84ad8b9e8e37d9d0f1012eddb697c29fe68e5033fb48e07620a4", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "tcl"}
# peak-limiter.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erzeugung der HTML-Datei für die Pegelschutz-Audioprüfung
# Dieses Skript generiert dynamisch die HTML-Struktur und simuliert 
# grundlegende JavaScript-Funktionalität durch Tcl-Prozeduren.

package require http
package require json
package require math

proc main {outputFile} {
    set html [generateHTML]
    set fh [open $outputFile w]
    puts $fh $html
    close $fh
    puts "HTML erfolgreich in $outputFile geschrieben."
}

proc generateHTML {} {
    set html {}
    append html "<!doctype html>\n"
    append html "<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>\n"
    append html "<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>\n"
    append html "<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>\n"
    append html "<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>\n"
    append html "<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>\n"
    append html "<script src=\"../browser-extension/content-core.js\"></script>\n"
    append html "<script>\n"
    append html [generateJavaScript]
    append html "</script></html>\n"
    return $html
}

proc generateJavaScript {} {
    set js {}
    append js "const core = TLC_CONTENT_CORE;\n"
    append js "const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));\n"
    append js "async function render(kind, strength, legacy) {\n"
    append js "  const rate = 48000, length = rate;\n"
    append js "  const context = new OfflineAudioContext(1, length, rate);\n"
    append js "  const buffer = context.createBuffer(1, length, rate);\n"
    append js "  const data = buffer.getChannelData(0);\n"
    append js "  for (let i = 0; i < length; i++) {\n"
    append js "    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);\n"
    append js "    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);\n"
    append js "    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);\n"
    append js "  }\n"
    append js "  if (kind === 'impulse') data[5000] = 0.95;\n"
    append js "  const source = context.createBufferSource(); source.buffer = buffer;\n"
    append js "  if (strength === null) source.connect(context.destination);\n"
    append js "  else if (legacy) {\n"
    append js "    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();\n"
    append js "    const threshold = core.limiterStrengthToDbfs(strength);\n"
    append js "    compressor.threshold.value = threshold; compressor.knee.value = 0.5;\n"
    append js "    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;\n"
    append js "    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);\n"
    append js "    source.connect(compressor).connect(makeup).connect(context.destination);\n"
    append js "  } else {\n"
    append js "    const node = await core.createPeakLimiterNode(context);\n"
    append js "    node.setProtection({enabled:true, strength});\n"
    append js "    source.connect(node).connect(context.destination);\n"
    append js "  }\n"
    append js "  source.start();\n"
    append js "  const rendered = await context.startRendering();\n"
    append js "  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',\n"
    append js "    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};\n"
    append js "}\n"
    append js "document.getElementById('run').onclick = async () => {\n"
    append js "  const output = document.getElementById('result'); output.textContent = 'Läuft';\n"
    append js "  try {\n"
    append js "    const rows = [];\n"
    append js "    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {\n"
    append js "      rows.push(await render(kind, null, false));\n"
    append js "      for (const strength of [25,75,100]) {\n"
    append js "        rows.push(await render(kind, strength, true));\n"
    append js "        rows.push(await render(kind, strength, false));\n"
    append js "      }\n"
    append js "    }\n"
    append js "    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&\n"
    append js "      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||\n"
    append js "       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));\n"
    append js "    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);\n"
    append js "  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }\n"
    append js "};\n"
    return $js
}

if {$argc != 1} {
    puts "Verwendung: $argv0 <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
main $outputFile
