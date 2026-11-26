// abstraction-provenance: {"artifact_sha256": "4cba06a4ddc7c001f4f5fdf4837dc68fd04238cb1ee3242ddf6a230d5d38c9f5", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "cpp"}
// generate-elevenlabs.mjs — portiert nach cpp
// Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <cstdlib>
#include <filesystem>
#include <curl/curl.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

// Callback function to write response data into a string
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* response) {
    size_t totalSize = size * nmemb;
    response->append((char*)contents, totalSize);
    return totalSize;
}

int main() {
    // Get environment variables
    const char* key = std::getenv("ELEVENLABS_API_KEY");
    const char* voiceIdEnv = std::getenv("ELEVENLABS_VOICE_ID");
    std::string voiceId = voiceIdEnv ? voiceIdEnv : "JBFqnCBsd6RMkjVDRZzb";
    
    if (!key) {
        std::cerr << "ELEVENLABS_API_KEY fehlt." << std::endl;
        return 1;
    }
    
    std::string text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.";
    
    // Initialize CURL
    CURL* curl = curl_easy_init();
    if (!curl) {
        std::cerr << "CURL initialization failed" << std::endl;
        return 1;
    }
    
    // Prepare request
    std::string url = "https://api.elevenlabs.io/v1/text-to-speech/" + voiceId + "?output_format=mp3_44100_128";
    std::string response_data;
    
    // Set CURL options
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_POST, 1L);
    
    // Set headers
    struct curl_slist* headers = nullptr;
    headers = curl_slist_append(headers, ("xi-api-key: " + std::string(key)).c_str());
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
    
    // Prepare JSON payload
    json payload = {
        {"text", text},
        {"model_id", "eleven_multilingual_v2"},
        {"voice_settings", {
            {"stability", 0.58},
            {"similarity_boost", 0.72},
            {"style", 0.18},
            {"use_speaker_boost", true}
        }}
    };
    std::string payload_str = payload.dump();
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, payload_str.c_str());
    
    // Set callback for response
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
    
    // Perform request
    CURLcode res = curl_easy_perform(curl);
    
    // Check for errors
    long response_code;
    curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
    
    if (res != CURLE_OK || response_code >= 400) {
        std::cerr << "ElevenLabs fehlgeschlagen: " << response_code << std::endl;
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        return 1;
    }
    
    // Clean up CURL
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);
    
    // Create directories
    fs::create_directories("../public/audio/");
    
    // Write audio file
    std::ofstream audio_file("../public/audio/project-narration.mp3", std::ios::binary);
    audio_file << response_data;
    audio_file.close();
    
    // Prepare result JSON
    json result = {
        {"model", "eleven_multilingual_v2"},
        {"voiceId", voiceId},
        {"characters", text.length()},
        {"text", text},
        {"output", "public/audio/project-narration.mp3"}
    };
    
    // Write result JSON file
    std::ofstream result_file("../media-production/elevenlabs-result.json");
    result_file << result.dump(2);
    result_file.close();
    
    std::cout << "ElevenLabs abgeschlossen: " << text.length() << " Zeichen." << std::endl;
    
    return 0;
}
