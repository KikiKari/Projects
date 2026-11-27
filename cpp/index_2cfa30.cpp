// abstraction-provenance: {"artifact_sha256": "95aa5c6a0c5b3abfc539ac30713560cf5ae02170d738083d7e77995af0b59ef3", "source_sha256": "2cfa301efe20d60c29e0e9f0746e5a99d405ea44a5d03839c72e6b525451fe07", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion-Android:site/index.html
// auch in: Projects@TikTok-Live-Companion-iOS:site/index.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>" << std::endl;
        return 1;
    }

    std::ofstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << std::endl;
        return 1;
    }

    // Write the doctype
    file << "<!doctype html>" << std::endl;

    // Start html tag with language attribute
    file << "<html lang=\"de\">" << std::endl;

    // Head section
    file << "  <head>" << std::endl;
    file << "    <meta charset=\"UTF-8\" />" << std::endl;
    file << "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />" << std::endl;
    file << "    <meta name=\"description\" content=\"Dokumentation für TikTok LIVE Companion 0.8.0 – Chat-TTS, Zuschauerstatistik, Songerkennung und Stream-Informationen direkt im Browser.\" />" << std::endl;
    file << "    <meta name=\"theme-color\" content=\"#ffffff\" />" << std::endl;
    file << "    <link rel=\"icon\" type=\"image/png\" href=\"/branding/staenderglobus-ios.png\" />" << std::endl;
    file << "    <link rel=\"apple-touch-icon\" href=\"/branding/staenderglobus-ios.png\" />" << std::endl;
    file << "    <title>TikTok LIVE Companion – Dokumentation</title>" << std::endl;
    file << "  </head>" << std::endl;

    // Body section
    file << "  <body>" << std::endl;
    file << "    <div id=\"root\"></div>" << std::endl;
    file << "    <script type=\"module\" src=\"/src/main.tsx\"></script>" << std::endl;
    file << "  </body>" << std::endl;

    // Close html tag
    file << "</html>" << std::endl;

    file.close();
    return 0;
}
