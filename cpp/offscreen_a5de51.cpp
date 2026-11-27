// abstraction-provenance: {"artifact_sha256": "5ab71745ad86e9937db28d2c8fae5b88532cdb786e8f8fdfe86ce067d921006c", "source_sha256": "a5de51b02b40bbdeafb7fb0f4da19091ec351b10a9160307085ebcef403cdd67", "target_language": "cpp"}
// offscreen.html — portiert nach cpp
// Quelle: html, Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <Ausgabedatei>" << std::endl;
        return 1;
    }

    std::ofstream datei(argv[1]);
    if (!datei.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << argv[1] << std::endl;
        return 1;
    }

    // Erzeuge das HTML-Dokument
    datei << "<!doctype html>\n";
    datei << "<html lang=\"de\">\n";
    datei << "<head>\n";
    datei << "  <meta charset=\"utf-8\">\n";
    datei << "  <title>TikTok LIVE Companion Sprachausgabe</title>\n";
    datei << "</head>\n";
    datei << "<body>\n";
    datei << "  <script src=\"offscreen.js\"></script>\n";
    datei << "</body>\n";
    datei << "</html>\n";

    datei.close();
    
    if (datei.fail()) {
        std::cerr << "Fehler beim Schreiben der Datei: " << argv[1] << std::endl;
        return 1;
    }

    return 0;
}
