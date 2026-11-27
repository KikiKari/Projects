// abstraction-provenance: {"artifact_sha256": "8db9e4a3c272adb940aa92dc83b2940c45c164fc2e286731c7155c8adfd8c4bf", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "c"}
// peak-limiter.html — portiert nach c
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Function prototypes
double limiterStrengthToDbfs(int strength);
double limiterMakeupCompensation(double threshold, int ratio);
double peakDb(const double* values, int length);
void render(const char* kind, int strength, int legacy, FILE* output);

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE* file = fopen(argv[1], "w");
    if (!file) {
        perror("Failed to open output file");
        return 1;
    }

    // Write HTML header and basic structure
    fprintf(file,
        "<!doctype html>\n"
        "<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>\n"
        "<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>\n"
        "<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>\n"
        "<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>\n"
        "<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>\n"
        "<script src=\"../browser-extension/content-core.js\"></script>\n"
        "<script>\n"
        "const core = TLC_CONTENT_CORE;\n");

    // Write helper functions
    fprintf(file,
        "const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));\n");

    // Write render function opening
    fprintf(file,
        "async function render(kind, strength, legacy) {\n"
        "  const rate = 48000, length = rate;\n"
        "  const context = new OfflineAudioContext(1, length, rate);\n"
        "  const buffer = context.createBuffer(1, length, rate);\n"
        "  const data = buffer.getChannelData(0);\n"
        "  for (let i = 0; i < length; i++) {\n"
        "    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);\n"
        "    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);\n"
        "    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);\n"
        "  }\n"
        "  if (kind === 'impulse') data[5000] = 0.95;\n"
        "  const source = context.createBufferSource(); source.buffer = buffer;\n"
        "  if (strength === null) source.connect(context.destination);\n"
        "  else if (legacy) {\n"
        "    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();\n"
        "    const threshold = core.limiterStrengthToDbfs(strength);\n"
        "    compressor.threshold.value = threshold; compressor.knee.value = 0.5;\n"
        "    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;\n"
        "    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);\n"
        "    source.connect(compressor).connect(makeup).connect(context.destination);\n"
        "  } else {\n"
        "    const node = await core.createPeakLimiterNode(context);\n"
        "    node.setProtection({enabled:true, strength});\n"
        "    source.connect(node).connect(context.destination);\n"
        "  }\n"
        "  source.start();\n"
        "  const rendered = await context.startRendering();\n"
        "  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',\n"
        "    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};\n"
        "}\n");

    // Write click handler
    fprintf(file,
        "document.getElementById('run').onclick = async () => {\n"
        "  const output = document.getElementById('result'); output.textContent = 'Läuft';\n"
        "  try {\n"
        "    const rows = [];\n"
        "    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {\n"
        "      rows.push(await render(kind, null, false));\n"
        "      for (const strength of [25,75,100]) {\n"
        "        rows.push(await render(kind, strength, true));\n"
        "        rows.push(await render(kind, strength, false));\n"
        "      }\n"
        "    }\n"
        "    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&\n"
        "      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||\n"
        "       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));\n"
        "    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);\n"
        "  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }\n"
        "};\n");

    // Close script and html tags
    fprintf(file, "</script></html>\n");

    fclose(file);
    return 0;
}

// Helper functions implementations (not used in this C version but shown for completeness)
double limiterStrengthToDbfs(int strength) {
    // This is a placeholder - actual implementation would depend on the specific formula
    return -((100 - strength) * 0.3); // Example conversion
}

double limiterMakeupCompensation(double threshold, int ratio) {
    // This is a placeholder - actual implementation would depend on the specific formula
    return pow(10, (-threshold * (1 - 1.0/ratio))/20);
}

double peakDb(const double* values, int length) {
    double max_val = 1e-10;
    for (int i = 0; i < length; i++) {
        double abs_val = fabs(values[i]);
        if (abs_val > max_val) {
            max_val = abs_val;
        }
    }
    return 20 * log10(max_val);
}

void render(const char* kind, int strength, int legacy, FILE* output) {
    // This function would contain the logic to generate audio processing results
    // In this simplified version, we're just generating the HTML structure
    // The actual audio processing would require more complex libraries
}
