// abstraction-provenance: {"artifact_sha256": "d8c60699727b5ad8ad6cf3996fe3e6405bb86ade64b4c544b373dc6d38a0c2c1", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "cpp"}
// model_usage.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <map>
#include <optional>
#include <fstream>
#include <sstream>
#include <stdexcept>
#include <algorithm>
#include <chrono>
#include <iomanip>
#include <memory>
#include <cstdio>
#include <cstdlib>

#ifdef _WIN32
#include <io.h>
#define popen _popen
#define pclose _pclose
#else
#include <unistd.h>
#endif

#include <nlohmann/json.hpp>

using json = nlohmann::json;

struct ModelCost {
    std::string model;
    double cost;
};

void eprint(const std::string& msg) {
    std::cerr << msg << std::endl;
}

std::string exec_command(const std::vector<std::string>& cmd_parts) {
    std::string cmd;
    for (size_t i = 0; i < cmd_parts.size(); ++i) {
        if (i > 0) cmd += " ";
        cmd += "\"" + cmd_parts[i] + "\"";
    }

    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"), pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }

    std::stringstream result;
    char buffer[128];
    while (fgets(buffer, sizeof buffer, pipe.get()) != nullptr) {
        result << buffer;
    }
    return result.str();
}

json run_codexbar_cost(const std::string& provider) {
    std::vector<std::string> cmd = {"codexbar", "cost", "--format", "json", "--provider", provider};
    std::string output;
    try {
        output = exec_command(cmd);
    } catch (...) {
        throw std::runtime_error("codexbar not found on PATH. Install CodexBar CLI first.");
    }

    try {
        json payload = json::parse(output);
        if (!payload.is_array()) {
            throw std::runtime_error("Expected codexbar cost JSON array.");
        }
        return payload;
    } catch (const json::exception&) {
        throw std::runtime_error("Failed to parse codexbar JSON output.");
    }
}

json load_payload(const std::optional<std::string>& input_path, const std::string& provider) {
    json data;
    if (input_path.has_value()) {
        std::string raw;
        if (input_path.value() == "-") {
            std::stringstream buffer;
            buffer << std::cin.rdbuf();
            raw = buffer.str();
        } else {
            std::ifstream file(input_path.value());
            if (!file.is_open()) {
                throw std::runtime_error("Could not open input file.");
            }
            std::stringstream buffer;
            buffer << file.rdbuf();
            raw = buffer.str();
        }
        data = json::parse(raw);
    } else {
        data = run_codexbar_cost(provider);
    }

    if (data.is_object()) {
        return data;
    }

    if (data.is_array()) {
        for (const auto& entry : data) {
            if (entry.is_object() && entry.contains("provider") && entry["provider"].is_string()) {
                if (entry["provider"] == provider) {
                    return entry;
                }
            }
        }
        throw std::runtime_error("Provider '" + provider + "' not found in codexbar payload.");
    }

    throw std::runtime_error("Unsupported JSON input format.");
}

std::vector<json> parse_daily_entries(const json& payload) {
    std::vector<json> result;
    if (payload.contains("daily") && payload["daily"].is_array()) {
        for (const auto& entry : payload["daily"]) {
            if (entry.is_object()) {
                result.push_back(entry);
            }
        }
    }
    return result;
}

std::optional<std::tm> parse_date(const std::string& value) {
    std::tm tm = {};
    std::istringstream ss(value);
    ss >> std::get_time(&tm, "%Y-%m-%d");
    if (ss.fail()) {
        return std::nullopt;
    }
    return tm;
}

std::vector<json> filter_by_days(const std::vector<json>& entries, const std::optional<int>& days) {
    if (!days.has_value()) {
        return entries;
    }

    auto now = std::chrono::system_clock::now();
    auto cutoff_time = now - std::chrono::hours(24 * (days.value() - 1));
    auto cutoff_date = std::chrono::system_clock::to_time_t(cutoff_time);
    std::tm cutoff_tm = *std::localtime(&cutoff_date);

    std::vector<json> filtered;
    for (const auto& entry : entries) {
        if (entry.contains("date") && entry["date"].is_string()) {
            auto parsed_opt = parse_date(entry["date"]);
            if (parsed_opt.has_value()) {
                std::tm parsed = parsed_opt.value();
                if (std::mktime(&parsed) >= std::mktime(&cutoff_tm)) {
                    filtered.push_back(entry);
                }
            }
        }
    }
    return filtered;
}

std::map<std::string, double> aggregate_costs(const std::vector<json>& entries) {
    std::map<std::string, double> totals;
    for (const auto& entry : entries) {
        if (entry.contains("modelBreakdowns") && entry["modelBreakdowns"].is_array()) {
            for (const auto& item : entry["modelBreakdowns"]) {
                if (item.is_object() && 
                    item.contains("modelName") && item["modelName"].is_string() &&
                    item.contains("cost") && (item["cost"].is_number_integer() || item["cost"].is_number_float())) {
                    std::string model = item["modelName"];
                    double cost = item["cost"];
                    totals[model] += cost;
                }
            }
        }
    }
    return totals;
}

std::pair<std::optional<std::string>, std::optional<std::string>> pick_current_model(const std::vector<json>& entries) {
    if (entries.empty()) {
        return {std::nullopt, std::nullopt};
    }

    std::vector<json> sorted_entries = entries;
    std::sort(sorted_entries.begin(), sorted_entries.end(),
              [](const json& a, const json& b) {
                  std::string date_a = a.contains("date") && a["date"].is_string() ? a["date"] : "";
                  std::string date_b = b.contains("date") && b["date"].is_string() ? b["date"] : "";
                  return date_a < date_b;
              });

    for (auto it = sorted_entries.rbegin(); it != sorted_entries.rend(); ++it) {
        const auto& entry = *it;
        if (entry.contains("modelBreakdowns") && entry["modelBreakdowns"].is_array() && !entry["modelBreakdowns"].empty()) {
            std::vector<ModelCost> scored;
            for (const auto& item : entry["modelBreakdowns"]) {
                if (item.is_object() && 
                    item.contains("modelName") && item["modelName"].is_string() &&
                    item.contains("cost") && (item["cost"].is_number_integer() || item["cost"].is_number_float())) {
                    scored.push_back({item["modelName"], static_cast<double>(item["cost"])});
                }
            }
            if (!scored.empty()) {
                std::sort(scored.begin(), scored.end(),
                          [](const ModelCost& a, const ModelCost& b) {
                              return a.cost > b.cost;
                          });
                std::optional<std::string> date_opt;
                if (entry.contains("date") && entry["date"].is_string()) {
                    date_opt = entry["date"];
                }
                return {scored[0].model, date_opt};
            }
        }
        if (entry.contains("modelsUsed") && entry["modelsUsed"].is_array() && !entry["modelsUsed"].empty()) {
            const auto& models_used = entry["modelsUsed"];
            if (!models_used.empty() && models_used.back().is_string()) {
                std::optional<std::string> date_opt;
                if (entry.contains("date") && entry["date"].is_string()) {
                    date_opt = entry["date"];
                }
                return {models_used.back(), date_opt};
            }
        }
    }
    return {std::nullopt, std::nullopt};
}

std::string usd(std::optional<double> value) {
    if (!value.has_value()) {
        return "—";
    }
    std::ostringstream oss;
    oss << "$" << std::fixed << std::setprecision(2) << std::setfill('0') << value.value();
    std::string s = oss.str();
    size_t dot_pos = s.find('.');
    if (dot_pos != std::string::npos) {
        std::string integer_part = s.substr(1, dot_pos - 1);
        std::string decimal_part = s.substr(dot_pos + 1);
        std::string formatted_integer;
        int count = 0;
        for (int i = integer_part.length() - 1; i >= 0; --i) {
            if (count > 0 && count % 3 == 0) {
                formatted_integer = "," + formatted_integer;
            }
            formatted_integer = integer_part[i] + formatted_integer;
            count++;
        }
        return "$" + formatted_integer + "." + decimal_part;
    }
    return s;
}

std::pair<std::optional<std::string>, std::optional<double>> latest_day_cost(const std::vector<json>& entries, const std::string& model) {
    if (entries.empty()) {
        return {std::nullopt, std::nullopt};
    }

    std::vector<json> sorted_entries = entries;
    std::sort(sorted_entries.begin(), sorted_entries.end(),
              [](const json& a, const json& b) {
                  std::string date_a = a.contains("date") && a["date"].is_string() ? a["date"] : "";
                  std::string date_b = b.contains("date") && b["date"].is_string() ? b["date"] : "";
                  return date_a < date_b;
              });

    for (auto it = sorted_entries.rbegin(); it != sorted_entries.rend(); ++it) {
        const auto& entry = *it;
        if (entry.contains("modelBreakdowns") && entry["modelBreakdowns"].is_array()) {
            for (const auto& item : entry["modelBreakdowns"]) {
                if (item.is_object() && item.contains("modelName") && item["modelName"].is_string()) {
                    if (item["modelName"] == model) {
                        std::optional<double> cost;
                        if (item.contains("cost") && (item["cost"].is_number_integer() || item["cost"].is_number_float())) {
                            cost = static_cast<double>(item["cost"]);
                        }
                        std::optional<std::string> day;
                        if (entry.contains("date") && entry["date"].is_string()) {
                            day = entry["date"];
                        }
                        return {day, cost};
                    }
                }
            }
        }
    }
    return {std::nullopt, std::nullopt};
}

std::string render_text_current(
    const std::string& provider,
    const std::string& model,
    const std::optional<std::string>& latest_date,
    const std::optional<double>& total_cost,
    const std::optional<double>& latest_cost,
    const std::optional<std::string>& latest_cost_date,
    int entry_count) {
    std::vector<std::string> lines = {
        "Provider: " + provider,
        "Current model: " + model
    };
    if (latest_date.has_value()) {
        lines.push_back("Latest model date: " + latest_date.value());
    }
    lines.push_back("Total cost (rows): " + usd(total_cost));
    if (latest_cost_date.has_value()) {
        lines.push_back("Latest day cost: " + usd(latest_cost) + " (" + latest_cost_date.value() + ")");
    }
    lines.push_back("Daily rows: " + std::to_string(entry_count));
    std::string result;
    for (size_t i = 0; i < lines.size(); ++i) {
        if (i > 0) result += "\n";
        result += lines[i];
    }
    return result;
}

std::string render_text_all(const std::string& provider, const std::map<std::string, double>& totals) {
    std::vector<std::pair<std::string, double>> sorted_totals(totals.begin(), totals.end());
    std::sort(sorted_totals.begin(), sorted_totals.end(),
              [](const std::pair<std::string, double>& a, const std::pair<std::string, double>& b) {
                  return a.second > b.second;
              });

    std::vector<std::string> lines = {
        "Provider: " + provider,
        "Models:"
    };
    for (const auto& pair : sorted_totals) {
        lines.push_back("- " + pair.first + ": " + usd(pair.second));
    }
    std::string result;
    for (size_t i = 0; i < lines.size(); ++i) {
        if (i > 0) result += "\n";
        result += lines[i];
    }
    return result;
}

json build_json_current(
    const std::string& provider,
    const std::string& model,
    const std::optional<std::string>& latest_date,
    const std::optional<double>& total_cost,
    const std::optional<double>& latest_cost,
    const std::optional<std::string>& latest_cost_date,
    int entry_count) {
    json j;
    j["provider"] = provider;
    j["mode"] = "current";
    j["model"] = model;
    j["latestModelDate"] = latest_date.value_or("");
    j["totalCostUSD"] = total_cost.value_or(0.0);
    j["latestDayCostUSD"] = latest_cost.value_or(0.0);
    j["latestDayCostDate"] = latest_cost_date.value_or("");
    j["dailyRowCount"] = entry_count;
    return j;
}

json build_json_all(const std::string& provider, const std::map<std::string, double>& totals) {
    std::vector<std::pair<std::string, double>> sorted_totals(totals.begin(), totals.end());
    std::sort(sorted_totals.begin(), sorted_totals.end(),
              [](const std::pair<std::string, double>& a, const std::pair<std::string, double>& b) {
                  return a.second > b.second;
              });

    json j;
    j["provider"] = provider;
    j["mode"] = "all";
    j["models"] = json::array();
    for (const auto& pair : sorted_totals) {
        json model_entry;
        model_entry["model"] = pair.first;
        model_entry["totalCostUSD"] = pair.second;
        j["models"].push_back(model_entry);
    }
    return j;
}

int main(int argc, char* argv[]) {
    std::string provider = "codex";
    std::string mode = "current";
    std::optional<std::string> model_arg;
    std::optional<std::string> input_path;
    std::optional<int> days;
    std::string format = "text";
    bool pretty = false;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--provider") {
            if (i + 1 < argc) {
                provider = argv[++i];
            }
        } else if (arg == "--mode") {
            if (i + 1 < argc) {
                mode = argv[++i];
            }
        } else if (arg == "--model") {
            if (i + 1 < argc) {
                model_arg = argv[++i];
            }
        } else if (arg == "--input") {
            if (i + 1 < argc) {
                input_path = argv[++i];
            }
        } else if (arg == "--days") {
            if (i + 1 < argc) {
                days = std::stoi(argv[++i]);
            }
        } else if (arg == "--format") {
            if (i + 1 < argc) {
                format = argv[++i];
            }
        } else if (arg == "--pretty") {
            pretty = true;
        }
    }

    json payload;
    try {
        payload = load_payload(input_path, provider);
    } catch (const std::exception& e) {
        eprint(e.what());
        return 1;
    }

    std::vector<json> entries = parse_daily_entries(payload);
    entries = filter_by_days(entries, days);

    if (mode == "current") {
        std::string model;
        std::optional<std::string> latest_date;
        if (model_arg.has_value()) {
            model = model_arg.value();
        } else {
            auto result = pick_current_model(entries);
            model = result.first.value_or("");
            latest_date = result.second;
        }
        if (model.empty()) {
            eprint("No model data found in codexbar cost payload.");
            return 2;
        }
        auto totals = aggregate_costs(entries);
        std::optional<double> total_cost;
        if (totals.find(model) != totals.end()) {
            total_cost = totals[model];
        }
        auto latest_result = latest_day_cost(entries, model);
        std::optional<double> latest_cost = latest_result.second;
        std::optional<std::string> latest_cost_date = latest_result.first;

        if (format == "json") {
            json payload_out = build_json_current(
                provider,
                model,
                latest_date,
                total_cost,
                latest_cost,
                latest_cost_date,
                static_cast<int>(entries.size())
            );
            if (pretty) {
                std::cout << payload_out.dump(2) << std::endl;
            } else {
                std::cout << payload_out.dump() << std::endl;
            }
        } else {
            std::cout << render_text_current(
                provider,
                model,
                latest_date,
                total_cost,
                latest_cost,
                latest_cost_date,
                static_cast<int>(entries.size())
            ) << std::endl;
        }
        return 0;
    }

    auto totals = aggregate_costs(entries);
    if (totals.empty()) {
        eprint("No model breakdowns found in codexbar cost payload.");
        return 2;
    }

    if (format == "json") {
        json payload_out = build_json_all(provider, totals);
        if (pretty) {
            std::cout << payload_out.dump(2) << std::endl;
        } else {
            std::cout << payload_out.dump() << std::endl;
        }
    } else {
        std::cout << render_text_all(provider, totals) << std::endl;
    }
    return 0;
}
