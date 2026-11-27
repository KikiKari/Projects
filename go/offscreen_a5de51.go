// abstraction-provenance: {"artifact_sha256": "d90235a542d288b6d6407a9391c21a321a8e6f45bcc42bf32f500ce0310bbb01", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "go"}
// offscreen.html — portiert nach go
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"flag"
	"fmt"
	"html/template"
	"os"
)

func main() {
	// Define command line flag for output file
	outputFile := flag.String("output", "", "Output file path")
	flag.Parse()

	// Check if output file is provided
	if *outputFile == "" {
		fmt.Println("Error: Output file path is required")
		fmt.Println("Usage: program -output <file_path>")
		os.Exit(1)
	}

	// Define the HTML template
	const htmlTemplate = `<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <title>TikTok LIVE Companion Sprachausgabe</title>
</head>
<body>
  <script src="offscreen.js"></script>
</body>
</html>`

	// Parse the template
	tmpl, err := template.New("offscreen").Parse(htmlTemplate)
	if err != nil {
		fmt.Printf("Error parsing template: %v\n", err)
		os.Exit(1)
	}

	// Create output file
	file, err := os.Create(*outputFile)
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Execute template and write to file
	err = tmpl.Execute(file, nil)
	if err != nil {
		fmt.Printf("Error executing template: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("HTML file created successfully: %s\n", *outputFile)
}
