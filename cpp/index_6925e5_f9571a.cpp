// abstraction-provenance: {"artifact_sha256": "180826020026c91745f9750f016e0819667af734920cd65fce04ad023d17100a", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "cpp"}
// index_6925e5.css — portiert nach cpp
// Quelle: css, Projects@abstractions:css/index_6925e5.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void write_css_file(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << "/* abstraction-provenance: {\"artifact_sha256\": \"ede701dd0faa101fb7d23c7e6bd8e28625c33e7b3d07a7ededc1bf14cbfcb761\", \"source_sha256\": \"6925e5ed34d3344b10c23ce3442546a31631cc8434f3b7df4bdc003d32218523\", \"target_language\": \"css\"} */\n";
    file << "/* index.html — portiert nach css */\n";
    file << "/* Quelle: html, Projects@MCP-Server-Monitor:public/index.html */\n";
    file << "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n";

    file << ":root{\n";
    file << "  --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;\n";
    file << "  --ac:#6d5bd0; --ac-soft:#efecfb;\n";
    file << "  --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;\n";
    file << "  color-scheme: light;\n";
    file << "}\n";
    
    file << "@media (prefers-color-scheme: dark){\n";
    file << "  :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;\n";
    file << "         --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }\n";
    file << "}\n";
    
    file << "*{box-sizing:border-box}\n";
    
    file << "body{margin:0;background:var(--bg);color:var(--text);\n";
    file << "     font:16px/1.6 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n";
    
    file << ".wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}\n";
    
    file << "header{padding:64px 0 36px;border-bottom:1px solid var(--line)}\n";
    
    file << "h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}\n";
    
    file << ".lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}\n";
    
    file << "h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;\n";
    file << "   color:var(--muted);font-weight:650}\n";
    
    file << "h3{font-size:17px;margin:24px 0 6px}\n";
    
    file << "p{margin:0 0 14px;max-width:70ch}\n";
    
    file << ".badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}\n";
    
    file << ".badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;\n";
    file << "       background:var(--soft);color:var(--muted);border:1px solid var(--line)}\n";
    
    file << ".badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}\n";
    
    file << "table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}\n";
    
    file << "th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}\n";
    
    file << "th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}\n";
    
    file << "code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;\n";
    file << "     font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}\n";
    
    file << "pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;\n";
    file << "    padding:13px 15px;overflow-x:auto;margin:0 0 14px}\n";
    
    file << "pre code{background:none;padding:0}\n";
    
    file << ".card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}\n";
    
    file << ".note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;\n";
    file << "      padding:14px 16px;margin:0 0 16px;font-size:14.5px}\n";
    
    file << ".note b{color:var(--warn)}\n";
    
    file << "fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}\n";
    
    file << "legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}\n";
    
    file << "label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}\n";
    
    file << "label.q input{margin-top:4px;flex:none}\n";
    
    file << "label.q span small{display:block;color:var(--muted);font-size:13px}\n";
    
    file << "#ergebnis{margin-top:6px}\n";
    
    file << ".verdict{border:1px solid var(--line);border-left:4px solid var(--ac);\n";
    file << "         border-radius:10px;padding:16px 18px;background:var(--soft)}\n";
    
    file << ".verdict h3{margin:0 0 6px;font-size:18px}\n";
    
    file << ".verdict .step{font-weight:650;margin:10px 0 0}\n";
    
    file << ".verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);\n";
    file << "            border-radius:8px;font-size:14px}\n";
    
    file << ".probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}\n";
    
    file << ".probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);\n";
    file << "             border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}\n";
    
    file << ".btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;\n";
    file << "     border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}\n";
    
    file << ".btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}\n";
    
    file << "footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);\n";
    file << "       color:var(--muted);font-size:14px}\n";
    
    file << "a{color:var(--ac)}\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
