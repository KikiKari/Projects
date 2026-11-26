// abstraction-provenance: {"artifact_sha256": "30b951260e432eb61de532eafceb1aa4f1f43a137707c936a70370f3ff16d8fa", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "go"}
// index.html — portiert nach go
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"os"
	"path/filepath"
)

func main() {
	// Standardmäßig auf stdout ausgeben
	output := os.Stdout
	
	// Falls ein Argument übergeben wurde, in Datei schreiben
	if len(os.Args) > 1 {
		file, err := os.Create(filepath.Clean(os.Args[1]))
		if err != nil {
			fmt.Fprintf(os.Stderr, "Fehler beim Erstellen der Datei: %v\n", err)
			os.Exit(1)
		}
		defer file.Close()
		output = file
	}

	// HTML-Dokument generieren
	fmt.Fprintln(output, "<!DOCTYPE html>")
	fmt.Fprintln(output, "<html lang=\"de\">")
	fmt.Fprintln(output, "<head>")
	fmt.Fprintln(output, "<meta charset=\"utf-8\">")
	fmt.Fprintln(output, "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">")
	fmt.Fprintln(output, "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">")
	fmt.Fprintln(output, "<title>Weiterleitung zur 3D-Ansicht</title>")
	fmt.Fprintln(output, "<link rel=\"canonical\" href=\"3d.html\">")
	fmt.Fprintln(output, "<script>location.replace('3d.html');</script>")
	fmt.Fprintln(output, "</head>")
	fmt.Fprintln(output, "<body>")
	fmt.Fprintln(output, "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>")
	fmt.Fprintln(output, "</body>")
	fmt.Fprintln(output, "</html>")
}
