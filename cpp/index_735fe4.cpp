// abstraction-provenance: {"artifact_sha256": "4a0130866ed2b85e7dce5ebb25f712a756f29ddf13745bb8d9403d15a0857f4a", "source_sha256": "735fe4b2c74b10f265f715cd4e85d574f46a7132d2e592703b5e712888470105", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, OpenClaw@main:index.html
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

    // Schreibe DOCTYPE und öffnendes HTML-Tag
    file << "<!DOCTYPE html>\n";
    file << "<html lang=\"de\">\n";
    
    // Head-Bereich
    file << "  <head>\n";
    file << "    <meta charset=\"utf-8\" />\n";
    file << "    <link rel=\"icon\" href=\"/favicon.ico\" />\n";
    file << "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />\n";
    file << "    <meta name=\"theme-color\" content=\"#0b1020\" />\n";
    file << "    <meta\n";
    file << "      name=\"description\"\n";
    file << "      content=\"OpenClaw Startseite für Repository, Dokumentation und Frontend-Branch.\"\n";
    file << "    />\n";
    file << "    <link rel=\"apple-touch-icon\" href=\"/logo192.png\" />\n";
    file << "    <!--\n";
    file << "      manifest.json provides metadata used when your web app is installed on a\n";
    file << "      user's mobile device or desktop. See https://developers.google.com/web/fundamentals/web-app-manifest/\n";
    file << "    -->\n";
    file << "    <link rel=\"manifest\" href=\"/manifest.json\" />\n";
    file << "    <title>OpenClaw</title>\n";
    file << "  </head>\n";
    
    // Body-Bereich
    file << "  <body>\n";
    file << "    <noscript>You need to enable JavaScript to run this app.</noscript>\n";
    file << "    <div id=\"root\"></div>\n";
    file << "    <!--\n";
    file << "      This HTML file is a template.\n";
    file << "      If you open it directly in the browser, you will see an empty page.\n";
    file << "\n";
    file << "      You can add webfonts, meta tags, or analytics to this file.\n";
    file << "      The build step will place the bundled scripts into the <body> tag.\n";
    file << "\n";
    file << "      To begin the development, run `npm start` or `yarn start`.\n";
    file << "      To create a production bundle, use `npm run build` or `yarn build`.\n";
    file << "    -->\n";
    file << "  </body>\n";
    
    // Script-Tag
    file << "  <script type=\"module\" src=\"/src/index.jsx\"></script>\n";
    
    // Schließe HTML-Tag
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
