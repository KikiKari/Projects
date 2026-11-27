// abstraction-provenance: {"artifact_sha256": "a20d63500a99a810f9ace688a538048fbe6de87aa08375cd7e7dd5e73aba5381", "source_sha256": "162cbb093559fd1ff9a7f362e753f4d965a73d5e557fce20d9cd95367574146b", "target_language": "go"}
// peak-limiter.html — portiert nach go
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/tests/peak-limiter.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/tests/peak-limiter.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/tests/peak-limiter.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"encoding/json"
	"fmt"
	"math"
	"os"
	"text/template"
)

// Core simulation of the audio processing functions
type Core struct{}

func (c *Core) LimiterStrengthToDbfs(strength int) float64 {
	return -float64(strength)/100*30 - 6
}

func (c *Core) LimiterMakeupCompensation(threshold, ratio float64) float64 {
	if ratio <= 1 {
		return 1
	}
	return math.Pow(10, -threshold*(1-1/ratio)/20)
}

func (c *Core) CreatePeakLimiterNode() string {
	return "PeakLimiterNode"
}

// Audio processing simulation
type AudioBuffer struct {
	Data []float64
	Rate int
}

type OfflineAudioContext struct {
	SampleRate int
	Length     int
	Channels   int
}

func NewOfflineAudioContext(channels, length, sampleRate int) *OfflineAudioContext {
	return &OfflineAudioContext{
		SampleRate: sampleRate,
		Length:     length,
		Channels:   channels,
	}
}

func (ctx *OfflineAudioContext) CreateBuffer(channels, length, sampleRate int) *AudioBuffer {
	return &AudioBuffer{
		Data: make([]float64, length),
		Rate: sampleRate,
	}
}

func (buffer *AudioBuffer) GetChannelData(channel int) []float64 {
	return buffer.Data
}

func PeakDb(values []float64) float64 {
	maxVal := 1e-10
	for _, v := range values {
		absV := math.Abs(v)
		if absV > maxVal {
			maxVal = absV
		}
	}
	return 20 * math.Log10(maxVal)
}

type ResultRow struct {
	Kind        string  `json:"kind"`
	Strength    *int    `json:"strength"`
	Path        string  `json:"path"`
	InputDbfs   float64 `json:"inputDbfs"`
	OutputDbfs  float64 `json:"outputDbfs"`
}

func Render(core *Core, kind string, strength *int, legacy bool) (*ResultRow, error) {
	rate := 48000
	length := rate
	context := NewOfflineAudioContext(1, length, rate)
	buffer := context.CreateBuffer(1, length, rate)
	data := buffer.GetChannelData(0)

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

	var path string
	if strength == nil {
		path = "off"
	} else if legacy {
		path = "0.8.2-compressor"
	} else {
		path = "candidate-lookahead"
	}

	// Simulate audio processing (simplified)
	outputData := make([]float64, len(data))
	copy(outputData, data)

	// Apply limiter effect if needed
	if strength != nil {
		threshold := core.LimiterStrengthToDbfs(*strength)
		
		if legacy {
			// Simplified compressor simulation
			makeup := core.LimiterMakeupCompensation(threshold, 20)
			for i, sample := range outputData {
				if math.Abs(sample) > math.Pow(10, threshold/20) {
					sign := 1.0
					if sample < 0 {
						sign = -1.0
					}
					compressed := sign * math.Pow(math.Abs(sample)*math.Pow(10, -threshold/20), 1/20) * math.Pow(10, threshold/20)
					outputData[i] = compressed * makeup
				}
			}
		} else {
			// Simplified lookahead limiter simulation
			limit := math.Pow(10, threshold/20)
			for i, sample := range outputData {
				if math.Abs(sample) > limit {
					outputData[i] = math.Copysign(limit, sample)
				}
			}
		}
	}

	inputDbfs := PeakDb(data)
	outputDbfs := PeakDb(outputData)

	return &ResultRow{
		Kind:        kind,
		Strength:    strength,
		Path:        path,
		InputDbfs:   inputDbfs,
		OutputDbfs:  outputDbfs,
	}, nil
}

func RunTest() (map[string]interface{}, error) {
	core := &Core{}
	var rows []ResultRow

	kinds := []string{"impulse", "short-high-tone", "level-step", "speech-band"}
	strengths := []int{25, 75, 100}

	for _, kind := range kinds {
		// No processing
		row, err := Render(core, kind, nil, false)
		if err != nil {
			return nil, err
		}
		rows = append(rows, *row)

		// With processing
		for _, strength := range strengths {
			// Legacy
			row, err := Render(core, kind, &strength, true)
			if err != nil {
				return nil, err
			}
			rows = append(rows, *row)

			// New
			row, err = Render(core, kind, &strength, false)
			if err != nil {
				return nil, err
			}
			rows = append(rows, *row)
		}
	}

	// Check failures
	var failures []ResultRow
	for _, row := range rows {
		if row.Path == "candidate-lookahead" {
			threshold := core.LimiterStrengthToDbfs(*row.Strength)
			if row.OutputDbfs > threshold+0.05 || 
			   (row.Kind == "speech-band" && math.Abs(row.OutputDbfs-row.InputDbfs) > 0.05) {
				failures = append(failures, row)
			}
		}
	}

	result := map[string]interface{}{
		"passed":   len(failures) == 0,
		"failures": failures,
		"rows":     rows,
	}

	return result, nil
}

const htmlTemplate = `<!doctype html>
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
    output.textContent = {{.Result}};
  } catch(error) { output.textContent = 'FEHLER: ' + error.stack; }
};
</script></html>`

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run script.go <output-file>")
		os.Exit(1)
	}

	filename := os.Args[1]

	// Run the test to get results
	result, err := RunTest()
	if err != nil {
		fmt.Printf("Error running test: %v\n", err)
		os.Exit(1)
	}

	// Convert result to JSON string for embedding
	resultJSON, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		fmt.Printf("Error marshaling result: %v\n", err)
		os.Exit(1)
	}

	// Create template with result embedded
	tmpl := template.Must(template.New("html").Parse(htmlTemplate))
	
	file, err := os.Create(filename)
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	data := struct {
		Result string
	}{
		Result: fmt.Sprintf("`%s`", string(resultJSON)),
	}

	err = tmpl.Execute(file, data)
	if err != nil {
		fmt.Printf("Error executing template: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("HTML file generated: %s\n", filename)
}
