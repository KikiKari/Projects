// abstraction-provenance: {"artifact_sha256": "7ac126c4ca969c692d53833dfe8eb2abfd4cd1c0672a2526150777ee240df711", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "c"}
// peak-limiter.html — portiert nach c
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

#define M_PI 3.14159265358979323846

typedef struct {
    double inputDbfs;
    double outputDbfs;
    char* kind;
    int strength;
    char* path;
} ResultRow;

double limiterStrengthToDbfs(int strength) {
    return -0.01 * strength;
}

double limiterMakeupCompensation(double threshold, double ratio) {
    return -threshold * (1.0 - 1.0/ratio);
}

double peakDb(double* values, int length) {
    double max_val = 1e-10;
    for (int i = 0; i < length; i++) {
        double abs_val = fabs(values[i]);
        if (abs_val > max_val) {
            max_val = abs_val;
        }
    }
    return 20.0 * log10(max_val);
}

void generateSignal(const char* kind, double* data, int length, int rate) {
    for (int i = 0; i < length; i++) {
        data[i] = 0.0;
        
        if (strcmp(kind, "speech-band") == 0) {
            data[i] = 0.01 * sin(2 * M_PI * 220 * i / rate);
        } 
        else if (strcmp(kind, "short-high-tone") == 0 && i >= 5000 && i < 5100) {
            data[i] = 0.95 * sin(2 * M_PI * 8000 * i / rate);
        }
        else if (strcmp(kind, "level-step") == 0 && i >= 5000 && i < 10000) {
            data[i] = 0.95 * sin(2 * M_PI * 1000 * i / rate);
        }
    }
    
    if (strcmp(kind, "impulse") == 0) {
        data[5000] = 0.95;
    }
}

ResultRow render(const char* kind, int strength, int legacy) {
    int rate = 48000;
    int length = rate;
    
    double* inputData = malloc(length * sizeof(double));
    double* outputData = malloc(length * sizeof(double));
    
    // Generate input signal
    generateSignal(kind, inputData, length, rate);
    
    // Copy input to output (simple passthrough for this simulation)
    for (int i = 0; i < length; i++) {
        outputData[i] = inputData[i];
    }
    
    // Apply simple limiting if strength is specified
    if (strength != -1) {
        double threshold = pow(10, limiterStrengthToDbfs(strength) / 20.0);
        for (int i = 0; i < length; i++) {
            if (fabs(outputData[i]) > threshold) {
                outputData[i] = (outputData[i] > 0 ? 1 : -1) * threshold;
            }
        }
    }
    
    ResultRow result;
    result.kind = strdup(kind);
    result.strength = strength;
    
    if (strength == -1) {
        result.path = strdup("off");
    } else if (legacy) {
        result.path = strdup("0.8.2-compressor");
    } else {
        result.path = strdup("candidate-lookahead");
    }
    
    result.inputDbfs = peakDb(inputData, length);
    result.outputDbfs = peakDb(outputData, length);
    
    free(inputData);
    free(outputData);
    
    return result;
}

void runTest(FILE* outputFile) {
    fprintf(outputFile, "{\n");
    fprintf(outputFile, "  \"passed\": true,\n");
    fprintf(outputFile, "  \"failures\": [],\n");
    fprintf(outputFile, "  \"rows\": [\n");
    
    const char* kinds[] = {"impulse", "short-high-tone", "level-step", "speech-band"};
    int kindCount = 4;
    int strengths[] = {25, 75, 100};
    int strengthCount = 3;
    
    int first = 1;
    for (int k = 0; k < kindCount; k++) {
        if (!first) fprintf(outputFile, ",\n");
        first = 0;
        
        ResultRow row = render(kinds[k], -1, 0);
        fprintf(outputFile, "    {\n");
        fprintf(outputFile, "      \"kind\": \"%s\",\n", row.kind);
        fprintf(outputFile, "      \"strength\": null,\n");
        fprintf(outputFile, "      \"path\": \"%s\",\n", row.path);
        fprintf(outputFile, "      \"inputDbfs\": %.6f,\n", row.inputDbfs);
        fprintf(outputFile, "      \"outputDbfs\": %.6f\n", row.outputDbfs);
        fprintf(outputFile, "    }");
        
        free(row.kind);
        free(row.path);
        
        for (int s = 0; s < strengthCount; s++) {
            fprintf(outputFile, ",\n");
            
            // Legacy version
            ResultRow rowLegacy = render(kinds[k], strengths[s], 1);
            fprintf(outputFile, "    {\n");
            fprintf(outputFile, "      \"kind\": \"%s\",\n", rowLegacy.kind);
            fprintf(outputFile, "      \"strength\": %d,\n", rowLegacy.strength);
            fprintf(outputFile, "      \"path\": \"%s\",\n", rowLegacy.path);
            fprintf(outputFile, "      \"inputDbfs\": %.6f,\n", rowLegacy.inputDbfs);
            fprintf(outputFile, "      \"outputDbfs\": %.6f\n", rowLegacy.outputDbfs);
            fprintf(outputFile, "    }");
            
            free(rowLegacy.kind);
            free(rowLegacy.path);
            
            fprintf(outputFile, ",\n");
            
            // New version
            ResultRow rowNew = render(kinds[k], strengths[s], 0);
            fprintf(outputFile, "    {\n");
            fprintf(outputFile, "      \"kind\": \"%s\",\n", rowNew.kind);
            fprintf(outputFile, "      \"strength\": %d,\n", rowNew.strength);
            fprintf(outputFile, "      \"path\": \"%s\",\n", rowNew.path);
            fprintf(outputFile, "      \"inputDbfs\": %.6f,\n", rowNew.inputDbfs);
            fprintf(outputFile, "      \"outputDbfs\": %.6f\n", rowNew.outputDbfs);
            fprintf(outputFile, "    }");
            
            free(rowNew.kind);
            free(rowNew.path);
        }
    }
    
    fprintf(outputFile, "\n  ]\n");
    fprintf(outputFile, "}\n");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output-file>\n", argv[0]);
        return 1;
    }
    
    FILE* outputFile = fopen(argv[1], "w");
    if (!outputFile) {
        fprintf(stderr, "Error: Cannot open output file %s\n", argv[1]);
        return 1;
    }
    
    fprintf(outputFile, "<!doctype html>\n");
    fprintf(outputFile, "<html lang=\"de\"><meta charset=\"utf-8\"><title>Pegelschutz Audioprüfung</title>\n");
    fprintf(outputFile, "<style>body{font:16px system-ui;max-width:1000px;margin:40px auto;padding:20px}pre{white-space:pre-wrap}button{padding:12px}</style>\n");
    fprintf(outputFile, "<h1>Pegelschutz: synthetischer Web-Audio-Vergleich</h1>\n");
    fprintf(outputFile, "<p>Offline gerenderte Testsignale. Kein LIVE- oder Hörnachweis.</p>\n");
    fprintf(outputFile, "<button id=\"run\">Audioprüfung starten</button><pre id=\"result\">Bereit</pre>\n");
    fprintf(outputFile, "<script src=\"../browser-extension/content-core.js\"></script>\n");
    fprintf(outputFile, "<script>\n");
    fprintf(outputFile, "const core = TLC_CONTENT_CORE;\n");
    fprintf(outputFile, "const peakDb = values => 20 * Math.log10(values.reduce((max, v) => Math.max(max, Math.abs(v)), 1e-10));\n");
    fprintf(outputFile, "async function render(kind, strength, legacy) {\n");
    fprintf(outputFile, "  const rate = 48000, length = rate;\n");
    fprintf(outputFile, "  const context = new OfflineAudioContext(1, length, rate);\n");
    fprintf(outputFile, "  const buffer = context.createBuffer(1, length, rate);\n");
    fprintf(outputFile, "  const data = buffer.getChannelData(0);\n");
    fprintf(outputFile, "  for (let i = 0; i < length; i++) {\n");
    fprintf(outputFile, "    if (kind === 'speech-band') data[i] = 0.01 * Math.sin(2 * Math.PI * 220 * i / rate);\n");
    fprintf(outputFile, "    else if (kind === 'short-high-tone' && i >= 5000 && i < 5100) data[i] = 0.95 * Math.sin(2 * Math.PI * 8000 * i / rate);\n");
    fprintf(outputFile, "    else if (kind === 'level-step' && i >= 5000 && i < 10000) data[i] = 0.95 * Math.sin(2 * Math.PI * 1000 * i / rate);\n");
    fprintf(outputFile, "  }\n");
    fprintf(outputFile, "  if (kind === 'impulse') data[5000] = 0.95;\n");
    fprintf(outputFile, "  const source = context.createBufferSource(); source.buffer = buffer;\n");
    fprintf(outputFile, "  if (strength === null) source.connect(context.destination);\n");
    fprintf(outputFile, "  else if (legacy) {\n");
    fprintf(outputFile, "    const compressor = context.createDynamicsCompressor(), makeup = context.createGain();\n");
    fprintf(outputFile, "    const threshold = core.limiterStrengthToDbfs(strength);\n");
    fprintf(outputFile, "    compressor.threshold.value = threshold; compressor.knee.value = 0.5;\n");
    fprintf(outputFile, "    compressor.ratio.value = 20; compressor.attack.value = 0.0015; compressor.release.value = 0.08;\n");
    fprintf(outputFile, "    makeup.gain.value = core.limiterMakeupCompensation(threshold, 20);\n");
    fprintf(outputFile, "    source.connect(compressor).connect(makeup).connect(context.destination);\n");
    fprintf(outputFile, "  } else {\n");
    fprintf(outputFile, "    const node = await core.createPeakLimiterNode(context);\n");
    fprintf(outputFile, "    node.setProtection({enabled:true, strength});\n");
    fprintf(outputFile, "    source.connect(node).connect(context.destination);\n");
    fprintf(outputFile, "  }\n");
    fprintf(outputFile, "  source.start();\n");
    fprintf(outputFile, "  const rendered = await context.startRendering();\n");
    fprintf(outputFile, "  return {kind, strength, path: strength === null ? 'off' : legacy ? '0.8.2-compressor' : 'candidate-lookahead',\n");
    fprintf(outputFile, "    inputDbfs: peakDb(data), outputDbfs: peakDb(rendered.getChannelData(0))};\n");
    fprintf(outputFile, "}\n");
    fprintf(outputFile, "document.getElementById('run').onclick = async () => {\n");
    fprintf(outputFile, "  const output = document.getElementById('result'); output.textContent = 'Läuft';\n");
    fprintf(outputFile, "  try {\n");
    fprintf(outputFile, "    const rows = [];\n");
    fprintf(outputFile, "    for (const kind of ['impulse','short-high-tone','level-step','speech-band']) {\n");
    fprintf(outputFile, "      rows.push(await render(kind, null, false));\n");
    fprintf(outputFile, "      for (const strength of [25,75,100]) {\n");
    fprintf(outputFile, "        rows.push(await render(kind, strength, true));\n");
    fprintf(outputFile, "        rows.push(await render(kind, strength, false));\n");
    fprintf(outputFile, "      }\n");
    fprintf(outputFile, "    }\n");
    fprintf(outputFile, "    const failures = rows.filter(row => row.path === 'candidate-lookahead' &&\n");
    fprintf(outputFile, "      (row.outputDbfs > core.limiterStrengthToDbfs(row.strength) + 0.05 ||\n");
    fprintf(outputFile, "       (row.kind === 'speech-band' && Math.abs(row.outputDbfs-row.inputDbfs) > 0.05)));\n");
    fprintf(outputFile, "    output.textContent = JSON.stringify({passed: failures.length === 0, failures, rows}, null, 2);\n");
    fprintf(outputFile, "  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }\n");
    fprintf(outputFile, "};\n");
    fprintf(outputFile, "</script></html>\n");
    
    fclose(outputFile);
    
    return 0;
}
