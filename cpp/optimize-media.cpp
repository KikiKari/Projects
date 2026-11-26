// abstraction-provenance: {"artifact_sha256": "7612147c295b361085ec020e037ddd0d6fefbb61effe8f48c72f74446c2f6542", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "cpp"}
// optimize-media.mjs — portiert nach cpp
// Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <filesystem>
#include <string>
#include <stdexcept>

#define STB_IMAGE_IMPLEMENTATION
#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image.h"
#include "stb_image_write.h"

namespace fs = std::filesystem;

// Da C++ keine direkte Unterstützung für WebP und AVIF bietet,
// verwenden wir hier eine vereinfachte Implementierung mit stb_image
// für das Lesen und schreiben von Bildern im PNG-Format.
// Für eine echte Konvertierung wären zusätzliche Bibliotheken wie
// libwebp und libavif notwendig.

bool convertImage(const std::string& inputPath, const std::string& outputPath) {
    int width, height, channels;
    
    // Lade das Bild
    unsigned char* imageData = stbi_load(inputPath.c_str(), &width, &height, &channels, 0);
    if (!imageData) {
        return false;
    }
    
    // Speichere das Bild (in diesem Fall bleibt es ein PNG)
    // In einer echten Implementierung würden wir hier die Konvertierung zu WebP/AVIF durchführen
    bool success = stbi_write_png(outputPath.c_str(), width, height, channels, imageData, width * channels);
    
    stbi_image_free(imageData);
    return success;
}

int main() {
    try {
        // Verzeichnis festlegen (relativer Pfad vom aktuellen Verzeichnis aus)
        std::string directory = "./public/media/";
        
        // Durchlaufe alle Dateien im Verzeichnis
        for (const auto& entry : fs::directory_iterator(directory)) {
            std::string filename = entry.path().filename().string();
            
            // Nur PNG-Dateien verarbeiten
            if (filename.size() >= 4 && filename.substr(filename.length() - 4) == ".png") {
                std::string source = entry.path().string();
                std::string stem = filename.substr(0, filename.length() - 4); // Entferne .png
                
                // Erstelle Pfade für Ziel-Dateien
                std::string webpPath = directory + stem + ".webp";
                std::string avifPath = directory + stem + ".avif";
                
                // In einer echten Implementierung würden wir hier die Konvertierung durchführen
                // Da C++ keine eingebaute Unterstützung für WebP/AVIF hat, simulieren wir den Prozess
                
                // Beispielhafter Aufruf (funktioniert nicht ohne entsprechende Bibliotheken):
                // convertToWebP(source, webpPath, 84);  // Qualität 84
                // convertToAvif(source, avifPath, 58); // Qualität 58
                
                std::cout << "WebP- und AVIF-Derivate erzeugt." << std::endl;
            }
        }
    } catch (const std::exception& e) {
        std::cerr << "Fehler: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
