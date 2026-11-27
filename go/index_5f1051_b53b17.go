// abstraction-provenance: {"artifact_sha256": "933ee2cdb3de47bc0a2e81c91aa1139365101027d229eaa1dc5cf1cd5a343b94", "source_sha256": "b53b17806f268da8dc7115668f5a04c5ff39edd9b2305ba40f1b04e598002f81", "target_language": "go"}
// index_5f1051.css — portiert nach go
// Quelle: css, Projects@abstractions:css/index_5f1051.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

type CSSRule struct {
	Selector string
	Props    map[string]string
}

type StyleSheet struct {
	Rules []CSSRule
}

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]
	
	stylesheet := StyleSheet{
		Rules: []CSSRule{
			{ // body rule
				Selector: "body",
				Props: map[string]string{
					"background-color": "white",
					"color":             "black",
					"margin":            "0",
					"padding":           "0",
					"font-family":       "Arial, sans-serif",
				},
			},
			{ // table rule
				Selector: "table",
				Props: map[string]string{
					"border-collapse": "collapse",
				},
			},
			{ // .globalnav-container rule
				Selector: ".globalnav-container",
				Props: map[string]string{
					"width":       "780px",
					"border":      "0",
					"cellpadding": "0",
					"cellspacing": "0",
				},
			},
			{ // .header-left rule
				Selector: ".header-left",
				Props: map[string]string{
					"vertical-align": "top",
					"text-align":     "left",
				},
			},
			{ // .header-right rule
				Selector: ".header-right",
				Props: map[string]string{
					"vertical-align": "top",
					"text-align":     "right",
				},
			},
			{ // .logo-link rule
				Selector: ".logo-link",
				Props: map[string]string{
					"text-decoration": "none",
					"border":          "0",
				},
			},
			{ // .logo-image rule
				Selector: ".logo-image",
				Props: map[string]string{
					"border": "0",
				},
			},
			{ // .hosted-by rule
				Selector: ".hosted-by",
				Props: map[string]string{
					"font-size":       "1px",
					"text-decoration": "none",
				},
			},
			{ // .active-state-logo rule
				Selector: ".active-state-logo",
				Props: map[string]string{
					"border": "0",
					"title":  "\"This site is hosted by ActiveState\"",
				},
			},
			{ // #globalnav rule
				Selector: "#globalnav",
				Props: map[string]string{
					"clear": "both",
				},
			},
			{ // #globalnav ul rule
				Selector: "#globalnav ul",
				Props: map[string]string{
					"list-style-type": "none",
					"margin":          "0",
					"padding":         "0",
					"overflow":        "hidden",
				},
			},
			{ // #globalnav li rule
				Selector: "#globalnav li",
				Props: map[string]string{
					"float": "left",
				},
			},
			{ // #globalnav a rule
				Selector: "#globalnav a",
				Props: map[string]string{
					"display":         "block",
					"padding":         "8px 16px",
					"text-decoration": "none",
					"color":           "#000",
				},
			},
			{ // #globalnav a.here rule
				Selector: "#globalnav a.here",
				Props: map[string]string{
					"background-color": "#3163CE",
					"color":            "white",
				},
			},
			{ // .divider-top rule
				Selector: ".divider-top",
				Props: map[string]string{
					"border-top": "2px solid #3163CE",
					"width":      "780px",
				},
			},
			{ // .search-table rule
				Selector: ".search-table",
				Props: map[string]string{
					"width":       "780px",
					"border":      "0",
					"cellpadding": "2",
					"cellspacing": "0",
				},
			},
			{ // .search-container rule
				Selector: ".search-container",
				Props: map[string]string{
					"display":        "table-cell",
					"vertical-align": "middle",
					"margin":         "0px",
				},
			},
			{ // .search-form rule
				Selector: ".search-form",
				Props: map[string]string{
					"display": "inline",
				},
			},
			{ // .search-input rule
				Selector: ".search-input",
				Props: map[string]string{
					"size":       "20",
					"maxlength":  "255",
					"value":      "\"\"",
				},
			},
			{ // .submit-button rule
				Selector: ".submit-button",
				Props: map[string]string{
					"border": "0",
				},
			},
			{ // .hidden-input rule
				Selector: ".hidden-input",
				Props: map[string]string{
					"display": "none",
				},
			},
			{ // .banner rule
				Selector: ".banner",
				Props: map[string]string{
					"text-align":  "right",
					"font-weight": "bold",
					"margin":      "0",
				},
			},
			{ // .divider-yellow rule
				Selector: ".divider-yellow",
				Props: map[string]string{
					"border-top":   "1px solid #FFCE00",
					"margin-bottom": "2px",
					"width":        "780px",
				},
			},
			{ // .content-table rule
				Selector: ".content-table",
				Props: map[string]string{
					"width":       "780px",
					"border":      "0",
					"cellpadding": "0",
					"cellspacing": "0",
				},
			},
			{ // .keylist rule
				Selector: ".keylist",
				Props: map[string]string{
					"margin": "0",
					"padding": "0",
				},
			},
			{ // .keylist dt rule
				Selector: ".keylist dt",
				Props: map[string]string{
					"font-weight": "bold",
					"margin-top":  "10px",
				},
			},
			{ // .keylist dd rule
				Selector: ".keylist dd",
				Props: map[string]string{
					"margin-left":   "20px",
					"margin-bottom": "10px",
				},
			},
			{ // .footer rule
				Selector: ".footer",
				Props: map[string]string{
					"text-align": "center",
					"clear":      "both",
				},
			},
			{ // .footer small rule
				Selector: ".footer small",
				Props: map[string]string{
					"font-size": "12px",
				},
			},
			{ // .footer a rule
				Selector: ".footer a",
				Props: map[string]string{
					"text-decoration": "none",
					"color":           "#000",
				},
			},
			{ // .footer a:hover rule
				Selector: ".footer a:hover",
				Props: map[string]string{
					"text-decoration": "underline",
				},
			},
			{ // .clear rule
				Selector: ".clear",
				Props: map[string]string{
					"clear": "both",
				},
			},
		},
	}

	file, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	tmpl := `/* abstraction-provenance: {"artifact_sha256": "cdcc9e9ffa451d8c92fd763b0dfd0b1974003a826baaae753e2f347cfd3c9f57", "source_sha256": "5f1051ecfd7f7a7dbdb89449a4e356b1ff5b7daa5e21e2c82defb13ede719988", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/tcl/index.html */
/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/tcl/index.html */
/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */

{{range .Rules}}{{.Selector}} {
{{range $prop, $val}}    {{$prop}}: {{$val}};
{{end}}
}

{{end}}`

	t := template.Must(template.New("css").Parse(tmpl))
	err = t.Execute(file, stylesheet)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error executing template: %v\n", err)
		os.Exit(1)
	}
}
