// abstraction-provenance: {"artifact_sha256": "217102287ca27c41b065b16d473d03732c6733eb34e3d5e4b299d9280fc0b78a", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "go"}
// globals.css — portiert nach go
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


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
	
	builder.WriteString("@import \"tailwindcss\";\n\n")
	
	builder.WriteString(":root {\n")
	variables := map[string]string{
		"--bg": "#faf8f4",
		"--surface": "#ffffff",
		"--surface-2": "#f1eee7",
		"--ink": "#1b1a17",
		"--ink-2": "#3c3a34",
		"--muted": "#6e6a61",
		"--line": "#e5e1d8",
		"--line-strong": "#d4cfc3",
		"--accent": "#a8542f",
		"--accent-press": "#8e4526",
		"--accent-tint": "#f1e5dd",
		"--on-accent": "#ffffff",
		"--accent-2": "#2e7d7b",
		"--accent-2-press": "#225e5b",
		"--accent-3": "#c77d2e",
		"--footer-bg": "#191815",
		"--footer-fg": "#efeae0",
		"--footer-muted": "#9a958a",
		"--success": "#2e7d5b",
		"--danger": "#9e3f32",
		"--font-display": "\"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif",
		"--font-sans": "\"Segoe UI\", Inter, system-ui, -apple-system, sans-serif",
		"--font-mono": "\"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace",
		"--space-1": "0.25rem",
		"--space-2": "0.5rem",
		"--space-3": "0.75rem",
		"--space-4": "1rem",
		"--space-5": "1.25rem",
		"--space-6": "1.5rem",
		"--space-8": "2rem",
		"--space-10": "2.5rem",
		"--space-12": "3rem",
		"--space-16": "4rem",
		"--space-20": "5rem",
		"--space-24": "6rem",
		"--space-30": "7.5rem",
		"--radius-sm": "0.375rem",
		"--radius-md": "0.625rem",
		"--radius-lg": "1.125rem",
		"--radius-pill": "999px",
		"--shadow-sm": "0 1px 2px rgb(27 26 23 / 6%)",
		"--shadow-md": "0 10px 30px -16px rgb(27 26 23 / 22%)",
		"--shadow-lg": "0 34px 70px -34px rgb(27 26 23 / 32%)",
		"--container": "75rem",
		"--motion-fast": "180ms",
		"--motion-base": "350ms",
		"--motion-slow": "800ms",
		"--ease-out": "cubic-bezier(0.22, 0.61, 0.36, 1)",
	}
	
	for key, value := range variables {
		builder.WriteString(fmt.Sprintf("  %s: %s;\n", key, value))
	}
	builder.WriteString("}\n\n")
	
	builder.WriteString("@theme inline {\n")
	themeVars := []string{
		"--color-bg: var(--bg)",
		"--color-surface: var(--surface)",
		"--color-surface-2: var(--surface-2)",
		"--color-ink: var(--ink)",
		"--color-ink-2: var(--ink-2)",
		"--color-muted: var(--muted)",
		"--color-line: var(--line)",
		"--color-line-strong: var(--line-strong)",
		"--color-accent: var(--accent)",
		"--color-accent-2: var(--accent-2)",
		"--color-accent-3: var(--accent-3)",
		"--font-display: var(--font-display)",
		"--font-sans: var(--font-sans)",
		"--font-mono: var(--font-mono)",
	}
	for _, themeVar := range themeVars {
		builder.WriteString(fmt.Sprintf("  %s;\n", themeVar))
	}
	builder.WriteString("}\n\n")
	
	builder.WriteString("* { box-sizing: border-box; }\n")
	builder.WriteString("html { scroll-behavior: smooth; }\n")
	builder.WriteString("body {\n")
	builder.WriteString("  margin: 0;\n")
	builder.WriteString("  background: var(--bg);\n")
	builder.WriteString("  color: var(--ink);\n")
	builder.WriteString("  font-family: var(--font-sans);\n")
	builder.WriteString("  line-height: 1.5;\n")
	builder.WriteString("  -webkit-font-smoothing: antialiased;\n")
	builder.WriteString("}\n")
	builder.WriteString("a { color: inherit; }\n")
	builder.WriteString("button, input, textarea { font: inherit; }\n")
	builder.WriteString("::selection { background: var(--accent-tint); color: var(--ink); }\n\n")
	
	builder.WriteString(".display {\n")
	builder.WriteString("  font-family: var(--font-display);\n")
	builder.WriteString("  font-weight: 400;\n")
	builder.WriteString("  letter-spacing: -0.022em;\n")
	builder.WriteString("}\n")
	builder.WriteString(".eyebrow {\n")
	builder.WriteString("  font-family: var(--font-mono);\n")
	builder.WriteString("  font-size: 0.75rem;\n")
	builder.WriteString("  letter-spacing: 0.16em;\n")
	builder.WriteString("  text-transform: uppercase;\n")
	builder.WriteString("}\n")
	builder.WriteString(".focus-ring:focus-visible {\n")
	builder.WriteString("  outline: 2px solid var(--accent);\n")
	builder.WriteString("  outline-offset: 4px;\n")
	builder.WriteString("}\n")
	builder.WriteString(".content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }\n\n")
	
	builder.WriteString("@media (prefers-reduced-motion: reduce) {\n")
	builder.WriteString("  html { scroll-behavior: auto; }\n")
	builder.WriteString("  *, *::before, *::after {\n")
	builder.WriteString("    animation-duration: 0.01ms !important;\n")
	builder.WriteString("    animation-iteration-count: 1 !important;\n")
	builder.WriteString("    scroll-behavior: auto !important;\n")
	builder.WriteString("    transition-duration: 0.01ms !important;\n")
	builder.WriteString("  }\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */\n")
	builder.WriteString("body[data-hero-immersive=\"true\"] > header,\n")
	builder.WriteString("body[data-hero-immersive=\"true\"] header[data-site-header] {\n")
	builder.WriteString("  opacity: 0;\n")
	builder.WriteString("  pointer-events: none;\n")
	builder.WriteString("  transition: opacity 0.4s ease-out;\n")
	builder.WriteString("}\n\n")
	
	builder.WriteString("/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */\n")
	builder.WriteString("@keyframes dropfall {\n")
	builder.WriteString("  0% {\n")
	builder.WriteString("    transform: translateY(0);\n")
	builder.WriteString("    opacity: 0;\n")
	builder.WriteString("  }\n")
	builder.WriteString("  10% {\n")
	builder.WriteString("    opacity: 0.9;\n")
	builder.WriteString("  }\n")
	builder.WriteString("  90% {\n")
	builder.WriteString("    opacity: 0.7;\n")
	builder.WriteString("  }\n")
	builder.WriteString("  100% {\n")
	builder.WriteString("    transform: translateY(110vh);\n")
	builder.WriteString("    opacity: 0;\n")
	builder.WriteString("  }\n")
	builder.WriteString("}\n")
	
	return builder.String()
}
