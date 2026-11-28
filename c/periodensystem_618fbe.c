// abstraction-provenance: {"artifact_sha256": "728059e50e9b67a0ceddf53999462c460bcee58dd5ac8717c820528fe20eec16", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "c"}
// periodensystem.css — portiert nach c
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    const char* selector;
    const char* properties;
} CSSRule;

typedef struct {
    const char* name;
    const char* light_value;
    const char* dark_value;
} CSSVariable;

void write_css_rule(FILE* file, const char* selector, const char* properties) {
    fprintf(file, "%s { %s }\n", selector, properties);
}

void write_css_variable_rule(FILE* file, const char* selector, const CSSVariable* variables, int count, int is_dark) {
    fprintf(file, "%s {\n", selector);
    for (int i = 0; i < count; i++) {
        fprintf(file, "  %s: %s;\n", variables[i].name, is_dark ? variables[i].dark_value : variables[i].light_value);
    }
    fprintf(file, "}\n");
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_file>\n", argv[0]);
        return 1;
    }

    FILE* file = fopen(argv[1], "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    // Write comments
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* periodensystem.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

    // Base styles
    write_css_rule(file, "*", "box-sizing: border-box; margin: 0; padding: 0;");
    
    // CSS Variables
    CSSVariable variables[] = {
        {"--bg", "#fafaf7", "#1a1a1a"},
        {"--surface", "#ffffff", "#242424"},
        {"--border", "rgba(0,0,0,0.12)", "rgba(255,255,255,0.15)"},
        {"--text", "#1a1a1a", "#f0f0f0"},
        {"--text-muted", "#666", "#aaa"}
    };
    
    write_css_variable_rule(file, ":root", variables, 5, 0);
    fprintf(file, "@media (prefers-color-scheme: dark) {\n");
    write_css_variable_rule(file, "  :root", variables, 5, 1);
    fprintf(file, "}\n");

    // Body styles
    write_css_rule(file, "body", "font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif; background: var(--bg); color: var(--text); padding: 24px; max-width: 1100px; margin: 0 auto; line-height: 1.5;");
    write_css_rule(file, "h1", "font-size: 22px; font-weight: 500; margin-bottom: 4px;");
    write_css_rule(file, ".subtitle", "color: var(--text-muted); font-size: 14px; margin-bottom: 20px;");
    write_css_rule(file, ".detail", "background: var(--surface); border: 1px solid var(--border); border-radius: 12px; padding: 16px 20px; min-height: 110px; display: flex; align-items: center; gap: 20px; margin-bottom: 16px;");
    write_css_rule(file, ".detail-empty", "color: var(--text-muted); font-size: 14px; text-align: center; width: 100%;");
    write_css_rule(file, ".symbol-box", "font-size: 40px; font-weight: 500; line-height: 1; width: 80px; height: 80px; display: flex; align-items: center; justify-content: center; border-radius: 8px; flex-shrink: 0;");
    write_css_rule(file, ".info-name", "font-size: 20px; font-weight: 500; margin-bottom: 8px;");
    write_css_rule(file, ".info-meta", "font-size: 13px; color: var(--text-muted); display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 4px 24px;");
    write_css_rule(file, ".info-meta b", "font-weight: 500; color: var(--text); margin-left: 6px;");
    write_css_rule(file, ".grid", "display: grid; grid-template-columns: repeat(18, minmax(0, 1fr)); gap: 3px;");
    write_css_rule(file, ".fgrid", "margin-top: 8px;");
    write_css_rule(file, ".cell", "aspect-ratio: 1; border-radius: 4px; padding: 3px; display: flex; flex-direction: column; align-items: center; justify-content: center; cursor: pointer; font-family: inherit; line-height: 1; transition: transform 0.12s ease; border: 0; position: relative; overflow: hidden;");
    write_css_rule(file, ".cell:hover", "transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15);");
    write_css_rule(file, ".cell:focus-visible", "outline: 2px solid var(--text); outline-offset: 1px;");
    write_css_rule(file, ".cell.active", "outline: 2px solid var(--text); outline-offset: 1px; z-index: 4;");
    write_css_rule(file, ".cell .num", "font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px;");
    write_css_rule(file, ".cell .sym", "font-size: 14px; font-weight: 500; margin-top: 2px;");
    write_css_rule(file, ".cell-marker", "cursor: default; font-size: 9px; font-weight: 500; border: 1px dashed currentColor; background: transparent !important;");
    write_css_rule(file, ".cell-marker:hover", "transform: none; box-shadow: none;");

    // Category colors - Light
    write_css_rule(file, ".cat-am", "background: #FCEBEB; color: #501313;");
    write_css_rule(file, ".cat-em", "background: #FAEEDA; color: #412402;");
    write_css_rule(file, ".cat-tm", "background: #E6F1FB; color: #042C53;");
    write_css_rule(file, ".cat-ptm", "background: #F1EFE8; color: #2C2C2A;");
    write_css_rule(file, ".cat-hm", "background: #E1F5EE; color: #04342C;");
    write_css_rule(file, ".cat-nm", "background: #EAF3DE; color: #173404;");
    write_css_rule(file, ".cat-h", "background: #EEEDFE; color: #26215C;");
    write_css_rule(file, ".cat-eg", "background: #FBEAF0; color: #4B1528;");
    write_css_rule(file, ".cat-la", "background: #FAECE7; color: #4A1B0C;");
    write_css_rule(file, ".cat-ac", "background: #F5C4B3; color: #4A1B0C;");

    // Category colors - Dark
    fprintf(file, "@media (prefers-color-scheme: dark) {\n");
    write_css_rule(file, "  .cat-am", "background: #791F1F; color: #F7C1C1;");
    write_css_rule(file, "  .cat-em", "background: #633806; color: #FAC775;");
    write_css_rule(file, "  .cat-tm", "background: #0C447C; color: #B5D4F4;");
    write_css_rule(file, "  .cat-ptm", "background: #444441; color: #D3D1C7;");
    write_css_rule(file, "  .cat-hm", "background: #085041; color: #9FE1CB;");
    write_css_rule(file, "  .cat-nm", "background: #27500A; color: #C0DD97;");
    write_css_rule(file, "  .cat-h", "background: #3C3489; color: #CECBF6;");
    write_css_rule(file, "  .cat-eg", "background: #72243E; color: #F4C0D1;");
    write_css_rule(file, "  .cat-la", "background: #712B13; color: #F5C4B3;");
    write_css_rule(file, "  .cat-ac", "background: #993C1D; color: #F5C4B3;");
    fprintf(file, "}\n");

    // Legend
    write_css_rule(file, ".legend", "display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 8px 16px; margin-top: 24px; font-size: 12px; color: var(--text-muted);");
    write_css_rule(file, ".legend-item", "display: flex; align-items: center; gap: 8px;");
    write_css_rule(file, ".legend-swatch", "width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0;");

    fclose(file);
    return 0;
}
