// abstraction-provenance: {"artifact_sha256": "48c710377910b7dd5066dc1effa12f1b6bc2bee3870e529efbd0c2259af7b4b1", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "go"}
// index.html — portiert nach go
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

type MetaData struct {
	Charset     string
	Viewport    string
	Description string
	ThemeColor  string
	Favicon     string
	AppleIcon   string
	Title       string
}

type PageData struct {
	Lang string
	Meta MetaData
	Body struct {
		RootDiv    string
		ScriptSrc  string
		ScriptType string
	}
}

const htmlTemplate = `<!doctype html>
<html lang="{{.Lang}}">
  <head>
    <meta charset="{{.Meta.Charset}}" />
    <meta name="viewport" content="{{.Meta.Viewport}}" />
    <meta name="description" content="{{.Meta.Description}}" />
    <meta name="theme-color" content="{{.Meta.ThemeColor}}" />
    <link rel="icon" type="image/png" href="{{.Meta.Favicon}}" />
    <link rel="apple-touch-icon" href="{{.Meta.AppleIcon}}" />
    <title>{{.Meta.Title}}</title>
  </head>
  <body>
    <div id="{{.Body.RootDiv}}"></div>
    <script type="{{.Body.ScriptType}}" src="{{.Body.ScriptSrc}}"></script>
  </body>
</html>`

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: program <output-file>")
		os.Exit(1)
	}

	filename := os.Args[1]

	data := PageData{
		Lang: "de",
		Meta: MetaData{
			Charset:     "UTF-8",
			Viewport:    "width=device-width, initial-scale=1.0",
			Description: "Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.",
			ThemeColor:  "#ffffff",
			Favicon:     "/branding/staenderglobus-ios.png",
			AppleIcon:   "/branding/staenderglobus-ios.png",
			Title:       "TikTok LIVE Companion – Dokumentation",
		},
		Body: struct {
			RootDiv    string
			ScriptSrc  string
			ScriptType string
		}{
			RootDiv:    "root",
			ScriptSrc:  "/src/main.tsx",
			ScriptType: "module",
		},
	}

	tmpl, err := template.New("index").Parse(htmlTemplate)
	if err != nil {
		fmt.Printf("Error parsing template: %v\n", err)
		os.Exit(1)
	}

	file, err := os.Create(filename)
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	err = tmpl.Execute(file, data)
	if err != nil {
		fmt.Printf("Error executing template: %v\n", err)
		os.Exit(1)
	}
}
