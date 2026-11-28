// abstraction-provenance: {"artifact_sha256": "966e4d9a8d01201a4ca5ac6f44dd4006a8fe983af82e3500b34066b25533dc84", "source_sha256": "638dc60323e7b18098ef0f5b3cef4b90dd9bb4ffeca2fdedb49c5b2aebbe59c3", "target_language": "c"}
// popup.css — portiert nach c
// Quelle: css, Projects@abstractions:css/popup.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void write_css_content(FILE *file) {
    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"9a98ca6b7904c136087b8d4d69db570323e127c17f3231983fad5ab0ede46fb9\", \"source_sha256\": \"460df65e46318ad1986c44053aeaeda0d4be58e1787c4233154a42f92badec94\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* popup.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n");
    
    fprintf(file, ":root {\n");
    fprintf(file, "  --bg: #0f1115;\n");
    fprintf(file, "  --card: #171a21;\n");
    fprintf(file, "  --line: #262b36;\n");
    fprintf(file, "  --text: #f2f4f8;\n");
    fprintf(file, "  --muted: #9aa3b2;\n");
    fprintf(file, "  --accent: #fe2c55;\n");
    fprintf(file, "  --ok: #22c55e;\n");
    fprintf(file, "  color-scheme: dark;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "@media (prefers-color-scheme: light) {\n");
    fprintf(file, "  :root {\n");
    fprintf(file, "    --bg: #fff;\n");
    fprintf(file, "    --card: #f6f7f9;\n");
    fprintf(file, "    --line: #e3e6ea;\n");
    fprintf(file, "    --text: #16191d;\n");
    fprintf(file, "    --muted: #6b7280;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "* {\n");
    fprintf(file, "  box-sizing: border-box;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "body {\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  width: 420px;\n");
    fprintf(file, "  max-height: 600px;\n");
    fprintf(file, "  overflow: auto;\n");
    fprintf(file, "  background: var(--bg);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  font: 14px/1.45 -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".wrap {\n");
    fprintf(file, "  padding: 12px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "header {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  margin-bottom: 10px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "h1 {\n");
    fprintf(file, "  font-size: 14px;\n");
    fprintf(file, "  margin: 0;\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".badge {\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  font-weight: 700;\n");
    fprintf(file, "  padding: 3px 9px;\n");
    fprintf(file, "  border-radius: 99px;\n");
    fprintf(file, "  background: #2a2f3a;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  display: inline-flex;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  gap: 5px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".badge.live {\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".badge .dot {\n");
    fprintf(file, "  width: 6px;\n");
    fprintf(file, "  height: 6px;\n");
    fprintf(file, "  border-radius: 50%%;\n");
    fprintf(file, "  background: currentColor;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".badge.live .dot {\n");
    fprintf(file, "  animation: pulse 1.6s infinite;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "@keyframes pulse {\n");
    fprintf(file, "  0%%, 100%% {\n");
    fprintf(file, "    opacity: 1;\n");
    fprintf(file, "  }\n");
    fprintf(file, "  50%% {\n");
    fprintf(file, "    opacity: .25;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".row {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 6px;\n");
    fprintf(file, "  flex-wrap: wrap;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  margin-bottom: 8px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "input, select, button {\n");
    fprintf(file, "  font: inherit;\n");
    fprintf(file, "  border-radius: 7px;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  background: var(--card);\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  padding: 6px 9px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button {\n");
    fprintf(file, "  cursor: pointer;\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "button.primary {\n");
    fprintf(file, "  background: var(--accent);\n");
    fprintf(file, "  border-color: var(--accent);\n");
    fprintf(file, "  color: #fff;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".player {\n");
    fprintf(file, "  position: relative;\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  aspect-ratio: 9/16;\n");
    fprintf(file, "  max-height: 360px;\n");
    fprintf(file, "  background: #000;\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  margin: 8px 0;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".player iframe {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  width: 100%%;\n");
    fprintf(file, "  height: 100%%;\n");
    fprintf(file, "  border: 0;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".placeholder {\n");
    fprintf(file, "  position: absolute;\n");
    fprintf(file, "  inset: 0;\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  flex-direction: column;\n");
    fprintf(file, "  gap: 6px;\n");
    fprintf(file, "  align-items: center;\n");
    fprintf(file, "  justify-content: center;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  text-align: center;\n");
    fprintf(file, "  padding: 16px;\n");
    fprintf(file, "  font-size: 13px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".card {\n");
    fprintf(file, "  background: var(--card);\n");
    fprintf(file, "  border: 1px solid var(--line);\n");
    fprintf(file, "  border-radius: 10px;\n");
    fprintf(file, "  padding: 10px 12px;\n");
    fprintf(file, "  margin-bottom: 8px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "h2 {\n");
    fprintf(file, "  font-size: 11px;\n");
    fprintf(file, "  text-transform: uppercase;\n");
    fprintf(file, "  letter-spacing: .05em;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  margin: 0 0 6px;\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".meta {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  font-size: 12.5px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".strong {\n");
    fprintf(file, "  color: var(--text);\n");
    fprintf(file, "  font-weight: 600;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".stream {\n");
    fprintf(file, "  display: flex;\n");
    fprintf(file, "  gap: 8px;\n");
    fprintf(file, "  padding: 5px 0;\n");
    fprintf(file, "  border-bottom: 1px solid var(--line);\n");
    fprintf(file, "  font-size: 12.5px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".stream:last-child {\n");
    fprintf(file, "  border-bottom: 0;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".stream .when {\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  white-space: nowrap;\n");
    fprintf(file, "  font-variant-numeric: tabular-nums;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".stream .t {\n");
    fprintf(file, "  flex: 1;\n");
    fprintf(file, "  min-width: 0;\n");
    fprintf(file, "  overflow: hidden;\n");
    fprintf(file, "  text-overflow: ellipsis;\n");
    fprintf(file, "  white-space: nowrap;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".stream.now {\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "  font-weight: 650;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".err {\n");
    fprintf(file, "  background: #3a1d22;\n");
    fprintf(file, "  border: 1px solid #5c2a33;\n");
    fprintf(file, "  color: #ffb4c0;\n");
    fprintf(file, "  padding: 8px 10px;\n");
    fprintf(file, "  border-radius: 8px;\n");
    fprintf(file, "  font-size: 12.5px;\n");
    fprintf(file, "  margin-bottom: 8px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "@media (prefers-color-scheme: light) {\n");
    fprintf(file, "  .err {\n");
    fprintf(file, "    background: #fdeceb;\n");
    fprintf(file, "    border-color: #f5c6c2;\n");
    fprintf(file, "    color: #b91c1c;\n");
    fprintf(file, "  }\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, ".note {\n");
    fprintf(file, "  font-size: 11.5px;\n");
    fprintf(file, "  color: var(--muted);\n");
    fprintf(file, "  line-height: 1.4;\n");
    fprintf(file, "  margin-top: 8px;\n");
    fprintf(file, "}\n\n");
    
    fprintf(file, "a {\n");
    fprintf(file, "  color: var(--accent);\n");
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Verwendung: %s <dateiname>\n", argv[0]);
        return 1;
    }
    
    FILE *file = fopen(argv[1], "w");
    if (!file) {
        perror("Fehler beim Öffnen der Datei");
        return 1;
    }
    
    write_css_content(file);
    
    fclose(file);
    return 0;
}
