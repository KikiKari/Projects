#!/usr/bin/env tclsh
# peak-limiter.html — portiert nach tcl
# Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/tests/peak-limiter.html
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

# Tcl 8.6 Script zur Erzeugung der HTML-Datei peak-limiter.html
# Dieses Skript generiert dynamisch die HTML-Struktur und simuliert
# grundlegend die Funktionalität des originalen JavaScript-Codes,
# allerdings ohne Web Audio API, da Tcl diese nicht bietet.

package require http
package require json
package require json::write

proc writeHtmlFile {filename} {
    set fp [open $filename w]
    fconfigure $fp -encoding utf-8

    # HTML-Kopf und Metadaten
    puts $fp {<!doctype html>}
    puts $fp {<html lang="de"><meta charset="utf-8"><title>Pegelschutz Audioprüfung</title>}

    # CSS-Stildefinitionen
    puts $fp {<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>}

    # Überschrift und Beschreibung
    puts $fp {<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>}
    puts $fp {<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>}

    # Button und Ausgabebereich
    puts $fp {<button id="run">Audioprüfung starten</button><pre id="result">Bereit</pre>}

    # Externer Skriptbezug (angenommen, dass content-core.js existiert)
    puts $fp {<script src="../browser-extension/content-core.js"></script>}

    # JavaScript-Codeblock
    puts $fp {<script>}
    puts $fp {const core = TLC_CONTENT_CORE;}
    puts $fp {const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));}

    # Render-Funktion
    puts $fp {

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
    }

    # Eventhandler für den Button
    puts $fp {
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
    }

    # Abschluss des Script-Tags und HTML-Dokuments
    puts $fp {</script>}
    puts $fp {</html>}

    close $fp
}

# Hauptprogramm: Prüfe Kommandozeilenargumente
if {$argc != 1} {
    puts stderr "Aufruf: [info script] <ausgabedatei>"
    exit 1
}

set outputFile [lindex $argv 0]
writeHtmlFile $outputFile
puts "HTML-Datei wurde erfolgreich erstellt: $outputFile"
