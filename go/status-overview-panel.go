// abstraction-provenance: {"artifact_sha256": "5956eb7ae610c391caa338accca0d9c4ea01d0a7c53e077e1e7c264311f04c96", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "go"}
// status-overview-panel.css — portiert nach go
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
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
	
	// Define CSS rules as structured data
	rules := []struct {
		selector string
		props    map[string]string
	}{
		{
			selector: ".overview-row",
			props: map[string]string{
				"display":              "grid",
				"grid-template-columns": "24px minmax(0,1fr) 11px 22px auto",
				"gap":                  "7px",
				"align-items":          "center",
				"margin":               "6px 0",
			},
		},
		{
			selector: ".overview-row input",
			props: map[string]string{
				"min-width": "0",
				"width":     "100%",
			},
		},
		{
			selector: ".overview-state",
			props: map[string]string{
				"width":         "11px",
				"height":        "11px",
				"border-radius": "50%",
				"background":    "#888",
			},
		},
		{
			selector: ".overview-state.online",
			props: map[string]string{
				"background": "var(--good)",
				"box-shadow": "0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent)",
			},
		},
		{
			selector: ".overview-state.offline",
			props: map[string]string{
				"background": "var(--bad)",
				"box-shadow": "0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent)",
			},
		},
		{
			selector: ".overview-state.checking, .overview-state.error",
			props: map[string]string{
				"background": "var(--warn)",
			},
		},
		{
			selector: ".overview-count",
			props: map[string]string{
				"font-size":              "11px",
				"text-align":             "center",
				"font-variant-numeric":  "tabular-nums",
			},
		},
		{
			selector: ".overview-actions",
			props: map[string]string{
				"display":              "grid",
				"grid-template-columns": "44px repeat(2,minmax(0,1fr))",
				"gap":                  "6px",
				"align-items":          "stretch",
			},
		},
		{
			selector: ".overview-actions button",
			props: map[string]string{
				"min-width":    "0",
				"padding":      "8px 2px",
				"font-size":    "11px",
				"white-space":  "nowrap",
			},
		},
		{
			selector: "#overview-rows",
			props: map[string]string{
				"display":        "flex",
				"flex-direction": "column",
			},
		},
		{
			selector: ".monitor-settings > label:not(.option-row)",
			props: map[string]string{
				"display": "block",
				"margin":  "12px 0",
			},
		},
		{
			selector: ".monitor-settings .option-row input",
			props: map[string]string{
				"appearance":  "auto",
				"width":       "13px",
				"height":      "13px",
				"min-width":   "13px",
				"background":  "none",
			},
		},
		{
			selector: ".overview-link",
			props: map[string]string{
				"padding":        "8px 0",
				"border-bottom":  "1px solid #bbb",
				"overflow-wrap":  "anywhere",
			},
		},
		{
			selector: ".overview-link p",
			props: map[string]string{
				"margin": "4px 0",
			},
		},
		{
			selector: ".overview-row .overview-retry",
			props: map[string]string{
				"width":              "24px",
				"min-width":          "24px",
				"height":             "26px",
				"min-height":         "26px",
				"padding":            "0",
				"background-image":   "var(--icon-reset)",
				"background-size":    "20px",
				"background-position": "center",
				"background-repeat":  "no-repeat",
			},
		},
		{
			selector: ".top-setting input",
			props: map[string]string{
				"appearance":  "auto",
				"-webkit-appearance": "checkbox",
				"width":       "13px",
				"height":      "13px",
				"min-width":   "13px",
				"background":  "none",
			},
		},
		{
			selector: ".overview-visually-hidden",
			props: map[string]string{
				"position":   "absolute",
				"width":      "1px",
				"height":     "1px",
				"padding":    "0",
				"margin":     "-1px",
				"overflow":   "hidden",
				"clip":       "rect(0,0,0,0)",
				"white-space": "nowrap",
				"border":     "0",
			},
		},
		{
			selector: ".overview-row[hidden]",
			props: map[string]string{
				"display": "none",
			},
		},
	}

	var builder strings.Builder
	
	for _, rule := range rules {
		builder.WriteString(rule.selector)
		builder.WriteString(" {")
		
		for prop, value := range rule.props {
			builder.WriteString(" ")
			builder.WriteString(prop)
			builder.WriteString(":")
			builder.WriteString(value)
			builder.WriteString(";")
		}
		
		builder.WriteString(" }\n")
	}

	content := builder.String()

	if err := os.WriteFile(filename, []byte(content), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing to file: %v\n", err)
		os.Exit(1)
	}
}
