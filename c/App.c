// abstraction-provenance: {"artifact_sha256": "8a061df5e5a752ed74ab6375f738134c39c1468cd1be49286edccf142f1f9b65", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "c"}
// App.css — portiert nach c
// Quelle: css, OpenClaw@main:src/App.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_rule(FILE *file, const char *selector, const char *properties) {
    fprintf(file, "%s {\n%s}\n\n", selector, properties);
}

void generate_css_file(const char *filename) {
    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return;
    }

    // Root styles
    write_css_rule(file, ":root", 
        "  color-scheme: dark;\n"
        "  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n"
        "  background: #0b1020;\n"
        "  color: #eef2ff;\n");

    // Universal selector
    write_css_rule(file, "*", "  box-sizing: border-box;\n");

    // Body styles
    write_css_rule(file, "body", 
        "  margin: 0;\n"
        "  min-width: 320px;\n"
        "  min-height: 100vh;\n"
        "  background:\n"
        "    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),\n"
        "    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),\n"
        "    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);\n");

    // Page shell
    write_css_rule(file, ".page-shell", 
        "  min-height: 100vh;\n"
        "  display: grid;\n"
        "  place-items: center;\n"
        "  padding: 2rem;\n");

    // Hero card
    write_css_rule(file, ".hero-card", 
        "  width: min(100%, 56rem);\n"
        "  padding: clamp(2rem, 6vw, 4.5rem);\n"
        "  border: 1px solid rgba(148, 163, 184, 0.28);\n"
        "  border-radius: 2rem;\n"
        "  background: rgba(15, 23, 42, 0.72);\n"
        "  box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35);\n"
        "  backdrop-filter: blur(18px);\n");

    // Eyebrow
    write_css_rule(file, ".eyebrow", 
        "  margin: 0 0 1rem;\n"
        "  color: #67e8f9;\n"
        "  font-size: 0.8rem;\n"
        "  font-weight: 700;\n"
        "  letter-spacing: 0.18em;\n"
        "  text-transform: uppercase;\n");

    // Heading 1
    write_css_rule(file, "h1", 
        "  margin: 0;\n"
        "  max-width: 12ch;\n"
        "  font-size: clamp(2.75rem, 8vw, 6rem);\n"
        "  line-height: 0.95;\n"
        "  letter-spacing: -0.06em;\n");

    // Lead paragraph
    write_css_rule(file, ".lead", 
        "  margin: 1.5rem 0 0;\n"
        "  max-width: 42rem;\n"
        "  color: #cbd5e1;\n"
        "  font-size: clamp(1.05rem, 2vw, 1.35rem);\n"
        "  line-height: 1.65;\n");

    // Link grid container
    write_css_rule(file, ".link-grid", 
        "  display: grid;\n"
        "  gap: 0.85rem;\n"
        "  margin-top: 2rem;\n");

    // Link grid items
    write_css_rule(file, ".link-grid a", 
        "  display: flex;\n"
        "  align-items: center;\n"
        "  justify-content: space-between;\n"
        "  gap: 1rem;\n"
        "  padding: 1rem 1.15rem;\n"
        "  border: 1px solid rgba(148, 163, 184, 0.25);\n"
        "  border-radius: 1rem;\n"
        "  color: #f8fafc;\n"
        "  text-decoration: none;\n"
        "  background: rgba(255, 255, 255, 0.06);\n");

    // Link hover and focus states
    write_css_rule(file, ".link-grid a:hover,\n.link-grid a:focus-visible", 
        "  border-color: rgba(103, 232, 249, 0.75);\n"
        "  outline: none;\n"
        "  background: rgba(103, 232, 249, 0.12);\n");

    fclose(file);
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        printf("Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }

    generate_css_file(argv[1]);
    return 0;
}
