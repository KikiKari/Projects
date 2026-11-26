// abstraction-provenance: {"artifact_sha256": "39256acc1fd0720eb2709143af79a459e9144e5424a4673732b2e1795b220398", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "cpp"}
// gen_tree.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <sstream>

// Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
// (used because the `tree` binary is unavailable in this sandbox).

namespace fs = std::filesystem;

const std::string ROOT = "/workspace";
const std::string OUT = "/workspace/important/openclaw-tree.txt";
const int MAX_DEPTH = 6;

std::vector<std::string> collect(const std::string& path, const std::string& prefix = "", int depth = 1) {
    std::vector<std::string> lines;
    
    try {
        std::vector<fs::path> entries;
        for (const auto& entry : fs::directory_iterator(path)) {
            entries.push_back(entry.path());
        }
        
        // Sort entries by filename
        std::sort(entries.begin(), entries.end(), [](const fs::path& a, const fs::path& b) {
            return a.filename() < b.filename();
        });
        
        size_t total = entries.size();
        for (size_t i = 0; i < total; ++i) {
            bool is_last = (i == total - 1);
            std::string connector = is_last ? "└── " : "├── ";
            std::string name = entries[i].filename().string();
            lines.push_back(prefix + connector + name);
            
            std::string full = entries[i].string();
            if (depth < MAX_DEPTH && fs::is_directory(entries[i]) && !fs::is_symlink(entries[i])) {
                std::string next_prefix = prefix + (is_last ? "    " : "│   ");
                auto sub_lines = collect(full, next_prefix, depth + 1);
                lines.insert(lines.end(), sub_lines.begin(), sub_lines.end());
            }
        }
    } catch (const fs::filesystem_error&) {
        // Ignore directories we can't read
    }
    
    return lines;
}

std::string getCurrentTimeISO() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::gmtime(&time_t), "%Y-%m-%dT%H:%M:%S") 
       << "." << std::setfill('0') << std::setw(3) << ms.count() << "Z";
    return ss.str();
}

int main() {
    auto body = collect(ROOT);
    
    std::string header = 
        "# OpenClaw Workspace Tree\n"
        "# Generiert: " + getCurrentTimeISO() + "\n"
        "# Befehl: tree -a -L 6 " + ROOT + " (emuliert via gen_tree.cpp)\n"
        "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
    
    std::string content = header + ".\n";
    for (const auto& line : body) {
        content += line + "\n";
    }
    
    std::ofstream file(OUT);
    if (file.is_open()) {
        file << content;
        file.close();
        
        std::cout << "written " << OUT << ": " << (body.size() + 1) << " lines, " 
                  << content.length() << " bytes" << std::endl;
    } else {
        std::cerr << "Failed to write to " << OUT << std::endl;
        return 1;
    }
    
    return 0;
}
