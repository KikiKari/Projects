// abstraction-provenance: {"artifact_sha256": "d5d9476f73083c39031a099f2128e97173e6a77c2be2aef9e5e0f3150e860fec", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "cpp"}
// gateway_transport.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <chrono>
#include <exception>
#include <fstream>
#include <functional>
#include <iomanip>
#include <map>
#include <memory>
#include <mutex>
#include <nlohmann/json.hpp>
#include <random>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <vector>

using json = nlohmann::json;

class TransportUnresolved : public std::runtime_error {
public:
    explicit TransportUnresolved(const std::string& message) : std::runtime_error(message) {}
};

std::string gateway_token() {
    const char* env_token = std::getenv("OPENCLAW_GATEWAY_TOKEN");
    if (env_token && std::string(env_token).find_first_not_of(" \t\n\r") != std::string::npos) {
        std::string token(env_token);
        token.erase(0, token.find_first_not_of(" \t\n\r"));
        token.erase(token.find_last_not_of(" \t\n\r") + 1);
        return token;
    }

    std::string config_path_str;
    const char* env_config_path = std::getenv("OPENCLAW_CONFIG_PATH");
    if (env_config_path) {
        config_path_str = env_config_path;
    } else {
        config_path_str = std::getenv("HOME");
        if (!config_path_str.empty()) {
            config_path_str += "/.openclaw/openclaw.json";
        } else {
            return "";
        }
    }

    try {
        std::ifstream file(config_path_str);
        if (!file.is_open()) {
            return "";
        }
        json config;
        file >> config;
        auto gateway = config.find("gateway");
        if (gateway != config.end() && gateway->is_object()) {
            auto auth = gateway->find("auth");
            if (auth != gateway->end() && auth->is_object()) {
                auto token_it = auth->find("token");
                if (token_it != auth->end() && token_it->is_string()) {
                    std::string token = token_it->get<std::string>();
                    if (!token.empty() && !token.starts_with("${")) {
                        token.erase(0, token.find_first_not_of(" \t\n\r"));
                        token.erase(token.find_last_not_of(" \t\n\r") + 1);
                        return token;
                    }
                }
            }
        }
    } catch (...) {
        return "";
    }
    return "";
}

class GatewayTransport {
private:
    json& state;
    std::function<void(json&)> save;
    std::string url;
    std::string token;
    int timeout;
    int interval;
    std::function<json(const std::string&, const json&, const std::string&)> opener;
    std::function<double()> clock;
    std::function<void(int)> sleep_func;

    json _request(const std::string& node, const json& request, const std::string& device_id = "") {
        json payload_data = {
            {"node", node},
            {"device_id", device_id.empty() ? nullptr : device_id},
            {"request", request}
        };
        
        std::string payload_str = payload_data.dump();
        
        // Simulate HTTP request/response using custom opener function
        try {
            json result = opener(node, request, device_id);
            
            if (!result.contains("result")) {
                throw TransportUnresolved("invalid gateway response");
            }
            
            if (!device_id.empty() && result.contains("device_id") && 
                result["device_id"].get<std::string>() != device_id) {
                throw TransportUnresolved("gateway device identity mismatch");
            }
            
            return result["result"];
        } catch (const std::exception& e) {
            throw TransportUnresolved(std::string("Gateway request failed: ") + e.what());
        }
    }

    void _release(const json& original, json& entry) {
        if (entry.contains("released") && entry["released"] == true) {
            return;
        }
        
        try {
            json result = _request(
                original["selected_node"].get<std::string>(),
                {
                    {"operation", "release"},
                    {"job_id", original["job_id"]},
                    {"attempt_id", original["attempt_id"]}
                },
                original["selected_device_id"].get<std::string>()
            );
            
            if (result.contains("status") && result["status"] == "released" &&
                result["job_id"] == original["job_id"] &&
                result["attempt_id"] == original["attempt_id"] &&
                result["selected_node"] == original["selected_node"] &&
                result["target_language"] == original["target_language"]) {
                
                entry["released"] = true;
                save(state);
            }
        } catch (const TransportUnresolved&) {
            // Retry cleanup later; the result is durable in manager state.
            return;
        }
    }

public:
    GatewayTransport(json& state,
                     std::function<void(json&)> save,
                     const std::string& url,
                     const std::string& token,
                     int timeout = 3900,
                     int interval = 3,
                     std::function<json(const std::string&, const json&, const std::string&)> opener = nullptr,
                     std::function<double()> clock = []() { 
                         auto now = std::chrono::steady_clock::now().time_since_epoch();
                         return std::chrono::duration<double>(now).count();
                     },
                     std::function<void(int)> sleep_func = [](int seconds) {
                         std::this_thread::sleep_for(std::chrono::seconds(seconds));
                     }) :
        state(state), save(save), url(url), token(token),
        timeout(timeout), interval(interval), clock(clock), sleep_func(sleep_func) {
        
        // Parse URL to validate format
        if (url.find("http://") != 0 && url.find("https://") != 0) {
            throw std::invalid_argument("invalid Gateway URL");
        }
        
        if (url.find("http://") == 0) {
            size_t start = 7; // Skip "http://"
            size_t end = url.find("/", start);
            if (end == std::string::npos) end = url.length();
            std::string hostname = url.substr(start, end - start);
            if (hostname != "127.0.0.1" && hostname != "localhost" && hostname != "::1") {
                throw std::invalid_argument("unencrypted Gateway must use loopback");
            }
        }
        
        if (token.empty() || timeout <= 0 || interval <= 0) {
            throw std::invalid_argument("Gateway token and positive timeouts required");
        }
    }

    json available() {
        json result = _request("node1", {{"operation", "availability"}});
        if (!result.is_object()) {
            throw TransportUnresolved("invalid node availability");
        }
        return result;
    }

    void release_pending() {
        if (!state.contains("auftraege")) return;
        
        for (auto& [key, entry] : state["auftraege"].items()) {
            if (entry.is_object() && 
                entry.contains("status") && 
                (entry["status"] == "completed" || entry["status"] == "rejected" || entry["status"] == "failed") &&
                entry.contains("job") && entry["job"].is_object()) {
                _release(entry["job"], entry);
            }
        }
    }

    void reject(json& job, const std::string& reason) {
        if (!job.contains("source_sha256") || !job.contains("target_language")) {
            return;
        }
        
        std::string key = job["source_sha256"].get<std::string>() + ":" + job["target_language"].get<std::string>();
        
        if (!state.contains("auftraege") || !state["auftraege"].contains(key)) {
            return;
        }
        
        json& entry = state["auftraege"][key];
        if (!entry.is_object() || !entry.contains("status") || entry["status"] != "completed") {
            return;
        }
        
        if (!entry.contains("job") || !entry["job"].is_object() || 
            !entry["job"].contains("attempt_id") || 
            !job.contains("attempt_id") ||
            entry["job"]["attempt_id"] != job["attempt_id"]) {
            throw TransportUnresolved("rejected attempt identity mismatch");
        }
        
        entry["status"] = "rejected";
        entry["validation_error"] = reason.substr(0, 500);
        save(state);
    }

    json operator()(json& job) {
        if (!job.contains("source_sha256") || !job.contains("target_language") || !job.contains("selected_device_id")) {
            throw std::invalid_argument("missing source identity");
        }
        
        std::string key = job["source_sha256"].get<std::string>() + ":" + job["target_language"].get<std::string>();
        
        json empty_obj = json::object();
        json& entries = state.contains("auftraege") ? state["auftraege"] : (state["auftraege"] = json::object());
        
        bool fresh = false;
        json* entry_ptr = nullptr;
        
        if (entries.contains(key)) {
            json& entry = entries[key];
            if (entry.is_object() && entry.contains("status") && entry["status"] == "rejected") {
                _release(entry["job"], entry);
                if (!entry.contains("released") || entry["released"] != true) {
                    throw TransportUnresolved("rejected attempt release is unresolved");
                }
                
                json previous = entry;
                json original = job;
                original["attempt_id"] = generate_uuid();
                
                json new_entry = {
                    {"job", original},
                    {"status", "submitted"}
                };
                
                if (previous.contains("previous_attempts")) {
                    new_entry["previous_attempts"] = previous["previous_attempts"];
                } else {
                    new_entry["previous_attempts"] = json::array();
                }
                
                new_entry["previous_attempts"].push_back({
                    {"job_id", previous["job"].value("job_id", "")},
                    {"attempt_id", previous["job"].value("attempt_id", "")},
                    {"selected_node", previous["job"].value("selected_node", "")},
                    {"validation_error", previous.value("validation_error", "")}
                });
                
                entries[key] = new_entry;
                save(state);
                fresh = true;
                entry_ptr = &entries[key];
            } else {
                entry_ptr = &entry;
            }
        } else {
            fresh = true;
            json original = job;
            original["attempt_id"] = generate_uuid();
            
            json new_entry = {
                {"job", original},
                {"status", "submitted"}
            };
            
            entries[key] = new_entry;
            save(state);
            entry_ptr = &entries[key];
        }
        
        json& entry = *entry_ptr;
        json& original = entry["job"];
        
        // Update job with original values
        for (auto& item : original.items()) {
            job[item.key()] = item.value();
        }
        
        if (entry.contains("response")) {
            _release(original, entry);
            return entry["response"];
        }
        
        if (entry.contains("status") && entry["status"] == "failed") {
            throw TransportUnresolved("attempt requires reconciliation");
        }
        
        json status;
        if (fresh) {
            try {
                status = _request(
                    original["selected_node"].get<std::string>(),
                    {
                        {"operation", "execute"},
                        {"job", original}
                    },
                    original["selected_device_id"].get<std::string>()
                );
            } catch (const TransportUnresolved&) {
                // The request may have been accepted. Query, never resend.
            }
        }
        
        double deadline = clock() + timeout;
        while (true) {
            if (status.is_null()) {
                status = _request(
                    original["selected_node"].get<std::string>(),
                    {
                        {"operation", "status"},
                        {"job_id", original["job_id"]},
                        {"attempt_id", original["attempt_id"]}
                    },
                    original["selected_device_id"].get<std::string>()
                );
            }
            
            if (!status.is_object()) {
                throw TransportUnresolved("attempt is not known by the node");
            }
            
            if (status.value("job_id", "") != original["job_id"] ||
                status.value("attempt_id", "") != original["attempt_id"] ||
                status.value("selected_node", "") != original["selected_node"] ||
                status.value("target_language", "") != original["target_language"]) {
                throw TransportUnresolved("status identity mismatch");
            }
            
            std::string state_val = status.value("status", "");
            if (state_val == "completed") {
                json response = status["response"];
                if (!response.is_object() || 
                    response.value("status", "") != "ok" ||
                    response.value("job_id", "") != original["job_id"] ||
                    response.value("selected_node", "") != original["selected_node"] ||
                    response.value("target_language", "") != original["target_language"] ||
                    !response.contains("code") || 
                    !response["code"].is_string() || 
                    response["code"].get<std::string>().empty()) {
                    throw TransportUnresolved("invalid translation result");
                }
                
                entry["response"] = response;
                entry["status"] = "completed";
                save(state);
                _release(original, entry);
                return response;
            }
            
            if (state_val == "failed" || state_val == "unknown") {
                entry["status"] = state_val;
                save(state);
                if (state_val == "failed") {
                    _release(original, entry);
                }
                throw TransportUnresolved("attempt requires reconciliation");
            }
            
            if (state_val != "running" || clock() >= deadline) {
                throw TransportUnresolved("attempt is unresolved");
            }
            
            sleep_func(interval);
            status = json(); // Reset status for next iteration
        }
    }

private:
    std::string generate_uuid() {
        static std::random_device rd;
        static std::mt19937 gen(rd());
        static std::uniform_int_distribution<> dis(0, 15);
        
        std::stringstream ss;
        ss << std::hex;
        for (int i = 0; i < 32; ++i) {
            if (i == 8 || i == 12 || i == 16 || i == 20) {
                ss << "-";
            }
            ss << dis(gen);
        }
        return ss.str();
    }
};
