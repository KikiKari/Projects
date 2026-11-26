// abstraction-provenance: {"artifact_sha256": "a4b18af67dd5ed518c46914763fc903a47b05aeffaba3fdd7d4ed5ccc9ac6ae8", "source_sha256": "c10479f79ca5554fe399cf2f5d70fb5b32e837c1c7a846eb7dd7c9e9e5319c66", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:site/index.html
// auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:site/index.html
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

void writeHtmlDocument(const std::string& filename) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << filename << std::endl;
        return;
    }

    file << "<!doctype html>\n";
    file << "<html lang=\"de\">\n";
    file << "  <head>\n";
    file << "    <meta charset=\"UTF-8\" />\n";
    file << "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n";
    file << "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.2 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />\n";
    file << "    <meta name=\"theme-color\" content=\"#ffffff\" />\n";
    file << "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />\n";
    file << "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />\n";
    file << "    <title>TikTok LIVE Companion – Dokumentation</title>\n";
    file << "  </head>\n";
    file << "  <body>\n";
    file << "    <div id=\"root\"></div>\n";
    file << "    <script type=\"module\" src=\"/src/main.tsx\"></script>\n";
    file << "  </body>\n";
    file << "</html>\n";

    file.close();
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }

    writeHtmlDocument(argv[1]);
    return 0;
}
