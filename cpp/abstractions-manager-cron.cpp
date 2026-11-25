// abstraction-provenance: {"artifact_sha256": "c554bbb9a043bea129227bf162d65969d3cccb8e027448a0dc76bba8ab6dd44f", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "cpp"}
// abstractions-manager-cron.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <cstdlib>
#include <unistd.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <fcntl.h>

int main(int argc, char* argv[]) {
    // Set environment variables
    setenv("PATH", "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin", 1);

    // Load environment variables from .env file
    std::ifstream envFile("/home/openclaw/.openclaw/.env");
    if (envFile.is_open()) {
        std::string line;
        while (getline(envFile, line)) {
            size_t delimiterPos = line.find('=');
            if (delimiterPos != std::string::npos) {
                std::string key = line.substr(0, delimiterPos);
                std::string value = line.substr(delimiterPos + 1);
                setenv(key.c_str(), value.c_str(), 1);
            }
        }
        envFile.close();
    }

    // Check if OPENROUTER_API_KEY is set
    if (getenv("OPENROUTER_API_KEY") == nullptr) {
        std::cerr << "OPENROUTER_API_KEY fehlt" << std::endl;
        return 1;
    }

    // Set GITHUB_TOKEN if not already set
    if (getenv("GITHUB_TOKEN") == nullptr) {
        if (getenv("GH_TOKEN") != nullptr) {
            setenv("GITHUB_TOKEN", getenv("GH_TOKEN"), 1);
        } else if (getenv("GH_ACCESS_TOKEN") != nullptr) {
            setenv("GITHUB_TOKEN", getenv("GH_ACCESS_TOKEN"), 1);
        }
    }

    // Create a lock file
    int lockFd = open("/home/openclaw/.openclaw/locks/abstractions-manager.lock", O_RDWR | O_CREAT, 0666);
    if (lockFd == -1) {
        std::cerr << "Failed to create lock file" << std::endl;
        return 1;
    }

    // Try to acquire the lock
    if (flock(lockFd, LOCK_EX | LOCK_NB) == -1) {
        std::cerr << "Failed to acquire lock" << std::endl;
        close(lockFd);
        return 1;
    }

    // Prepare the command to execute
    std::vector<std::string> command = {
        "/usr/bin/python3",
        "/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py"
    };

    // Add the command line arguments
    for (int i = 1; i < argc; ++i) {
        command.push_back(argv[i]);
    }

    // Convert the command to a format suitable for execvp
    std::vector<char*> argvList;
    for (const auto& arg : command) {
        argvList.push_back(const_cast<char*>(arg.c_str()));
    }
    argvList.push_back(nullptr);

    // Execute the command
    execvp(argvList[0], argvList.data());

    // If execvp returns, it means an error occurred
    std::cerr << "Failed to execute command" << std::endl;
    flock(lockFd, LOCK_UN);
    close(lockFd);
    return 1;
}
