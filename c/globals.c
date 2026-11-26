// abstraction-provenance: {"artifact_sha256": "fd2cf597f9471a58065949fbc1f3e79bc96ca543412795b4f724bbed6e82ed71", "source_sha256": "b88df9f02f19546f5017a166224fb0f62931a65cd0239064afc9de2e7c454027", "target_language": "c"}
// globals.css — portiert nach c
// Quelle: css, Onboarding@main:app/globals.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Structure to hold CSS variable definitions
typedef struct {
    const char* name;
    const char* value;
} CssVariable;

// Structure to hold CSS rules
typedef struct {
    const char* selector;
    const char* properties;
} CssRule;

// Function to write a CSS file from structured data
void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    // Write imports
    fprintf(file, "@import \"tailwindcss\";\n\n");

    // Define variables
    CssVariable root_vars[] = {
        {"--bg", "#faf8f4"},
        {"--surface", "#ffffff"},
        {"--surface-2", "#f1eee7"},
        {"--ink", "#1b1a17"},
        {"--ink-2", "#3c3a34"},
        {"--muted", "#6e6a61"},
        {"--line", "#e5e1d8"},
        {"--line-strong", "#d4cfc3"},
        {"--accent", "#a8542f"},
        {"--accent-press", "#8e4526"},
        {"--accent-tint", "#f1e5dd"},
        {"--on-accent", "#ffffff"},
        {"--accent-2", "#2e7d7b"},
        {"--accent-2-press", "#225e5b"},
        {"--accent-3", "#c77d2e"},
        {"--footer-bg", "#191815"},
        {"--footer-fg", "#efeae0"},
        {"--footer-muted", "#9a958a"},
        {"--success", "#2e7d5b"},
        {"--danger", "#9e3f32"},
        {"--font-display", "\"Iowan Old Style\", \"Palatino Linotype\", Georgia, \"Times New Roman\", serif"},
        {"--font-sans", "\"Segoe UI\", Inter, system-ui, -apple-system, sans-serif"},
        {"--font-mono", "\"Cascadia Code\", \"SFMono-Regular\", Consolas, ui-monospace, monospace"},
        {"--space-1", "0.25rem"},
        {"--space-2", "0.5rem"},
        {"--space-3", "0.75rem"},
        {"--space-4", "1rem"},
        {"--space-5", "1.25rem"},
        {"--space-6", "1.5rem"},
        {"--space-8", "2rem"},
        {"--space-10", "2.5rem"},
        {"--space-12", "3rem"},
        {"--space-16", "4rem"},
        {"--space-20", "5rem"},
        {"--space-24", "6rem"},
        {"--space-30", "7.5rem"},
        {"--radius-sm", "0.375rem"},
        {"--radius-md", "0.625rem"},
        {"--radius-lg", "1.125rem"},
        {"--radius-pill", "999px"},
        {"--shadow-sm", "0 1px 2px rgb(27 26 23 / 6%)"},
        {"--shadow-md", "0 10px 30px -16px rgb(27 26 23 / 22%)"},
        {"--shadow-lg", "0 34px 70px -34px rgb(27 26 23 / 32%)"},
        {"--container", "75rem"},
        {"--motion-fast", "180ms"},
        {"--motion-base", "350ms"},
        {"--motion-slow", "800ms"},
        {"--ease-out", "cubic-bezier(0.22, 0.61, 0.36, 1)"},
        {NULL, NULL}
    };

    // Write :root block
    fprintf(file, ":root {\n");
    for (int i = 0; root_vars[i].name != NULL; i++) {
        fprintf(file, "  %s: %s;\n", root_vars[i].name, root_vars[i].value);
    }
    fprintf(file, "}\n\n");

    // Theme inline variables
    CssVariable theme_vars[] = {
        {"--color-bg", "var(--bg)"},
        {"--color-surface", "var(--surface)"},
        {"--color-surface-2", "var(--surface-2)"},
        {"--color-ink", "var(--ink)"},
        {"--color-ink-2", "var(--ink-2)"},
        {"--color-muted", "var(--muted)"},
        {"--color-line", "var(--line)"},
        {"--color-line-strong", "var(--line-strong)"},
        {"--color-accent", "var(--accent)"},
        {"--color-accent-2", "var(--accent-2)"},
        {"--color-accent-3", "var(--accent-3)"},
        {"--font-display", "var(--font-display)"},
        {"--font-sans", "var(--font-sans)"},
        {"--font-mono", "var(--font-mono)"},
        {NULL, NULL}
    };

    // Write @theme inline block
    fprintf(file, "@theme inline {\n");
    for (int i = 0; theme_vars[i].name != NULL; i++) {
        fprintf(file, "  %s: %s;\n", theme_vars[i].name, theme_vars[i].value);
    }
    fprintf(file, "}\n\n");

    // Basic CSS rules
    CssRule basic_rules[] = {
        {"*", "box-sizing: border-box;"},
        {"html", "scroll-behavior: smooth;"},
        {"body", "margin: 0;\n  background: var(--bg);\n  color: var(--ink);\n  font-family: var(--font-sans);\n  line-height: 1.5;\n  -webkit-font-smoothing: antialiased;"},
        {"a", "color: inherit;"},
        {"button, input, textarea", "font: inherit;"},
        {"::selection", "background: var(--accent-tint); color: var(--ink);"},
        {NULL, NULL}
    };

    // Write basic rules
    for (int i = 0; basic_rules[i].selector != NULL; i++) {
        fprintf(file, "%s { %s }\n", basic_rules[i].selector, basic_rules[i].properties);
    }
    fprintf(file, "\n");

    // Class-specific rules
    CssRule class_rules[] = {
        {".display", "font-family: var(--font-display);\n  font-weight: 400;\n  letter-spacing: -0.022em;"},
        {".eyebrow", "font-family: var(--font-mono);\n  font-size: 0.75rem;\n  letter-spacing: 0.16em;\n  text-transform: uppercase;"},
        {".focus-ring:focus-visible", "outline: 2px solid var(--accent);\n  outline-offset: 4px;"},
        {".content-auto", "content-visibility: auto; contain-intrinsic-size: 1px 800px;"},
        {NULL, NULL}
    };

    // Write class rules
    for (int i = 0; class_rules[i].selector != NULL; i++) {
        fprintf(file, "%s {\n  %s\n}\n", class_rules[i].selector, class_rules[i].properties);
    }
    fprintf(file, "\n");

    // Media query for reduced motion
    fprintf(file, "@media (prefers-reduced-motion: reduce) {\n");
    fprintf(file, "  html { scroll-behavior: auto; }\n");
    fprintf(file, "  *, *::before, *::after {\n");
    fprintf(file, "    animation-duration: 0.01ms !important;\n");
    fprintf(file, "    animation-iteration-count: 1 !important;\n");
    fprintf(file, "    scroll-behavior: auto !important;\n");
    fprintf(file, "    transition-duration: 0.01ms !important;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");

    // Header hiding rules
    fprintf(file, "/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */\n");
    fprintf(file, "body[data-hero-immersive=\"true\"] > header,\n");
    fprintf(file, "body[data-hero-immersive=\"true\"] header[data-site-header] {\n");
    fprintf(file, "  opacity: 0;\n");
    fprintf(file, "  pointer-events: none;\n");
    fprintf(file, "  transition: opacity 0.4s ease-out;\n");
    fprintf(file, "}\n\n");

    // Keyframe animation
    fprintf(file, "/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */\n");
    fprintf(file, "@keyframes dropfall {\n");
    fprintf(file, "  0%% {\n");
    fprintf(file, "    transform: translateY(0);\n");
    fprintf(file, "    opacity: 0;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  10%% {\n");
    fprintf(file, "    opacity: 0.9;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  90%% {\n");
    fprintf(file, "    opacity: 0.7;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  100%% {\n");
    fprintf(file, "    transform: translateY(110vh);\n");
    fprintf(file, "    opacity: 0;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
