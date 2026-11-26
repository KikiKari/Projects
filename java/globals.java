// abstraction-provenance: {"artifact_sha256": "a452afaf49fa1d75d56e6f2c8203b1e7a73d77f559bf837f70811dc98ad7bd2e", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "java"}
// globals.css — portiert nach java
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

import java.io.FileWriter;
import java.io.IOException;
import java.util.Map;

public class GlobalsCSSGenerator {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java GlobalsCSSGenerator <output-file>");
            System.exit(1);
        }
        
        String outputFile = args[0];
        generateCSS(outputFile);
    }

    private static void generateCSS(String outputFile) {
        StringBuilder css = new StringBuilder();
        
        // Import statement
        css.append("@import \"tailwindcss\";\n\n");
        
        // Root variables
        css.append(":root {\n");
        Map<String, String> variables = getRootVariables();
        for (Map.Entry<String, String> entry : variables.entrySet()) {
            css.append("  ").append(entry.getKey()).append(": ").append(entry.getValue()).append(";\n");
        }
        css.append("}\n\n");
        
        // Theme inline
        css.append("@theme inline {\n");
        Map<String, String> themeVars = getThemeVariables();
        for (Map.Entry<String, String> entry : themeVars.entrySet()) {
            css.append("  ").append(entry.getKey()).append(": var(").append(entry.getValue()).append(");\n");
        }
        css.append("}\n\n");
        
        // Base styles
        css.append("* { box-sizing: border-box; }\n");
        css.append("html { scroll-behavior: smooth; }\n");
        css.append("body {\n");
        css.append("  margin: 0;\n");
        css.append("  background: var(--bg);\n");
        css.append("  color: var(--ink);\n");
        css.append("  font-family: var(--font-sans);\n");
        css.append("  line-height: 1.5;\n");
        css.append("  -webkit-font-smoothing: antialiased;\n");
        css.append("}\n");
        css.append("a { color: inherit; }\n");
        css.append("button, input, textarea { font: inherit; }\n");
        css.append("::selection { background: var(--accent-tint); color: var(--ink); }\n\n");
        
        // Utility classes
        css.append(".display {\n");
        css.append("  font-family: var(--font-display);\n");
        css.append("  font-weight: 400;\n");
        css.append("  letter-spacing: -0.022em;\n");
        css.append("}\n");
        css.append(".eyebrow {\n");
        css.append("  font-family: var(--font-mono);\n");
        css.append("  font-size: 0.75rem;\n");
        css.append("  letter-spacing: 0.16em;\n");
        css.append("  text-transform: uppercase;\n");
        css.append("}\n");
        css.append(".focus-ring:focus-visible {\n");
        css.append("  outline: 2px solid var(--accent);\n");
        css.append("  outline-offset: 4px;\n");
        css.append("}\n");
        css.append(".content-auto { content-visibility: auto; contain-intrinsic-size: 1px 800px; }\n\n");
        
        // Media query
        css.append("@media (prefers-reduced-motion: reduce) {\n");
        css.append("  html { scroll-behavior: auto; }\n");
        css.append("  *, *::before, *::after {\n");
        css.append("    animation-duration: 0.01ms !important;\n");
        css.append("    animation-iteration-count: 1 !important;\n");
        css.append("    scroll-behavior: auto !important;\n");
        css.append("    transition-duration: 0.01ms !important;\n");
        css.append("  }\n");
        css.append("}\n\n");
        
        // Header hiding comment and rules
        css.append("/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */\n");
        css.append("body[data-hero-immersive=\"true\"] > header,\n");
        css.append("body[data-hero-immersive=\"true\"] header[data-site-header] {\n");
        css.append("  opacity: 0;\n");
        css.append("  pointer-events: none;\n");
        css.append("  transition: opacity 0.4s ease-out;\n");
        css.append("}\n\n");
        
        // Keyframes
        css.append("/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */\n");
        css.append("@keyframes dropfall {\n");
        css.append("  0% {\n");
        css.append("    transform: translateY(0);\n");
        css.append("    opacity: 0;\n");
        css.append("  }\n");
        css.append("  10% {\n");
        css.append("    opacity: 0.9;\n");
        css.append("  }\n");
        css.append("  90% {\n");
        css.append("    opacity: 0.7;\n");
        css.append("  }\n");
        css.append("  100% {\n");
        css.append("    transform: translateY(110vh);\n");
        css.append("    opacity: 0;\n");
        css.append("  }\n");
        css.append("}\n");
        
        try (FileWriter writer = new FileWriter(outputFile)) {
            writer.write(css.toString());
        } catch (IOException e) {
            System.err.println("Error writing to file: " + e.getMessage());
            System.exit(1);
        }
    }

    private static Map<String, String> getRootVariables() {
        return Map.ofEntries(
            Map.entry("--bg", "#faf8f4"),
            Map.entry("--surface", "#ffffff"),
            Map.entry("--surface-2", "#f1eee7"),
            Map.entry("--ink", "#1b1a17"),
            Map.entry("--ink-2", "#3c3a34"),
            Map.entry("--muted", "#6e6a61"),
            Map.entry("--line", "#e5e1d8"),
            Map.entry("--line-strong", "#d4cfc3"),
            Map.entry("--accent", "#a8542f"),
            Map.entry("--accent-press", "#8e4526"),
            Map.entry("--accent-tint", "#f1e5dd"),
            Map.entry("--on-accent", "#ffffff"),
            Map.entry("--accent-2", "#2e7d7b"),
            Map.entry("--accent-2-press", "#225e5b"),
            Map.entry("--accent-3", "#c77d2e"),
            Map.entry("--footer-bg", "#191815"),
            Map.entry("--footer-fg", "#efeae0"),
            Map.entry("--footer-muted", "#9a958a"),
            Map.entry("--success", "#2e7d5b"),
            Map.entry("--danger", "#9e3f32"),
            Map.entry("--font-display", "\"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif"),
            Map.entry("--font-sans", "\"Segoe UI\", Inter, system-ui, -apple-system, sans-serif"),
            Map.entry("--font-mono", "\"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace"),
            Map.entry("--space-1", "0.25rem"),
            Map.entry("--space-2", "0.5rem"),
            Map.entry("--space-3", "0.75rem"),
            Map.entry("--space-4", "1rem"),
            Map.entry("--space-5", "1.25rem"),
            Map.entry("--space-6", "1.5rem"),
            Map.entry("--space-8", "2rem"),
            Map.entry("--space-10", "2.5rem"),
            Map.entry("--space-12", "3rem"),
            Map.entry("--space-16", "4rem"),
            Map.entry("--space-20", "5rem"),
            Map.entry("--space-24", "6rem"),
            Map.entry("--space-30", "7.5rem"),
            Map.entry("--radius-sm", "0.375rem"),
            Map.entry("--radius-md", "0.625rem"),
            Map.entry("--radius-lg", "1.125rem"),
            Map.entry("--radius-pill", "999px"),
            Map.entry("--shadow-sm", "0 1px 2px rgb(27 26 23 / 6%)"),
            Map.entry("--shadow-md", "0 10px 30px -16px rgb(27 26 23 / 22%)"),
            Map.entry("--shadow-lg", "0 34px 70px -34px rgb(27 26 23 / 32%)"),
            Map.entry("--container", "75rem"),
            Map.entry("--motion-fast", "180ms"),
            Map.entry("--motion-base", "350ms"),
            Map.entry("--motion-slow", "800ms"),
            Map.entry("--ease-out", "cubic-bezier(0.22, 0.61, 0.36, 1)")
        );
    }

    private static Map<String, String> getThemeVariables() {
        return Map.of(
            "--color-bg", "--bg",
            "--color-surface", "--surface",
            "--color-surface-2", "--surface-2",
            "--color-ink", "--ink",
            "--color-ink-2", "--ink-2",
            "--color-muted", "--muted",
            "--color-line", "--line",
            "--color-line-strong", "--line-strong",
            "--color-accent", "--accent",
            "--color-accent-2", "--accent-2",
            "--color-accent-3", "--accent-3",
            "--font-display", "--font-display",
            "--font-sans", "--font-sans",
            "--font-mono", "--font-mono"
        );
    }
}
