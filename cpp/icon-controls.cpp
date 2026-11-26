// abstraction-provenance: {"artifact_sha256": "31569700f60199a449d387619606f4f5fd43b94f6aae2ece0d3c3158627c2d2a", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "cpp"}
// icon-controls.css — portiert nach cpp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>

class CSSGenerator {
private:
    struct IconStyle {
        std::string name;
        std::string path;
    };
    
    std::vector<IconStyle> styles = {
        {"plastisch", "plastisch"},
        {"glass", "glass"},
        {"linear", "linear"}
    };
    
    std::vector<std::string> iconNames = {
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
        "volume-slider"
    };

public:
    void generateCSS(std::ostream& out) {
        // Generate style-specific rules
        for (const auto& style : styles) {
            out << "html[data-icon-style=\"" << style.name << "\"] {";
            for (const auto& icon : iconNames) {
                out << "--icon-" << icon << ":url(\"icons/" << style.path << "/" << icon << ".png\");";
            }
            out << "}\n";
        }
        
        // Generate generic CSS rules
        out << "button[data-control-icon]::before,.control-icon::before { content:\"\"; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }\n";
        out << "button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }\n";
        out << "button[data-control-icon][hidden] { display:none; }\n";
        out << "input[type=\"checkbox\"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }\n";
        out << "input[type=\"checkbox\"]:checked { background-image:var(--icon-on); }\n";
        out << "input[type=\"checkbox\"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }\n";
        out << "input[type=\"checkbox\"]:disabled { opacity:.45; cursor:default; }\n";
        out << ".control-icon { display:inline-flex; align-items:center; }\n";
        out << "input[type=\"range\"] { min-height:32px; }\n";
        out << ".icon-style-setting { display:flex; align-items:center; gap:8px; }\n\n";
        
        // Generate icon-specific CSS variables
        for (const auto& icon : iconNames) {
            out << "[data-control-icon=\"" << icon << "\"] { --control-icon:var(--icon-" << icon << "); }\n";
        }
    }
};

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>\n";
        return 1;
    }
    
    std::ofstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << " for writing\n";
        return 1;
    }
    
    CSSGenerator generator;
    generator.generateCSS(file);
    
    file.close();
    return 0;
}
