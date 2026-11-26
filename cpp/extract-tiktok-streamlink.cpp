// abstraction-provenance: {"artifact_sha256": "41feef3a06891b3ccbf2a607a90282a2c06707832faaa0991a7df18192f799c5", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "cpp"}
// extract-tiktok-streamlink.sh — portiert nach cpp
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <cstdlib>
#include <cstdio>
#include <memory>
#include <stdexcept>
#include <regex>
#include <unistd.h>
#include <sys/wait.h>

std::string exec(const char* cmd) {
    std::array<char, 128> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
        result += buffer.data();
    }
    return result;
}

bool command_exists(const std::string& cmd) {
    std::string command = "command -v " + cmd + " >/dev/null 2>&1";
    return system(command.c_str()) == 0;
}

std::string get_timestamp() {
    char buffer[21];
    time_t rawtime;
    struct tm *timeinfo;
    
    time(&rawtime);
    timeinfo = gmtime(&rawtime);
    
    strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", timeinfo);
    return std::string(buffer);
}

void emit_json(bool success, const std::string& method, const std::string& username,
               const std::string& url, const std::string& quality, const std::string& author,
               const std::string& title, const std::string& error, const std::string& timestamp,
               const std::string& status) {
    std::cout << "{";
    bool first = true;
    
    auto add_field = [&](const std::string& key, const std::string& value) {
        if (!value.empty()) {
            if (!first) std::cout << ",";
            std::cout << "\"" << key << "\":\"" << value << "\"";
            first = false;
        }
    };
    
    if (success) {
        std::cout << "\"success\":true";
        first = false;
    } else {
        std::cout << "\"success\":false";
        first = false;
    }
    
    add_field("method", method);
    add_field("username", username);
    add_field("url", url);
    add_field("quality", quality);
    add_field("author", author);
    add_field("title", title);
    add_field("error", error);
    add_field("timestamp", timestamp);
    add_field("status", status);
    
    std::cout << "}" << std::endl;
}

double get_load_per_cpu() {
    std::string load_avg_cmd = "python3 -c 'import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))'";
    std::string output = exec(load_avg_cmd.c_str());
    return std::stod(output);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <username> [quality] [--json]" << std::endl;
        return 64;
    }
    
    std::string username = argv[1];
    if (username[0] == '@') {
        username = username.substr(1);
    }
    
    std::string quality = (argc >= 3) ? argv[2] : "best";
    std::string json_flag = (argc >= 4) ? argv[3] : "";
    std::string timestamp = get_timestamp();
    
    // Validate username
    std::regex username_regex("^[A-Za-z0-9._]{1,24}$");
    if (!std::regex_match(username, username_regex)) {
        std::cerr << "Invalid TikTok username" << std::endl;
        return 64;
    }
    
    // Validate quality
    std::vector<std::string> valid_qualities = {"best", "worst", "original", "1080p60", "720p60", "720p", "540p", "360p", "auto"};
    bool valid_quality = false;
    for (const auto& q : valid_qualities) {
        if (quality == q) {
            valid_quality = true;
            break;
        }
    }
    if (!valid_quality) {
        std::cerr << "Invalid stream quality" << std::endl;
        return 64;
    }
    
    // Check load
    double load_per_cpu = get_load_per_cpu();
    const char* max_load_env = std::getenv("TIKTOK_MAX_LOAD_PER_CPU");
    double max_load = max_load_env ? std::stod(max_load_env) : 1.5;
    
    if (load_per_cpu > max_load) {
        emit_json(false, "streamlink", username, "", quality, "", "", 
                  "host overloaded", timestamp, "overloaded");
        return 75;
    }
    
    // Check if streamlink exists
    if (!command_exists("streamlink")) {
        emit_json(false, "streamlink", username, "", quality, "", "", 
                  "streamlink not installed", timestamp, "dependency_missing");
        return 2;
    }
    
    std::string live_url = "https://www.tiktok.com/@" + username + "/live";
    std::string selector;
    
    if (quality == "original") {
        selector = "origin,uhd_60,hd_60,hd,sd,ld,best,worst";
    } else if (quality == "auto") {
        selector = "best,origin,uhd_60,hd_60,hd,sd,ld,worst";
    } else if (quality == "1080p60") {
        selector = "uhd_60,hd_60,hd,sd,ld,worst";
    } else if (quality == "720p60") {
        selector = "hd_60,hd,sd,ld,worst";
    } else if (quality == "720p") {
        selector = "hd,sd,ld,worst";
    } else if (quality == "540p") {
        selector = "sd,ld,worst";
    } else if (quality == "360p") {
        selector = "ld,worst";
    } else {
        selector = quality;
    }
    
    // Try streamlink with --json first
    std::string streamlink_cmd = "streamlink --json \"" + live_url + "\" \"" + selector + "\" 2>/dev/null";
    std::string output = exec(streamlink_cmd.c_str());
    
    if (output.empty()) {
        // Try with --stream-url
        streamlink_cmd = "streamlink --stream-url \"" + live_url + "\" \"" + selector + "\" 2>/dev/null";
        std::string url = exec(streamlink_cmd.c_str());
        
        if (url.empty()) {
            emit_json(false, "streamlink", username, "", quality, "", "", 
                      "streamlink failed or no stream found", timestamp, "offline");
            return 1;
        }
        
        // Remove trailing newline
        if (!url.empty() && url.back() == '\n') {
            url.pop_back();
        }
        
        if (json_flag == "--json") {
            emit_json(true, "streamlink", username, url, quality, "", "", "", timestamp, "live");
        } else {
            std::cout << url << std::endl;
        }
        return 0;
    }
    
    // Parse JSON output
    std::string parse_cmd = "python3 -c '"
        "import json, sys;"
        "data = json.load(sys.stdin);"
        "url = data.get(\\\"url\\\", \\\"\\\");"
        "streams = data.get(\\\"streams\\\", {});"
        "if not url and isinstance(streams, dict):"
        "    for key in (\\\"best\\\", \\\"worst\\\", *streams.keys()):"
        "        value = streams.get(key);"
        "        if isinstance(value, dict) and value.get(\\\"url\\\"):"
        "            url = value[\\\"url\\\"];"
        "            break;"
        "metadata = data.get(\\\"metadata\\\", {});"
        "print(\\\"{\\\\\\\"url\\\\\\\":\\\\\\\"\\\" + url + \\\"\\\\\\\",\\\\\\\"author\\\\\\\":\\\\\\\"\\\" + metadata.get(\\\"author\\\", \\\"\\\") + \\\"\\\\\\\",\\\\\\\"title\\\\\\\":\\\\\\\"\\\" + metadata.get(\\\"title\\\", \\\"\\\") + \\\"\\\\\\\"}\\\")'"
        " <<<'" + output + "' 2>/dev/null";
    
    std::string parsed_output = exec(parse_cmd.c_str());
    
    if (parsed_output.empty()) {
        emit_json(false, "streamlink", username, "", quality, "", "", 
                  "invalid streamlink JSON", timestamp, "technical_error");
        return 2;
    }
    
    // Extract fields from parsed JSON
    std::string extract_fields_cmd = "python3 -c '"
        "import json, sys;"
        "d=json.load(sys.stdin);"
        "print(d.get(\\\"url\\\", \\\"\\\"));"
        "print(d.get(\\\"author\\\", \\\"\\\"));"
        "print(d.get(\\\"title\\\", \\\"\\\"))'"
        " <<<'" + parsed_output + "'";
    
    std::string fields_output = exec(extract_fields_cmd.c_str());
    std::vector<std::string> fields;
    size_t pos = 0;
    std::string token;
    while ((pos = fields_output.find('\n')) != std::string::npos) {
        token = fields_output.substr(0, pos);
        fields.push_back(token);
        fields_output.erase(0, pos + 1);
    }
    
    std::string url = fields.size() > 0 ? fields[0] : "";
    std::string author = fields.size() > 1 ? fields[1] : "";
    std::string title = fields.size() > 2 ? fields[2] : "";
    
    if (url.empty()) {
        emit_json(false, "streamlink", username, "", quality, author, title, 
                  "could not extract stream URL", timestamp, "offline");
        return 1;
    }
    
    if (json_flag == "--json") {
        emit_json(true, "streamlink", username, url, quality, author, title, "", timestamp, "live");
    } else {
        std::cout << url << std::endl;
    }
    
    return 0;
}
