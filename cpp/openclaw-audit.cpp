// abstraction-provenance: {"artifact_sha256": "b999d20957fbb3767ec4260de5eb6757cc0a7a6607fff9ed7fe77857723b2a8f", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "cpp"}
// openclaw-audit.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <ctime>
#include <cstdlib>
#include <filesystem>
#include <chrono>
#include <sstream>
#include <iomanip>
#include <cstdio>
#include <memory>
#include <array>

namespace fs = std::filesystem;

class OpenClawAudit {
private:
    std::string script_dir;
    std::string date_stamp;
    std::string out_file;
    std::vector<std::string> oc_cmd{"openclaw", "--no-color"};
    
    std::string getCurrentTime() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::stringstream ss;
        ss << std::put_time(std::localtime(&time_t), "%Y-%m-%d");
        return ss.str();
    }
    
    std::string getISOTime() {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        std::stringstream ss;
        ss << std::put_time(std::localtime(&time_t), "%Y-%m-%dT%H:%M:%S%z");
        return ss.str();
    }
    
    std::string execCommand(const std::vector<std::string>& cmd) {
        std::string command_str = "";
        for (size_t i = 0; i < cmd.size(); ++i) {
            if (i > 0) command_str += " ";
            command_str += cmd[i];
        }
        
        std::array<char, 128> buffer;
        std::string result;
        std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(command_str.c_str(), "r"), pclose);
        
        if (!pipe) {
            return "ERROR: Failed to execute command";
        }
        
        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            result += buffer.data();
        }
        
        return result;
    }
    
    int execCommandWithStatus(const std::vector<std::string>& cmd) {
        std::string command_str = "";
        for (size_t i = 0; i < cmd.size(); ++i) {
            if (i > 0) command_str += " ";
            command_str += cmd[i];
        }
        
        return std::system(command_str.c_str());
    }
    
    std::string getHostname() {
        char buffer[256];
        if (gethostname(buffer, sizeof(buffer)) == 0) {
            return std::string(buffer);
        }
        return "unknown";
    }
    
    std::string getUsername() {
        const char* user = std::getenv("USER");
        if (user) {
            return std::string(user);
        }
        return "unknown";
    }
    
    std::string getVersion() {
        try {
            std::vector<std::string> version_cmd = {"openclaw", "--version"};
            return execCommand(version_cmd);
        } catch (...) {
            return "unknown";
        }
    }
    
public:
    OpenClawAudit() {
        // Get script directory (current working directory in this case)
        script_dir = fs::current_path().string();
        date_stamp = getCurrentTime();
        out_file = script_dir + "/openclaw-audit-" + date_stamp + ".log";
    }
    
    void writeHeader() {
        std::ofstream file(out_file);
        if (!file.is_open()) {
            throw std::runtime_error("Could not open output file");
        }
        
        file << "================================================================\n";
        file << "OpenClaw audit run\n";
        file << "Started:  " << getISOTime() << "\n";
        file << "Host:     " << getHostname() << "\n";
        file << "User:     " << getUsername() << "\n";
        file << "Version:  " << getVersion();
        file << "Output:   " << out_file << "\n";
        file << "================================================================\n";
        file.close();
    }
    
    void runCmd(const std::string& title, const std::vector<std::string>& cmd) {
        std::ofstream file(out_file, std::ios::app);
        if (!file.is_open()) {
            throw std::runtime_error("Could not open output file for appending");
        }
        
        file << "\n";
        file << "----------------------------------------------------------------\n";
        file << "### " << title << "\n";
        file << "### $ ";
        for (size_t i = 0; i < cmd.size(); ++i) {
            if (i > 0) file << " ";
            file << cmd[i];
        }
        file << "\n";
        file << "### " << getISOTime() << "\n";
        file << "----------------------------------------------------------------\n";
        file.close();
        
        // Execute command and append output
        std::array<char, 128> buffer;
        std::string command_str = "";
        for (size_t i = 0; i < cmd.size(); ++i) {
            if (i > 0) command_str += " ";
            command_str += cmd[i];
        }
        
        std::unique_ptr<FILE, decltype(&pclose)> pipe(popen((command_str + " 2>&1").c_str(), "r"), pclose);
        std::ofstream outfile(out_file, std::ios::app);
        
        if (!pipe) {
            outfile << "ERROR: Failed to execute command\n";
            outfile << "[exit: 1]\n";
            outfile.close();
            return;
        }
        
        while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
            outfile << buffer.data();
        }
        
        int rc = pclose(pipe.release());
        outfile << "[exit: " << rc << "]\n";
        outfile.close();
    }
    
    void writeFooter() {
        std::ofstream file(out_file, std::ios::app);
        file << "\n";
        file << "================================================================\n";
        file << "Audit complete: " << getISOTime() << "\n";
        file << "================================================================\n";
        file.close();
    }
    
    void runAudit() {
        writeHeader();
        
        std::vector<std::string> cmd1 = oc_cmd;
        cmd1.insert(cmd1.end(), {"tasks", "audit", "--severity", "error"});
        runCmd("tasks audit --severity error", cmd1);
        
        std::vector<std::string> cmd2 = oc_cmd;
        cmd2.insert(cmd2.end(), {"secrets", "audit"});
        runCmd("secrets audit", cmd2);
        
        std::vector<std::string> cmd3 = oc_cmd;
        cmd3.insert(cmd3.end(), {"security", "audit"});
        runCmd("security audit", cmd3);
        
        std::vector<std::string> cmd4 = oc_cmd;
        cmd4.insert(cmd4.end(), {"plugins", "doctor"});
        runCmd("plugins doctor", cmd4);
        
        std::vector<std::string> cmd5 = oc_cmd;
        cmd5.insert(cmd5.end(), {"plugins", "deps"});
        runCmd("plugins deps", cmd5);
        
        std::vector<std::string> cmd6 = oc_cmd;
        cmd6.insert(cmd6.end(), {"plugins", "registry"});
        runCmd("plugins registry", cmd6);
        
        std::vector<std::string> cmd7 = oc_cmd;
        cmd7.insert(cmd7.end(), {"skills", "check"});
        runCmd("skills check", cmd7);
        
        std::vector<std::string> cmd8 = oc_cmd;
        cmd8.insert(cmd8.end(), {"hooks", "check"});
        runCmd("hooks check", cmd8);
        
        std::vector<std::string> cmd9 = oc_cmd;
        cmd9.insert(cmd9.end(), {"gateway", "status", "--deep"});
        runCmd("gateway status --deep", cmd9);
        
        std::vector<std::string> cmd10 = oc_cmd;
        cmd10.insert(cmd10.end(), {"channels", "status", "--probe"});
        runCmd("channels status --probe", cmd10);
        
        std::vector<std::string> cmd11 = oc_cmd;
        cmd11.insert(cmd11.end(), {"memory", "status", "--deep"});
        runCmd("memory status --deep", cmd11);
        
        std::vector<std::string> cmd12 = oc_cmd;
        cmd12.insert(cmd12.end(), {"sessions", "--all-agents"});
        runCmd("sessions --all-agents", cmd12);
        
        std::vector<std::string> cmd13 = oc_cmd;
        cmd13.insert(cmd13.end(), {"tasks", "list"});
        runCmd("tasks list", cmd13);
        
        std::vector<std::string> cmd14 = oc_cmd;
        cmd14.insert(cmd14.end(), {"cron", "list"});
        runCmd("cron list", cmd14);
        
        writeFooter();
        
        std::cout << "Audit complete. Output: " << out_file << std::endl;
    }
};

int main() {
    try {
        OpenClawAudit audit;
        audit.runAudit();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
