// abstraction-provenance: {"artifact_sha256": "259867e6c43bce821b703291d342e3751cabff638d33816c76282d2ecdc836e5", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "cpp"}
// extract-tiktok-yt-dlp.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <fstream>
#include <sstream>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <regex>
#include <filesystem>
#include <chrono>
#include <iomanip>
#include <ctime>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

// Function to execute a command and capture its output
std::pair<std::string, int> exec_command(const std::string& cmd) {
    std::array<char, 128> buffer;
    std::string result;
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) {
        return { "", -1 };
    }
    while (fgets(buffer.data(), buffer.size(), pipe) != nullptr) {
        result += buffer.data();
    }
    int status = pclose(pipe);
    int exit_code = WEXITSTATUS(status);
    return { result, exit_code };
}

// Function to get current UTC timestamp
std::string get_timestamp() {
    auto now = std::chrono::system_clock::now();
    auto time_t = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(gmtime(&time_t), "%Y-%m-%dT%H:%M:%SZ");
    return ss.str();
}

// Function to emit JSON response
void emit_json(bool success, const std::string& method, const std::string& username,
               const std::string& url, const std::string& format,
               const std::string& error, const std::string& timestamp,
               const std::string& status) {
    json payload;
    payload["success"] = success;
    payload["method"] = method;
    payload["username"] = username;
    if (!url.empty()) payload["url"] = url;
    if (!format.empty()) payload["format"] = format;
    if (!error.empty()) payload["error"] = error;
    payload["timestamp"] = timestamp;
    if (!status.empty()) payload["status"] = status;
    
    std::cout << payload.dump(-1) << std::endl;
}

// Function to cleanup temporary directory
void cleanup_temp_dir(const std::string& tmp_dir) {
    std::error_code ec;
    fs::remove_all(tmp_dir, ec);
}

int main(int argc, char* argv[]) {
    // Parse arguments
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <username> [format] [--json]" << std::endl;
        return 64;
    }
    
    std::string username_arg = argv[1];
    std::string username = username_arg;
    if (!username.empty() && username[0] == '@') {
        username = username.substr(1);
    }
    
    std::string format = (argc >= 3) ? argv[2] : "best";
    std::string json_flag = (argc >= 4) ? argv[3] : "";
    
    std::string timestamp = get_timestamp();
    
    // Create temporary directory
    std::string tmp_dir_template = "/tmp/tiktok-yt-dlp.XXXXXX";
    char tmp_dir_buf[256];
    strcpy(tmp_dir_buf, tmp_dir_template.c_str());
    char* mkdtemp_result = mkdtemp(tmp_dir_buf);
    if (!mkdtemp_result) {
        std::cerr << "Failed to create temporary directory" << std::endl;
        return 1;
    }
    std::string tmp_dir = mkdtemp_result;
    
    // Register cleanup function
    std::atexit([tmp_dir]() {
        cleanup_temp_dir(tmp_dir);
    });
    
    // Validate username
    std::regex username_regex("^[A-Za-z0-9._]{1,24}$");
    if (!std::regex_match(username, username_regex)) {
        std::cerr << "Invalid TikTok username" << std::endl;
        return 64;
    }
    
    // Validate format
    std::vector<std::string> valid_formats = {
        "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
        "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
        "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
        "hls-sd/hls-ld/flv-sd/flv-ld",
        "hls-ld/flv-ld",
        "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
    };
    
    bool valid_format = false;
    for (const auto& f : valid_formats) {
        if (format == f) {
            valid_format = true;
            break;
        }
    }
    
    if (!valid_format) {
        std::cerr << "Invalid yt-dlp format" << std::endl;
        return 64;
    }
    
    // Check system load
    std::string load_cmd = "python3 -c 'import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))'";
    auto [load_output, _] = exec_command(load_cmd);
    double load_per_cpu = 0.0;
    try {
        load_per_cpu = std::stod(load_output);
    } catch (...) {
        load_per_cpu = 0.0;
    }
    
    const char* max_load_env = std::getenv("TIKTOK_MAX_LOAD_PER_CPU");
    double max_load = max_load_env ? std::stod(max_load_env) : 1.5;
    
    if (load_per_cpu > max_load) {
        emit_json(false, "yt-dlp", username, "", format, "host overloaded", timestamp, "overloaded");
        return 75;
    }
    
    // Check if yt-dlp is installed
    auto [_, yt_dlp_exit] = exec_command("command -v yt-dlp >/dev/null 2>&1");
    if (yt_dlp_exit != 0) {
        emit_json(false, "yt-dlp", username, "", format, "yt-dlp not installed", timestamp, "dependency_missing");
        return 2;
    }
    
    // Run yt-dlp command
    std::string live_url = "https://www.tiktok.com/@" + username + "/live";
    std::string stdout_file = tmp_dir + "/stdout.json";
    std::string stderr_file = tmp_dir + "/stderr.log";
    std::string yt_dlp_cmd = "yt-dlp --no-warnings --dump-single-json --skip-download --format \"" + 
                             format + "\" \"" + live_url + "\" >\"" + stdout_file + "\" 2>\"" + stderr_file + "\"";
    
    int exit_code = system(yt_dlp_cmd.c_str()) >> 8;
    
    if (exit_code != 0) {
        std::ifstream err_file(stderr_file);
        std::string stderr_content((std::istreambuf_iterator<char>(err_file)),
                                    std::istreambuf_iterator<char>());
        err_file.close();
        
        std::string status = "technical_error";
        int code = 2;
        
        std::transform(stderr_content.begin(), stderr_content.end(), stderr_content.begin(), ::tolower);
        if (stderr_content.find("not currently live") != std::string::npos ||
            stderr_content.find("no live cdn found") != std::string::npos ||
            stderr_content.find("not available") != std::string::npos ||
            stderr_content.find("private video") != std::string::npos) {
            status = "offline";
            code = 1;
        }
        
        // Truncate error message to 1000 characters
        std::string error_msg = stderr_content.substr(0, 1000);
        emit_json(false, "yt-dlp", username, "", format, error_msg, timestamp, status);
        return code;
    }
    
    // Extract URL from JSON
    std::ifstream json_file(stdout_file);
    json data;
    try {
        json_file >> data;
    } catch (...) {
        json_file.close();
        emit_json(false, "yt-dlp", username, "", format, "could not parse JSON response", timestamp, "offline");
        return 1;
    }
    json_file.close();
    
    std::string url;
    std::vector<std::string> candidates;
    
    if (data.contains("url") && data["url"].is_string()) {
        candidates.push_back(data["url"]);
    }
    
    if (data.contains("formats") && data["formats"].is_array()) {
        for (const auto& item : data["formats"]) {
            if (item.is_object() && item.contains("url") && item["url"].is_string()) {
                candidates.push_back(item["url"]);
            }
        }
    }
    
    for (const auto& candidate : candidates) {
        std::string lower_candidate = candidate;
        std::transform(lower_candidate.begin(), lower_candidate.end(), lower_candidate.begin(), ::tolower);
        
        if (candidate.rfind("https://", 0) == 0 && 
            (lower_candidate.find(".m3u8") != std::string::npos || 
             lower_candidate.find(".flv") != std::string::npos) &&
            candidate.find("only_audio=1") == std::string::npos) {
            url = candidate;
            break;
        }
    }
    
    if (url.empty()) {
        emit_json(false, "yt-dlp", username, "", format, "could not extract HTTPS video URL", timestamp, "offline");
        return 1;
    }
    
    if (json_flag == "--json") {
        emit_json(true, "yt-dlp", username, url, format, "", timestamp, "live");
    } else {
        std::cout << url << std::endl;
    }
    
    return 0;
}
