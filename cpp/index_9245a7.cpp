// abstraction-provenance: {"artifact_sha256": "bc6892aadca37ff46a0e0e0b745127f7e0f083e81fe567ad4390a64f2febd44e", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "cpp"}
// index.html — portiert nach cpp
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Verwendung: " << argv[0] << " <ausgabedatei>" << std::endl;
        return 1;
    }

    std::ofstream datei(argv[1]);
    if (!datei.is_open()) {
        std::cerr << "Fehler beim Öffnen der Datei: " << argv[1] << std::endl;
        return 1;
    }

    // Schreibe das HTML-Dokument
    datei << "<!DOCTYPE html>\n";
    datei << "<html lang=\"de\">\n";
    datei << "<head>\n";
    datei << "<meta charset=\"utf-8\">\n";
    datei << "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n";
    datei << "<meta http-equiv=\"refresh\" content=\"0; url=3d.html\">\n";
    datei << "<title>Weiterleitung zur 3D-Ansicht</title>\n";
    datei << "<link rel=\"canonical\" href=\"3d.html\">\n";
    datei << "<script>location.replace('3d.html');</script>\n";
    datei << "</head>\n";
    datei << "<body>\n";
    datei << "<p><a href=\"3d.html\">3D-Ansicht öffnen</a></p>\n";
    datei << "</body>\n";
    datei << "</html>\n";

    datei.close();
    
    if (datei.fail()) {
        std::cerr << "Fehler beim Schreiben der Datei: " << argv[1] << std::endl;
        return 1;
    }

    return 0;
}
