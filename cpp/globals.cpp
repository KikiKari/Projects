// abstraction-provenance: {"artifact_sha256": "e3fe709e1c4b381fe782c0cc741b6f2dd80c00075593564b0532a5af3d8356b6", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "cpp"}
// globals.css — portiert nach cpp
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <map>

class CSSGenerator {
private:
    std::map<std::string, std::string> variables;

public:
    CSSGenerator() {
        // Initialize CSS variables
        variables["--bg"] = "#faf8f4";
        variables["--surface"] = "#ffffff";
        variables["--surface-2"] = "#f1eee7";
        variables["--ink"] = "#1b1a17";
        variables["--ink-2"] = "#3c3a34";
        variables["--muted"] = "#6e6a61";
        variables["--line"] = "#e5e1d8";
        variables["--line-strong"] = "#d4cfc3";
        variables["--accent"] = "#a8542f";
        variables["--accent-press"] = "#8e4526";
        variables["--accent-tint"] = "#f1e5dd";
        variables["--on-accent"] = "#ffffff";
        variables["--accent-2"] = "#2e7d7b";
        variables["--accent-2-press"] = "#225e5b";
        variables["--accent-3"] = "#c77d2e";
        variables["--footer-bg"] = "#191815";
        variables["--footer-fg"] = "#efeae0";
        variables["--footer-muted"] = "#9a958a";
        variables["--success"] = "#2e7d5b";
        variables["--danger"] = "#9e3f32";
        variables["--font-display"] = "\"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif";
        variables["--font-sans"] = "\"Segoe UI\", Inter, system-ui, -apple-system, sans-serif";
        variables["--font-mono"] = "\"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace";
        variables["--space-1"] = "0.25rem";
        variables["--space-2"] = "0.5rem";
        variables["--space-3"] = "0.75rem";
        variables["--space-4"] = "1rem";
        variables["--space-5"] = "1.25rem";
        variables["--space-6"] = "1.5rem";
        variables["--space-8"] = "2rem";
        variables["--space-10"] = "2.5rem";
        variables["--space-12"] = "3rem";
        variables["--space-16"] = "4rem";
        variables["--space-20"] = "5rem";
        variables["--space-24"] = "6rem";
        variables["--space-30"] = "7.5rem";
        variables["--radius-sm"] = "0.375rem";
        variables["--radius-md"] = "0.625rem";
        variables["--radius-lg"] = "1.125rem";
        variables["--radius-pill"] = "999px";
        variables["--shadow-sm"] = "0 1px 2px rgb(27 26 23 / 6%)";
        variables["--shadow-md"] = "0 10px 30px -16px rgb(27 26 23 / 22%)";
        variables["--shadow-lg"] = "0 34px 70px -34px rgb(27 26 23 / 32%)";
        variables["--container"] = "75rem";
        variables["--motion-fast"] = "180ms";
        variables["--motion-base"] = "350ms";
        variables["--motion-slow"] = "800ms";
        variables["--ease-out"] = "cubic-bezier(0.22, 0.61, 0.36, 1)";
    }

    std::string generateCSS() {
        std::string css = "@import \"tailwindcss\";\n\n";
        
        // Root variables
        css += ":root {\n";
        for (const auto& pair : variables) {
            css += "  " + pair.first + ": " + pair.second + ";\n";
        }
        css += "}\n\n";
        
        // Theme inline
        css += "@theme inline {\n";
        css += "  --color-bg: var(--bg);\n";
        css += "  --color-surface: var(--surface);\n";
        css += "  --color-surface-2: var(--surface-2);\n";
        css += "  --color-ink: var(--ink);\n";
        css += "  --color-ink-2: var(--ink-2);\n";
        css += "  --color-muted: var(--muted);\n";
        css += "  --color-line: var(--line);\n";
        css += "  --color-line-strong: var(--line-strong);\n";
        css += "  --color-accent: var(--accent);\n";
        css += "  --color-accent-2: var(--accent-2);\n";
        css += "  --color-accent-3: var(--accent-3);\n";
        css += "  --font-display: var(--font-display);\n";
        css += "  --font-sans: var(--font-sans);\n";
        css += "  --font-mono: var(--font-mono);\n";
        css += "}\n\n";
        
        // Base styles
        css += "* { box-sizing: border-box; }\n";
        css += "html { scroll-behavior: smooth; }\n";
        css += "body {\n";
        css += "  margin: 0;\n";
        css += "  background: var(--bg);\n";
        css += "  color: var(--ink);\n";
        css += "  font-family: var(--font-sans);\n";
        css += "  line-height: 1.5;\n";
        css += "  -webkit-font-smoothing: antialiased;\n";
        css += "}\n";
        css += "a { color: inherit; }\n";
        css += "button, input, textarea { font: inherit; }\n";
        css += "::selection { background: var(--accent-tint); color: var(--ink); }\n\n";
        
        // Utility classes
        css += ".display {\n";
        css += "  font-family: var(--font-display);\n";
        css += "  font-weight: 400;\n";
        css += "  letter-spacing: -0.022em;\n";
        css += "}\n";
        css += ".eyebrow {\n";
        css += "  font-family: var(--font-mono);\n";
        css += "  font-size: 0.75rem;\n";
        css += "  letter-spacing: 0.16em;\n";
        css += "  text-transform: uppercase;\n";
        css += "}\n";
        css += ".focus-ring:focus-visible {\n";
        css += "  outline: 2px solid var(--accent);\n";
        css += "  outline-offset: 4px;\n";
        css += "}\n";
        css += ".content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }\n\n";
        
        // Media query
        css += "@media (prefers-reduced-motion: reduce) {\n";
        css += "  html { scroll-behavior: auto; }\n";
        css += "  *, *::before, *::after {\n";
        css += "    animation-duration: 0.01ms !important;\n";
        css += "    animation-iteration-count: 1 !important;\n";
        css += "    scroll-behavior: auto !important;\n";
        css += "    transition-duration: 0.01ms !important;\n";
        css += "  }\n";
        css += "}\n\n";
        
        // Header hiding styles
        css += "/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */\n";
        css += "body[data-hero-immersive=\"true\"] > header,\n";
        css += "body[data-hero-immersive=\"true\"] header[data-site-header] {\n";
        css += "  opacity: 0;\n";
        css += "  pointer-events: none;\n";
        css += "  transition: opacity 0.4s ease-out;\n";
        css += "}\n\n";
        
        // Keyframes
        css += "/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */\n";
        css += "@keyframes dropfall {\n";
        css += "  0% {\n";
        css += "    transform: translateY(0);\n";
        css += "    opacity: 0;\n";
        css += "  }\n";
        css += "  10% {\n";
        css += "    opacity: 0.9;\n";
        css += "  }\n";
        css += "  90% {\n";
        css += "    opacity: 0.7;\n";
        css += "  }\n";
        css += "  100% {\n";
        css += "    transform: translateY(110vh);\n";
        css += "    opacity: 0;\n";
        css += "  }\n";
        css += "}\n";
        
        return css;
    }
    
    void writeToFile(const std::string& filename) {
        std::ofstream file(filename);
        if (file.is_open()) {
            file << generateCSS();
            file.close();
        } else {
            std::cerr << "Unable to open file: " << filename << std::endl;
        }
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>" << std::endl;
        return 1;
    }
    
    CSSGenerator generator;
    generator.writeToFile(argv[1]);
    
    return 0;
}
