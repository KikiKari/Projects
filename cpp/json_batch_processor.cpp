// abstraction-provenance: {"artifact_sha256": "62d0463a8d0a76c9872b04aa75c21c60c2182c101029d6119f1a5a8c7f785560", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "cpp"}
// json_batch_processor.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <filesystem>
#include <thread>
#include <future>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <algorithm>
#include <exception>
#include <sstream>
#include <optional>
#include <nlohmann/json.hpp>

using json = nlohmann::json;
namespace fs = std::filesystem;

// Forward declarations
class BatchResult;
std::vector<json> parse_json(const std::string& content, bool repair = true);
std::vector<json> parse_and_validate(const std::string& content, bool repair = true);

class BatchResult {
public:
    int index;
    std::string source;
    bool success;
    json data;
    std::optional<std::string> error;

    BatchResult(int idx, const std::string& src, bool succ, 
                const json& d = json(), const std::optional<std::string>& err = std::nullopt)
        : index(idx), source(src), success(succ), data(d), error(err) {}

    json to_json() const {
        json j;
        j["index"] = index;
        j["source"] = source;
        j["success"] = success;
        j["data"] = data;
        if (error.has_value()) {
            j["error"] = error.value();
        } else {
            j["error"] = nullptr;
        }
        return j;
    }
};

std::vector<json> read_jsonl(const fs::path& file_path) {
    std::vector<json> results;
    std::ifstream file(file_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + file_path.string());
    }

    std::string line;
    int line_num = 0;
    while (std::getline(file, line)) {
        ++line_num;
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        
        if (line.empty()) {
            continue;
        }

        try {
            json obj = json::parse(line);
            results.push_back(obj);
        } catch (const json::exception& e) {
            json error_result;
            error_result["index"] = line_num;
            error_result["source"] = file_path.string() + ":" + std::to_string(line_num);
            error_result["success"] = false;
            error_result["error"] = "JSON decode error: " + std::string(e.what());
            results.push_back(error_result);
        }
    }

    return results;
}

template<typename InputType, typename ProcessorFunc>
std::vector<BatchResult> process_batch(
    const std::vector<InputType>& inputs,
    ProcessorFunc processor,
    size_t max_workers = 4
) {
    std::vector<BatchResult> results;
    std::vector<std::future<BatchResult>> futures;
    
    // Limit number of threads to avoid overhead
    size_t num_threads = std::min(max_workers, inputs.size());
    if (num_threads == 0) num_threads = 1;
    
    std::vector<std::thread> workers;
    std::queue<std::pair<size_t, InputType>> work_queue;
    std::mutex queue_mutex;
    std::condition_variable condition;
    bool done = false;
    
    // Fill the work queue
    for (size_t i = 0; i < inputs.size(); ++i) {
        work_queue.emplace(i, inputs[i]);
    }
    
    // Worker function
    auto worker_func = [&]() {
        while (true) {
            std::pair<size_t, InputType> work_item;
            {
                std::unique_lock<std::mutex> lock(queue_mutex);
                condition.wait(lock, [&]{ return !work_queue.empty() || done; });
                if (done && work_queue.empty()) return;
                if (!work_queue.empty()) {
                    work_item = work_queue.front();
                    work_queue.pop();
                } else {
                    continue;
                }
            }
            
            try {
                BatchResult result = processor(work_item.second, work_item.first);
                {
                    std::lock_guard<std::mutex> lock(queue_mutex);
                    results.push_back(result);
                }
            } catch (const std::exception& e) {
                BatchResult result(work_item.first, 
                                  std::to_string(work_item.first),
                                  false,
                                  json(),
                                  "Unexpected error: " + std::string(e.what()));
                {
                    std::lock_guard<std::mutex> lock(queue_mutex);
                    results.push_back(result);
                }
            }
        }
    };
    
    // Start worker threads
    for (size_t i = 0; i < num_threads; ++i) {
        workers.emplace_back(worker_func);
    }
    
    // Notify all workers that they can start processing
    condition.notify_all();
    
    // Wait for all workers to finish
    for (auto& worker : workers) {
        worker.join();
    }
    
    // Sort results by index
    std::sort(results.begin(), results.end(), 
              [](const BatchResult& a, const BatchResult& b) {
                  return a.index < b.index;
              });
    
    return results;
}

std::vector<BatchResult> process_file_batch(
    const std::vector<fs::path>& file_paths,
    bool repair = true,
    size_t max_workers = 4
) {
    auto processor = [repair](const fs::path& path, size_t idx) -> BatchResult {
        try {
            std::ifstream file(path);
            if (!file.is_open()) {
                return BatchResult(idx, path.string(), false, json(), 
                                 "Could not open file");
            }
            
            std::stringstream buffer;
            buffer << file.rdbuf();
            std::string content = buffer.str();
            
            std::vector<json> data = parse_json(content, repair);
            
            return BatchResult(idx, path.string(), true, data.empty() ? json() : data[0]);
        } catch (const std::exception& e) {
            return BatchResult(idx, path.string(), false, json(), 
                             std::string(typeid(e).name()) + ": " + std::string(e.what()));
        }
    };
    
    return process_batch(file_paths, processor, max_workers);
}

std::vector<BatchResult> process_jsonl_file(
    const fs::path& file_path,
    bool repair = true
) {
    std::vector<BatchResult> results;
    
    std::ifstream file(file_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not open file: " + file_path.string());
    }
    
    std::string line;
    int line_num = 0;
    while (std::getline(file, line)) {
        ++line_num;
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        
        if (line.empty()) {
            continue;
        }
        
        try {
            std::vector<json> data = parse_json(line, repair);
            
            results.emplace_back(
                line_num,
                file_path.string() + ":" + std::to_string(line_num),
                true,
                data.empty() ? json() : data[0]
            );
        } catch (const std::exception& e) {
            results.emplace_back(
                line_num,
                file_path.string() + ":" + std::to_string(line_num),
                false,
                json(),
                std::string(e.what())
            );
        }
    }
    
    return results;
}

void write_jsonl(const std::vector<BatchResult>& results, 
                const fs::path& output_path, 
                bool only_successful = true) {
    std::ofstream file(output_path);
    if (!file.is_open()) {
        throw std::runtime_error("Could not create output file: " + output_path.string());
    }
    
    for (const auto& result : results) {
        if (only_successful && !result.success) {
            continue;
        }
        file << result.to_json().dump() << "\n";
    }
}

std::vector<json> parse_json(const std::string& content, bool repair) {
    std::vector<json> results;
    
    try {
        json j = json::parse(content);
        results.push_back(j);
    } catch (const json::exception&) {
        if (repair) {
            // Simple repair attempt - wrap in array if it's a single object
            try {
                std::string repaired_content = "[" + content + "]";
                json j = json::parse(repaired_content);
                results.push_back(j);
            } catch (const json::exception& e) {
                throw std::runtime_error("JSON parsing failed even after repair attempts: " + std::string(e.what()));
            }
        } else {
            throw;
        }
    }
    
    return results;
}

std::vector<json> parse_and_validate(const std::string& content, bool repair) {
    // In C++ we don't have Pydantic, so this is just parsing
    return parse_json(content, repair);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " [options] <input_files...>\n";
        std::cerr << "Options:\n";
        std::cerr << "  --jsonl, -l       Treat inputs as JSON-Lines files\n";
        std::cerr << "  --repair, -r      Enable JSON repair (default)\n";
        std::cerr << "  --workers, -w N   Parallel workers (default: 4)\n";
        std::cerr << "  --output, -o FILE Output JSON-Lines file\n";
        std::cerr << "  --summary, -s     Show summary only\n";
        return 1;
    }
    
    bool jsonl_mode = false;
    bool repair = true;
    size_t workers = 4;
    std::string output_file;
    bool summary_only = false;
    std::vector<std::string> input_files;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--jsonl" || arg == "-l") {
            jsonl_mode = true;
        } else if (arg == "--repair" || arg == "-r") {
            repair = true;
        } else if (arg == "--workers" || arg == "-w") {
            if (i + 1 < argc) {
                workers = std::stoi(argv[++i]);
            }
        } else if (arg == "--output" || arg == "-o") {
            if (i + 1 < argc) {
                output_file = argv[++i];
            }
        } else if (arg == "--summary" || arg == "-s") {
            summary_only = true;
        } else if (arg.substr(0, 2) == "--") {
            std::cerr << "Unknown option: " << arg << "\n";
            return 1;
        } else {
            input_files.push_back(arg);
        }
    }
    
    if (input_files.empty()) {
        std::cerr << "No input files specified\n";
        return 1;
    }
    
    std::vector<BatchResult> all_results;
    
    if (jsonl_mode) {
        // JSON-Lines mode
        for (const auto& input_file : input_files) {
            try {
                auto results = process_jsonl_file(input_file, repair);
                all_results.insert(all_results.end(), results.begin(), results.end());
            } catch (const std::exception& e) {
                std::cerr << "Error processing " << input_file << ": " << e.what() << "\n";
            }
        }
    } else {
        // Standard JSON batch mode
        std::vector<fs::path> paths;
        for (const auto& input_file : input_files) {
            paths.push_back(input_file);
        }
        all_results = process_file_batch(paths, repair, workers);
    }
    
    // Calculate statistics
    size_t successful = 0;
    for (const auto& result : all_results) {
        if (result.success) {
            ++successful;
        }
    }
    size_t failed = all_results.size() - successful;
    
    if (summary_only) {
        std::cout << "Processed: " << all_results.size() << "\n";
        std::cout << "Successful: " << successful << "\n";
        std::cout << "Failed: " << failed << "\n";
    } else {
        for (const auto& result : all_results) {
            if (result.success) {
                std::cout << result.data.dump(-1, ' ', false, json::error_handler_t::replace) << "\n";
            } else {
                std::cerr << "ERROR [" << result.source << "]: " << result.error.value_or("Unknown error") << "\n";
            }
        }
    }
    
    // Optional: JSONL output
    if (!output_file.empty()) {
        try {
            write_jsonl(all_results, output_file, false);
            std::cerr << "\nResults written to: " << output_file << "\n";
        } catch (const std::exception& e) {
            std::cerr << "Error writing output file: " << e.what() << "\n";
        }
    }
    
    return (failed == 0) ? 0 : 1;
}
