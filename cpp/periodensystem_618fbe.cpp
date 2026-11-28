// abstraction-provenance: {"artifact_sha256": "76a41e1d58da064d9aebefb0c708bde02a52ca8373872877d419e75f8c896dfb", "source_sha256": "618fbec1aa70b1376cdfa3b8809f339c78f591a33e1ef35fb84ee21ffcdc97cf", "target_language": "cpp"}
// periodensystem.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/periodensystem.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_file>" << std::endl;
        return 1;
    }

    std::ofstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << std::endl;
        return 1;
    }

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"57a7240136c3ce381e11df3125a02154266008c65c09f97475511fe273d71a65\", \"source_sha256\": \"dd2fb3ad5bb22a75afbf2a71e58025215a6cba660525d3fa1c6b4ea12fc311fb\", \"target_language\": \"css\"} */\n";
    file << "/* periodensystem.html — portiert nach css */\n";
    file << "/* Quelle: html, Onboarding@main:docs/reference-library/examples/periodensystem.html */\n";
    file << "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << "* { box-sizing: border-box; margin: 0; padding: 0; }\n";
    file << ":root {\n";
    file << "  --bg: #fafaf7;\n";
    file << "  --surface: #ffffff;\n";
    file << "  --border: rgba(0,0,0,0.12);\n";
    file << "  --text: #1a1a1a;\n";
    file << "  --text-muted: #666;\n";
    file << "}\n";
    file << "@media (prefers-color-scheme: dark) {\n";
    file << "  :root {\n";
    file << "    --bg: #1a1a1a;\n";
    file << "    --surface: #242424;\n";
    file << "    --border: rgba(255,255,255,0.15);\n";
    file << "    --text: #f0f0f0;\n";
    file << "    --text-muted: #aaa;\n";
    file << "  }\n";
    file << "}\n";
    file << "body {\n";
    file << "  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "  padding: 24px;\n";
    file << "  max-width: 1100px;\n";
    file << "  margin: 0 auto;\n";
    file << "  line-height: 1.5;\n";
    file << "}\n";
    file << "h1 { font-size: 22px; font-weight: 500; margin-bottom: 4px; }\n";
    file << ".subtitle { color: var(--text-muted); font-size: 14px; margin-bottom: 20px; }\n";
    file << ".detail {\n";
    file << "  background: var(--surface);\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 12px;\n";
    file << "  padding: 16px 20px;\n";
    file << "  min-height: 110px;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 20px;\n";
    file << "  margin-bottom: 16px;\n";
    file << "}\n";
    file << ".detail-empty {\n";
    file << "  color: var(--text-muted);\n";
    file << "  font-size: 14px;\n";
    file << "  text-align: center;\n";
    file << "  width: 100%;\n";
    file << "}\n";
    file << ".symbol-box {\n";
    file << "  font-size: 40px;\n";
    file << "  font-weight: 500;\n";
    file << "  line-height: 1;\n";
    file << "  width: 80px;\n";
    file << "  height: 80px;\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  border-radius: 8px;\n";
    file << "  flex-shrink: 0;\n";
    file << "}\n";
    file << ".info-name { font-size: 20px; font-weight: 500; margin-bottom: 8px; }\n";
    file << ".info-meta {\n";
    file << "  font-size: 13px;\n";
    file << "  color: var(--text-muted);\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(2, minmax(0, 1fr));\n";
    file << "  gap: 4px 24px;\n";
    file << "}\n";
    file << ".info-meta b { font-weight: 500; color: var(--text); margin-left: 6px; }\n";
    file << ".grid {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(18, minmax(0, 1fr));\n";
    file << "  gap: 3px;\n";
    file << "}\n";
    file << ".fgrid { margin-top: 8px; }\n";
    file << ".cell {\n";
    file << "  aspect-ratio: 1;\n";
    file << "  border-radius: 4px;\n";
    file << "  padding: 3px;\n";
    file << "  display: flex;\n";
    file << "  flex-direction: column;\n";
    file << "  align-items: center;\n";
    file << "  justify-content: center;\n";
    file << "  cursor: pointer;\n";
    file << "  font-family: inherit;\n";
    file << "  line-height: 1;\n";
    file << "  transition: transform 0.12s ease;\n";
    file << "  border: 0;\n";
    file << "  position: relative;\n";
    file << "  overflow: hidden;\n";
    file << "}\n";
    file << ".cell:hover { transform: scale(1.18); z-index: 5; box-shadow: 0 2px 8px rgba(0,0,0,0.15); }\n";
    file << ".cell:focus-visible { outline: 2px solid var(--text); outline-offset: 1px; }\n";
    file << ".cell.active { outline: 2px solid var(--text); outline-offset: 1px; z-index: 4; }\n";
    file << ".cell .num { font-size: 9px; opacity: 0.75; align-self: flex-start; line-height: 1; padding-left: 2px; }\n";
    file << ".cell .sym { font-size: 14px; font-weight: 500; margin-top: 2px; }\n";
    file << ".cell-marker {\n";
    file << "  cursor: default;\n";
    file << "  font-size: 9px;\n";
    file << "  font-weight: 500;\n";
    file << "  border: 1px dashed currentColor;\n";
    file << "  background: transparent !important;\n";
    file << "}\n";
    file << ".cell-marker:hover { transform: none; box-shadow: none; }\n";
    file << ".cat-am { background: #FCEBEB; color: #501313; }\n";
    file << ".cat-em { background: #FAEEDA; color: #412402; }\n";
    file << ".cat-tm { background: #E6F1FB; color: #042C53; }\n";
    file << ".cat-ptm { background: #F1EFE8; color: #2C2C2A; }\n";
    file << ".cat-hm { background: #E1F5EE; color: #04342C; }\n";
    file << ".cat-nm { background: #EAF3DE; color: #173404; }\n";
    file << ".cat-h { background: #EEEDFE; color: #26215C; }\n";
    file << ".cat-eg { background: #FBEAF0; color: #4B1528; }\n";
    file << ".cat-la { background: #FAECE7; color: #4A1B0C; }\n";
    file << ".cat-ac { background: #F5C4B3; color: #4A1B0C; }\n";
    file << "@media (prefers-color-scheme: dark) {\n";
    file << "  .cat-am { background: #791F1F; color: #F7C1C1; }\n";
    file << "  .cat-em { background: #633806; color: #FAC775; }\n";
    file << "  .cat-tm { background: #0C447C; color: #B5D4F4; }\n";
    file << "  .cat-ptm { background: #444441; color: #D3D1C7; }\n";
    file << "  .cat-hm { background: #085041; color: #9FE1CB; }\n";
    file << "  .cat-nm { background: #27500A; color: #C0DD97; }\n";
    file << "  .cat-h { background: #3C3489; color: #CECBF6; }\n";
    file << "  .cat-eg { background: #72243E; color: #F4C0D1; }\n";
    file << "  .cat-la { background: #712B13; color: #F5C4B3; }\n";
    file << "  .cat-ac { background: #993C1D; color: #F5C4B3; }\n";
    file << "}\n";
    file << ".legend {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));\n";
    file << "  gap: 8px 16px;\n";
    file << "  margin-top: 24px;\n";
    file << "  font-size: 12px;\n";
    file << "  color: var(--text-muted);\n";
    file << "}\n";
    file << ".legend-item { display: flex; align-items: center; gap: 8px; }\n";
    file << ".legend-swatch { width: 14px; height: 14px; border-radius: 3px; flex-shrink: 0; }\n";

    file.close();
    return 0;
}
