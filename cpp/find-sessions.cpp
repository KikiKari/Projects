// abstraction-provenance: {"artifact_sha256": "b77818cf24a6868763dbf214569453841d6b7447307cfbd5966e4f627284b245", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "cpp"}
// find-sessions.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <sys/wait.h>
#include <cstring>
#include <algorithm>
#include <sstream>

namespace fs = std::filesystem;

void usage() {
    std::cout << R"(Usage: find-sessions [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help
)";
}

std::string getEnvOrDefault(const char* env_var, const std::string& default_value) {
    const char* value = std::getenv(env_var);
    return value ? value : default_value;
}

bool commandExists(const std::string& cmd) {
    std::string command = "command -v " + cmd + " >/dev/null 2>&1";
    return std::system(command.c_str()) == 0;
}

std::string execCommand(const std::vector<std::string>& cmd) {
    std::string commandStr;
    for (const auto& arg : cmd) {
        commandStr += arg + " ";
    }
    
    FILE* pipe = popen(commandStr.c_str(), "r");
    if (!pipe) return "";
    
    char buffer[1024];
    std::string result;
    while (fgets(buffer, sizeof buffer, pipe)) {
        result += buffer;
    }
    pclose(pipe);
    return result;
}

bool list_sessions(const std::string& label, const std::vector<std::string>& tmux_cmd, const std::string& query) {
    std::vector<std::string> full_cmd = tmux_cmd;
    full_cmd.insert(full_cmd.end(), {"list-sessions", "-F", "#{session_name}\\t#{session_attached}\\t#{session_created_string}"});
    
    std::string commandStr;
    for (const auto& arg : full_cmd) {
        commandStr += arg + " ";
    }
    
    FILE* pipe = popen((commandStr + " 2>/dev/null").c_str(), "r");
    if (!pipe) {
        std::cerr << "No tmux server found on " << label << std::endl;
        return false;
    }
    
    char buffer[1024];
    std::string sessions;
    while (fgets(buffer, sizeof buffer, pipe)) {
        sessions += buffer;
    }
    int status = pclose(pipe);
    
    if (status != 0) {
        std::cerr << "No tmux server found on " << label << std::endl;
        return false;
    }
    
    if (!query.empty()) {
        std::istringstream iss(sessions);
        std::string line;
        std::string filtered_sessions;
        while (std::getline(iss, line)) {
            std::string lower_line = line;
            std::transform(lower_line.begin(), lower_line.end(), lower_line.begin(), ::tolower);
            std::string lower_query = query;
            std::transform(lower_query.begin(), lower_query.end(), lower_query.begin(), ::tolower);
            if (lower_line.find(lower_query) != std::string::npos) {
                filtered_sessions += line + "\n";
            }
        }
        sessions = filtered_sessions;
    }
    
    if (sessions.empty()) {
        std::cout << "No sessions found on " << label << std::endl;
        return true;
    }
    
    std::cout << "Sessions on " << label << ":" << std::endl;
    
    std::istringstream iss(sessions);
    std::string line;
    while (std::getline(iss, line)) {
        if (line.empty()) continue;
        
        size_t tab1 = line.find('\t');
        size_t tab2 = line.find('\t', tab1 + 1);
        
        if (tab1 != std::string::npos && tab2 != std::string::npos) {
            std::string name = line.substr(0, tab1);
            std::string attached = line.substr(tab1 + 1, tab2 - tab1 - 1);
            std::string created = line.substr(tab2 + 1);
            
            std::string attached_label = (attached == "1") ? "attached" : "detached";
            std::cout << "  - " << name << " (" << attached_label << ", started " << created << ")" << std::endl;
        }
    }
    
    return true;
}

int main(int argc, char* argv[]) {
    std::string socket_name;
    std::string socket_path;
    std::string query;
    bool scan_all = false;
    
    std::string tmpdir = getEnvOrDefault("TMPDIR", "/tmp");
    std::string socket_dir = getEnvOrDefault("CLAWDBOT_TMUX_SOCKET_DIR", tmpdir + "/clawdbot-tmux-sockets");
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "-L" || arg == "--socket") {
            if (i + 1 < argc) {
                socket_name = argv[++i];
            } else {
                std::cerr << "Option " << arg << " requires an argument." << std::endl;
                usage();
                return 1;
            }
        } else if (arg == "-S" || arg == "--socket-path") {
            if (i + 1 < argc) {
                socket_path = argv[++i];
            } else {
                std::cerr << "Option " << arg << " requires an argument." << std::endl;
                usage();
                return 1;
            }
        } else if (arg == "-A" || arg == "--all") {
            scan_all = true;
        } else if (arg == "-q" || arg == "--query") {
            if (i + 1 < argc) {
                query = argv[++i];
            } else {
                std::cerr << "Option " << arg << " requires an argument." << std::endl;
                usage();
                return 1;
            }
        } else if (arg == "-h" || arg == "--help") {
            usage();
            return 0;
        } else {
            std::cerr << "Unknown option: " << arg << std::endl;
            usage();
            return 1;
        }
    }
    
    if (scan_all && (!socket_name.empty() || !socket_path.empty())) {
        std::cerr << "Cannot combine --all with -L or -S" << std::endl;
        return 1;
    }
    
    if (!socket_name.empty() && !socket_path.empty()) {
        std::cerr << "Use either -L or -S, not both" << std::endl;
        return 1;
    }
    
    if (!commandExists("tmux")) {
        std::cerr << "tmux not found in PATH" << std::endl;
        return 1;
    }
    
    if (scan_all) {
        if (!fs::exists(socket_dir) || !fs::is_directory(socket_dir)) {
            std::cerr << "Socket directory not found: " << socket_dir << std::endl;
            return 1;
        }
        
        std::vector<fs::path> sockets;
        for (const auto& entry : fs::directory_iterator(socket_dir)) {
            if (entry.is_socket()) {
                sockets.push_back(entry.path());
            }
        }
        
        if (sockets.empty()) {
            std::cerr << "No sockets found under " << socket_dir << std::endl;
            return 1;
        }
        
        int exit_code = 0;
        for (const auto& sock : sockets) {
            std::vector<std::string> tmux_cmd = {"tmux", "-S", sock.string()};
            if (!list_sessions("socket path '" + sock.string() + "'", tmux_cmd, query)) {
                exit_code = 1;
            }
        }
        return exit_code;
    }
    
    std::vector<std::string> tmux_cmd = {"tmux"};
    std::string socket_label = "default socket";
    
    if (!socket_name.empty()) {
        tmux_cmd.push_back("-L");
        tmux_cmd.push_back(socket_name);
        socket_label = "socket name '" + socket_name + "'";
    } else if (!socket_path.empty()) {
        tmux_cmd.push_back("-S");
        tmux_cmd.push_back(socket_path);
        socket_label = "socket path '" + socket_path + "'";
    }
    
    if (!list_sessions(socket_label, std::vector<std::string>(tmux_cmd.begin() + 1, tmux_cmd.end()), query)) {
        return 1;
    }
    
    return 0;
}
