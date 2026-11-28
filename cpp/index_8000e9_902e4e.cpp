// abstraction-provenance: {"artifact_sha256": "347cdb03526580dfb3770c8421431b570626f0e12a7089c868f1f5f0f1a2ddb6", "source_sha256": "902e4e6fa157d8f76bb20b7b21eb51af1e266f087317cd16510ad7f701088c8a", "target_language": "cpp"}
// index_8000e9.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_8000e9.css
// Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

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
        variables["--bg"] = "#FAF8F4";
        variables["--ink"] = "#1B1A17";
        variables["--accent"] = "#A8542F";
        variables["--accent-2"] = "#2E7D7B";
        variables["--font-display"] = "'Newsreader', Georgia, serif";
        variables["--font-body"] = "'Hanken Grotesk', -apple-system, sans-serif";
        variables["--font-mono"] = "'JetBrains Mono', monospace";
    }
    
    std::string getVariable(const std::string& varName) {
        auto it = variables.find(varName);
        if (it != variables.end()) {
            return it->second;
        }
        return varName;
    }
    
    std::string generateCSS() {
        std::string css = "";
        
        // Add comments
        css += "/* abstraction-provenance: {\"artifact_sha256\": \"50aebf2d1d10e4ad074a50e2b0bd451a6c86206ca6d2a94a111305552465c90c\", \"source_sha256\": \"8000e9809d37f9906f93defd5eae67343fbc40139349c6251ff385eeee2cb8fb\", \"target_language\": \"css\"} */\n";
        css += "/* index.html — portiert nach css */\n";
        css += "/* Quelle: html, Onboarding@main:development/preview-renders/hover-mock/index.html */\n";
        css += "/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */\n\n";
        
        // Root variables
        css += ":root {\n";
        for (const auto& pair : variables) {
            css += "  " + pair.first + ": " + pair.second + ";\n";
        }
        css += "}\n\n";
        
        // Universal selector
        css += "* {\n";
        css += "  box-sizing: border-box;\n";
        css += "  margin: 0;\n";
        css += "  padding: 0;\n";
        css += "}\n\n";
        
        // Body styles
        css += "body {\n";
        css += "  font-family: " + getVariable("--font-body") + ";\n";
        css += "  background: " + getVariable("--bg") + ";\n";
        css += "  color: " + getVariable("--ink") + ";\n";
        css += "  padding: 32px 16px 80px;\n";
        css += "}\n\n";
        
        // Heading styles
        css += "h1 {\n";
        css += "  font-family: " + getVariable("--font-display") + ";\n";
        css += "  font-weight: 500;\n";
        css += "  font-size: 28px;\n";
        css += "  max-width: 1400px;\n";
        css += "  margin: 0 auto 12px;\n";
        css += "}\n\n";
        
        // Intro styles
        css += ".intro {\n";
        css += "  max-width: 1400px;\n";
        css += "  margin: 0 auto 32px;\n";
        css += "  color: #666;\n";
        css += "  font-size: 14px;\n";
        css += "  line-height: 1.5;\n";
        css += "}\n\n";
        
        // Grid styles
        css += ".grid {\n";
        css += "  display: grid;\n";
        css += "  gap: 32px;\n";
        css += "  max-width: 1400px;\n";
        css += "  margin: 0 auto;\n";
        css += "}\n\n";
        
        // Variant styles
        css += ".variant {\n";
        css += "  background: #000;\n";
        css += "  border-radius: 16px;\n";
        css += "  overflow: hidden;\n";
        css += "  box-shadow: 0 12px 40px rgba(0,0,0,0.15);\n";
        css += "}\n\n";
        
        css += ".variant-header {\n";
        css += "  background: #fff;\n";
        css += "  padding: 16px 24px;\n";
        css += "  display: flex;\n";
        css += "  align-items: center;\n";
        css += "  justify-content: space-between;\n";
        css += "  gap: 16px;\n";
        css += "  border-bottom: 1px solid #eee;\n";
        css += "}\n\n";
        
        css += ".variant-label {\n";
        css += "  font-family: " + getVariable("--font-mono") + ";\n";
        css += "  font-size: 11px;\n";
        css += "  letter-spacing: 0.2em;\n";
        css += "  text-transform: uppercase;\n";
        css += "  color: " + getVariable("--accent") + ";\n";
        css += "  font-weight: 600;\n";
        css += "}\n\n";
        
        css += ".variant-title {\n";
        css += "  font-family: " + getVariable("--font-display") + ";\n";
        css += "  font-size: 20px;\n";
        css += "  font-weight: 500;\n";
        css += "}\n\n";
        
        css += ".variant-desc {\n";
        css += "  font-size: 13px;\n";
        css += "  color: #666;\n";
        css += "  flex: 1;\n";
        css += "  text-align: right;\n";
        css += "}\n\n";
        
        // Scene styles
        css += ".scene {\n";
        css += "  position: relative;\n";
        css += "  aspect-ratio: 16 / 9;\n";
        css += "  background: url('bg.png') center/cover no-repeat;\n";
        css += "  overflow: hidden;\n";
        css += "}\n\n";
        
        css += ".orb {\n";
        css += "  position: absolute;\n";
        css += "  width: 12%;\n";
        css += "  aspect-ratio: 1;\n";
        css += "  left: 42%;\n";
        css += "  top: 55%;\n";
        css += "  transform: translate(-50%, -50%);\n";
        css += "  cursor: pointer;\n";
        css += "}\n\n";
        
        css += ".orb img {\n";
        css += "  width: 100%;\n";
        css += "  height: 100%;\n";
        css += "  object-fit: contain;\n";
        css += "}\n\n";
        
        // Card preview styles
        css += ".card-preview {\n";
        css += "  position: absolute;\n";
        css += "  left: 55%;\n";
        css += "  top: 45%;\n";
        css += "  background: rgba(255,255,255,0.98);\n";
        css += "  padding: 16px 20px;\n";
        css += "  border-radius: 12px;\n";
        css += "  box-shadow: 0 8px 24px rgba(0,0,0,0.25);\n";
        css += "  width: 240px;\n";
        css += "  animation: slideIn 0.3s ease-out;\n";
        css += "}\n\n";
        
        css += ".card-preview .badge {\n";
        css += "  display: inline-block;\n";
        css += "  background: " + getVariable("--accent-2") + ";\n";
        css += "  color: white;\n";
        css += "  font-family: " + getVariable("--font-mono") + ";\n";
        css += "  font-size: 9px;\n";
        css += "  letter-spacing: 0.15em;\n";
        css += "  text-transform: uppercase;\n";
        css += "  padding: 3px 8px;\n";
        css += "  border-radius: 3px;\n";
        css += "  margin-bottom: 8px;\n";
        css += "}\n\n";
        
        css += ".card-preview h3 {\n";
        css += "  font-family: " + getVariable("--font-display") + ";\n";
        css += "  font-size: 18px;\n";
        css += "  font-weight: 500;\n";
        css += "  margin-bottom: 6px;\n";
        css += "  color: " + getVariable("--ink") + ";\n";
        css += "}\n\n";
        
        css += ".card-preview p {\n";
        css += "  font-size: 12px;\n";
        css += "  color: #555;\n";
        css += "  line-height: 1.4;\n";
        css += "}\n\n";
        
        // SlideIn animation
        css += "@keyframes slideIn {\n";
        css += "  from {\n";
        css += "    opacity: 0;\n";
        css += "    transform: translateX(-8px);\n";
        css += "  }\n";
        css += "  to {\n";
        css += "    opacity: 1;\n";
        css += "    transform: translateX(0);\n";
        css += "  }\n";
        css += "}\n\n";
        
        // Tooltip styles
        css += ".tooltip {\n";
        css += "  position: absolute;\n";
        css += "  left: 42%;\n";
        css += "  top: 46%;\n";
        css += "  transform: translate(-50%, -100%);\n";
        css += "  color: white;\n";
        css += "  text-shadow: 0 2px 12px rgba(0,0,0,0.8);\n";
        css += "  font-family: " + getVariable("--font-display") + ";\n";
        css += "  font-size: 20px;\n";
        css += "  font-weight: 500;\n";
        css += "  white-space: nowrap;\n";
        css += "  animation: fadeUp 0.3s ease-out;\n";
        css += "}\n\n";
        
        // FadeUp animation
        css += "@keyframes fadeUp {\n";
        css += "  from {\n";
        css += "    opacity: 0;\n";
        css += "    transform: translate(-50%, -80%);\n";
        css += "  }\n";
        css += "  to {\n";
        css += "    opacity: 1;\n";
        css += "    transform: translate(-50%, -100%);\n";
        css += "  }\n";
        css += "}\n\n";
        
        // Full overlay styles
        css += ".full-overlay {\n";
        css += "  position: absolute;\n";
        css += "  inset: 0;\n";
        css += "  background: rgba(0,0,0,0.5);\n";
        css += "  backdrop-filter: blur(6px);\n";
        css += "  display: flex;\n";
        css += "  align-items: center;\n";
        css += "  justify-content: center;\n";
        css += "  animation: fadeIn 0.35s ease-out;\n";
        css += "}\n\n";
        
        css += ".full-overlay .panel {\n";
        css += "  background: rgba(255,255,255,0.98);\n";
        css += "  padding: 32px 40px;\n";
        css += "  border-radius: 20px;\n";
        css += "  max-width: 420px;\n";
        css += "  box-shadow: 0 20px 60px rgba(0,0,0,0.4);\n";
        css += "  text-align: center;\n";
        css += "}\n\n";
        
        css += ".full-overlay .badge {\n";
        css += "  display: inline-block;\n";
        css += "  background: " + getVariable("--accent") + ";\n";
        css += "  color: white;\n";
        css += "  font-family: " + getVariable("--font-mono") + ";\n";
        css += "  font-size: 10px;\n";
        css += "  letter-spacing: 0.2em;\n";
        css += "  text-transform: uppercase;\n";
        css += "  padding: 4px 10px;\n";
        css += "  border-radius: 4px;\n";
        css += "  margin-bottom: 14px;\n";
        css += "}\n\n";
        
        css += ".full-overlay h3 {\n";
        css += "  font-family: " + getVariable("--font-display") + ";\n";
        css += "  font-size: 28px;\n";
        css += "  font-weight: 500;\n";
        css += "  margin-bottom: 10px;\n";
        css += "  color: " + getVariable("--ink") + ";\n";
        css += "}\n\n";
        
        css += ".full-overlay p {\n";
        css += "  font-size: 14px;\n";
        css += "  color: #555;\n";
        css += "  line-height: 1.5;\n";
        css += "  margin-bottom: 20px;\n";
        css += "}\n\n";
        
        css += ".full-overlay .preview-img {\n";
        css += "  width: 100%;\n";
        css += "  aspect-ratio: 16/10;\n";
        css += "  background: linear-gradient(135deg, #A8542F, #2E7D7B);\n";
        css += "  border-radius: 8px;\n";
        css += "  margin-bottom: 16px;\n";
        css += "  display: flex;\n";
        css += "  align-items: center;\n";
        css += "  justify-content: center;\n";
        css += "  color: white;\n";
        css += "  font-family: " + getVariable("--font-mono") + ";\n";
        css += "  font-size: 11px;\n";
        css += "  letter-spacing: 0.15em;\n";
        css += "  opacity: 0.9;\n";
        css += "}\n\n";
        
        // FadeIn animation
        css += "@keyframes fadeIn {\n";
        css += "  from {\n";
        css += "    opacity: 0;\n";
        css += "  }\n";
        css += "  to {\n";
        css += "    opacity: 1;\n";
        css += "  }\n";
        css += "}\n\n";
        
        // Instruction styles
        css += ".instruction {\n";
        css += "  text-align: center;\n";
        css += "  color: #999;\n";
        css += "  font-size: 12px;\n";
        css += "  margin-top: 16px;\n";
        css += "  font-family: " + getVariable("--font-mono") + ";\n";
        css += "  letter-spacing: 0.15em;\n";
        css += "  text-transform: uppercase;\n";
        css += "}\n\n";
        
        // Media query
        css += "@media (max-width: 900px) {\n";
        css += "  .card-preview {\n";
        css += "    width: 180px;\n";
        css += "    padding: 12px 14px;\n";
        css += "  }\n";
        css += "  \n";
        css += "  .card-preview h3 {\n";
        css += "    font-size: 15px;\n";
        css += "  }\n";
        css += "  \n";
        css += "  .card-preview p {\n";
        css += "    font-size: 11px;\n";
        css += "  }\n";
        css += "  \n";
        css += "  .tooltip {\n";
        css += "    font-size: 15px;\n";
        css += "  }\n";
        css += "  \n";
        css += "  .full-overlay .panel {\n";
        css += "    padding: 20px 24px;\n";
        css += "    max-width: 300px;\n";
        css += "  }\n";
        css += "  \n";
        css += "  .full-overlay h3 {\n";
        css += "    font-size: 20px;\n";
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
    std::string filename = "index_8000e9.css";
    
    if (argc > 1) {
        filename = argv[1];
    }
    
    CSSGenerator generator;
    generator.writeToFile(filename);
    
    return 0;
}
