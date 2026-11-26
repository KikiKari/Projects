// abstraction-provenance: {"artifact_sha256": "2ac2af10ec221027f33272f9f9311a4145cae4adf2a1295ed1d4d0474c7ba8a1", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "go"}
// icon-controls.css — portiert nach go
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
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
	f, err := os.Create(filename)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating file: %v\n", err)
		os.Exit(1)
	}
	defer f.Close()

	// Define icon styles and their corresponding directory paths
	styles := map[string]string{
		"plastisch": "plastisch",
		"glass":     "glass",
		"linear":    "linear",
	}

	// List of all icons with their filenames (without extension)
	iconNames := []string{
		"auto-chat-refresh-counter",
		"browser",
		"captions",
		"chat-counter",
		"fullscreen",
		"mute",
		"off",
		"on",
		"pip",
		"play",
		"player",
		"protection-slider",
		"recommendation-counter",
		"report",
		"reset",
		"settings",
		"status",
		"stop",
		"unmute",
		"volume-slider",
	}

	// Generate CSS rules for each style
	for styleName, dirPath := range styles {
		fmt.Fprintf(f, "html[data-icon-style=\"%s\"] {", styleName)
		for _, iconName := range iconNames {
			fmt.Fprintf(f, "--icon-%s:url(\"icons/%s/%s.png\");", iconName, dirPath, iconName)
		}
		fmt.Fprintln(f, "}")
	}

	// Common CSS rules
	commonCSS := `
button[data-control-icon]::before,
.control-icon::before {
	content: "";
	display: inline-block;
	width: 32px;
	height: 32px;
	flex: 0 0 32px;
	background: var(--control-icon) center/contain no-repeat;
	vertical-align: middle;
	margin-inline-end: 0;
	pointer-events: none;
}

button[data-control-icon] {
	min-height: 44px;
	min-width: 44px;
	font-size: 0;
	display: inline-flex;
	align-items: center;
	justify-content: center;
}

button[data-control-icon][hidden] {
	display: none;
}

input[type="checkbox"] {
	appearance: none;
	-webkit-appearance: none;
	width: 44px;
	height: 44px;
	min-width: 44px;
	border: 0;
	background: var(--icon-off) center/40px no-repeat;
	cursor: pointer;
	vertical-align: middle;
}

input[type="checkbox"]:checked {
	background-image: var(--icon-on);
}

input[type="checkbox"]:focus-visible,
button[data-control-icon]:focus-visible {
	outline: 2px solid #1769df;
	outline-offset: 2px;
}

input[type="checkbox"]:disabled {
	opacity: .45;
	cursor: default;
}

.control-icon {
	display: inline-flex;
	align-items: center;
}

input[type="range"] {
	min-height: 32px;
}

.icon-style-setting {
	display: flex;
	align-items: center;
	gap: 8px;
}
`

	fmt.Fprintln(f, strings.TrimSpace(commonCSS))

	// Icon-specific control rules
	for _, iconName := range iconNames {
		fmt.Fprintf(f, "[data-control-icon=\"%s\"] { --control-icon:var(--icon-%s); }\n", iconName, iconName)
	}
}
