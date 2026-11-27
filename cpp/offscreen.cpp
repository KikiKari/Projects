// abstraction-provenance: {"artifact_sha256": "ad0b19e2169301c4675a26b31792b6ae156f10c5699e1df2f515758b0880c2d7", "source_sha256": "a243d1fdcbd0c82c97b2771c181438428885fd9c2feaed782f7e9eb8066fed59", "target_language": "cpp"}
// offscreen.html — portiert nach cpp
// Quelle: html, Projects@TikTok-Live-Companion:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/offscreen.html
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/offscreen.html
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/offscreen.html
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    // Prüfe ob ein Dateiname übergeben wurde
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <dateiname>" << std::endl;
        return 1;
    }

    // Öffne die Ausgabedatei
    std::ofstream datei(argv[1]);
    if (!datei.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << argv[1] << std::endl;
        return 1;
    }

    // Erzeuge das HTML-Dokument strukturiert
    datei << "<!doctype html>" << std::endl;
    datei << "<html lang=\"de\">" << std::endl;
    datei << "<head>" << std::endl;
    datei << "  <meta charset=\"utf-8\">" << std::endl;
    datei << "  <title>TikTok LIVE Companion Sprachausgabe</title>" << std::endl;
    datei << "</head>" << std::endl;
    datei << "<body>" << std::endl;
    datei << "  <script src=\"offscreen.js\"></script>" << std::endl;
    datei << "</body>" << std::endl;
    datei << "</html>" << std::endl;

    // Schließe die Datei
    datei.close();

    return 0;
}
