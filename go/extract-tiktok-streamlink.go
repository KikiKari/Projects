// abstraction-provenance: {"artifact_sha256": "1259a79d248e39f7bdb39617b58ae9465ad9a169b10976f42b1f72d94b66e468", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "go"}
// extract-tiktok-streamlink.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"os"
	"os/exec"
	"regexp"
	"strconv"
	"strings"
	"time"
)

type Payload struct {
	Success   bool   `json:"success,omitempty"`
	Method    string `json:"method,omitempty"`
	Username  string `json:"username,omitempty"`
	URL       string `json:"url,omitempty"`
	Quality   string `json:"quality,omitempty"`
	Author    string `json:"author,omitempty"`
	Title     string `json:"title,omitempty"`
	Error     string `json:"error,omitempty"`
	Timestamp string `json:"timestamp,omitempty"`
	Status    string `json:"status,omitempty"`
}

func emitJSON(success bool, method, username, url, quality, author, title, errorStr, timestamp, status string) {
	payload := Payload{
		Success:   success,
		Method:    method,
		Username:  username,
		URL:       url,
		Quality:   quality,
		Author:    author,
		Title:     title,
		Error:     errorStr,
		Timestamp: timestamp,
		Status:    status,
	}
	
	// Remove empty fields
	if !success {
		payload.URL = ""
		payload.Author = ""
		payload.Title = ""
	}
	if success {
		payload.Error = ""
		payload.Status = ""
	}
	if errorStr == "" {
		payload.Error = ""
	}
	if status == "" {
		payload.Status = ""
	}
	if author == "" {
		payload.Author = ""
	}
	if title == "" {
		payload.Title = ""
	}
	if url == "" {
		payload.URL = ""
	}
	
	jsonData, _ := json.Marshal(payload)
	fmt.Println(string(jsonData))
}

func getLoadPerCPU() (float64, error) {
	cmd := exec.Command("python3", "-c", `
import os
load_avg = os.getloadavg()[0]
cpu_count = max(1, os.cpu_count() or 1)
print(load_avg / cpu_count)
`)
	output, err := cmd.Output()
	if err != nil {
		return 0, err
	}
	load, err := strconv.ParseFloat(strings.TrimSpace(string(output)), 64)
	if err != nil {
		return 0, err
	}
	return load, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Invalid TikTok username")
		os.Exit(64)
	}
	
	username := strings.TrimPrefix(os.Args[1], "@")
	quality := "best"
	if len(os.Args) > 2 {
		quality = os.Args[2]
	}
	jsonFlag := ""
	if len(os.Args) > 3 {
		jsonFlag = os.Args[3]
	}
	timestamp := time.Now().UTC().Format("2006-01-02T15:04:05Z")

	// Validate username
	usernameRegex := regexp.MustCompile(`^[A-Za-z0-9._]{1,24}$`)
	if !usernameRegex.MatchString(username) {
		emitJSON(false, "streamlink", username, "", quality, "", "", "Invalid TikTok username", timestamp, "invalid_input")
		os.Exit(64)
	}

	// Validate quality
	validQualities := map[string]bool{
		"best": true, "worst": true, "original": true, "1080p60": true,
		"720p60": true, "720p": true, "540p": true, "360p": true, "auto": true,
	}
	if !validQualities[quality] {
		emitJSON(false, "streamlink", username, "", quality, "", "", "Invalid stream quality", timestamp, "invalid_input")
		os.Exit(64)
	}

	// Check system load
	loadPerCPU, err := getLoadPerCPU()
	if err != nil {
		loadPerCPU = 0
	}
	maxLoadStr := os.Getenv("TIKTOK_MAX_LOAD_PER_CPU")
	if maxLoadStr == "" {
		maxLoadStr = "1.5"
	}
	maxLoad, err := strconv.ParseFloat(maxLoadStr, 64)
	if err != nil {
		maxLoad = 1.5
	}
	
	if loadPerCPU > maxLoad {
		emitJSON(false, "streamlink", username, "", quality, "", "", "host overloaded", timestamp, "overloaded")
		os.Exit(75)
	}

	// Check if streamlink exists
	_, err = exec.LookPath("streamlink")
	if err != nil {
		emitJSON(false, "streamlink", username, "", quality, "", "", "streamlink not installed", timestamp, "dependency_missing")
		os.Exit(2)
	}

	liveURL := fmt.Sprintf("https://www.tiktok.com/@%s/live", username)
	
	selectorMap := map[string]string{
		"original": "origin,uhd_60,hd_60,hd,sd,ld,best,worst",
		"auto":     "best,origin,uhd_60,hd_60,hd,sd,ld,worst",
		"1080p60":  "uhd_60,hd_60,hd,sd,ld,worst",
		"720p60":   "hd_60,hd,sd,ld,worst",
		"720p":     "hd,sd,ld,worst",
		"540p":     "sd,ld,worst",
		"360p":     "ld,worst",
	}
	selector := selectorMap[quality]
	if selector == "" {
		selector = quality
	}

	// Try streamlink with --json first
	cmd := exec.Command("streamlink", "--json", liveURL, selector)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr
	err = cmd.Run()
	
	var output string
	if err == nil && stdout.Len() > 0 {
		output = stdout.String()
	} else {
		// Fallback to --stream-url
		cmd = exec.Command("streamlink", "--stream-url", liveURL, selector)
		cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		err = cmd.Run()
		
		if err != nil || stdout.Len() == 0 {
			emitJSON(false, "streamlink", username, "", quality, "", "", "streamlink failed or no stream found", timestamp, "offline")
			os.Exit(1)
		}
		
		url := strings.TrimSpace(stdout.String())
		if jsonFlag == "--json" {
			emitJSON(true, "streamlink", username, url, quality, "", "", "", timestamp, "live")
		} else {
			fmt.Println(url)
		}
		os.Exit(0)
	}

	// Parse JSON output
	var streamlinkData map[string]interface{}
	if err := json.Unmarshal([]byte(output), &streamlinkData); err != nil {
		emitJSON(false, "streamlink", username, "", quality, "", "", "invalid streamlink JSON", timestamp, "technical_error")
		os.Exit(2)
	}

	url := ""
	if u, ok := streamlinkData["url"].(string); ok {
		url = u
	}
	
	var author, title string
	if metadata, ok := streamlinkData["metadata"].(map[string]interface{}); ok {
		if a, ok := metadata["author"].(string); ok {
			author = a
		}
		if t, ok := metadata["title"].(string); ok {
			title = t
		}
	}
	
	if url == "" {
		if streams, ok := streamlinkData["streams"].(map[string]interface{}); ok {
			priorityKeys := []string{"best", "worst"}
			for k := range streams {
				priorityKeys = append(priorityKeys, k)
			}
			
			for _, key := range priorityKeys {
				if stream, ok := streams[key].(map[string]interface{}); ok {
					if u, ok := stream["url"].(string); ok && u != "" {
						url = u
						break
					}
				}
			}
		}
	}

	if url == "" {
		emitJSON(false, "streamlink", username, "", quality, author, title, "could not extract stream URL", timestamp, "offline")
		os.Exit(1)
	}

	if jsonFlag == "--json" {
		emitJSON(true, "streamlink", username, url, quality, author, title, "", timestamp, "live")
	} else {
		fmt.Println(url)
	}
}
