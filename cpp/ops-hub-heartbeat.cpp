// abstraction-provenance: {"artifact_sha256": "f5c20fb49f551af508d3983b8211e47062c050da86481fb4c9af933834c774f1", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "cpp"}
// ops-hub-heartbeat.js — portiert nach cpp
// Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
// auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <regex>

#ifdef _WIN32
#include <windows.h>
#else
#include <unistd.h>
#endif

std::string getExecutablePath() {
#ifdef _WIN32
    char buffer[MAX_PATH];
    GetModuleFileName(NULL, buffer, MAX_PATH);
    std::string::size_type pos = std::string(buffer).find_last_of("\\/");
    return std::string(buffer).substr(0, pos);
#else
    char buffer[1024];
    ssize_t len = readlink("/proc/self/exe", buffer, sizeof(buffer)-1);
    if (len != -1) {
        buffer[len] = '\0';
        std::string::size_type pos = std::string(buffer).find_last_of("/");
        return std::string(buffer).substr(0, pos);
    }
    return "";
#endif
}

std::string getCurrentTime() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    
    std::stringstream ss;
    ss << std::put_time(std::localtime(&time_t), "%d.%m.%Y, %H:%M:%S");
    return ss.str();
}

std::string readFile(const std::string& filePath) {
    std::ifstream file(filePath);
    if (!file.is_open()) {
        throw std::runtime_error("Konnte Datei nicht öffnen: " + filePath);
    }
    
    std::stringstream buffer;
    buffer << file.rdbuf();
    return buffer.str();
}

void writeFile(const std::string& filePath, const std::string& content) {
    std::ofstream file(filePath);
    if (!file.is_open()) {
        throw std::runtime_error("Konnte Datei nicht schreiben: " + filePath);
    }
    
    file << content;
}

void updateHeartbeat() {
    std::string exePath = getExecutablePath();
    std::string statusPath = exePath + "/../docs/ops-hub/status.md";
    
    std::string content;
    try {
        content = readFile(statusPath);
    } catch (const std::exception& err) {
        std::cerr << "❌ Konnte status.md nicht lesen: " << err.what() << std::endl;
        return;
    }
    
    std::string now = getCurrentTime();
    
    std::regex pattern(R"((Letzter Heartbeat:) [^\n]*)");
    std::string replacement = "$1 " + now;
    std::string updated = std::regex_replace(content, pattern, replacement);
    
    try {
        writeFile(statusPath, updated);
        std::cout << "✅ Heartbeat aktualisiert: " << now << std::endl;
    } catch (const std::exception& err) {
        std::cerr << "❌ Konnte status.md nicht schreiben: " << err.what() << std::endl;
    }
}

int main() {
    updateHeartbeat();
    return 0;
}
