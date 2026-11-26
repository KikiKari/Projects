// abstraction-provenance: {"artifact_sha256": "0177815aa7246f5795819dfd109362909c1a79e82ed73bc4528a16fd3beb2f3f", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "go"}
// frame.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

func usage() {
	fmt.Fprintln(os.Stderr, `Usage:
  frame.go <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.go video.mp4 --out /tmp/frame.jpg
  frame.go video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.go video.mp4 --index 0 --out /tmp/frame0.png`)
	os.Exit(2)
}

func main() {
	if len(os.Args) < 2 || os.Args[1] == "-h" || os.Args[1] == "--help" {
		usage()
	}

	in := os.Args[1]
	args := os.Args[2:]

	time := ""
	index := ""
	out := ""

	i := 0
	for i < len(args) {
		switch args[i] {
		case "--time":
			if i+1 >= len(args) {
				fmt.Fprintln(os.Stderr, "Missing value for --time")
				usage()
			}
			time = args[i+1]
			i += 2
		case "--index":
			if i+1 >= len(args) {
				fmt.Fprintln(os.Stderr, "Missing value for --index")
				usage()
			}
			index = args[i+1]
			i += 2
		case "--out":
			if i+1 >= len(args) {
				fmt.Fprintln(os.Stderr, "Missing value for --out")
				usage()
			}
			out = args[i+1]
			i += 2
		default:
			fmt.Fprintf(os.Stderr, "Unknown arg: %s\n", args[i])
			usage()
		}
	}

	if _, err := os.Stat(in); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "File not found: %s\n", in)
		os.Exit(1)
	}

	if out == "" {
		fmt.Fprintln(os.Stderr, "Missing --out")
		usage()
	}

	// Create output directory
	dir := filepath.Dir(out)
	if err := os.MkdirAll(dir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Failed to create directory: %s\n", err)
		os.Exit(1)
	}

	var cmd *exec.Cmd
	if index != "" {
		cmd = exec.Command("ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
			"-i", in,
			"-vf", fmt.Sprintf("select=eq(n\\,%s)", index),
			"-vframes", "1",
			out)
	} else if time != "" {
		cmd = exec.Command("ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
			"-ss", time,
			"-i", in,
			"-frames:v", "1",
			out)
	} else {
		cmd = exec.Command("ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
			"-i", in,
			"-vf", "select=eq(n\\,0)",
			"-vframes", "1",
			out)
	}

	// Capture stderr for logging purposes
	output, err := cmd.CombinedOutput()
	if err != nil {
		if len(output) > 0 {
			// Print ffmpeg output if there was an error
			fmt.Fprint(os.Stderr, string(output))
		}
		os.Exit(1)
	}

	fmt.Println(out)
}
