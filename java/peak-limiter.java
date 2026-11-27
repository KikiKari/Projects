// abstraction-provenance: {"artifact_sha256": "81df989c724c48d89ac5ec8a06b7f33b03b07e3e09b9edbc423fa7f66f17840d", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "java"}
// peak-limiter.html — portiert nach java
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.stream.*;
import javax.script.*;

public class PeakLimiter {
    private static final int RATE = 48000;
    private static final int LENGTH = RATE;
    
    public static void main(String[] args) throws Exception {
        if (args.length != 1) {
            System.err.println("Verwendung: java PeakLimiter <ausgabedatei>");
            System.exit(1);
        }
        
        String html = generateHTML();
        Files.write(Paths.get(args[0]), html.getBytes("UTF-8"));
    }
    
    private static String generateHTML() {
        StringBuilder html = new StringBuilder();
        html.append("<!doctype html>\n");
        html.append("<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>\n");
        html.append("<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>\n");
        html.append("<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>\n");
        html.append("<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>\n");
        html.append("<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>\n");
        html.append("<script src=\"../browser-extension/content-core.js\"></script>\n");
        html.append("<script>\n");
        html.append("const core = TLC_CONTENT_CORE;\n");
        html.append("const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));\n");
        html.append("async function render(kind, strength, legacy) {\n");
        html.append("  const rate = 48000, length = rate;\n");
        html.append("  const context = new OfflineAudioContext(1, length, rate);\n");
        html.append("  const buffer = context.createBuffer(1, length, rate);\n");
        html.append("  const data = buffer.getChannelData(0);\n");
        html.append("  for (let i = 0; i < length; i++) {\n");
        html.append("    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);\n");
        html.append("    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);\n");
        html.append("    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);\n");
        html.append("  }\n");
        html.append("  if (kind === 'impulse') data[5000] = 0.95;\n");
        html.append("  const source = context.createBufferSource(); source.buffer = buffer;\n");
        html.append("  if (strength === null) source.connect(context.destination);\n");
        html.append("  else if (legacy) {\n");
        html.append("    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();\n");
        html.append("    const threshold = core.limiterStrengthToDbfs(strength);\n");
        html.append("    compressor.threshold.value = threshold; compressor.knee.value = 0.5;\n");
        html.append("    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;\n");
        html.append("    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);\n");
        html.append("    source.connect(compressor).connect(makeup).connect(context.destination);\n");
        html.append("  } else {\n");
        html.append("    const node = await core.createPeakLimiterNode(context);\n");
        html.append("    node.setProtection({enabled:true, strength});\n");
        html.append("    source.connect(node).connect(context.destination);\n");
        html.append("  }\n");
        html.append("  source.start();\n");
        html.append("  const rendered = await context.startRendering();\n");
        html.append("  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',\n");
        html.append("    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};\n");
        html.append("}\n");
        html.append("document.getElementById('run').onclick = async () => {\n");
        html.append("  const output = document.getElementById('result'); output.textContent = 'Läuft';\n");
        html.append("  try {\n");
        html.append("    const rows = [];\n");
        html.append("    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {\n");
        html.append("      rows.push(await render(kind, null, false));\n");
        html.append("      for (const strength of [25,75,100]) {\n");
        html.append("        rows.push(await render(kind, strength, true));\n");
        html.append("        rows.push(await render(kind, strength, false));\n");
        html.append("      }\n");
        html.append("    }\n");
        html.append("    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&\n");
        html.append("      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||\n");
        html.append("       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));\n");
        html.append("    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);\n");
        html.append("  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }\n");
        html.append("};\n");
        html.append("</script></html>");
        
        return html.toString();
    }
}
