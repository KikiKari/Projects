// abstraction-provenance: {"artifact_sha256": "f65812f14b9750903b7a7b2e2ca9a64b240644cbefa6bf47cc533b7e63d7a24a", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "go"}
// App.css — portiert nach go
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"fmt"
	"os"
	"text/template"
)

type CSSRule struct {
	Selector string
	Props    []CSSProperty
}

type CSSProperty struct {
	Name  string
	Value string
}

func main() {
	if len(os.Args) != 2 {
		fmt.Println("Usage: go run app.go <output-file>")
		os.Exit(1)
	}

	filename := os.Args[1]

	cssRules := []CSSRule{
		{
			Selector: ":root",
			Props: []CSSProperty{
				{"color-scheme", "dark"},
				{"font-family", `Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`},
				{"background", "#0b1020"},
				{"color", "#eef2ff"},
			},
		},
		{
			Selector: "*",
			Props: []CSSProperty{
				{"box-sizing", "border-box"},
			},
		},
		{
			Selector: "body",
			Props: []CSSProperty{
				{"margin", "0"},
				{"min-width", "320px"},
				{"min-height", "100vh"},
				{"background", `radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem), radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem), linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%)`},
			},
		},
		{
			Selector: ".page-shell",
			Props: []CSSProperty{
				{"min-height", "100vh"},
				{"display", "grid"},
				{"place-items", "center"},
				{"padding", "2rem"},
			},
		},
		{
			Selector: ".hero-card",
			Props: []CSSProperty{
				{"width", "min(100%, 56rem)"},
				{"padding", "clamp(2rem, 6vw, 4.5rem)"},
				{"border", "1px solid rgba(148, 163, 184, 0.28)"},
				{"border-radius", "2rem"},
				{"background", "rgba(15, 23, 42, 0.72)"},
				{"box-shadow", "0 2rem 6rem rgba(0, 0, 0, 0.35)"},
				{"backdrop-filter", "blur(18px)"},
			},
		},
		{
			Selector: ".eyebrow",
			Props: []CSSProperty{
				{"margin", "0 0 1rem"},
				{"color", "#67e8f9"},
				{"font-size", "0.8rem"},
				{"font-weight", "700"},
				{"letter-spacing", "0.18em"},
				{"text-transform", "uppercase"},
			},
		},
		{
			Selector: "h1",
			Props: []CSSProperty{
				{"margin", "0"},
				{"max-width", "12ch"},
				{"font-size", "clamp(2.75rem, 8vw, 6rem)"},
				{"line-height", "0.95"},
				{"letter-spacing", "-0.06em"},
			},
		},
		{
			Selector: ".lead",
			Props: []CSSProperty{
				{"margin", "1.5rem 0 0"},
				{"max-width", "42rem"},
				{"color", "#cbd5e1"},
				{"font-size", "clamp(1.05rem, 2vw, 1.35rem)"},
				{"line-height", "1.65"},
			},
		},
		{
			Selector: ".link-grid",
			Props: []CSSProperty{
				{"display", "grid"},
				{"gap", "0.85rem"},
				{"margin-top", "2rem"},
			},
		},
		{
			Selector: ".link-grid a",
			Props: []CSSProperty{
				{"display", "flex"},
				{"align-items", "center"},
				{"justify-content", "space-between"},
				{"gap", "1rem"},
				{"padding", "1rem 1.15rem"},
				{"border", "1px solid rgba(148, 163, 184, 0.25)"},
				{"border-radius", "1rem"},
				{"color", "#f8fafc"},
				{"text-decoration", "none"},
				{"background", "rgba(255, 255, 255, 0.06)"},
			},
		},
		{
			Selector: ".link-grid a:hover,\n.link-grid a:focus-visible",
			Props: []CSSProperty{
				{"border-color", "rgba(103, 232, 249, 0.75)"},
				{"outline", "none"},
				{"background", "rgba(103, 232, 249, 0.12)"},
			},
		},
	}

	tmpl := `{{range .}}{{.Selector}} { {{range .Props}}
  {{.Name}}: {{.Value}};{{end}}
}{{end}}
`

	t, err := template.New("css").Parse(tmpl)
	if err != nil {
		panic(err)
	}

	file, err := os.Create(filename)
	if err != nil {
		panic(err)
	}
	defer file.Close()

	err = t.Execute(file, cssRules)
	if err != nil {
		panic(err)
	}
}
