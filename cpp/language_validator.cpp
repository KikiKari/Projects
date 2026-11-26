// abstraction-provenance: {"artifact_sha256": "0db661094b632a3713d91dbe62f1480a7f5c39fcf122551ebc7d40a3f285b3a9", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "cpp"}
// language_validator.py — portiert nach cpp
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <string>
#include <vector>
#include <filesystem>
#include <optional>
#include <map>
#include <stdexcept>
#include <chrono>
#include <thread>
#include <cstdlib>
#include <cstdio>

namespace fs = std::filesystem;

struct ValidationResult {
    std::string language;
    bool valid;
    std::vector<std::string> errors;
    std::vector<std::string> warnings;
    std::optional<std::string> doc_url;
};

class LanguageValidator {
private:
    struct Config {
        std::string cmd;
        std::vector<std::string> args;
        std::optional<std::string> linter;
    };

    static const std::map<std::string, Config> LANGUAGES;
    
    std::string language;
    bool use_websearch;
    Config config;

public:
    LanguageValidator(const std::string& lang, bool websearch = true) 
        : language(lang), use_websearch(websearch) {
        // Convert to lowercase
        for (auto& c : this->language) {
            c = std::tolower(c);
        }
        
        auto it = LANGUAGES.find(this->language);
        if (it == LANGUAGES.end()) {
            throw std::invalid_argument("Unsupported language: " + lang);
        }
        config = it->second;
    }

    ValidationResult validate(const fs::path& script_path) {
        ValidationResult result;
        result.language = language;
        result.valid = false;
        
        // Syntax check
        try {
            std::vector<std::string> cmd_parts = {config.cmd};
            cmd_parts.insert(cmd_parts.end(), config.args.begin(), config.args.end());
            cmd_parts.push_back(script_path.string());
            
            std::string command;
            for (size_t i = 0; i < cmd_parts.size(); ++i) {
                if (i > 0) command += " ";
                command += cmd_parts[i];
            }
            command += " 2>&1";
            
            FILE* pipe = popen(command.c_str(), "r");
            if (!pipe) {
                result.errors.push_back("Command not found: " + config.cmd);
                if (use_websearch) {
                    result.doc_url = fetchDocs();
                }
                return result;
            }
            
            std::string output;
            char buffer[128];
            while (fgets(buffer, sizeof buffer, pipe)) {
                output += buffer;
            }
            
            int return_code = pclose(pipe);
            if (return_code != 0) {
                if (!output.empty()) {
                    result.errors.push_back(output);
                }
            }
        } catch (const std::exception& e) {
            result.errors.push_back("Validation error: " + std::string(e.what()));
        }
        
        // Linter check if available
        if (config.linter.has_value()) {
            auto linter_warnings = runLinter(script_path);
            result.warnings.insert(result.warnings.end(), 
                                  linter_warnings.begin(), 
                                  linter_warnings.end());
        }
        
        result.valid = result.errors.empty();
        return result;
    }

private:
    std::vector<std::string> runLinter(const fs::path& script_path) {
        std::vector<std::string> warnings;
        std::string linter = config.linter.value();
        
        try {
            std::string command;
            if (linter == "shellcheck") {
                command = "shellcheck -f gcc " + script_path.string() + " 2>&1";
            } else if (linter == "pylint") {
                command = "pylint --output-format=parseable " + script_path.string() + " 2>&1";
            } else {
                return warnings;
            }
            
            FILE* pipe = popen(command.c_str(), "r");
            if (!pipe) {
                warnings.push_back("Linter not installed: " + linter);
                return warnings;
            }
            
            std::string output;
            char buffer[128];
            while (fgets(buffer, sizeof buffer, pipe)) {
                output += buffer;
            }
            
            pclose(pipe);
            
            if (!output.empty()) {
                size_t start = 0;
                size_t pos = 0;
                while ((pos = output.find('\n', start)) != std::string::npos) {
                    if (pos > start) {
                        warnings.push_back(output.substr(start, pos - start));
                    }
                    start = pos + 1;
                }
                if (start < output.length()) {
                    warnings.push_back(output.substr(start));
                }
            }
        } catch (const std::exception& e) {
            warnings.push_back("Linter error: " + std::string(e.what()));
        }
        
        return warnings;
    }
    
    std::optional<std::string> fetchDocs() {
        if (!use_websearch) {
            return std::nullopt;
        }
        
        static const std::map<std::string, std::string> docs = {
            {"powershell", "https://docs.microsoft.com/powershell/"},
            {"raku", "https://docs.raku.org/"},
            {"tcl", "https://www.tcl.tk/"}
        };
        
        auto it = docs.find(language);
        if (it != docs.end()) {
            return it->second;
        }
        return std::nullopt;
    }
};

// Static member definition
const std::map<std::string, LanguageValidator::Config> LanguageValidator::LANGUAGES = {
    {"bash", {"bash", {"-n"}, "shellcheck"}},
    {"sh", {"sh", {"-n"}, "shellcheck"}},
    {"python", {"python3", {"-m", "py_compile"}, "pylint"}},
    {"perl", {"perl", {"-c"}, "perlcritic"}},
    {"raku", {"raku", {"-c"}, std::nullopt}},
    {"powershell", {"pwsh", {"-Command", "Get-Command"}, std::nullopt}},
    {"javascript", {"node", {"--check"}, "eslint"}},
    {"tcl", {"tclsh", {}, std::nullopt}}
};

void printUsage(const char* prog_name) {
    std::cerr << "Usage: " << prog_name << " --lang LANGUAGE SCRIPT_FILE\n";
    std::cerr << "Validate scripts in multiple languages\n\n";
    std::cerr << "Arguments:\n";
    std::cerr << "  SCRIPT_FILE       Path to script file\n";
    std::cerr << "  --lang LANGUAGE   Language (bash/python/perl/etc.)\n";
    std::cerr << "  --no-websearch    Disable WebSearch\n";
}

int main(int argc, char* argv[]) {
    if (argc < 3) {
        printUsage(argv[0]);
        return 1;
    }
    
    std::string language;
    fs::path script_path;
    bool use_websearch = true;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--lang" && i + 1 < argc) {
            language = argv[++i];
        } else if (arg == "--no-websearch") {
            use_websearch = false;
        } else if (script_path.empty()) {
            script_path = argv[i];
        }
    }
    
    if (language.empty() || script_path.empty()) {
        printUsage(argv[0]);
        return 1;
    }
    
    if (!fs::exists(script_path)) {
        std::cerr << "Script file does not exist: " << script_path << "\n";
        return 1;
    }
    
    try {
        LanguageValidator validator(language, use_websearch);
        ValidationResult result = validator.validate(script_path);
        
        std::cout << "Language: " << result.language << "\n";
        std::cout << "Valid: " << (result.valid ? "true" : "false") << "\n";
        
        if (!result.errors.empty()) {
            std::cout << "Errors: " << result.errors.size() << "\n";
            for (size_t i = 0; i < std::min(size_t(5), result.errors.size()); ++i) {
                std::cout << "  - " << result.errors[i] << "\n";
            }
        }
        
        if (!result.warnings.empty()) {
            std::cout << "Warnings: " << result.warnings.size() << "\n";
            for (size_t i = 0; i < std::min(size_t(5), result.warnings.size()); ++i) {
                std::cout << "  - " << result.warnings[i] << "\n";
            }
        }
        
        if (result.doc_url.has_value()) {
            std::cout << "Docs: " << result.doc_url.value() << "\n";
        }
        
        return result.valid ? 0 : 1;
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }
}
