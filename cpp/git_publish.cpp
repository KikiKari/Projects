// abstraction-provenance: {"artifact_sha256": "942678e73b464cc8bc2e6e10bfd536c28e53e0a41b7d9d4f20d5ad0214cbf8b2", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "cpp"}
// git_publish.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <sstream>
#include <chrono>
#include <thread>
#include <iomanip>
#include <fstream>

namespace fs = std::filesystem;

const fs::path SKILLS_DIR = fs::path(std::getenv("HOME")) / ".openclaw" / "workspace" / "skills";

std::string get_current_time_iso() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;
    
    std::stringstream ss;
    ss << std::put_time(std::gmtime(&time_t), "%Y-%m-%dT%H:%M:%S") 
       << "." << std::setfill('0') << std::setw(3) << ms.count() << "Z";
    return ss.str();
}

bool git_commit(const fs::path& skill_path, const std::string& message = "") {
    std::string commit_message = message.empty() ? 
        "[skill] Auto-update " + skill_path.filename().string() + " - " + get_current_time_iso() : 
        message;
    
    std::string add_cmd = "cd " + SKILLS_DIR.parent_path().string() + " && git add " + skill_path.string();
    int add_result = std::system(add_cmd.c_str());
    
    if (add_result != 0) {
        return false;
    }
    
    std::string commit_cmd = "cd " + SKILLS_DIR.parent_path().string() + " && git commit -m \"" + commit_message + "\"";
    int commit_result = std::system(commit_cmd.c_str());
    
    return commit_result == 0;
}

std::pair<bool, std::string> clawhub_publish(const std::string& skill_name) {
    fs::path skill_path = SKILLS_DIR / skill_name;
    std::string cmd = "clawhub publish " + skill_path.string() + " --slug " + skill_name + " --version 1.0.0";
    
    std::array<char, 128> buffer;
    std::string result;
    FILE* pipe = popen(cmd.c_str(), "r");
    
    if (!pipe) {
        return {false, ""};
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe) != nullptr) {
        result += buffer.data();
    }
    
    int return_code = pclose(pipe);
    return {return_code == 0, result};
}

std::vector<std::string> get_changed_skills() {
    std::string cmd = "cd " + SKILLS_DIR.parent_path().string() + " && git status --short " + SKILLS_DIR.string();
    
    std::array<char, 128> buffer;
    std::string result;
    FILE* pipe = popen(cmd.c_str(), "r");
    
    if (!pipe) {
        return {};
    }
    
    while (fgets(buffer.data(), buffer.size(), pipe) != nullptr) {
        result += buffer.data();
    }
    
    pclose(pipe);
    
    std::vector<std::string> changed;
    std::istringstream iss(result);
    std::string line;
    
    while (std::getline(iss, line)) {
        if (!line.empty() && line.find("skills/") != std::string::npos) {
            size_t start_pos = line.find("skills/") + 7;
            size_t end_pos = line.find("/", start_pos);
            std::string skill = line.substr(start_pos, end_pos - start_pos);
            
            if (std::find(changed.begin(), changed.end(), skill) == changed.end()) {
                changed.push_back(skill);
            }
        }
    }
    
    return changed;
}

void batch_publish() {
    std::vector<std::string> changed = get_changed_skills();
    
    std::cout << "Changed skills: [";
    for (size_t i = 0; i < changed.size(); ++i) {
        std::cout << changed[i];
        if (i < changed.size() - 1) std::cout << ", ";
    }
    std::cout << "]" << std::endl;
    
    size_t limit = std::min(static_cast<size_t>(5), changed.size());
    for (size_t i = 0; i < limit; ++i) {
        if (i > 0) {
            std::cout << "Waiting 15min for rate limit..." << std::endl;
            // In real: std::this_thread::sleep_for(std::chrono::minutes(15));
        }
        
        std::cout << "Publishing " << changed[i] << "..." << std::endl;
        bool commit_ok = git_commit(SKILLS_DIR / changed[i]);
        
        if (commit_ok) {
            auto [pub_ok, output] = clawhub_publish(changed[i]);
            std::cout << "  " << (pub_ok ? "✓" : "✗") << " " << output << std::endl;
        }
    }
}

int main(int argc, char* argv[]) {
    std::string skill;
    bool publish_all = false;
    bool no_publish = false;
    std::string message;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--skill" && i + 1 < argc) {
            skill = argv[++i];
        } else if (arg == "--all") {
            publish_all = true;
        } else if (arg == "--no-publish") {
            no_publish = true;
        } else if (arg == "--message" && i + 1 < argc) {
            message = argv[++i];
        }
    }
    
    if (!skill.empty()) {
        fs::path skill_path = SKILLS_DIR / skill;
        if (no_publish) {
            git_commit(skill_path, message);
        } else {
            git_commit(skill_path, message);
            clawhub_publish(skill);
        }
    } else if (publish_all) {
        batch_publish();
    } else {
        std::cout << "Use --skill <name> or --all" << std::endl;
    }
    
    return 0;
}
