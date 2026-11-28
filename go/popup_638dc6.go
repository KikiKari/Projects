// abstraction-provenance: {"artifact_sha256": "d808267554a7f1b472be7d91860e4292bababdf7aa1acf1cb55004a540c1547e", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "go"}
// popup.css — portiert nach go
// Quelle: css, Projects@abstractions:css/popup.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"flag"
	"fmt"
	"os"
	"strings"
)

func main() {
	output := flag.String("output", "", "Output file path")
	flag.Parse()

	if *output == "" {
		fmt.Println("Usage: program --output <file>")
		os.Exit(1)
	}

	css := generateCSS()
	
	err := os.WriteFile(*output, []byte(css), 0644)
	if err != nil {
		fmt.Printf("Error writing file: %v\n", err)
		os.Exit(1)
	}
}

func generateCSS() string {
	var sb strings.Builder
	
	sb.WriteString("/* abstraction-provenance: {\"artifact_sha256\": \"9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9\", \"source_sha256\": \"460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94\", \"target_language\": \"css\"} */\n")
	sb.WriteString("/* popup.html — portiert nach css */\n")
	sb.WriteString("/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */\n")
	sb.WriteString("/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n")
	
	sb.WriteString(":root {\n")
	sb.WriteString("  --bg: #0f1115;\n")
	sb.WriteString("  --card: #171a21;\n")
	sb.WriteString("  --line: #262b36;\n")
	sb.WriteString("  --text: #f2f4f8;\n")
	sb.WriteString("  --muted: #9aa3b2;\n")
	sb.WriteString("  --accent: #fe2c55;\n")
	sb.WriteString("  --ok: #22c55e;\n")
	sb.WriteString("  color-scheme: dark;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("@media (prefers-color-scheme: light) {\n")
	sb.WriteString("  :root {\n")
	sb.WriteString("    --bg: #fff;\n")
	sb.WriteString("    --card: #f6f7f9;\n")
	sb.WriteString("    --line: #e3e6ea;\n")
	sb.WriteString("    --text: #16191d;\n")
	sb.WriteString("    --muted: #6b7280;\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("* {\n")
	sb.WriteString("  box-sizing: border-box;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("body {\n")
	sb.WriteString("  margin: 0;\n")
	sb.WriteString("  width: 420px;\n")
	sb.WriteString("  max-height: 600px;\n")
	sb.WriteString("  overflow: auto;\n")
	sb.WriteString("  background: var(--bg);\n")
	sb.WriteString("  color: var(--text);\n")
	sb.WriteString("  font: 14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".wrap {\n")
	sb.WriteString("  padding: 12px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("header {\n")
	sb.WriteString("  display: flex;\n")
	sb.WriteString("  gap: 8px;\n")
	sb.WriteString("  align-items: center;\n")
	sb.WriteString("  margin-bottom: 10px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("h1 {\n")
	sb.WriteString("  font-size: 14px;\n")
	sb.WriteString("  margin: 0;\n")
	sb.WriteString("  font-weight: 650;\n")
	sb.WriteString("  flex: 1;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".badge {\n")
	sb.WriteString("  font-size: 11px;\n")
	sb.WriteString("  font-weight: 700;\n")
	sb.WriteString("  padding: 3px 9px;\n")
	sb.WriteString("  border-radius: 99px;\n")
	sb.WriteString("  background: #2a2f3a;\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  display: inline-flex;\n")
	sb.WriteString("  align-items: center;\n")
	sb.WriteString("  gap: 5px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".badge.live {\n")
	sb.WriteString("  background: var(--accent);\n")
	sb.WriteString("  color: #fff;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".badge .dot {\n")
	sb.WriteString("  width: 6px;\n")
	sb.WriteString("  height: 6px;\n")
	sb.WriteString("  border-radius: 50%;\n")
	sb.WriteString("  background: currentColor;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".badge.live .dot {\n")
	sb.WriteString("  animation: pulse 1.6s infinite;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("@keyframes pulse {\n")
	sb.WriteString("  0%, 100% {\n")
	sb.WriteString("    opacity: 1;\n")
	sb.WriteString("  }\n")
	sb.WriteString("  50% {\n")
	sb.WriteString("    opacity: .25;\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".row {\n")
	sb.WriteString("  display: flex;\n")
	sb.WriteString("  gap: 6px;\n")
	sb.WriteString("  flex-wrap: wrap;\n")
	sb.WriteString("  align-items: center;\n")
	sb.WriteString("  margin-bottom: 8px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("input, select, button {\n")
	sb.WriteString("  font: inherit;\n")
	sb.WriteString("  border-radius: 7px;\n")
	sb.WriteString("  border: 1px solid var(--line);\n")
	sb.WriteString("  background: var(--card);\n")
	sb.WriteString("  color: var(--text);\n")
	sb.WriteString("  padding: 6px 9px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("button {\n")
	sb.WriteString("  cursor: pointer;\n")
	sb.WriteString("  font-weight: 600;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("button.primary {\n")
	sb.WriteString("  background: var(--accent);\n")
	sb.WriteString("  border-color: var(--accent);\n")
	sb.WriteString("  color: #fff;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".player {\n")
	sb.WriteString("  position: relative;\n")
	sb.WriteString("  width: 100%;\n")
	sb.WriteString("  aspect-ratio: 9/16;\n")
	sb.WriteString("  max-height: 360px;\n")
	sb.WriteString("  background: #000;\n")
	sb.WriteString("  border-radius: 10px;\n")
	sb.WriteString("  overflow: hidden;\n")
	sb.WriteString("  border: 1px solid var(--line);\n")
	sb.WriteString("  margin: 8px 0;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".player iframe {\n")
	sb.WriteString("  position: absolute;\n")
	sb.WriteString("  inset: 0;\n")
	sb.WriteString("  width: 100%;\n")
	sb.WriteString("  height: 100%;\n")
	sb.WriteString("  border: 0;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".placeholder {\n")
	sb.WriteString("  position: absolute;\n")
	sb.WriteString("  inset: 0;\n")
	sb.WriteString("  display: flex;\n")
	sb.WriteString("  flex-direction: column;\n")
	sb.WriteString("  gap: 6px;\n")
	sb.WriteString("  align-items: center;\n")
	sb.WriteString("  justify-content: center;\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  text-align: center;\n")
	sb.WriteString("  padding: 16px;\n")
	sb.WriteString("  font-size: 13px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".card {\n")
	sb.WriteString("  background: var(--card);\n")
	sb.WriteString("  border: 1px solid var(--line);\n")
	sb.WriteString("  border-radius: 10px;\n")
	sb.WriteString("  padding: 10px 12px;\n")
	sb.WriteString("  margin-bottom: 8px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("h2 {\n")
	sb.WriteString("  font-size: 11px;\n")
	sb.WriteString("  text-transform: uppercase;\n")
	sb.WriteString("  letter-spacing: .05em;\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  margin: 0 0 6px;\n")
	sb.WriteString("  font-weight: 650;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".meta {\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  font-size: 12.5px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".strong {\n")
	sb.WriteString("  color: var(--text);\n")
	sb.WriteString("  font-weight: 600;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".stream {\n")
	sb.WriteString("  display: flex;\n")
	sb.WriteString("  gap: 8px;\n")
	sb.WriteString("  padding: 5px 0;\n")
	sb.WriteString("  border-bottom: 1px solid var(--line);\n")
	sb.WriteString("  font-size: 12.5px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".stream:last-child {\n")
	sb.WriteString("  border-bottom: 0;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".stream .when {\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  white-space: nowrap;\n")
	sb.WriteString("  font-variant-numeric: tabular-nums;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".stream .t {\n")
	sb.WriteString("  flex: 1;\n")
	sb.WriteString("  min-width: 0;\n")
	sb.WriteString("  overflow: hidden;\n")
	sb.WriteString("  text-overflow: ellipsis;\n")
	sb.WriteString("  white-space: nowrap;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".stream.now {\n")
	sb.WriteString("  color: var(--accent);\n")
	sb.WriteString("  font-weight: 650;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".err {\n")
	sb.WriteString("  background: #3a1d22;\n")
	sb.WriteString("  border: 1px solid #5c2a33;\n")
	sb.WriteString("  color: #ffb4c0;\n")
	sb.WriteString("  padding: 8px 10px;\n")
	sb.WriteString("  border-radius: 8px;\n")
	sb.WriteString("  font-size: 12.5px;\n")
	sb.WriteString("  margin-bottom: 8px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("@media (prefers-color-scheme: light) {\n")
	sb.WriteString("  .err {\n")
	sb.WriteString("    background: #fdeceb;\n")
	sb.WriteString("    border-color: #f5c6c2;\n")
	sb.WriteString("    color: #b91c1c;\n")
	sb.WriteString("  }\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString(".note {\n")
	sb.WriteString("  font-size: 11.5px;\n")
	sb.WriteString("  color: var(--muted);\n")
	sb.WriteString("  line-height: 1.4;\n")
	sb.WriteString("  margin-top: 8px;\n")
	sb.WriteString("}\n\n")
	
	sb.WriteString("a {\n")
	sb.WriteString("  color: var(--accent);\n")
	sb.WriteString("}\n")
	
	return sb.String()
}
