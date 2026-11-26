// abstraction-provenance: {"artifact_sha256": "423a14da3a93984dee35992c83a5452bf4645bd2c96b25a6d9e1221d6d9666c7", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "cpp"}
// generate-wavespeed.mjs — portiert nach cpp
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <thread>
#include <chrono>
#include <curl/curl.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

// Callback function for writing received data into a string
size_t WriteCallback(void* contents, size_t size, size_t nmemb, std::string* userp) {
    size_t totalSize = size * nmemb;
    userp->append((char*)contents, totalSize);
    return totalSize;
}

// Function to read file content as base64 encoded string
std::string readFileAsBase64(const std::string& filepath) {
    std::ifstream file(filepath, std::ios::binary);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + filepath);
    }

    // Read binary data
    std::vector<unsigned char> buffer(std::istreambuf_iterator<char>(file), {});
    file.close();

    // Encode to base64
    static const std::string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    std::string result;
    int val = 0, valb = -6;
    for (unsigned char c : buffer) {
        val = (val << 8) + c;
        valb += 8;
        while (valb >= 0) {
            result.push_back(chars[(val >> valb) & 0x3F]);
            valb -= 6;
        }
    }
    if (valb > -6) result.push_back(chars[((val << 8) >> (valb + 8)) & 0x3F]);
    while (result.size() % 4) result.push_back('=');

    return result;
}

// Function to download file from URL and save it
bool downloadFile(const std::string& url, const std::string& filepath) {
    CURL* curl;
    FILE* fp;
    CURLcode res;

    curl = curl_easy_init();
    if (curl) {
        fp = fopen(filepath.c_str(), "wb");
        if (!fp) {
            curl_easy_cleanup(curl);
            return false;
        }

        curl_easy_setopt(curl, CURLOPT_URL, url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, NULL);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
        res = curl_easy_perform(curl);
        fclose(fp);
        curl_easy_cleanup(curl);

        return (res == CURLE_OK);
    }
    return false;
}

int main() {
    // Get API key from environment variable
    const char* key_env = std::getenv("WAVESPEED_API_KEY");
    if (!key_env) {
        std::cerr << "WAVESPEED_API_KEY fehlt." << std::endl;
        return 1;
    }
    std::string key(key_env);

    // Define paths
    std::string script_dir = "."; // Adjust this according to your needs
    std::string jobs_file = script_dir + "/../media-production/wavespeed-jobs.json";
    std::string raw_dir = script_dir + "/../media-production/raw/";
    std::string public_dir = script_dir + "/../public/media/";
    std::string results_file = script_dir + "/../media-production/wavespeed-results.json";

    // Create directories
    fs::create_directories(raw_dir);
    fs::create_directories(public_dir);

    // Load jobs
    std::ifstream jobs_stream(jobs_file);
    if (!jobs_stream.is_open()) {
        std::cerr << "Could not open jobs file." << std::endl;
        return 1;
    }
    json jobs;
    jobs_stream >> jobs;
    jobs_stream.close();

    // Load existing log
    json log;
    std::ifstream log_stream(results_file);
    if (log_stream.is_open()) {
        log_stream >> log;
        log_stream.close();
    } else {
        log = json::array();
    }

    // Process each job
    for (const auto& job : jobs) {
        std::string job_id = job["id"];
        std::string output_name = job["output"];
        std::string raw_path = raw_dir + job_id + ".png";
        std::string target_path = public_dir + output_name + ".png";

        // Check if already generated
        if (fs::exists(raw_path)) {
            bool found = false;
            for (const auto& entry : log) {
                if (entry["id"] == job_id) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                json new_entry = {
                    {"id", job_id},
                    {"requestId", "completed-before-resume"},
                    {"model", "google/nano-banana-2/edit"},
                    {"resolution", "4k"},
                    {"plannedCostUsd", 0.14},
                    {"output", output_name + ".png"}
                };
                log.push_back(new_entry);
                
                // Save updated log
                std::ofstream out_log(results_file);
                if (out_log.is_open()) {
                    out_log << log.dump(2) << std::endl;
                    out_log.close();
                }
            }
            std::cout << "Übersprungen: " << job_id << " ist bereits vorhanden." << std::endl;
            continue;
        }

        // Prepare images
        std::vector<std::string> images;
        for (const auto& image : job["images"]) {
            std::string img_url = image.get<std::string>();
            if (img_url.substr(0, 4) == "http" || img_url.substr(0, 5) == "data:") {
                images.push_back(img_url);
            } else {
                try {
                    std::string base64_data = readFileAsBase64(script_dir + "/../" + img_url);
                    images.push_back("data:image/png;base64," + base64_data);
                } catch (const std::exception& e) {
                    std::cerr << "Error reading image: " << e.what() << std::endl;
                    return 1;
                }
            }
        }

        // Submit request to WaveSpeed API
        CURL* curl = curl_easy_init();
        if (!curl) {
            std::cerr << "Failed to initialize CURL" << std::endl;
            return 1;
        }

        std::string response_string;
        curl_easy_setopt(curl, CURLOPT_URL, "https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit");
        curl_easy_setopt(curl, CURLOPT_POST, 1L);
        
        // Set headers
        struct curl_slist* headers = nullptr;
        headers = curl_slist_append(headers, ("Authorization: Bearer " + key).c_str());
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

        // Build POST data
        json post_data = {
            {"prompt", job["prompt"]},
            {"images", images},
            {"aspect_ratio", job["aspectRatio"]},
            {"resolution", "4k"},
            {"output_format", "png"},
            {"enable_web_search", false},
            {"enable_image_search", false},
            {"enable_sync_mode", false},
            {"enable_base64_output", false}
        };

        std::string post_data_str = post_data.dump();
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, post_data_str.c_str());

        // Set callback to capture response
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response_string);

        // Perform request
        CURLcode res = curl_easy_perform(curl);
        long response_code;
        curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response_code);
        curl_slist_free_all(headers);
        curl_easy_cleanup(curl);

        if (res != CURLE_OK || response_code >= 400) {
            std::cerr << "WaveSpeed submit fehlgeschlagen: " << response_code << " " << response_string << std::endl;
            return 1;
        }

        // Parse response
        json submitted_response = json::parse(response_string);
        std::string request_id = submitted_response.value("data", json::object()).value("id", submitted_response.value("id", ""));

        if (request_id.empty()) {
            std::cerr << "Invalid response from WaveSpeed API" << std::endl;
            return 1;
        }

        // Poll for result
        std::string result_url = "https://api.wavespeed.ai/api/v3/predictions/" + request_id + "/result";
        json result;
        bool completed = false;

        for (int attempt = 0; attempt < 90; ++attempt) {
            std::this_thread::sleep_for(std::chrono::seconds(4));

            curl = curl_easy_init();
            if (!curl) {
                std::cerr << "Failed to initialize CURL for polling" << std::endl;
                return 1;
            }

            std::string poll_response;
            curl_easy_setopt(curl, CURLOPT_URL, result_url.c_str());
            
            // Set authorization header
            struct curl_slist* poll_headers = nullptr;
            poll_headers = curl_slist_append(poll_headers, ("Authorization: Bearer " + key).c_str());
            curl_easy_setopt(curl, CURLOPT_HTTPHEADER, poll_headers);
            
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &poll_response);

            res = curl_easy_perform(curl);
            curl_slist_free_all(poll_headers);
            curl_easy_cleanup(curl);

            if (res == CURLE_OK) {
                result = json::parse(poll_response);
                std::string status = result.value("data", json::object()).value("status", "");
                if (status == "completed") {
                    completed = true;
                    break;
                } else if (status == "failed") {
                    std::cerr << "WaveSpeed job fehlgeschlagen: " << job_id << std::endl;
                    return 1;
                }
            }
        }

        if (!completed) {
            std::cerr << "Timeout waiting for WaveSpeed job completion: " << job_id << std::endl;
            return 1;
        }

        // Get output URL
        std::string output_url = result.value("data", json::object()).value("outputs", json::array())[0].get<std::string>();
        if (output_url.empty()) {
            std::cerr << "Kein Output für " << job_id << std::endl;
            return 1;
        }

        // Download the result
        if (!downloadFile(output_url, raw_path)) {
            std::cerr << "Failed to download output for " << job_id << std::endl;
            return 1;
        }

        // Copy to public directory
        try {
            fs::copy_file(raw_path, target_path, fs::copy_options::overwrite_existing);
        } catch (const fs::filesystem_error& e) {
            std::cerr << "Failed to copy file to public directory: " << e.what() << std::endl;
            return 1;
        }

        // Update log
        json new_entry = {
            {"id", job_id},
            {"requestId", request_id},
            {"model", "google/nano-banana-2/edit"},
            {"resolution", "4k"},
            {"plannedCostUsd", 0.14},
            {"output", output_name + ".png"}
        };
        log.push_back(new_entry);

        // Save updated log
        std::ofstream out_log(results_file);
        if (out_log.is_open()) {
            out_log << log.dump(2) << std::endl;
            out_log.close();
        }

        std::cout << "Abgeschlossen: " << job_id << std::endl;
    }

    // Final save of log
    std::ofstream final_log(results_file);
    if (final_log.is_open()) {
        final_log << log.dump(2) << std::endl;
        final_log.close();
    }

    double total_cost = log.size() * 0.14;
    std::cout << "WaveSpeed abgeschlossen: " << log.size() << " Assets, geplante Basiskosten $" 
              << std::fixed << std::setprecision(2) << total_cost << "." << std::endl;

    return 0;
}
