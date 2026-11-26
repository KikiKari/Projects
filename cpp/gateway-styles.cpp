// abstraction-provenance: {"artifact_sha256": "8b391fe117925bc59d0e669fa00ab3d170c236fc52b6874ffd605b4c96e394e5", "source_sha256": "47d390b58fc734629c213c66e58cb7f0c68bbd896bac294215d12289e5e21c07", "target_language": "cpp"}
// gateway-styles.css — portiert nach cpp
// Quelle: css, OpenClaw@main:examples/gateway-styles.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeCSS(std::ofstream& file) {
    file << "/* OpenClaw Gateway Dashboard */\n\n";
    
    file << "*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }\n\n";
    
    file << ":root {\n";
    file << "  --bg:       #0d1117;\n";
    file << "  --surface:  #161b22;\n";
    file << "  --border:   #30363d;\n";
    file << "  --text:     #e6edf3;\n";
    file << "  --muted:    #8b949e;\n";
    file << "  --green:    #3fb950;\n";
    file << "  --yellow:   #d29922;\n";
    file << "  --red:      #f85149;\n";
    file << "  --accent:   #58a6ff;\n";
    file << "}\n\n";
    
    file << "body {\n";
    file << "  background: var(--bg);\n";
    file << "  color: var(--text);\n";
    file << "  font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;\n";
    file << "  min-height: 100vh;\n";
    file << "}\n\n";
    
    file << "header {\n";
    file << "  display: flex;\n";
    file << "  align-items: center;\n";
    file << "  gap: 1rem;\n";
    file << "  padding: 1.25rem 2rem;\n";
    file << "  border-bottom: 1px solid var(--border);\n";
    file << "  background: var(--surface);\n";
    file << "}\n\n";
    
    file << "header h1 { font-size: 1.25rem; color: var(--accent); }\n\n";
    
    file << ".badge {\n";
    file << "  padding: .25rem .75rem;\n";
    file << "  border-radius: 999px;\n";
    file << "  font-size: .75rem;\n";
    file << "  font-weight: 600;\n";
    file << "  background: var(--border);\n";
    file << "  color: var(--muted);\n";
    file << "}\n";
    file << ".badge.ok    { background: #1a3a2a; color: var(--green); }\n";
    file << ".badge.warn  { background: #3a2e0a; color: var(--yellow); }\n";
    file << ".badge.error { background: #3a1010; color: var(--red); }\n\n";
    
    file << "main { padding: 2rem; max-width: 960px; margin: 0 auto; }\n\n";
    
    file << ".grid {\n";
    file << "  display: grid;\n";
    file << "  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));\n";
    file << "  gap: 1rem;\n";
    file << "  margin-bottom: 2rem;\n";
    file << "}\n\n";
    
    file << ".card {\n";
    file << "  background: var(--surface);\n";
    file << "  border: 1px solid var(--border);\n";
    file << "  border-radius: 8px;\n";
    file << "  padding: 1.25rem;\n";
    file << "  position: relative;\n";
    file << "}\n\n";
    
    file << ".card h2   { font-size: 1rem; margin-bottom: .25rem; }\n";
    file << ".card .endpoint { font-size: .8rem; color: var(--muted); }\n\n";
    
    file << ".status-dot {\n";
    file << "  position: absolute;\n";
    file << "  top: 1.25rem;\n";
    file << "  right: 1.25rem;\n";
    file << "  width: 10px;\n";
    file << "  height: 10px;\n";
    file << "  border-radius: 50%;\n";
    file << "  background: var(--border);\n";
    file << "}\n";
    file << ".status-dot.green { background: var(--green); box-shadow: 0 0 6px var(--green); }\n";
    file << ".status-dot.red   { background: var(--red);   box-shadow: 0 0 6px var(--red); }\n\n";
    
    file << ".metrics h2 { font-size: 1rem; margin-bottom: 1rem; }\n\n";
    
    file << "table {\n";
    file << "  width: 100%;\n";
    file << "  border-collapse: collapse;\n";
    file << "  font-size: .875rem;\n";
    file << "}\n";
    file << "th, td {\n";
    file << "  padding: .625rem 1rem;\n";
    file << "  text-align: left;\n";
    file << "  border-bottom: 1px solid var(--border);\n";
    file << "}\n";
    file << "th { color: var(--muted); font-weight: 500; }\n";
    file << "tr:last-child td { border-bottom: none; }\n";
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>" << std::endl;
        return 1;
    }
    
    std::ofstream outputFile(argv[1]);
    if (!outputFile.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << " for writing" << std::endl;
        return 1;
    }
    
    writeCSS(outputFile);
    outputFile.close();
    
    return 0;
}
