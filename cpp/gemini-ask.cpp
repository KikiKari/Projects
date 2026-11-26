// abstraction-provenance: {"artifact_sha256": "0273a881787d607c390d3a80792ae2e2d8cc44824dfb170cfbd694902edef994", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "cpp"}
// gemini-ask.js — portiert nach cpp
// Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
// auch in: OpenClaw@gateway2:scripts/gemini-ask.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cstring>
#include <curl/curl.h>
#include <unistd.h>
#include <sys/stat.h>

// Callback function to write response data
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* response) {
    size_t totalSize = size * nmemb;
    response->append((char*)contents, totalSize);
    return totalSize;
}

std::string readFile(const std::string& filepath) {
    std::ifstream file(filepath);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << filepath << std::endl;
        exit(1);
    }
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

std::string readStdin() {
    std::stringstream buffer;
    buffer << std::cin.rdbuf();
    return buffer.str();
}

void printUsage() {
    std::cerr << "Error: No prompt provided\n";
    std::cerr << "Usage: gemini-ask \"your question\"\n";
    std::cerr << "       gemini-ask --model gemini-pro \"your question\"\n";
    std::cerr << "       echo \"your question\" | gemini-ask\n";
}

int main(int argc, char* argv[]) {
    // Check API key
    const char* apiKeyEnv = std::getenv("GEMINI_API_KEY");
    if (!apiKeyEnv) {
        std::cerr << "Error: GEMINI_API_KEY environment variable is required\n";
        return 1;
    }
    std::string apiKey(apiKeyEnv);

    // Get default model from environment or use default
    std::string modelName = "gemini-pro";
    const char* modelEnv = std::getenv("GEMINI_MODEL");
    if (modelEnv) {
        modelName = std::string(modelEnv);
    }

    std::string prompt = "";
    std::string systemPrompt = "";
    std::vector<std::string> args(argv + 1, argv + argc);

    // Parse arguments
    for (size_t i = 0; i < args.size(); ++i) {
        if ((args[i] == "--model" || args[i] == "-m") && i + 1 < args.size()) {
            modelName = args[i + 1];
            args.erase(args.begin() + i, args.begin() + i + 2);
            i--; // Adjust index after erasure
        } else if ((args[i] == "--system" || args[i] == "-s") && i + 1 < args.size()) {
            systemPrompt = args[i + 1];
            args.erase(args.begin() + i, args.begin() + i + 2);
            i--; // Adjust index after erasure
        }
    }

    // Handle file input
    for (size_t i = 0; i < args.size(); ++i) {
        if ((args[i] == "--file" || args[i] == "-f") && i + 1 < args.size()) {
            std::string filePath = args[i + 1];
            prompt = readFile(filePath);
            args.erase(args.begin() + i, args.begin() + i + 2);
            i--; // Adjust index after erasure
        }
    }

    // Handle remaining arguments as prompt
    if (!prompt.empty() && args.empty()) {
        // Prompt already loaded from file
    } else if (!args.empty()) {
        std::stringstream ss;
        for (const auto& arg : args) {
            ss << arg << " ";
        }
        prompt = ss.str();
        // Remove trailing space
        if (!prompt.empty()) {
            prompt.pop_back();
        }
    } else if (!isatty(STDIN_FILENO)) {
        prompt = readStdin();
    }

    if (prompt.empty()) {
        printUsage();
        return 1;
    }

    // Initialize CURL
    CURL* curl = curl_easy_init();
    if (!curl) {
        std::cerr << "Error: Failed to initialize CURL\n";
        return 1;
    }

    std::string response_data;
    std::string url = "https://generativelanguage.googleapis.com/v1beta/models/" + modelName + ":generateContent?key=" + apiKey;

    // Prepare JSON payload
    std::string jsonPayload;
    if (!systemPrompt.empty()) {
        jsonPayload = "{"
                       "\"contents\":["
                       "{\"role\":\"user\",\"parts\":[{\"text\":\"" + systemPrompt + "\"}]},"
                       "{\"role\":\"model\",\"parts\":[{\"text\":\"Understood. I will follow that instruction.\"}]},"
                       "{\"role\":\"user\",\"parts\":[{\"text\":\"" + prompt + "\"}]}"
                       "],"
                       "\"generationConfig\":{"
                       "\"maxOutputTokens\":8192,"
                       "\"temperature\":0.7,"
                       "\"topP\":0.95"
                       "}"
                       "}";
    } else {
        jsonPayload = "{"
                       "\"contents\":["
                       "{\"role\":\"user\",\"parts\":[{\"text\":\"" + prompt + "\"}]}"
                       "],"
                       "\"generationConfig\":{"
                       "\"maxOutputTokens\":8192,"
                       "\"temperature\":0.7,"
                       "\"topP\":0.95"
                       "}"
                       "}";
    }

    // Set CURL options
    curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, jsonPayload.c_str());
    curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_data);
    
    struct curl_slist* headers = nullptr;
    headers = curl_slist_append(headers, "Content-Type: application/json");
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    // Perform the request
    CURLcode res = curl_easy_perform(curl);
    
    if (res != CURLE_OK) {
        std::cerr << "Error: CURL request failed: " << curl_easy_strerror(res) << std::endl;
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);
        return 1;
    }

    // Cleanup
    curl_slist_free_all(headers);
    curl_easy_cleanup(curl);

    // Output response
    std::cout << response_data << std::endl;

    return 0;
}
