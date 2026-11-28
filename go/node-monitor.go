// abstraction-provenance: {"artifact_sha256": "b653802fc7c79125421102cfb4bb1901e18502d4392e0637225fcea48c2e18b7", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "go"}
// node-monitor.css — portiert nach go
// Quelle: css, Projects@abstractions:css/node-monitor.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
)

// CSSRule represents a CSS rule with selectors and declarations
type CSSRule struct {
	Selector      string
	Declarations  map[string]string
}

// CSSDocument represents a complete CSS document
type CSSDocument struct {
	CommentHeader string
	Variables     map[string]string
	Rules         []CSSRule
}

// NewCSSDocument creates a new CSS document with default values
func NewCSSDocument() *CSSDocument {
	return &CSSDocument{
		Variables: make(map[string]string),
		Rules:     make([]CSSRule, 0),
	}
}

// AddVariable adds a CSS variable to the document
func (doc *CSSDocument) AddVariable(name, value string) {
	doc.Variables[name] = value
}

// AddRule adds a CSS rule to the document
func (doc *CSSDocument) AddRule(selector string, declarations map[string]string) {
	rule := CSSRule{
		Selector:     selector,
		Declarations: declarations,
	}
	doc.Rules = append(doc.Rules, rule)
}

// String generates the CSS string representation of the document
func (doc *CSSDocument) String() string {
	result := doc.CommentHeader + "\n\n"
	
	// Write variables in :root rule
	result += ":root {\n"
	for name, value := range doc.Variables {
		result += fmt.Sprintf("  %s: %s;\n", name, value)
	}
	result += "}\n\n"
	
	// Write other rules
	for _, rule := range doc.Rules {
		result += rule.Selector + " {\n"
		for property, value := range rule.Declarations {
			result += fmt.Sprintf("  %s: %s;\n", property, value)
		}
		result += "}\n\n"
	}
	
	return result
}

// Save writes the CSS document to a file
func (doc *CSSDocument) Save(filename string) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()
	
	_, err = file.WriteString(doc.String())
	return err
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run script.go <output-file>")
		os.Exit(1)
	}
	
	outputFile := os.Args[1]
	
	// Create CSS document
	doc := NewCSSDocument()
	
	// Set comment header
	doc.CommentHeader = `/* abstraction-provenance: {"artifact_sha256": "37bc702d7c4046193f78406172db9f9b81e5951260071773ee3519d55f802128", "source_sha256": "ed59efd19fa280b88488d50ce98f4213a84c5f833eacd98c7cb448f570c805fe", "target_language": "css"} */
/* node-monitor.html — portiert nach css */
/* Quelle: html, OpenClaw@main:examples/node-monitor.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */`
	
	// Define CSS variables
	variables := map[string]string{
		"--bg":      "#0d1117",
		"--surface": "#161b22",
		"--border":  "#30363d",
		"--text":    "#e6edf3",
		"--green":   "#3fb950",
		"--red":     "#f85149",
		"--accent":  "#58a6ff",
	}
	
	for name, value := range variables {
		doc.AddVariable(name, value)
	}
	
	// Define CSS rules
	rules := []struct {
		selector     string
		declarations map[string]string
	}{
		{
			selector: "*",
			declarations: map[string]string{
				"box-sizing": "border-box",
				"margin":     "0",
				"padding":    "0",
			},
		},
		{
			selector: "body",
			declarations: map[string]string{
				"background":   "var(--bg)",
				"color":        "var(--text)",
				"font-family":  "-apple-system, sans-serif",
				"padding":      "1.5rem",
			},
		},
		{
			selector: "h1",
			declarations: map[string]string{
				"color":       "var(--accent)",
				"margin-bottom": "1rem",
				"font-size":   "1.2rem",
			},
		},
		{
			selector: "canvas",
			declarations: map[string]string{
				"display":      "block",
				"border":       "1px solid var(--border)",
				"border-radius": "8px",
				"background":   "var(--surface)",
			},
		},
		{
			selector: "#log",
			declarations: map[string]string{
				"margin-top":    "1rem",
				"height":        "140px",
				"overflow-y":    "auto",
				"background":    "var(--surface)",
				"border":        "1px solid var(--border)",
				"border-radius": "8px",
				"padding":       ".75rem",
				"font-size":     ".78rem",
				"font-family":   "monospace",
				"color":         "#8b949e",
			},
		},
		{
			selector: "#log .err",
			declarations: map[string]string{
				"color": "var(--red)",
			},
		},
		{
			selector: "#log .ok",
			declarations: map[string]string{
				"color": "var(--green)",
			},
		},
	}
	
	for _, r := range rules {
		doc.AddRule(r.selector, r.declarations)
	}
	
	// Save to file
	err := doc.Save(outputFile)
	if err != nil {
		fmt.Printf("Error writing to file: %v\n", err)
		os.Exit(1)
	}
}
