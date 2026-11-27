// abstraction-provenance: {"artifact_sha256": "ddf5fabb707fb5808ed2c6fb5e8b1a9d9bf40632833d08fe0d86d3c35c75b801", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "go"}
// status-overview.css — portiert nach go
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]
	
	// Create the CSS content programmatically
	css := generateCSS()
	
	// Write to file
	err := os.WriteFile(filename, []byte(css), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
		os.Exit(1)
	}
}

func generateCSS() string {
	var css string
	
	// Universal selector and base styles
	css += "*{box-sizing:border-box}"
	css += "html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}"
	
	// Body layout
	css += "body{display:flex;flex-direction:column;height:100vh}"
	
	// Header styles
	css += "header{display:flex;gap:1em;align-items:baseline;padding:0 12px}"
	css += "h1{font-size:17px;margin:8px 0}"
	css += "header p{font-size:12px;color:#bbb;margin:0}"
	
	// Main grid layout
	css += "main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}"
	
	// Tile styles
	css += ".tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}"
	css += ".tile h2{font-size:13px;margin:3px 8px}"
	css += ".tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}"
	css += ".tile p{font-size:11px;margin:3px 8px;color:#ddd}"
	
	// Grid variation
	css += "main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}"
	
	// Hidden elements
	css += ".tile[hidden]{display:none}"
	
	return css
}
