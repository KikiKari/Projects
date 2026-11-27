// abstraction-provenance: {"artifact_sha256": "9136d22148110e4c8c4e71a8161435925dc1032eb7e05200751c06ae4b78356a", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "go"}
// offscreen.html — portiert nach go
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

// OffscreenHTML represents the structure of the HTML document
type OffscreenHTML struct {
	Charset string
	Title   string
	Script  string
}

func main() {
	// Check if filename argument is provided
	if len(os.Args) < 2 {
		fmt.Println("Usage: program <filename>")
		os.Exit(1)
	}

	filename := os.Args[1]

	// Define the data for the template
	data := OffscreenHTML{
		Charset: "utf-8",
		Title:   "TikTok LIVE Companion Sprachausgabe",
		Script:  "offscreen.js",
	}

	// Define the HTML template
	htmlTemplate := `<!doctype html>
<html lang="de">
<head>
  <meta charset="{{.Charset}}">
  <title>{{.Title}}</title>
</head>
<body>
  <script src="{{.Script}}"></script>
</body>
</html>`

	// Parse the template
	tmpl, err := template.New("offscreen").Parse(htmlTemplate)
	if err != nil {
		fmt.Printf("Error parsing template: %v\n", err)
		os.Exit(1)
	}

	// Create output file
	file, err := os.Create(filename)
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Execute template and write to file
	err = tmpl.Execute(file, data)
	if err != nil {
		fmt.Printf("Error executing template: %v\n", err)
		os.Exit(1)
	}
}
