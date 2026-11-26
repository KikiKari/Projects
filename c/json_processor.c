// abstraction-provenance: {"artifact_sha256": "85d83cc840e37700cc6f228085f523e74035b812a17dc55b1f1c2c5033a56eb0", "source_sha256": "f68a161573356fe83ce98ebe454cffaef6896f81d310cd932a9847500e671f9b", "target_language": "c"}
// json_processor.py — portiert nach c
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdbool.h>
#include <errno.h>

// JSON parsing library - using cJSON
#include "cjson/cJSON.h"

// Error codes
#define JSON_PROCESSING_ERROR 1
#define JSON_VALIDATION_ERROR 2
#define JSON_REPAIR_ERROR 3

// Structure for tool calls
typedef struct {
    char* tool;
    cJSON* arguments;
    char* reasoning;
} ToolCall;

// Function prototypes
char* repair_json_string(const char* raw_json);
cJSON* parse_json(const char* raw_input, bool repair);
cJSON* parse_and_validate(const char* raw_input, bool repair, bool strict);
ToolCall* validate_tool_call(const char* raw_json, const char* tool_name);
cJSON* safe_json_loads(const char* raw_input, cJSON* default_value, bool repair);
cJSON* extract_json_from_text(const char* text);

// Utility functions
char* read_file(const char* filepath);
void strip_whitespace(char* str);
bool starts_with(const char* str, const char* prefix);
bool ends_with(const char* str, const char* suffix);
char* substring(const char* str, int start, int end);
void replace_char(char* str, char find, char replace);
char* trim_whitespace(char* str);

// JSON repair implementation
char* repair_json_string(const char* raw_json) {
    // Simplified repair logic - remove comments and trailing commas
    char* cleaned = strdup(raw_json);
    if (!cleaned) return NULL;
    
    // Remove single line comments //
    char* comment_start = strstr(cleaned, "//");
    while (comment_start) {
        char* comment_end = strchr(comment_start, '\n');
        if (comment_end) {
            memmove(comment_start, comment_end, strlen(comment_end) + 1);
        } else {
            *comment_start = '\0';
        }
        comment_start = strstr(cleaned, "//");
    }
    
    // Remove multi-line comments /* */
    char* ml_comment_start = strstr(cleaned, "/*");
    while (ml_comment_start) {
        char* ml_comment_end = strstr(ml_comment_start, "*/");
        if (ml_comment_end) {
            memmove(ml_comment_start, ml_comment_end + 2, strlen(ml_comment_end + 2) + 1);
        } else {
            *ml_comment_start = '\0';
        }
        ml_comment_start = strstr(cleaned, "/*");
    }
    
    // Remove trailing commas before } or ]
    for (int i = 0; cleaned[i] != '\0'; i++) {
        if (cleaned[i] == ',') {
            int j = i + 1;
            // Skip whitespace
            while (cleaned[j] == ' ' || cleaned[j] == '\t' || cleaned[j] == '\n' || cleaned[j] == '\r') {
                j++;
            }
            if (cleaned[j] == '}' || cleaned[j] == ']') {
                memmove(&cleaned[i], &cleaned[i + 1], strlen(&cleaned[i + 1]) + 1);
                i--; // Adjust index after removal
            }
        }
    }
    
    return cleaned;
}

// Parse JSON with optional repair
cJSON* parse_json(const char* raw_input, bool repair) {
    char* input_copy = strdup(raw_input);
    if (!input_copy) return NULL;
    
    strip_whitespace(input_copy);
    
    // Try direct parsing first
    cJSON* result = cJSON_Parse(input_copy);
    if (result) {
        free(input_copy);
        return result;
    }
    
    // Extract JSON from markdown code blocks
    char* code_block_start = strstr(input_copy, "```");
    if (code_block_start) {
        char* json_start = strchr(code_block_start + 3, '{');
        if (!json_start) json_start = strchr(code_block_start + 3, '[');
        
        if (json_start) {
            char* json_end = strrchr(json_start, '}');
            if (!json_end) json_end = strrchr(json_start, ']');
            
            if (json_end) {
                char* json_str = substring(json_start, 0, json_end - json_start + 1);
                result = cJSON_Parse(json_str);
                free(json_str);
                if (result) {
                    free(input_copy);
                    return result;
                }
            }
        }
    }
    
    // Try repair if enabled
    if (repair) {
        char* repaired = repair_json_string(input_copy);
        if (repaired) {
            result = cJSON_Parse(repaired);
            free(repaired);
            if (result) {
                free(input_copy);
                return result;
            }
        }
    }
    
    free(input_copy);
    fprintf(stderr, "Could not parse JSON%s\n", repair ? " even after repair" : "");
    return NULL;
}

// Validate against a simple schema (placeholder for actual validation)
cJSON* parse_and_validate(const char* raw_input, bool repair, bool strict) {
    // In C, we don't have Pydantic-like validation, so this is a simplified version
    cJSON* data = parse_json(raw_input, repair);
    if (!data && strict) {
        fprintf(stderr, "JSON parsing failed in strict mode\n");
        return NULL;
    }
    return data;
}

// Validate tool call structure
ToolCall* validate_tool_call(const char* raw_json, const char* tool_name) {
    cJSON* parsed = parse_json(raw_json, true);
    if (!parsed) return NULL;
    
    ToolCall* tool_call = malloc(sizeof(ToolCall));
    if (!tool_call) {
        cJSON_Delete(parsed);
        return NULL;
    }
    
    cJSON* tool_item = cJSON_GetObjectItem(parsed, "tool");
    if (!tool_item || tool_item->type != cJSON_String) {
        fprintf(stderr, "Missing or invalid 'tool' field\n");
        free(tool_call);
        cJSON_Delete(parsed);
        return NULL;
    }
    
    tool_call->tool = strdup(tool_item->valuestring);
    
    cJSON* args_item = cJSON_GetObjectItem(parsed, "arguments");
    if (args_item) {
        tool_call->arguments = cJSON_Duplicate(args_item, true);
    } else {
        tool_call->arguments = cJSON_CreateObject();
    }
    
    cJSON* reasoning_item = cJSON_GetObjectItem(parsed, "reasoning");
    if (reasoning_item && reasoning_item->type == cJSON_String) {
        tool_call->reasoning = strdup(reasoning_item->valuestring);
    } else {
        tool_call->reasoning = NULL;
    }
    
    // Check tool name if specified
    if (tool_name && strcmp(tool_call->tool, tool_name) != 0) {
        fprintf(stderr, "Expected tool '%s', got '%s'\n", tool_name, tool_call->tool);
        free(tool_call->tool);
        if (tool_call->reasoning) free(tool_call->reasoning);
        cJSON_Delete(tool_call->arguments);
        free(tool_call);
        cJSON_Delete(parsed);
        return NULL;
    }
    
    cJSON_Delete(parsed);
    return tool_call;
}

// Safe JSON loading with default fallback
cJSON* safe_json_loads(const char* raw_input, cJSON* default_value, bool repair) {
    cJSON* result = parse_json(raw_input, repair);
    if (!result) {
        return default_value ? cJSON_Duplicate(default_value, true) : NULL;
    }
    return result;
}

// Extract JSON objects from text
cJSON* extract_json_from_text(const char* text) {
    cJSON* results = cJSON_CreateArray();
    if (!results) return NULL;
    
    const char* pos = text;
    while ((pos = strchr(pos, '{')) != NULL) {
        const char* end = strchr(pos, '}');
        if (end) {
            char* json_str = substring(pos, 0, end - pos + 1);
            cJSON* parsed = parse_json(json_str, true);
            if (parsed) {
                cJSON_AddItemToArray(results, parsed);
            }
            free(json_str);
            pos = end + 1;
        } else {
            pos++;
        }
    }
    
    return results;
}

// Utility function implementations
char* read_file(const char* filepath) {
    FILE* file = fopen(filepath, "rb");
    if (!file) {
        perror("Failed to open file");
        return NULL;
    }
    
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char* buffer = malloc(length + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }
    
    fread(buffer, 1, length, file);
    buffer[length] = '\0';
    fclose(file);
    
    return buffer;
}

void strip_whitespace(char* str) {
    char* src = str;
    char* dst = str;
    while (*src) {
        if (!isspace((unsigned char)*src)) {
            *dst = *src;
            dst++;
        }
        src++;
    }
    *dst = '\0';
}

bool starts_with(const char* str, const char* prefix) {
    return strncmp(str, prefix, strlen(prefix)) == 0;
}

bool ends_with(const char* str, const char* suffix) {
    size_t str_len = strlen(str);
    size_t suffix_len = strlen(suffix);
    return str_len >= suffix_len && !strcmp(str + str_len - suffix_len, suffix);
}

char* substring(const char* str, int start, int end) {
    int len = end - start;
    char* substr = malloc(len + 1);
    if (!substr) return NULL;
    strncpy(substr, str + start, len);
    substr[len] = '\0';
    return substr;
}

char* trim_whitespace(char* str) {
    char* end;
    
    // Trim leading space
    while(isspace((unsigned char)*str)) str++;
    
    if(*str == 0)  // All spaces?
        return str;
    
    // Trim trailing space
    end = str + strlen(str) - 1;
    while(end > str && isspace((unsigned char)*end)) end--;
    
    // Write new null terminator character
    end[1] = '\0';
    
    return str;
}

// Main function for CLI interface
int main(int argc, char* argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input> [--file] [--repair|--no-repair] [--pretty]\n", argv[0]);
        return 1;
    }
    
    bool is_file = false;
    bool repair = true;
    bool pretty = false;
    
    char* input_arg = argv[1];
    
    // Parse command line arguments
    for (int i = 2; i < argc; i++) {
        if (strcmp(argv[i], "--file") == 0 || strcmp(argv[i], "-f") == 0) {
            is_file = true;
        } else if (strcmp(argv[i], "--repair") == 0 || strcmp(argv[i], "-r") == 0) {
            repair = true;
        } else if (strcmp(argv[i], "--no-repair") == 0) {
            repair = false;
        } else if (strcmp(argv[i], "--pretty") == 0 || strcmp(argv[i], "-p") == 0) {
            pretty = true;
        }
    }
    
    char* content = NULL;
    
    if (is_file) {
        content = read_file(input_arg);
        if (!content) {
            return 1;
        }
    } else {
        content = strdup(input_arg);
        if (!content) {
            fprintf(stderr, "Memory allocation failed\n");
            return 1;
        }
    }
    
    cJSON* result = parse_json(content, repair);
    free(content);
    
    if (!result) {
        fprintf(stderr, "Error: Could not parse JSON\n");
        return 1;
    }
    
    char* output = cJSON_Print(result);
    if (!output) {
        fprintf(stderr, "Error: Failed to format JSON output\n");
        cJSON_Delete(result);
        return 1;
    }
    
    printf("%s\n", output);
    free(output);
    cJSON_Delete(result);
    
    return 0;
}
