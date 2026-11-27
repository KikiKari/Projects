// abstraction-provenance: {"artifact_sha256": "250f8d93dd210d2f6340b3f75c3105634f85697a4f2597a3048c0d6a09652a01", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "go"}
// index.html — portiert nach go
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

const htmlTemplate = `<!doctype html>
<html lang="de">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content="Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser." />
    <meta name="theme-color" content="#ffffff" />
    <link rel="icon" type="image/png" href="/branding/staenderglobus-ios.png" />
    <link rel="apple-touch-icon" href="/branding/staenderglobus-ios.png" />
    <title>TikTok LIVE Companion – Dokumentation</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>`

func main() {
	var filename string
	if len(os.Args) > 1 {
		filename = os.Args[1]
	} else {
		filename = "index.html"
	}

	tmpl, err := template.New("html").Parse(htmlTemplate)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Parsen des Templates: %v\n", err)
		os.Exit(1)
	}

	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Erstellen der Datei %s: %v\n", filename, err)
		os.Exit(1)
	}
	defer file.Close()

	err = tmpl.Execute(file, nil)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Fehler beim Schreiben in die Datei: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("HTML-Datei wurde erfolgreich erstellt: %s\n", filename)
}
