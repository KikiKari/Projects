// abstraction-provenance: {"artifact_sha256": "ea961bdeda0684214ed963b51c7fa716230a95f450d98cf36be63e153b0d56ba", "source_sha256": "18d15a289b831c9da96c808e0cc1de4dae7bf3dfc35a804a239a992cd82cde89", "target_language": "go"}
// index_57e3e2.css — portiert nach go
// Quelle: css, Projects@abstractions:css/index_57e3e2.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run generate_css.go <output_file>")
		os.Exit(1)
	}

	outputFile := os.Args[1]
	
	cssTemplate := `/* abstraction-provenance: {"artifact_sha256": "a05439af4536c91ed01734c3151c3870ffe206fc2433d74fe3db29d4666579ca", "source_sha256": "57e3e28b7c96948ea289f7d9401b6d0bf990d118129de570394784d35e23cf4c", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Projects@tagesstatus-live-public:tagesstatus-live-public/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

:root {
  color-scheme: light;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  background: #f7f7f5;
  color: #1d1c1a;
}

.wrap {
  max-width: 880px;
  margin: 0 auto;
  padding: 20px 16px 60px;
}

h1 {
  font-size: 22px;
  margin: 0 0 2px;
}

.sub {
  color: #6b6a66;
  font-size: 13px;
  margin-bottom: 16px;
}

.bar {
  display: flex;
  gap: 10px;
  align-items: center;
  margin-bottom: 16px;
  flex-wrap: wrap;
}

button {
  font-size: 13px;
  font-weight: 600;
  padding: 7px 13px;
  border: 1px solid #d9d8d3;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
}

button:hover {
  background: #f2f1ec;
}

button.primary {
  background: #1d1c1a;
  color: #fff;
  border-color: #1d1c1a;
}

.note {
  background: #fffdf4;
  border: 1px solid #f0e9c8;
  border-radius: 10px;
  padding: 12px 14px;
  font-size: 13px;
  color: #4a4734;
  margin-bottom: 16px;
  line-height: 1.5;
}

.section {
  background: #fff;
  border: 1px solid #e8e7e3;
  border-radius: 12px;
  margin-bottom: 14px;
  overflow: hidden;
}

.section > h2 {
  font-size: 15px;
  margin: 0;
  padding: 13px 16px;
  border-bottom: 1px solid #efeee9;
  display: flex;
  align-items: center;
  gap: 9px;
}

.section > h2 .badge {
  margin-left: auto;
  font-size: 12px;
  font-weight: 600;
  background: #efeee9;
  color: #5a5852;
  padding: 2px 9px;
  border-radius: 20px;
}

.body {
  padding: 8px 16px 14px;
  font-size: 14px;
}

.muted {
  color: #8a8884;
}

.err {
  color: #c0392b;
}

.kv {
  display: flex;
  justify-content: space-between;
  padding: 4px 0;
  border-bottom: 1px solid #f4f3ee;
}

.kv:last-child {
  border: none;
}

.kv .k {
  color: #6b6a66;
}

.kv .v {
  font-weight: 600;
}

a {
  color: #2b5cc4;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

/* settings modal */
.modal {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, .35);
  display: none;
  align-items: flex-start;
  justify-content: center;
  padding: 40px 16px;
  overflow: auto;
}

.modal.open {
  display: flex;
}

.card {
  background: #fff;
  border-radius: 14px;
  max-width: 560px;
  width: 100%;
  padding: 20px;
}

.card h3 {
  margin: 0 0 4px;
  font-size: 17px;
}

.card p.hint {
  margin: 0 0 16px;
  font-size: 12px;
  color: #8a8884;
}

.field {
  margin-bottom: 12px;
}

.field label {
  display: block;
  font-size: 12px;
  font-weight: 600;
  color: #5a5852;
  margin-bottom: 3px;
}

.field input {
  width: 100%;
  font-size: 13px;
  padding: 7px 9px;
  border: 1px solid #d9d8d3;
  border-radius: 7px;
  font-family: ui-monospace, Menlo, monospace;
}

.field .desc {
  font-size: 11px;
  color: #a8a6a1;
  margin-top: 2px;
}

.actions {
  display: flex;
  gap: 10px;
  justify-content: flex-end;
  margin-top: 8px;
}

.warn {
  background: #fdf3f3;
  border: 1px solid #f3d9d9;
  color: #9a3b3b;
  border-radius: 8px;
  padding: 10px 12px;
  font-size: 12px;
  margin-bottom: 14px;
}
`

	tmpl, err := template.New("css").Parse(cssTemplate)
	if err != nil {
		fmt.Printf("Error parsing template: %v\n", err)
		os.Exit(1)
	}

	file, err := os.Create(outputFile)
	if err != nil {
		fmt.Printf("Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	err = tmpl.Execute(file, nil)
	if err != nil {
		fmt.Printf("Error executing template: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("CSS file generated successfully: %s\n", outputFile)
}
