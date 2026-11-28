// abstraction-provenance: {"artifact_sha256": "50fa48d6eee5111e0eb05fd66b8b401793fbdcc7b328d9a7a9a94d97c7f1eaff", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "c"}
// index_8000e9.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_8000e9.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Error opening file");
        return;
    }

    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"50aebf2d1d10e4ad074a50e2b0bd451a6c86206ca6d2a94a111305552465c90c\", \"source_sha256\": \"8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #FAF8F4;\n");
    fprintf(file, "  --ink: #1B1A17;\n");
    fprintf(file, "  --accent: #A8542F;\n");
    fprintf(file, "  --accent-2: #2E7D7B;\n");
    fprintf(file, "  --font-display: 'Newsreader', Georgia, serif;\n");
    fprintf(file, "  --font-body: 'Hanken Grotesk', -apple-system, sans-serif;\n");
    fprintf(file, "  --font-mono: 'JetBrains Mono', monospace;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  padding: 0;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "body {\n");
    fprintf(file, "  font-family: var(--font-body);\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "  padding: 32px 16px 80px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "h1 {\n");
    fprintf(file, "  font-family: var(--font-display);\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  font-size: 28px;\n");
    fprintf(file, "  max-width: 1400px;\n");
    fprintf(file, "  margin: 0 auto 12px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".intro {\n");
    fprintf(file, "  max-width: 1400px;\n");
    fprintf(file, "  margin: 0 auto 32px;\n");
    fprintf(file, "  color: #666;\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".grid {\n");
    fprintf(file, "  display: grid;\n");
    fprintf(file, "  gap: 32px;\n");
    fprintf(file, "  max-width: 1400px;\n");
    fprintf(file, "  margin: 0 auto;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".variant {\n");
    fprintf(file, "  background: #000;\n");
    fprintf(file, "  border-radius: 16px;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  box-shadow: 0 12px 40px rgba(0,0,0,0.15);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".variant-header {\n");
    fprintf(file, "  background: #fff;\n");
    fprintf(file, "  padding: 16px 24px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: space-between;\n");
    fprintf(file, "  gap: 16px;\n");
    fprintf(file, "  border-bottom: 1px solid #eee;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".variant-label {\n");
    fprintf(file, "  font-family: var(--font-mono);\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  letter-spacing: 0.2em;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".variant-title {\n");
    fprintf(file, "  font-family: var(--font-display);\n");
    fprintf(file, "  font-size: 20px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".variant-desc {\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "  color: #666;\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  text-align: right;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".scene {\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  aspect-ratio: 16 / 9;\n");
    fprintf(file, "  background: url('bg.png') center/cover no-repeat;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".orb {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  width: 12%%;\n");
    fprintf(file, "  aspect-ratio: 1;\n");
    fprintf(file, "  left: 42%%;\n");
    fprintf(file, "  top: 55%%;\n");
    fprintf(file, "  transform: translate(-50%%, -50%%);\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".orb img {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  height: 100%%;\n");
    fprintf(file, "  object-fit: contain;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Variante 1: Karte daneben */\n");
    fprintf(file, ".card-preview {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  left: 55%%;\n");
    fprintf(file, "  top: 45%%;\n");
    fprintf(file, "  background: rgba(255,255,255,0.98);\n");
    fprintf(file, "  padding: 16px 20px;\n");
    fprintf(file, "  border-radius: 12px;\n");
    fprintf(file, "  box-shadow: 0 8px 24px rgba(0,0,0,0.25);\n");
    fprintf(file, "  width: 240px;\n");
    fprintf(file, "  animation: slideIn 0.3s ease-out;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card-preview .badge {\n");
    fprintf(file, "  display: inline-block;\n");
    fprintf(file, "  background: var(--accent-2);\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "  font-family: var(--font-mono);\n");
    fprintf(file, "  font-size: 9px;\n");
    fprintf(file, "  letter-spacing: 0.15em;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  padding: 3px 8px;\n");
    fprintf(file, "  border-radius: 3px;\n");
    fprintf(file, "  margin-bottom: 8px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card-preview h3 {\n");
    fprintf(file, "  font-family: var(--font-display);\n");
    fprintf(file, "  font-size: 18px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  margin-bottom: 6px;\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".card-preview p {\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  color: #555;\n");
    fprintf(file, "  line-height: 1.4;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@keyframes slideIn {\n");
    fprintf(file, "  from {\n");
    fprintf(file, "    opacity: 0;\n");
    fprintf(file, "    transform: translateX(-8px);\n");
    fprintf(file, "  }\n");
    fprintf(file, "  to {\n");
    fprintf(file, "    opacity: 1;\n");
    fprintf(file, "    transform: translateX(0);\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Variante 2: Minimaler Tooltip */\n");
    fprintf(file, ".tooltip {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  left: 42%%;\n");
    fprintf(file, "  top: 46%%;\n");
    fprintf(file, "  transform: translate(-50%%, -100%%);\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "  text-shadow: 0 2px 12px rgba(0,0,0,0.8);\n");
    fprintf(file, "  font-family: var(--font-display);\n");
    fprintf(file, "  font-size: 20px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  white-space: nowrap;\n");
    fprintf(file, "  animation: fadeUp 0.3s ease-out;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@keyframes fadeUp {\n");
    fprintf(file, "  from {\n");
    fprintf(file, "    opacity: 0;\n");
    fprintf(file, "    transform: translate(-50%%, -80%%);\n");
    fprintf(file, "  }\n");
    fprintf(file, "  to {\n");
    fprintf(file, "    opacity: 1;\n");
    fprintf(file, "    transform: translate(-50%%, -100%%);\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");

    fprintf(file, "/* Variante 3: Vollflächiges Overlay */\n");
    fprintf(file, ".full-overlay {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  background: rgba(0,0,0,0.5);\n");
    fprintf(file, "  backdrop-filter: blur(6px);\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  animation: fadeIn 0.35s ease-out;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".full-overlay .panel {\n");
    fprintf(file, "  background: rgba(255,255,255,0.98);\n");
    fprintf(file, "  padding: 32px 40px;\n");
    fprintf(file, "  border-radius: 20px;\n");
    fprintf(file, "  max-width: 420px;\n");
    fprintf(file, "  box-shadow: 0 20px 60px rgba(0,0,0,0.4);\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".full-overlay .badge {\n");
    fprintf(file, "  display: inline-block;\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "  font-family: var(--font-mono);\n");
    fprintf(file, "  font-size: 10px;\n");
    fprintf(file, "  letter-spacing: 0.2em;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  padding: 4px 10px;\n");
    fprintf(file, "  border-radius: 4px;\n");
    fprintf(file, "  margin-bottom: 14px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".full-overlay h3 {\n");
    fprintf(file, "  font-family: var(--font-display);\n");
    fprintf(file, "  font-size: 28px;\n");
    fprintf(file, "  font-weight: 500;\n");
    fprintf(file, "  margin-bottom: 10px;\n");
    fprintf(file, "  color: var(--ink);\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".full-overlay p {\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  color: #555;\n");
    fprintf(file, "  line-height: 1.5;\n");
    fprintf(file, "  margin-bottom: 20px;\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".full-overlay .preview-img {\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  aspect-ratio: 16/10;\n");
    fprintf(file, "  background: linear-gradient(135deg, #A8542F, #2E7D7B);\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  margin-bottom: 16px;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  color: white;\n");
    fprintf(file, "  font-family: var(--font-mono);\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  letter-spacing: 0.15em;\n");
    fprintf(file, "  opacity: 0.9;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@keyframes fadeIn {\n");
    fprintf(file, "  from {\n");
    fprintf(file, "    opacity: 0;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  to {\n");
    fprintf(file, "    opacity: 1;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");

    fprintf(file, ".instruction {\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "  color: #999;\n");
    fprintf(file, "  font-size: 12px;\n");
    fprintf(file, "  margin-top: 16px;\n");
    fprintf(file, "  font-family: var(--font-mono);\n");
    fprintf(file, "  letter-spacing: 0.15em;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "}\n\n");

    fprintf(file, "@media (max-width: 900px) {\n");
    fprintf(file, "  .card-preview {\n");
    fprintf(file, "    width: 180px;\n");
    fprintf(file, "    padding: 12px 14px;\n");
    fprintf(file, "  }\n\n");
    
    fprintf(file, "  .card-preview h3 {\n");
    fprintf(file, "    font-size: 15px;\n");
    fprintf(file, "  }\n\n");
    
    fprintf(file, "  .card-preview p {\n");
    fprintf(file, "    font-size: 11px;\n");
    fprintf(file, "  }\n\n");
    
    fprintf(file, "  .tooltip {\n");
    fprintf(file, "    font-size: 15px;\n");
    fprintf(file, "  }\n\n");
    
    fprintf(file, "  .full-overlay .panel {\n");
    fprintf(file, "    padding: 20px 24px;\n");
    fprintf(file, "    max-width: 300px;\n");
    fprintf(file, "  }\n\n");
    
    fprintf(file, "  .full-overlay h3 {\n");
    fprintf(file, "    font-size: 20px;\n");
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
