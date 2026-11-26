// abstraction-provenance: {"artifact_sha256": "f3fab67dc6e1693b3370736194108c721a6bb2104970e340f2736e51c5d7f63b", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "go"}
// generate-wavespeed.mjs — portiert nach go
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type Job struct {
	ID           string   `json:"id"`
	Output       string   `json:"output"`
	Prompt       string   `json:"prompt"`
	Images       []string `json:"images"`
	AspectRatio  string   `json:"aspectRatio"`
}

type LogEntry struct {
	ID            string  `json:"id"`
	RequestID     string  `json:"requestId"`
	Model         string  `json:"model"`
	Resolution    string  `json:"resolution"`
	PlannedCostUsd float64 `json:"plannedCostUsd"`
	Output        string  `json:"output"`
}

type SubmitResponse struct {
	Data struct {
		ID string `json:"id"`
	} `json:"data"`
	ID string `json:"id"`
}

type PollResponse struct {
	Data struct {
		Status  string   `json:"status"`
		Outputs []string `json:"outputs"`
	} `json:"data"`
}

func main() {
	key := os.Getenv("WAVESPEED_API_KEY")
	if key == "" {
		panic("WAVESPEED_API_KEY fehlt.")
	}

	// Get current directory
	currentDir, _ := os.Getwd()
	mediaProductionDir := filepath.Join(currentDir, "..", "media-production")
	rawDir := filepath.Join(mediaProductionDir, "raw")
	publicDir := filepath.Join(currentDir, "..", "public", "media")
	resultUrl := filepath.Join(mediaProductionDir, "wavespeed-results.json")

	// Create directories
	os.MkdirAll(rawDir, 0755)
	os.MkdirAll(publicDir, 0755)

	// Read jobs
	jobsData, err := os.ReadFile(filepath.Join(mediaProductionDir, "wavespeed-jobs.json"))
	if err != nil {
		panic(err)
	}

	var jobs []Job
	err = json.Unmarshal(jobsData, &jobs)
	if err != nil {
		panic(err)
	}

	// Read log
	logData, err := os.ReadFile(resultUrl)
	if err != nil {
		logData = []byte("[]")
	}

	var log []LogEntry
	json.Unmarshal(logData, &log)

	for _, job := range jobs {
		rawPath := filepath.Join(rawDir, job.ID+".png")
		targetPath := filepath.Join(publicDir, job.Output+".png")

		// Check if file already exists
		if _, err := os.Stat(rawPath); err == nil {
			found := false
			for _, entry := range log {
				if entry.ID == job.ID {
					found = true
					break
				}
			}
			if !found {
				log = append(log, LogEntry{
					ID:            job.ID,
					RequestID:     "completed-before-resume",
					Model:         "google/nano-banana-2/edit",
					Resolution:    "4k",
					PlannedCostUsd: 0.14,
					Output:        filepath.Base(targetPath),
				})
				writeLog(resultUrl, log)
			}
			fmt.Printf("Übersprungen: %s ist bereits vorhanden.\n", job.ID)
			continue
		}

		// Process images
		var processedImages []string
		for _, image := range job.Images {
			if strings.HasPrefix(image, "http:") || strings.HasPrefix(image, "https:") || strings.HasPrefix(image, "data:") {
				processedImages = append(processedImages, image)
			} else {
				imagePath := filepath.Join(currentDir, "..", image)
				bytes, err := os.ReadFile(imagePath)
				if err != nil {
					panic(err)
				}
				encoded := base64.StdEncoding.EncodeToString(bytes)
				processedImages = append(processedImages, "data:image/png;base64,"+encoded)
			}
		}

		// Submit job
		submitData := map[string]interface{}{
			"prompt":              job.Prompt,
			"images":              processedImages,
			"aspect_ratio":        job.AspectRatio,
			"resolution":          "4k",
			"output_format":       "png",
			"enable_web_search":   false,
			"enable_image_search": false,
			"enable_sync_mode":    false,
			"enable_base64_output": false,
		}

		submitJSON, _ := json.Marshal(submitData)
		req, _ := http.NewRequest("POST", "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit", strings.NewReader(string(submitJSON)))
		req.Header.Set("Authorization", "Bearer "+key)
		req.Header.Set("Content-Type", "application/json")

		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			panic(err)
		}
		defer resp.Body.Close()

		if resp.StatusCode != 200 {
			body, _ := io.ReadAll(resp.Body)
			panic(fmt.Sprintf("WaveSpeed submit fehlgeschlagen: %d %s", resp.StatusCode, string(body)))
		}

		var submitted SubmitResponse
		json.NewDecoder(resp.Body).Decode(&submitted)
		requestId := submitted.Data.ID
		if requestId == "" {
			requestId = submitted.ID
		}

		// Poll for result
		var result PollResponse
		for attempt := 0; attempt < 90; attempt++ {
			time.Sleep(4000 * time.Millisecond)
			
			pollReq, _ := http.NewRequest("GET", fmt.Sprintf("https://api.wavespeed.ai/api/v3/predictions/%s/result", requestId), nil)
			pollReq.Header.Set("Authorization", "Bearer "+key)
			
			pollResp, err := client.Do(pollReq)
			if err != nil {
				panic(err)
			}
			
			json.NewDecoder(pollResp.Body).Decode(&result)
			pollResp.Body.Close()
			
			if result.Data.Status == "completed" {
				break
			}
			if result.Data.Status == "failed" {
				panic(fmt.Sprintf("WaveSpeed job fehlgeschlagen: %s", job.ID))
			}
		}

		if len(result.Data.Outputs) == 0 {
			panic(fmt.Sprintf("Kein Output für %s", job.ID))
		}

		url := result.Data.Outputs[0]
		resp, err = http.Get(url)
		if err != nil {
			panic(err)
		}
		defer resp.Body.Close()

		bytes, err := io.ReadAll(resp.Body)
		if err != nil {
			panic(err)
		}

		os.WriteFile(rawPath, bytes, 0644)
		os.WriteFile(targetPath, bytes, 0644)

		log = append(log, LogEntry{
			ID:            job.ID,
			RequestID:     requestId,
			Model:         "google/nano-banana-2/edit",
			Resolution:    "4k",
			PlannedCostUsd: 0.14,
			Output:        filepath.Base(targetPath),
		})
		writeLog(resultUrl, log)
		fmt.Printf("Abgeschlossen: %s\n", job.ID)
	}

	writeLog(resultUrl, log)
	fmt.Printf("WaveSpeed abgeschlossen: %d Assets, geplante Basiskosten $%.2f.\n", len(log), float64(len(log))*0.14)
}

func writeLog(path string, log []LogEntry) {
	data, _ := json.MarshalIndent(log, "", "  ")
	os.WriteFile(path, data, 0644)
}
