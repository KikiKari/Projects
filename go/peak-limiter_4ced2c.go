// abstraction-provenance: {"artifact_sha256": "35ac1c658b168be486eeb449d356d6e3e199bc0a3b2afab348194c37305d946b", "source_sha256": "4ced2ca9b27b1be45a4172c7993a0693b54431a3a2703c30cb796b668ff34bc0", "target_language": "go"}
// peak-limiter.html — portiert nach go
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
)

// Core simulation of the audio processing logic
type Core struct{}

func (c *Core) LimiterStrengthToDbfs(strength int) float64 {
	return -0.01*float64(strength) - 5.0
}

func (c *Core) LimiterMakeupCompensation(threshold, ratio float64) float64 {
	return math.Pow(10, -threshold*(1-1/ratio)/20)
}

func (c *Core) CreatePeakLimiterNode() *PeakLimiterNode {
	return &PeakLimiterNode{}
}

type PeakLimiterNode struct {
	enabled   bool
	strength  int
	threshold float64
	attack    float64
	release   float64
	envelope  float64
	gain      float64
	buffer    []float64
	delayBuf  []float64
	delayPos  int
}

func (p *PeakLimiterNode) SetProtection(enabled bool, strength int) {
	p.enabled = enabled
	p.strength = strength
	p.threshold = -0.01*float64(strength) - 5.0
	p.attack = 0.0015
	p.release = 0.08
	p.envelope = 0
	p.gain = 1
}

func (p *PeakLimiterNode) Process(input []float64) []float64 {
	if !p.enabled {
		return input
	}

	output := make([]float64, len(input))
	attackCoeff := math.Exp(-1.0 / (48000 * p.attack))
	releaseCoeff := math.Exp(-1.0 / (48000 * p.release))
	
	for i := 0; i < len(input); i++ {
		// Envelope detection
		envIn := math.Abs(input[i])
		if envIn > p.envelope {
			p.envelope = attackCoeff*p.envelope + (1-attackCoeff)*envIn
		} else {
			p.envelope = releaseCoeff*p.envelope + (1-releaseCoeff)*envIn
		}
		
		// Gain calculation
		if p.envelope > math.Pow(10, p.threshold/20) {
			targetGain := math.Pow(10, p.threshold/20) / p.envelope
			p.gain = 0.99*p.gain + 0.01*targetGain
		} else {
			p.gain = 0.99*p.gain + 0.01*1.0
		}
		
		output[i] = input[i] * p.gain
	}
	
	return output
}

func peakDb(values []float64) float64 {
	maxVal := 1e-10
	for _, v := range values {
		absV := math.Abs(v)
		if absV > maxVal {
			maxVal = absV
		}
	}
	return 20 * math.Log10(maxVal)
}

func render(kind string, strength *int, legacy bool) (map[string]interface{}, error) {
	rate := 48000
	length := rate
	data := make([]float64, length)
	
	for i := 0; i < length; i++ {
		if kind == "speech-band" {
			data[i] = 0.01 * math.Sin(2*math.Pi*220*float64(i)/float64(rate))
		} else if kind == "short-high-tone" && i >= 5000 && i < 5100 {
			data[i] = 0.95 * math.Sin(2*math.Pi*8000*float64(i)/float64(rate))
		} else if kind == "level-step" && i >= 5000 && i < 10000 {
			data[i] = 0.95 * math.Sin(2*math.Pi*1000*float64(i)/float64(rate))
		}
	}
	
	if kind == "impulse" {
		data[5000] = 0.95
	}
	
	var output []float64
	
	if strength == nil {
		output = data
	} else {
		core := &Core{}
		threshold := core.LimiterStrengthToDbfs(*strength)
		
		if legacy {
			// Compressor simulation
			attackCoeff := math.Exp(-1.0 / (48000 * 0.0015))
			releaseCoeff := math.Exp(-1.0 / (48000 * 0.08))
			envelope := 0.0
			gain := 1.0
			
			output = make([]float64, len(data))
			makeupGain := core.LimiterMakeupCompensation(threshold, 20)
			
			for i := 0; i < len(data); i++ {
				envIn := math.Abs(data[i])
				if envIn > envelope {
					envelope = attackCoeff*envelope + (1-attackCoeff)*envIn
				} else {
					envelope = releaseCoeff*envelope + (1-releaseCoeff)*envIn
				}
				
				if envelope > math.Pow(10, threshold/20) {
					targetGain := math.Pow(10, threshold/20) / envelope
					gain = 0.99*gain + 0.01*targetGain
				} else {
					gain = 0.99*gain + 0.01*1.0
				}
				
				output[i] = data[i] * gain * makeupGain
			}
		} else {
			// Peak limiter simulation
			node := core.CreatePeakLimiterNode()
			node.SetProtection(true, *strength)
			output = node.Process(data)
		}
	}
	
	path := ""
	if strength == nil {
		path = "off"
	} else if legacy {
		path = "0.8.2-compressor"
	} else {
		path = "candidate-lookahead"
	}
	
	result := map[string]interface{}{
		"kind":        kind,
		"path":        path,
		"inputDbfs":   peakDb(data),
		"outputDbfs":  peakDb(output),
	}
	
	if strength != nil {
		result["strength"] = *strength
	}
	
	return result, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: program <output-file>")
		os.Exit(1)
	}
	
	outputFile := os.Args[1]
	
	htmlContent := `<!doctype html>
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
</script></html>`
	
	err := os.WriteFile(outputFile, []byte(htmlContent), 0644)
	if err != nil {
		fmt.Printf("Error writing file: %v\n", err)
		os.Exit(1)
	}
	
	fmt.Printf("HTML file written to: %s\n", filepath.Abs(outputFile))
	
	// Run the audio test simulation
	rows := []map[string]interface{}{}
	kinds := []string{"impulse", "short-high-tone", "level-step", "speech-band"}
	strengths := []int{25, 75, 100}
	
	for _, kind := range kinds {
		row, _ := render(kind, nil, false)
		rows = append(rows, row)
		
		for _, strength := range strengths {
			row, _ := render(kind, &strength, true)
			rows = append(rows, row)
			
			row, _ = render(kind, &strength, false)
			rows = append(rows, row)
		}
	}
	
	core := &Core{}
	failures := []map[string]interface{}{}
	for _, row := range rows {
		if row["path"] == "candidate-lookahead" {
			strength := row["strength"].(int)
			threshold := core.LimiterStrengthToDbfs(strength)
			if row["outputDbfs"].(float64) > threshold+0.05 ||
				(row["kind"] == "speech-band" && math.Abs(row["outputDbfs"].(float64)-row["inputDbfs"].(float64)) > 0.05) {
				failures = append(failures, row)
			}
		}
	}
	
	result := map[string]interface{}{
		"passed":  len(failures) == 0,
		"failures": failures,
		"rows":    rows,
	}
	
	jsonResult, _ := json.MarshalIndent(result, "", "  ")
	fmt.Printf("\nTest Results:\n%s\n", string(jsonResult))
}
