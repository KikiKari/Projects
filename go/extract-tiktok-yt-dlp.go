// abstraction-provenance: {"artifact_sha256": "cf0a5da4e0afda8757cf5dbf00d850662bb6023e1f6cc0e1bb74151075ab3745", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "go"}
// extract-tiktok-yt-dlp.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
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
	"runtime"
	"strconv"
	"strings"
	"syscall"
	"time"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "Usage: extract-tiktok-yt-dlp.go <username> [format] [--json]")
		os.Exit(64)
	}
	username := strings.TrimPrefix(os.Args[1], "@")
	format := "best"
	if len(os.Args) > 2 {
		format = os.Args[2]
	}
	jsonFlag := ""
	if len(os.Args) > 3 {
		jsonFlag = os.Args[3]
	}

	timestamp := time.Now().UTC().Format("2006-01-02T15:04:05Z")
	tmpDir, err := os.MkdirTemp("/tmp", "tiktok-yt-dlp.*")
	if err != nil {
		emitJSON(false, "yt-dlp", username, "", format, "failed to create temp dir", timestamp, "technical_error")
		os.Exit(2)
	}
	defer os.RemoveAll(tmpDir)

	validUsername := regexp.MustCompile(`^[A-Za-z0-9._]{1,24}$`)
	if !validUsername.MatchString(username) {
		fmt.Fprintln(os.Stderr, "Invalid TikTok username")
		os.Exit(64)
	}

	validFormats := map[string]bool{
		"hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld": true,
		"hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld":                                 true,
		"hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld":                                            true,
		"hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld":                                              true,
		"hls-sd/hls-ld/flv-sd/flv-ld":                                                            true,
		"hls-ld/flv-ld":                                                                          true,
		"hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld":                      true,
	}
	if !validFormats[format] {
		fmt.Fprintln(os.Stderr, "Invalid yt-dlp format")
		os.Exit(64)
	}

	loadPerCPU := getLoadPerCPU()
	maxLoadStr := os.Getenv("TIKTOK_MAX_LOAD_PER_CPU")
	if maxLoadStr == "" {
		maxLoadStr = "1.5"
	}
	maxLoad, _ := strconv.ParseFloat(maxLoadStr, 64)
	if loadPerCPU > maxLoad {
		emitJSON(false, "yt-dlp", username, "", format, "host overloaded", timestamp, "overloaded")
		os.Exit(75)
	}

	if _, err := exec.LookPath("yt-dlp"); err != nil {
		emitJSON(false, "yt-dlp", username, "", format, "yt-dlp not installed", timestamp, "dependency_missing")
		os.Exit(2)
	}

	liveURL := fmt.Sprintf("https://www.tiktok.com/@%s/live", username)
	stdoutFile := tmpDir + "/stdout.json"
	stderrFile := tmpDir + "/stderr.log"

	cmd := exec.Command("yt-dlp", "--no-warnings", "--dump-single-json", "--skip-download", "--format", format, liveURL)
	stdout, _ := os.Create(stdoutFile)
	stderr, _ := os.Create(stderrFile)
	cmd.Stdout = stdout
	cmd.Stderr = stderr
	err = cmd.Run()
	stdout.Close()
	stderr.Close()

	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.Sys().(syscall.WaitStatus).ExitStatus()
		} else {
			exitCode = 1
		}
	} else {
		exitCode = 0
	}

	if exitCode != 0 {
		status := "technical_error"
		code := 2
		errorMsg := readFirst1000Chars(stderrFile)
		if strings.Contains(strings.ToLower(errorMsg), "not currently live") ||
			strings.Contains(strings.ToLower(errorMsg), "no live cdn found") ||
			strings.Contains(strings.ToLower(errorMsg), "not available") ||
			strings.Contains(strings.ToLower(errorMsg), "private video") {
			status = "offline"
			code = 1
		}
		emitJSON(false, "yt-dlp", username, "", format, errorMsg, timestamp, status)
		os.Exit(code)
	}

	url := extractVideoURL(stdoutFile)
	if url == "" {
		emitJSON(false, "yt-dlp", username, "", format, "could not extract HTTPS video URL", timestamp, "offline")
		os.Exit(1)
	}

	if jsonFlag == "--json" {
		emitJSON(true, "yt-dlp", username, url, format, "", timestamp, "live")
	} else {
		fmt.Println(url)
	}
}

func emitJSON(success bool, method string, username string, url string, format string, error string, timestamp string, status string) {
	payload := make(map[string]interface{})
	if success {
		payload["success"] = success
	}
	if method != "" {
		payload["method"] = method
	}
	if username != "" {
		payload["username"] = username
	}
	if url != "" {
		payload["url"] = url
	}
	if format != "" {
		payload["format"] = format
	}
	if error != "" {
		payload["error"] = error
	}
	if timestamp != "" {
		payload["timestamp"] = timestamp
	}
	if status != "" {
		payload["status"] = status
	}
	jsonData, _ := json.Marshal(payload)
	fmt.Fprintln(os.Stderr, string(jsonData))
}

func getLoadPerCPU() float64 {
	// Approximation of load average per CPU using runtime.NumCPU()
	// This is a simplified approach since Go doesn't expose load averages directly
	// In practice, you might want to read from /proc/loadavg on Linux
	// For cross-platform compatibility, we'll return a fixed value or use a stub
	// Here we simulate reading load average
	loadAvg := getLoadAverage()
	cpuCount := float64(runtime.NumCPU())
	if cpuCount == 0 {
		cpuCount = 1
	}
	return loadAvg / cpuCount
}

func getLoadAverage() float64 {
	// On Unix systems, read from /proc/loadavg
	data, err := os.ReadFile("/proc/loadavg")
	if err != nil {
		return 0.0 // fallback
	}
	fields := strings.Fields(string(data))
	if len(fields) < 1 {
		return 0.0
	}
	load, err := strconv.ParseFloat(fields[0], 64)
	if err != nil {
		return 0.0
	}
	return load
}

func readFirst1000Chars(filename string) string {
	file, err := os.Open(filename)
	if err != nil {
		return ""
	}
	defer file.Close()
	reader := bufio.NewReader(file)
	buf := make([]byte, 1000)
	n, _ := reader.Read(buf)
	return string(buf[:n])
}

func extractVideoURL(filename string) string {
	file, err := os.Open(filename)
	if err != nil {
		return ""
	}
	defer file.Close()

	var data map[string]interface{}
	decoder := json.NewDecoder(file)
	if err := decoder.Decode(&data); err != nil {
		return ""
	}

	var candidates []string
	if url, ok := data["url"].(string); ok {
		candidates = append(candidates, url)
	}
	if formats, ok := data["formats"].([]interface{}); ok {
		for _, item := range formats {
			if formatMap, ok := item.(map[string]interface{}); ok {
				if url, ok := formatMap["url"].(string); ok {
					candidates = append(candidates, url)
				}
			}
		}
	}

	for _, value := range candidates {
		low := strings.ToLower(value)
		if strings.HasPrefix(value, "https://") && (strings.Contains(low, ".m3u8") || strings.Contains(low, ".flv")) && !strings.Contains(low, "only_audio=1") {
			return value
		}
	}
	return ""
}
