// abstraction-provenance: {"artifact_sha256": "d62fc5f3437c2e8d9f37eb12aa8328ddba887b04d419bc6a770702631cab5efc", "source_sha256": "cbb5bc6a6daaf8b0fa22ba63f44d741131d32c58a9faab7d6cda9954587b0052", "target_language": "go"}
// index_58ad28.css — portiert nach go
// Quelle: css, Projects@abstractions:css/index_58ad28.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


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
	content := generateCSS()

	if err := os.WriteFile(filename, []byte(content), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing file: %v\n", err)
		os.Exit(1)
	}
}

func generateCSS() string {
	var builder strings.Builder

	// Root variables for light theme
	builder.WriteString(":root {\n")
	builder.WriteString("  --bg: #ffffff;\n")
	builder.WriteString("  --soft: #f6f7f9;\n")
	builder.WriteString("  --line: #e3e6ea;\n")
	builder.WriteString("  --text: #16191d;\n")
	builder.WriteString("  --muted: #5f6773;\n")
	builder.WriteString("  --tg: #2481cc;\n")
	builder.WriteString("  --tg-soft: #e8f2fb;\n")
	builder.WriteString("  --tt: #fe2c55;\n")
	builder.WriteString("  --ok: #15803d;\n")
	builder.WriteString("  --ok-soft: #e7f6ec;\n")
	builder.WriteString("  --warn: #b45309;\n")
	builder.WriteString("  --warn-soft: #fdf3e3;\n")
	builder.WriteString("  color-scheme: light;\n")
	builder.WriteString("}\n\n")

	// Dark theme media query
	builder.WriteString("@media (prefers-color-scheme: dark) {\n")
	builder.WriteString("  :root {\n")
	builder.WriteString("    --bg: #0f1115;\n")
	builder.WriteString("    --soft: #171a21;\n")
	builder.WriteString("    --line: #262b36;\n")
	builder.WriteString("    --text: #f2f4f8;\n")
	builder.WriteString("    --muted: #9aa3b2;\n")
	builder.WriteString("    --tg-soft: #132a3d;\n")
	builder.WriteString("    --ok-soft: #12261a;\n")
	builder.WriteString("    --warn-soft: #2c2110;\n")
	builder.WriteString("    color-scheme: dark;\n")
	builder.WriteString("  }\n")
	builder.WriteString("}\n\n")

	// Universal selector
	builder.WriteString("* {\n")
	builder.WriteString("  box-sizing: border-box;\n")
	builder.WriteString("}\n\n")

	// Body styles
	builder.WriteString("body {\n")
	builder.WriteString("  margin: 0;\n")
	builder.WriteString("  background: var(--bg);\n")
	builder.WriteString("  color: var(--text);\n")
	builder.WriteString("  font: 16px/1.6 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n")
	builder.WriteString("}\n\n")

	// Wrap class
	builder.WriteString(".wrap {\n")
	builder.WriteString("  max-width: 820px;\n")
	builder.WriteString("  margin: 0 auto;\n")
	builder.WriteString("  padding: 0 20px 72px;\n")
	builder.WriteString("}\n\n")

	// Header styles
	builder.WriteString("header {\n")
	builder.WriteString("  padding: 64px 0 40px;\n")
	builder.WriteString("  border-bottom: 1px solid var(--line);\n")
	builder.WriteString("  margin-bottom: 8px;\n")
	builder.WriteString("}\n\n")

	// Heading 1
	builder.WriteString("h1 {\n")
	builder.WriteString("  font-size: 34px;\n")
	builder.WriteString("  line-height: 1.2;\n")
	builder.WriteString("  margin: 0 0 12px;\n")
	builder.WriteString("  letter-spacing: -0.02em;\n")
	builder.WriteString("}\n\n")

	// Lede paragraph
	builder.WriteString(".lede {\n")
	builder.WriteString("  font-size: 18px;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  margin: 0 0 22px;\n")
	builder.WriteString("  max-width: 60ch;\n")
	builder.WriteString("}\n\n")

	// Heading 2
	builder.WriteString("h2 {\n")
	builder.WriteString("  font-size: 13px;\n")
	builder.WriteString("  margin: 44px 0 14px;\n")
	builder.WriteString("  text-transform: uppercase;\n")
	builder.WriteString("  letter-spacing: 0.06em;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  font-weight: 650;\n")
	builder.WriteString("}\n\n")

	// Heading 3
	builder.WriteString("h3 {\n")
	builder.WriteString("  font-size: 17px;\n")
	builder.WriteString("  margin: 26px 0 6px;\n")
	builder.WriteString("}\n\n")

	// Paragraph
	builder.WriteString("p {\n")
	builder.WriteString("  margin: 0 0 14px;\n")
	builder.WriteString("  max-width: 68ch;\n")
	builder.WriteString("}\n\n")

	// Badges container
	builder.WriteString(".badges {\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  gap: 7px;\n")
	builder.WriteString("  flex-wrap: wrap;\n")
	builder.WriteString("  margin-bottom: 22px;\n")
	builder.WriteString("}\n\n")

	// Badge style
	builder.WriteString(".badge {\n")
	builder.WriteString("  font-size: 12px;\n")
	builder.WriteString("  font-weight: 650;\n")
	builder.WriteString("  padding: 4px 11px;\n")
	builder.WriteString("  border-radius: 99px;\n")
	builder.WriteString("  background: var(--soft);\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("}\n\n")

	// Active badge
	builder.WriteString(".badge.on {\n")
	builder.WriteString("  background: var(--ok-soft);\n")
	builder.WriteString("  color: var(--ok);\n")
	builder.WriteString("  border-color: transparent;\n")
	builder.WriteString("}\n\n")

	// Call to action container
	builder.WriteString(".cta {\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  gap: 10px;\n")
	builder.WriteString("  flex-wrap: wrap;\n")
	builder.WriteString("}\n\n")

	// Button style
	builder.WriteString(".btn {\n")
	builder.WriteString("  display: inline-block;\n")
	builder.WriteString("  font-weight: 650;\n")
	builder.WriteString("  font-size: 15px;\n")
	builder.WriteString("  padding: 11px 20px;\n")
	builder.WriteString("  border-radius: 9px;\n")
	builder.WriteString("  text-decoration: none;\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("  background: var(--bg);\n")
	builder.WriteString("  color: var(--text);\n")
	builder.WriteString("}\n\n")

	// Primary button
	builder.WriteString(".btn.primary {\n")
	builder.WriteString("  background: var(--tg);\n")
	builder.WriteString("  border-color: var(--tg);\n")
	builder.WriteString("  color: #fff;\n")
	builder.WriteString("}\n\n")

	// Button hover state
	builder.WriteString(".btn:hover {\n")
	builder.WriteString("  border-color: var(--tg);\n")
	builder.WriteString("}\n\n")

	// Grid layout
	builder.WriteString(".grid {\n")
	builder.WriteString("  display: grid;\n")
	builder.WriteString("  grid-template-columns: repeat(auto-fit, minmax(230px, 1fr));\n")
	builder.WriteString("  gap: 14px;\n")
	builder.WriteString("}\n\n")

	// Card component
	builder.WriteString(".card {\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("  border-radius: 12px;\n")
	builder.WriteString("  padding: 16px 18px;\n")
	builder.WriteString("  background: var(--bg);\n")
	builder.WriteString("}\n\n")

	// Card heading
	builder.WriteString(".card h3 {\n")
	builder.WriteString("  margin-top: 0;\n")
	builder.WriteString("  font-size: 15.5px;\n")
	builder.WriteString("}\n\n")

	// Card paragraph
	builder.WriteString(".card p {\n")
	builder.WriteString("  font-size: 14px;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  margin: 0;\n")
	builder.WriteString("}\n\n")

	// Steps ordered list
	builder.WriteString("ol.steps {\n")
	builder.WriteString("  list-style: none;\n")
	builder.WriteString("  counter-reset: s;\n")
	builder.WriteString("  padding: 0;\n")
	builder.WriteString("  margin: 0;\n")
	builder.WriteString("}\n\n")

	// Step list items
	builder.WriteString("ol.steps li {\n")
	builder.WriteString("  counter-increment: s;\n")
	builder.WriteString("  position: relative;\n")
	builder.WriteString("  padding: 0 0 20px 40px;\n")
	builder.WriteString("  border-left: 2px solid var(--line);\n")
	builder.WriteString("  margin-left: 11px;\n")
	builder.WriteString("}\n\n")

	// Last step item
	builder.WriteString("ol.steps li:last-child {\n")
	builder.WriteString("  border-left-color: transparent;\n")
	builder.WriteString("  padding-bottom: 0;\n")
	builder.WriteString("}\n\n")

	// Step numbers
	builder.WriteString("ol.steps li::before {\n")
	builder.WriteString("  content: counter(s);\n")
	builder.WriteString("  position: absolute;\n")
	builder.WriteString("  left: -13px;\n")
	builder.WriteString("  top: 0;\n")
	builder.WriteString("  width: 24px;\n")
	builder.WriteString("  height: 24px;\n")
	builder.WriteString("  border-radius: 50%;\n")
	builder.WriteString("  background: var(--tg);\n")
	builder.WriteString("  color: #fff;\n")
	builder.WriteString("  display: flex;\n")
	builder.WriteString("  align-items: center;\n")
	builder.WriteString("  justify-content: center;\n")
	builder.WriteString("  font-size: 12px;\n")
	builder.WriteString("  font-weight: 700;\n")
	builder.WriteString("}\n\n")

	// Step bold text
	builder.WriteString("ol.steps b {\n")
	builder.WriteString("  display: block;\n")
	builder.WriteString("  margin-bottom: 3px;\n")
	builder.WriteString("}\n\n")

	// Step paragraphs
	builder.WriteString("ol.steps p {\n")
	builder.WriteString("  font-size: 14.5px;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  margin: 0 0 8px;\n")
	builder.WriteString("}\n\n")

	// Inline code
	builder.WriteString("code {\n")
	builder.WriteString("  background: var(--soft);\n")
	builder.WriteString("  padding: 2px 7px;\n")
	builder.WriteString("  border-radius: 5px;\n")
	builder.WriteString("  font-size: 13.5px;\n")
	builder.WriteString("  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;\n")
	builder.WriteString("  word-break: break-word;\n")
	builder.WriteString("}\n\n")

	// Code blocks
	builder.WriteString("pre {\n")
	builder.WriteString("  background: var(--soft);\n")
	builder.WriteString("  border: 1px solid var(--line);\n")
	builder.WriteString("  border-radius: 10px;\n")
	builder.WriteString("  padding: 13px 15px;\n")
	builder.WriteString("  overflow-x: auto;\n")
	builder.WriteString("  margin: 0 0 14px;\n")
	builder.WriteString("}\n\n")

	// Code in pre blocks
	builder.WriteString("pre code {\n")
	builder.WriteString("  background: none;\n")
	builder.WriteString("  padding: 0;\n")
	builder.WriteString("  font-size: 13.5px;\n")
	builder.WriteString("  line-height: 1.7;\n")
	builder.WriteString("}\n\n")

	// Tables
	builder.WriteString("table {\n")
	builder.WriteString("  width: 100%;\n")
	builder.WriteString("  border-collapse: collapse;\n")
	builder.WriteString("  font-size: 14.5px;\n")
	builder.WriteString("  margin: 0 0 16px;\n")
	builder.WriteString("}\n\n")

	// Table headers and cells
	builder.WriteString("th,\n")
	builder.WriteString("td {\n")
	builder.WriteString("  text-align: left;\n")
	builder.WriteString("  padding: 9px 11px;\n")
	builder.WriteString("  border-bottom: 1px solid var(--line);\n")
	builder.WriteString("  vertical-align: top;\n")
	builder.WriteString("}\n\n")

	// Table headers
	builder.WriteString("th {\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("  font-size: 12px;\n")
	builder.WriteString("  text-transform: uppercase;\n")
	builder.WriteString("  letter-spacing: 0.04em;\n")
	builder.WriteString("  font-weight: 650;\n")
	builder.WriteString("}\n\n")

	// Note boxes
	builder.WriteString(".note {\n")
	builder.WriteString("  border-left: 3px solid var(--warn);\n")
	builder.WriteString("  background: var(--warn-soft);\n")
	builder.WriteString("  border-radius: 0 9px 9px 0;\n")
	builder.WriteString("  padding: 13px 16px;\n")
	builder.WriteString("  margin: 0 0 16px;\n")
	builder.WriteString("  font-size: 14.5px;\n")
	builder.WriteString("}\n\n")

	// Note bold text
	builder.WriteString(".note b {\n")
	builder.WriteString("  display: block;\n")
	builder.WriteString("  margin-bottom: 3px;\n")
	builder.WriteString("}\n\n")

	// Links
	builder.WriteString("a {\n")
	builder.WriteString("  color: var(--tg);\n")
	builder.WriteString("}\n\n")

	// Footer
	builder.WriteString("footer {\n")
	builder.WriteString("  margin-top: 52px;\n")
	builder.WriteString("  padding-top: 22px;\n")
	builder.WriteString("  border-top: 1px solid var(--line);\n")
	builder.WriteString("  font-size: 13.5px;\n")
	builder.WriteString("  color: var(--muted);\n")
	builder.WriteString("}\n")

	return builder.String()
}
