// abstraction-provenance: {"artifact_sha256": "6674d536797e6a591c3aa19fd24ed50fc63fc0d011b4c4fa784b795758b6ae7a", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "cpp"}
// peak-limiter.html — portiert nach cpp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <cmath>
#include <vector>
#include <algorithm>
#include <memory>
#include <stdexcept>

// Forward declarations for audio processing functions
double peakDb(const std::vector<double>& values);
std::vector<double> createTestSignal(const std::string& kind, int rate, int length);
void processWithCompressor(std::vector<double>& data, double strength);
void processWithLimiter(std::vector<double>& data, double strength);

struct RenderResult {
    std::string kind;
    double strength;
    std::string path;
    double inputDbfs;
    double outputDbfs;
};

class Core {
public:
    static double limiterStrengthToDbfs(double strength) {
        return -20.0 + (strength / 100.0) * 20.0;
    }
    
    static double limiterMakeupCompensation(double threshold, double ratio) {
        return -(threshold * (1.0 - 1.0/ratio));
    }
};

double peakDb(const std::vector<double>& values) {
    double maxVal = 1e-10;
    for (double v : values) {
        maxVal = std::max(maxVal, std::abs(v));
    }
    return 20.0 * std::log10(maxVal);
}

std::vector<double> createTestSignal(const std::string& kind, int rate, int length) {
    std::vector<double> data(length, 0.0);
    
    for (int i = 0; i < length; i++) {
        if (kind == "speech-band") {
            data[i] = 0.01 * std::sin(2 * M_PI * 220 * i / rate);
        } else if (kind == "short-high-tone" && i >= 5000 && i < 5100) {
            data[i] = 0.95 * std::sin(2 * M_PI * 8000 * i / rate);
        } else if (kind == "level-step" && i >= 5000 && i < 10000) {
            data[i] = 0.95 * std::sin(2 * M_PI * 1000 * i / rate);
        }
    }
    
    if (kind == "impulse") {
        data[5000] = 0.95;
    }
    
    return data;
}

void processWithCompressor(std::vector<double>& data, double strength) {
    double threshold = Core::limiterStrengthToDbfs(strength);
    double makeup = Core::limiterMakeupCompensation(threshold, 20);
    
    // Simple compressor simulation
    for (auto& sample : data) {
        double absSample = std::abs(sample);
        if (absSample > std::pow(10, threshold/20.0)) {
            sample = (sample > 0 ? 1 : -1) * std::pow(absSample, 1.0/20.0) * std::pow(10, threshold/20.0);
        }
        sample *= std::pow(10, makeup/20.0);
    }
}

void processWithLimiter(std::vector<double>& data, double strength) {
    double limitThreshold = std::pow(10, Core::limiterStrengthToDbfs(strength)/20.0);
    
    for (auto& sample : data) {
        if (std::abs(sample) > limitThreshold) {
            sample = (sample > 0 ? 1 : -1) * limitThreshold;
        }
    }
}

RenderResult render(const std::string& kind, double strength, bool legacy) {
    const int rate = 48000;
    const int length = rate;
    
    std::vector<double> data = createTestSignal(kind, rate, length);
    double inputDbfs = peakDb(data);
    
    if (strength == -1) { // null case
        return {kind, strength, "off", inputDbfs, peakDb(data)};
    } else if (legacy) {
        processWithCompressor(data, strength);
        return {kind, strength, "0.8.2-compressor", inputDbfs, peakDb(data)};
    } else {
        processWithLimiter(data, strength);
        return {kind, strength, "candidate-lookahead", inputDbfs, peakDb(data)};
    }
}

std::string generateHTML() {
    std::string html = 
R"(<!doctype html>
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
</script></html>)";
    
    return html;
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <ausgabedatei>" << std::endl;
        return 1;
    }
    
    std::string filename = argv[1];
    std::ofstream file(filename);
    
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return 1;
    }
    
    try {
        std::string content = generateHTML();
        file << content;
        file.close();
        std::cout << "HTML-Datei erfolgreich erstellt: " << filename << std::endl;
    } catch (const std::exception& e) {
        std::cerr << "Fehler beim Erstellen der HTML-Datei: " << e.what() << std::endl;
        file.close();
        return 1;
    }
    
    return 0;
}
