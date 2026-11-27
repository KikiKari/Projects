// abstraction-provenance: {"artifact_sha256": "f6884eb4459ff713afe75fdfcb6758e85e67f1017b3465efdaf8819a54e303f3", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "cpp"}
// peak-limiter.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <vector>
#include <algorithm>
#include <memory>
#include <stdexcept>

// Simple HTML generator class
class HtmlDocument {
private:
    std::string content;
    
public:
    HtmlDocument() {
        content = "<!doctype html>\n<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>\n";
        content += "<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>\n";
        content += "<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>\n";
        content += "<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>\n";
        content += "<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>\n";
        content += "<script src=\"../browser-extension/content-core.js\"></script>\n";
        content += "<script>\n";
        content += "const core = TLC_CONTENT_CORE;\n";
        content += "const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));\n";
        content += "async function render(kind, strength, legacy) {\n";
        content += "  const rate = 48000, length = rate;\n";
        content += "  const context = new OfflineAudioContext(1, length, rate);\n";
        content += "  const buffer = context.createBuffer(1, length, rate);\n";
        content += "  const data = buffer.getChannelData(0);\n";
        content += "  for (let i = 0; i < length; i++) {\n";
        content += "    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);\n";
        content += "    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);\n";
        content += "    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);\n";
        content += "  }\n";
        content += "  if (kind === 'impulse') data[5000] = 0.95;\n";
        content += "  const source = context.createBufferSource(); source.buffer = buffer;\n";
        content += "  if (strength === null) source.connect(context.destination);\n";
        content += "  else if (legacy) {\n";
        content += "    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();\n";
        content += "    const threshold = core.limiterStrengthToDbfs(strength);\n";
        content += "    compressor.threshold.value = threshold; compressor.knee.value = 0.5;\n";
        content += "    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;\n";
        content += "    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);\n";
        content += "    source.connect(compressor).connect(makeup).connect(context.destination);\n";
        content += "  } else {\n";
        content += "    const node = await core.createPeakLimiterNode(context);\n";
        content += "    node.setProtection({enabled:true, strength});\n";
        content += "    source.connect(node).connect(context.destination);\n";
        content += "  }\n";
        content += "  source.start();\n";
        content += "  const rendered = await context.startRendering();\n";
        content += "  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',\n";
        content += "    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};\n";
        content += "}\n";
        content += "document.getElementById('run').onclick = async () => {\n";
        content += "  const output = document.getElementById('result'); output.textContent = 'Läuft';\n";
        content += "  try {\n";
        content += "    const rows = [];\n";
        content += "    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {\n";
        content += "      rows.push(await render(kind, null, false));\n";
        content += "      for (const strength of [25,75,100]) {\n";
        content += "        rows.push(await render(kind, strength, true));\n";
        content += "        rows.push(await render(kind, strength, false));\n";
        content += "      }\n";
        content += "    }\n";
        content += "    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&\n";
        content += "      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||\n";
        content += "       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));\n";
        content += "    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);\n";
        content += "  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }\n";
        content += "};\n";
        content += "</script></html>\n";
    }
    
    void saveToFile(const std::string& filename) {
        std::ofstream file(filename);
        if (!file.is_open()) {
            throw std::runtime_error("Could not open file for writing: " + filename);
        }
        file << content;
        file.close();
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>" << std::endl;
        return 1;
    }
    
    try {
        HtmlDocument doc;
        doc.saveToFile(argv[1]);
        std::cout << "HTML document generated successfully: " << argv[1] << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
