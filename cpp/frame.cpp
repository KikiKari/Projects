// abstraction-provenance: {"artifact_sha256": "e93c9b133798db8d533a086bd57154d2df7165774aca2835d047bb66403cca76", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "cpp"}
// frame.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <cstdlib>
#include <unistd.h>
#include <sys/wait.h>

namespace fs = std::filesystem;

void usage() {
    std::cerr << R"(Usage:
  frame <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame video.mp4 --out /tmp/frame.jpg
  frame video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame video.mp4 --index 0 --out /tmp/frame0.png
)";
    std::exit(2);
}

bool fileExists(const std::string& path) {
    return fs::exists(path) && fs::is_regular_file(path);
}

std::string dirname(const std::string& path) {
    return fs::path(path).parent_path().string();
}

void runFFmpeg(const std::vector<std::string>& args) {
    std::vector<char*> argv;
    argv.reserve(args.size() + 1);
    
    for (const auto& arg : args) {
        argv.push_back(const_cast<char*>(arg.c_str()));
    }
    argv.push_back(nullptr);

    pid_t pid = fork();
    if (pid == 0) {
        execvp("ffmpeg", argv.data());
        std::perror("Failed to execute ffmpeg");
        std::exit(1);
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) != 0) {
            std::exit(WEXITSTATUS(status));
        }
        if (WIFSIGNALED(status)) {
            std::exit(1);
        }
    } else {
        std::perror("fork failed");
        std::exit(1);
    }
}

int main(int argc, char* argv[]) {
    if (argc <= 1 || std::string(argv[1]) == "-h" || std::string(argv[1]) == "--help") {
        usage();
    }

    std::string in = argv[1];
    
    std::string time;
    std::string index;
    std::string out;

    for (int i = 2; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--time") {
            if (i + 1 >= argc) {
                std::cerr << "Missing value for --time\n";
                usage();
            }
            time = argv[++i];
        } else if (arg == "--index") {
            if (i + 1 >= argc) {
                std::cerr << "Missing value for --index\n";
                usage();
            }
            index = argv[++i];
        } else if (arg == "--out") {
            if (i + 1 >= argc) {
                std::cerr << "Missing value for --out\n";
                usage();
            }
            out = argv[++i];
        } else {
            std::cerr << "Unknown arg: " << arg << "\n";
            usage();
        }
    }

    if (!fileExists(in)) {
        std::cerr << "File not found: " << in << "\n";
        return 1;
    }

    if (out.empty()) {
        std::cerr << "Missing --out\n";
        usage();
    }

    fs::create_directories(dirname(out));

    if (!index.empty()) {
        runFFmpeg({
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", in,
            "-vf", "select=eq(n\\," + index + ")",
            "-vframes", "1",
            out
        });
    } else if (!time.empty()) {
        runFFmpeg({
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-ss", time,
            "-i", in,
            "-frames:v", "1",
            out
        });
    } else {
        runFFmpeg({
            "ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
            "-i", in,
            "-vf", "select=eq(n\\,0)",
            "-vframes", "1",
            out
        });
    }

    std::cout << out << "\n";
    return 0;
}
