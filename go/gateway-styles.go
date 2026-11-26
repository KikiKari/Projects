// abstraction-provenance: {"artifact_sha256": "35b1bad70702743e61baf5c3f5bf68d54484da32f085ba590b9c97ebeeabcad5", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "go"}
// gateway-styles.css — portiert nach go
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

// CSSRule represents a CSS rule with selector and properties
type CSSRule struct {
	Selector   string
	Properties map[string]string
}

// CSSVariable represents a CSS variable
type CSSVariable struct {
	Name  string
	Value string
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run script.go <output-file>")
		os.Exit(1)
	}

	filename := os.Args[1]

	// Define CSS variables
	variables := []CSSVariable{
		{Name: "--bg", Value: "#0d1117"},
		{Name: "--surface", Value: "#161b22"},
		{Name: "--border", Value: "#30363d"},
		{Name: "--text", Value: "#e6edf3"},
		{Name: "--muted", Value: "#8b949e"},
		{Name: "--green", Value: "#3fb950"},
		{Name: "--yellow", Value: "#d29922"},
		{Name: "--red", Value: "#f85149"},
		{Name: "--accent", Value: "#58a6ff"},
	}

	// Define CSS rules
	rules := []CSSRule{
		{
			Selector: "*",
			Properties: map[string]string{
				"box-sizing": "border-box",
				"margin":     "0",
				"padding":    "0",
			},
		},
		{
			Selector: "*::before, *::after",
			Properties: map[string]string{
				"box-sizing": "border-box",
				"margin":     "0",
				"padding":    "0",
			},
		},
		{
			Selector: ":root",
			Properties: func() map[string]string {
				props := make(map[string]string)
				for _, v := range variables {
					props[v.Name] = v.Value
				}
				return props
			}(),
		},
		{
			Selector: "body",
			Properties: map[string]string{
				"background":   "var(--bg)",
				"color":        "var(--text)",
				"font-family":  `-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`,
				"min-height":   "100vh",
			},
		},
		{
			Selector: "header",
			Properties: map[string]string{
				"display":         "flex",
				"align-items":     "center",
				"gap":             "1rem",
				"padding":         "1.25rem 2rem",
				"border-bottom":   "1px solid var(--border)",
				"background":      "var(--surface)",
			},
		},
		{
			Selector: "header h1",
			Properties: map[string]string{
				"font-size": "1.25rem",
				"color":     "var(--accent)",
			},
		},
		{
			Selector: ".badge",
			Properties: map[string]string{
				"padding":      ".25rem .75rem",
				"border-radius": "999px",
				"font-size":    ".75rem",
				"font-weight":  "600",
				"background":   "var(--border)",
				"color":        "var(--muted)",
			},
		},
		{
			Selector: ".badge.ok",
			Properties: map[string]string{
				"background": "#1a3a2a",
				"color":      "var(--green)",
			},
		},
		{
			Selector: ".badge.warn",
			Properties: map[string]string{
				"background": "#3a2e0a",
				"color":      "var(--yellow)",
			},
		},
		{
			Selector: ".badge.error",
			Properties: map[string]string{
				"background": "#3a1010",
				"color":      "var(--red)",
			},
		},
		{
			Selector: "main",
			Properties: map[string]string{
				"padding":    "2rem",
				"max-width":  "960px",
				"margin":     "0 auto",
			},
		},
		{
			Selector: ".grid",
			Properties: map[string]string{
				"display":               "grid",
				"grid-template-columns": "repeat(auto-fit, minmax(260px, 1fr))",
				"gap":                   "1rem",
				"margin-bottom":         "2rem",
			},
		},
		{
			Selector: ".card",
			Properties: map[string]string{
				"background":   "var(--surface)",
				"border":       "1px solid var(--border)",
				"border-radius": "8px",
				"padding":      "1.25rem",
				"position":     "relative",
			},
		},
		{
			Selector: ".card h2",
			Properties: map[string]string{
				"font-size":     "1rem",
				"margin-bottom": ".25rem",
			},
		},
		{
			Selector: ".card .endpoint",
			Properties: map[string]string{
				"font-size": ".8rem",
				"color":     "var(--muted)",
			},
		},
		{
			Selector: ".status-dot",
			Properties: map[string]string{
				"position":      "absolute",
				"top":           "1.25rem",
				"right":         "1.25rem",
				"width":         "10px",
				"height":        "10px",
				"border-radius": "50%",
				"background":    "var(--border)",
			},
		},
		{
			Selector: ".status-dot.green",
			Properties: map[string]string{
				"background": "var(--green)",
				"box-shadow": "0 0 6px var(--green)",
			},
		},
		{
			Selector: ".status-dot.red",
			Properties: map[string]string{
				"background": "var(--red)",
				"box-shadow": "0 0 6px var(--red)",
			},
		},
		{
			Selector: ".metrics h2",
			Properties: map[string]string{
				"font-size":     "1rem",
				"margin-bottom": "1rem",
			},
		},
		{
			Selector: "table",
			Properties: map[string]string{
				"width":           "100%",
				"border-collapse": "collapse",
				"font-size":       ".875rem",
			},
		},
		{
			Selector: "th, td",
			Properties: map[string]string{
				"padding":       ".625rem 1rem",
				"text-align":    "left",
				"border-bottom": "1px solid var(--border)",
			},
		},
		{
			Selector: "th",
			Properties: map[string]string{
				"color":       "var(--muted)",
				"font-weight": "500",
			},
		},
		{
			Selector: "tr:last-child td",
			Properties: map[string]string{
				"border-bottom": "none",
			},
		},
	}

	// Create template for CSS generation
	cssTemplate := `/* OpenClaw Gateway Dashboard */

{{ range $rule := .Rules }}{{ if eq $rule.Selector ":root" }}{{ $rule.Selector }} {
{{ range $name, $value := $rule.Properties }}  {{ $name }}: {{ $value }};
{{ end }}} 

{{ else }}{{ $rule.Selector }} {
{{ range $name, $value := $rule.Properties }}  {{ $name }}: {{ $value }};
{{ end }}}

{{ end }}{{ end }}`

	tmpl, err := template.New("css").Parse(cssTemplate)
	if err != nil {
		panic(err)
	}

	file, err := os.Create(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	err = tmpl.Execute(file, map[string]interface{}{
		"Rules": rules,
	})
	if err != nil {
		panic(err)
	}
}
