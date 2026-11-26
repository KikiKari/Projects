// abstraction-provenance: {"artifact_sha256": "5b20a18620ed2cdea1865d1952d5ceda5b70e6d7a47129536750ca190ccee165", "source_sha256": "dbaea8c95e59c0899e7e4b8d3cced26cf954364749b998f1841e8d3d5f745baf", "target_language": "cpp"}
// architecture3d.css — portiert nach cpp
// Quelle: css, Projects@TikTok-Live-Companion:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-Android:site/src/architecture3d.css
// auch in: Projects@TikTok-Live-Companion-iOS:site/src/architecture3d.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/src/architecture3d.css
// auch in: 1 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>

class CSSGenerator {
private:
    std::map<std::string, std::map<std::string, std::string>> rules;
    std::vector<std::pair<std::string, std::map<std::string, std::string>>> mediaRules;

public:
    void addRule(const std::string& selector, const std::map<std::string, std::string>& properties) {
        rules[selector] = properties;
    }

    void addMediaRule(const std::string& mediaQuery, const std::map<std::string, std::map<std::string, std::string>>& mediaRulesMap) {
        for (const auto& rule : mediaRulesMap) {
            std::map<std::string, std::string> ruleCopy = rule.second;
            mediaRules.push_back({mediaQuery + "||" + rule.first, ruleCopy});
        }
    }

    std::string generateCSS() {
        std::string css = ":root { color-scheme: light; }\n";
        
        for (const auto& rule : rules) {
            css += rule.first + " { ";
            for (const auto& prop : rule.second) {
                css += prop.first + ": " + prop.second + "; ";
            }
            css += "}\n";
        }
        
        for (const auto& mediaRule : mediaRules) {
            size_t pos = mediaRule.first.find("||");
            std::string mediaQuery = mediaRule.first.substr(0, pos);
            std::string selector = mediaRule.first.substr(pos + 2);
            
            css += mediaQuery + " {\n";
            css += "  " + selector + " { ";
            for (const auto& prop : mediaRule.second) {
                css += prop.first + ": " + prop.second + "; ";
            }
            css += "}\n";
            css += "}\n";
        }
        
        return css;
    }
};

std::string generateArchitecture3DCSS() {
    CSSGenerator generator;
    
    // Main rules
    generator.addRule(".architecture-3d-page", {
        {"min-height", "100vh"},
        {"overflow-x", "hidden"},
        {"background", "#fffdf9"},
        {"color", "#14223c"},
        {"padding-bottom", "48px"}
    });
    
    generator.addRule(".architecture-3d-header", {
        {"min-height", "70px"},
        {"display", "flex"},
        {"align-items", "center"},
        {"justify-content", "space-between"},
        {"gap", "20px"},
        {"padding", "12px max(22px, calc((100vw - 1240px)/2))"},
        {"border-bottom", "1px solid #d9e2ec"},
        {"background", "rgba(255,253,249,.96)"}
    });
    
    generator.addRule(".architecture-3d-header a", {
        {"color", "#14223c"},
        {"text-decoration", "none"},
        {"font-weight", "800"}
    });
    
    generator.addRule(".architecture-3d-header b", {
        {"color", "#e5384f"}
    });
    
    generator.addRule(".architecture-3d-header nav", {
        {"display", "flex"},
        {"gap", "20px"}
    });
    
    generator.addRule(".architecture-3d-intro, .architecture-3d-workspace, .architecture-3d-legend, .architecture-3d-note", {
        {"width", "min(1240px, calc(100% - 36px))"},
        {"margin-inline", "auto"}
    });
    
    generator.addRule(".architecture-3d-intro", {
        {"padding", "54px 0 26px"}
    });
    
    generator.addRule(".architecture-3d-intro h1", {
        {"margin", "5px 0 15px"},
        {"font-size", "clamp(2.35rem, 5vw, 4.3rem)"},
        {"line-height", "1.02"},
        {"letter-spacing", "-.05em"}
    });
    
    generator.addRule(".architecture-3d-intro > p:last-child", {
        {"max-width", "820px"},
        {"color", "#526078"},
        {"font-size", "1.05rem"},
        {"line-height", "1.7"}
    });
    
    generator.addRule(".architecture-3d-eyebrow", {
        {"margin", "0"},
        {"color", "#0c8f9d"},
        {"font-size", ".73rem"},
        {"font-weight", "900"},
        {"letter-spacing", ".14em"}
    });
    
    generator.addRule(".architecture-3d-workspace", {
        {"display", "grid"},
        {"grid-template-columns", "minmax(0, 1fr) 290px"},
        {"gap", "18px"}
    });
    
    generator.addRule(".architecture-3d-scene-shell", {
        {"min-height", "650px"},
        {"position", "relative"},
        {"overflow", "hidden"},
        {"border-radius", "16px"},
        {"background", "#0f1729"},
        {"box-shadow", "0 20px 55px rgba(16,29,52,.22)"}
    });
    
    generator.addRule(".architecture-3d-scene", {
        {"position", "absolute"},
        {"inset", "0"},
        {"opacity", "0"},
        {"transition", "opacity .18s ease"},
        {"touch-action", "pan-y"}
    });
    
    generator.addRule(".architecture-3d-scene.is-ready", {
        {"opacity", "1"}
    });
    
    generator.addRule(".architecture-3d-scene canvas", {
        {"display", "block"},
        {"width", "100%"},
        {"height", "100%"}
    });
    
    generator.addRule(".architecture-3d-scene:focus-visible", {
        {"outline", "3px solid #25c5d2"},
        {"outline-offset", "-5px"}
    });
    
    generator.addRule(".architecture-3d-fallback", {
        {"position", "absolute"},
        {"inset", "0"},
        {"width", "100%"},
        {"height", "100%"},
        {"object-fit", "contain"},
        {"background", "#0f1729"}
    });
    
    generator.addRule(".architecture-3d-controls", {
        {"position", "absolute"},
        {"right", "14px"},
        {"top", "14px"},
        {"display", "flex"},
        {"gap", "8px"},
        {"z-index", "4"}
    });
    
    generator.addRule(".architecture-3d-controls button, .architecture-3d-step button", {
        {"min-height", "44px"},
        {"border", "1px solid #60708a"},
        {"border-radius", "9px"},
        {"background", "rgba(15,23,41,.88)"},
        {"color", "white"},
        {"padding", "9px 13px"},
        {"font-weight", "800"},
        {"cursor", "pointer"}
    });
    
    generator.addRule(".architecture-3d-inspector", {
        {"align-self", "stretch"},
        {"padding", "24px"},
        {"border", "1px solid #d4dee8"},
        {"border-radius", "16px"},
        {"background", "white"}
    });
    
    generator.addRule(".architecture-3d-inspector h2", {
        {"margin", "9px 0"},
        {"font-size", "1.45rem"}
    });
    
    generator.addRule(".architecture-3d-inspector > p:not(.architecture-3d-eyebrow)", {
        {"color", "#526078"},
        {"min-height", "48px"}
    });
    
    generator.addRule(".architecture-3d-inspector dl", {
        {"margin", "25px 0"}
    });
    
    generator.addRule(".architecture-3d-inspector dl div", {
        {"padding", "12px 0"},
        {"border-bottom", "1px solid #e2e8f0"}
    });
    
    generator.addRule(".architecture-3d-inspector dt", {
        {"color", "#758198"},
        {"font-size", ".74rem"},
        {"text-transform", "uppercase"},
        {"letter-spacing", ".08em"}
    });
    
    generator.addRule(".architecture-3d-inspector dd", {
        {"margin", "4px 0 0"},
        {"font-weight", "800"},
        {"overflow-wrap", "anywhere"}
    });
    
    generator.addRule(".architecture-3d-step", {
        {"display", "grid"},
        {"grid-template-columns", "1fr 1fr"},
        {"gap", "8px"}
    });
    
    generator.addRule(".architecture-3d-step button", {
        {"background", "#14223c"}
    });
    
    generator.addRule(".architecture-3d-legend", {
        {"display", "flex"},
        {"flex-wrap", "wrap"},
        {"gap", "24px"},
        {"padding", "23px 0 10px"}
    });
    
    generator.addRule(".architecture-3d-legend span", {
        {"display", "inline-flex"},
        {"align-items", "center"},
        {"gap", "9px"},
        {"font-size", ".85rem"},
        {"font-weight", "750"}
    });
    
    generator.addRule(".architecture-3d-legend i", {
        {"width", "30px"},
        {"height", "4px"},
        {"display", "inline-block"},
        {"background", "#25c5d2"}
    });
    
    generator.addRule(".architecture-3d-legend i.audio", {
        {"background", "#ff557a"}
    });
    
    generator.addRule(".architecture-3d-legend i.token", {
        {"background", "repeating-linear-gradient(90deg,#e9a12d 0 7px,transparent 7px 11px)"}
    });
    
    generator.addRule(".architecture-3d-note", {
        {"color", "#66758a"},
        {"font-size", ".82rem"}
    });
    
    // Media queries
    std::map<std::string, std::map<std::string, std::string>> media820Rules;
    media820Rules[".architecture-3d-workspace"] = {{"grid-template-columns", "1fr"}};
    media820Rules[".architecture-3d-scene-shell"] = {{"min-height", "520px"}};
    media820Rules[".architecture-3d-inspector"] = {{"order", "2"}};
    generator.addMediaRule("@media (max-width: 820px)", media820Rules);
    
    std::map<std::string, std::map<std::string, std::string>> media520Rules;
    media520Rules[".architecture-3d-header"] = {
        {"padding-inline", "16px"},
        {"gap", "8px"},
        {"font-size", ".82rem"}
    };
    media520Rules[".architecture-3d-header nav"] = {{"gap", "10px"}};
    media520Rules[".architecture-3d-intro"] = {{"padding-top", "35px"}};
    media520Rules[".architecture-3d-intro h1"] = {
        {"font-size", "clamp(2rem, 10vw, 2.75rem)"},
        {"overflow-wrap", "anywhere"}
    };
    media520Rules[".architecture-3d-intro > p:last-child"] = {{"overflow-wrap", "anywhere"}};
    media520Rules[".architecture-3d-scene-shell"] = {{"min-height", "460px"}};
    media520Rules[".architecture-3d-controls"] = {
        {"left", "10px"},
        {"right", "10px"},
        {"justify-content", "space-between"}
    };
    media520Rules[".architecture-3d-controls button"] = {
        {"min-width", "44px"},
        {"padding-inline", "8px"},
        {"font-size", ".77rem"}
    };
    media520Rules[".architecture-3d-legend"] = {
        {"display", "grid"},
        {"gap", "12px"}
    };
    generator.addMediaRule("@media (max-width: 520px)", media520Rules);
    
    // Reduced motion media query
    std::map<std::string, std::map<std::string, std::string>> reducedMotionRules;
    reducedMotionRules[".architecture-3d-scene"] = {{"transition", "none"}};
    generator.addMediaRule("@media (prefers-reduced-motion: reduce)", reducedMotionRules);
    
    return generator.generateCSS();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output_file>" << std::endl;
        return 1;
    }
    
    std::string cssContent = generateArchitecture3DCSS();
    
    std::ofstream outputFile(argv[1]);
    if (!outputFile.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << " for writing." << std::endl;
        return 1;
    }
    
    outputFile << cssContent;
    outputFile.close();
    
    std::cout << "CSS file generated successfully: " << argv[1] << std::endl;
    
    return 0;
}
