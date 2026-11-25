// abstraction-provenance: {"artifact_sha256": "6ecb0adc97b399b8e67c29b60ca470e55319c44bd6d977922e9714b0ce82f947", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "cpp"}
// check_conflicts.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <filesystem>
#include <string>
#include <vector>
#include <set>
#include <map>
#include <algorithm>
#include <iomanip>
#include <sstream>
#include <fstream>
#include <openssl/sha.h>
#include <iomanip>
#include <ctime>

namespace fs = std::filesystem;

const fs::path CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills";
const fs::path GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills";

std::string get_file_hash(const fs::path& file_path) {
    std::ifstream file(file_path, std::ios::binary);
    if (!file) {
        return "";
    }

    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    
    char buffer[8192];
    while (file.read(buffer, sizeof(buffer)) || file.gcount() > 0) {
        SHA256_Update(&sha256, buffer, file.gcount());
    }
    
    unsigned char hash[SHA256_DIGEST_LENGTH];
    SHA256_Final(hash, &sha256);
    
    std::stringstream ss;
    for (int i = 0; i < SHA256_DIGEST_LENGTH; ++i) {
        ss << std::hex << std::setw(2) << std::setfill('0') << static_cast<int>(hash[i]);
    }
    
    return ss.str();
}

std::string format_time_t(std::time_t time) {
    std::tm* tm_ptr = std::localtime(&time);
    std::ostringstream oss;
    oss << std::put_time(tm_ptr, "%Y-%m-%d %H:%M:%S");
    return oss.str();
}

void collect_files(const fs::path& root, std::map<std::string, fs::path>& files) {
    if (!fs::exists(root) || !fs::is_directory(root)) {
        return;
    }
    
    for (const auto& entry : fs::recursive_directory_iterator(root)) {
        if (entry.is_regular_file()) {
            std::string path_str = entry.path().string();
            if (path_str.find("/.git/") == std::string::npos && 
                path_str.substr(path_str.length() - 5) != "/.git") {
                std::string relative_path = fs::relative(entry.path(), root).string();
                files[relative_path] = entry.path();
            }
        }
    }
}

struct FileConflict {
    std::string file;
    std::string clawhub_modified;
    std::string git_modified;
    std::string newer;
};

struct SkillConflict {
    std::string skill;
    std::vector<FileConflict> conflicts;
};

void check_conflicts() {
    std::vector<SkillConflict> conflicts;
    
    std::set<std::string> common_skills;
    
    if (fs::exists(CLAWHUB_DIR) && fs::exists(GIT_DIR)) {
        std::set<std::string> clawhub_skills;
        std::set<std::string> git_skills;
        
        for (const auto& entry : fs::directory_iterator(CLAWHUB_DIR)) {
            if (entry.is_directory()) {
                clawhub_skills.insert(entry.path().filename().string());
            }
        }
        
        for (const auto& entry : fs::directory_iterator(GIT_DIR)) {
            if (entry.is_directory()) {
                git_skills.insert(entry.path().filename().string());
            }
        }
        
        std::set_intersection(
            clawhub_skills.begin(), clawhub_skills.end(),
            git_skills.begin(), git_skills.end(),
            std::inserter(common_skills, common_skills.begin())
        );
    }
    
    std::cout << "Prüfe " << common_skills.size() << " Skills auf Konflikte...\n\n";
    
    for (const auto& skill : common_skills) {
        fs::path clawhub_path = CLAWHUB_DIR / skill;
        fs::path git_path = GIT_DIR / skill;
        
        std::vector<FileConflict> skill_conflicts;
        
        std::map<std::string, fs::path> clawhub_files;
        std::map<std::string, fs::path> git_files;
        
        collect_files(clawhub_path, clawhub_files);
        collect_files(git_path, git_files);
        
        std::set<std::string> common_files;
        for (const auto& pair : clawhub_files) {
            if (git_files.find(pair.first) != git_files.end()) {
                common_files.insert(pair.first);
            }
        }
        
        for (const auto& rel_path : common_files) {
            const fs::path& clawhub_file = clawhub_files[rel_path];
            const fs::path& git_file = git_files[rel_path];
            
            if (get_file_hash(clawhub_file) != get_file_hash(git_file)) {
                auto clawhub_time = fs::last_write_time(clawhub_file);
                auto git_time = fs::last_write_time(git_file);
                
                std::time_t clawhub_time_t = std::chrono::system_clock::to_time_t(
                    std::chrono::time_point_cast<std::chrono::system_clock::duration>(
                        clawhub_time.to_time_t()
                    )
                );
                
                std::time_t git_time_t = std::chrono::system_clock::to_time_t(
                    std::chrono::time_point_cast<std::chrono::system_clock::duration>(
                        git_time.to_time_t()
                    )
                );
                
                std::string clawhub_mtime = format_time_t(clawhub_time_t);
                std::string git_mtime = format_time_t(git_time_t);
                
                std::string newer = (clawhub_time > git_time) ? "clawhub" : "git";
                
                skill_conflicts.push_back({
                    rel_path,
                    clawhub_mtime,
                    git_mtime,
                    newer
                });
            }
        }
        
        if (!skill_conflicts.empty()) {
            conflicts.push_back({skill, skill_conflicts});
        }
    }
    
    if (!conflicts.empty()) {
        std::cout << "⚠️  KONFLIKTE GEFUNDEN:\n";
        std::cout << std::string(80, '=') << "\n";
        
        for (const auto& conflict : conflicts) {
            std::cout << "\n📦 Skill: " << conflict.skill << "\n";
            std::cout << std::string(40, '-') << "\n";
            
            for (const auto& file_conflict : conflict.conflicts) {
                std::cout << "  📄 " << file_conflict.file << "\n";
                std::cout << "     ClawHub: " << file_conflict.clawhub_modified << "\n";
                std::cout << "     Git:     " << file_conflict.git_modified << "\n";
                std::cout << "     Neuer:   " << file_conflict.newer << "\n\n";
            }
        }
        
        std::cout << std::string(80, '=') << "\n";
        std::cout << "Gesamt: " << conflicts.size() << " Skills mit Konflikten\n";
        std::cout << "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.\n";
    } else {
        std::cout << "✅ Keine Konflikte gefunden!\n";
        std::cout << "Alle gemeinsamen Skills sind synchron.\n";
    }
}

int main() {
    check_conflicts();
    return 0;
}
