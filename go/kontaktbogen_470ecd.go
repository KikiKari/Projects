// abstraction-provenance: {"artifact_sha256": "c16d53a05c4cb68ceb3722fa9d26b580627766c97bd1945ecc3a2fd5d09b05ea", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "go"}
// kontaktbogen.css — portiert nach go
// Quelle: css, Projects@abstractions:css/kontaktbogen.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]
	
	css := generateCSS()
	
	err := os.WriteFile(filename, []byte(css), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
		os.Exit(1)
	}
}

func generateCSS() string {
	var builder strings.Builder
	
	builder.WriteString("/* abstraction-provenance: {\"artifact_sha256\": \"450641e159859fa2b6c4bef0c3cf3d2fc42700f880b018b48996ee2e02d23ab2\", \"source_sha256\": \"ca574d779b67b58a38559123215e116d8c6e2ef4c122350bb69958e8a6423187\", \"target_language\": \"css\"} */\n")
	builder.WriteString("/* kontaktbogen.html — portiert nach css */\n")
	builder.WriteString("/* Quelle: html, Onboarding@main:development/contactsheets/v1/kontaktbogen.html */\n")
	builder.WriteString("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n")
	
	builder.WriteString(":root {\n")
	builder.WriteString("  --bg: #FAF8F4;\n")
	builder.WriteString("  --ink: #1B1A17;\n")
	builder.WriteString("  --muted: #6E6A61;\n")
	builder.WriteString("  --line: #E5E1D8;\n")
	builder.WriteString("  --accent: #A8542F;\n")
	builder.WriteString("  --accent-2: #2E7D7B;\n")
	builder.WriteString("  --surface: #fff;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("* {\n")
	builder.WriteString("  box-sizing: border-box;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("body {\n")
	builder.WriteString("  margin: 0;\n")
	builder.WriteString("  font-family: 'Hanken Grotesk', system-ui, sans-serif;\n")
	builder.WriteString("  background: var(--bg);\n")
	builder.WriteString("  color: var(--ink);\n")
	builder.WriteString("  line-height: 1.5;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("header {\n")
	builder.WriteString("  padding: 2.5rem 2rem 1rem;\n")
	builder.WriteString("  border-bottom: 1px solid var(--line);\n")
	builder.WriteString("  background: var(--surface);\n")
	builder.WriteString("  position: sticky;\n")
	builder.WriteString("  top: 0;\n")
	builder.WriteString("  z-index: 10;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("header h1 {\n")
	builder.WriteString("  margin: 0 0 .5rem;\n")
	builder.WriteString("  font-family: 'Newsreader', Georgia, serif;\n")
	builder.WriteString("  font-weight: 400;\n")
	builder.WriteString("  font-size: 2.25rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("header p {\n")
	builder.WriteString("  margin: .25rem 0;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  max-width: 80ch;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".legend {\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  gap: 1rem;\n")
	builder.WriteString("  flex-wrap: wrap;\n")
	builder.WriteString("  margin-top: .75rem;\n")
	builder.WriteString("  font-size: .8125rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".pill {\n")
	builder.WriteString("  padding: .15rem .6rem;\n")
	builder.WriteString("  border-radius: 999px;\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("  background: #fff;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".pill.pflicht {\n")
	builder.WriteString("  border-color: var(--accent);\n")
	builder.WriteString("  color: var(--accent);\n")
	builder.WriteString("  font-weight: 600;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".pill.auswahl {\n")
	builder.WriteString("  border-color: var(--accent-2);\n")
	builder.WriteString("  color: var(--accent-2);\n")
	builder.WriteString("  font-weight: 600;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("main {\n")
	builder.WriteString("  padding: 2rem;\n")
	builder.WriteString("  max-width: 1400px;\n")
	builder.WriteString("  margin: 0 auto;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("section {\n")
	builder.WriteString("  margin: 2.5rem 0;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("section h2 {\n")
	builder.WriteString("  font-family: 'Newsreader', serif;\n")
	builder.WriteString("  font-weight: 400;\n")
	builder.WriteString("  font-size: 1.5rem;\n")
	builder.WriteString("  margin: 0 0 .25rem;\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  align-items: center;\n")
	builder.WriteString("  gap: .75rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("section .sub {\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  font-size: .875rem;\n")
	builder.WriteString("  margin: 0 0 1.25rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".grid {\n")
	builder.WriteString("  display: grid;\n")
	builder.WriteString("  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));\n")
	builder.WriteString("  gap: 1rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card {\n")
	builder.WriteString("  background: var(--surface);\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("  border-radius: 10px;\n")
	builder.WriteString("  overflow: hidden;\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  flex-direction: column;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card .imgwrap {\n")
	builder.WriteString("  aspect-ratio: 1;\n")
	builder.WriteString("  background: #f1eee7;\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  align-items: center;\n")
	builder.WriteString("  justify-content: center;\n")
	builder.WriteString("  overflow: hidden;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card img {\n")
	builder.WriteString("  width: 100%;\n")
	builder.WriteString("  height: 100%;\n")
	builder.WriteString("  object-fit: contain;\n")
	builder.WriteString("  background: #fff;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card .meta {\n")
	builder.WriteString("  padding: .6rem .75rem .75rem;\n")
	builder.WriteString("  font-size: .78125rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card .name {\n")
	builder.WriteString("  font-family: 'JetBrains Mono', monospace;\n")
	builder.WriteString("  font-size: .6875rem;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  word-break: break-all;\n")
	builder.WriteString("  line-height: 1.3;\n")
	builder.WriteString("  margin-bottom: .35rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card .dims {\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  font-size: .6875rem;\n")
	builder.WriteString("  margin-bottom: .35rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".card .prompt {\n")
	builder.WriteString("  color: var(--ink);\n")
	builder.WriteString("  font-size: .75rem;\n")
	builder.WriteString("  line-height: 1.35;\n")
	builder.WriteString("  font-style: italic;\n")
	builder.WriteString("  border-top: 1px solid var(--line);\n")
	builder.WriteString("  padding-top: .4rem;\n")
	builder.WriteString("  margin-top: .35rem;\n")
	builder.WriteString("  max-height: 5.5em;\n")
	builder.WriteString("  overflow: hidden;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".tag {\n")
	builder.WriteString("  display: inline-block;\n")
	builder.WriteString("  padding: .1rem .45rem;\n")
	builder.WriteString("  border-radius: 999px;\n")
	builder.WriteString("  font-size: .6875rem;\n")
	builder.WriteString("  background: #F1EEE7;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  margin-right: .25rem;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".tag.p {\n")
	builder.WriteString("  background: #F1E5DD;\n")
	builder.WriteString("  color: var(--accent);\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString(".tag.a {\n")
	builder.WriteString("  background: #DEEDEC;\n")
	builder.WriteString("  color: var(--accent-2);\n")
	builder.WriteString("}\n")
	
	return builder.String()
}
