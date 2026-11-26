// abstraction-provenance: {"artifact_sha256": "c8a2914994d272e8c3a798765df0ab95bc7f172a99a0077f9e114701b81eacf3", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "c"}
// gemini-ask.js — portiert nach c
// Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
// auch in: OpenClaw@gateway2:scripts/gemini-ask.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <curl/curl.h>

#define DEFAULT_MODEL "gemini-pro"
#define MAX_BUFFER_SIZE 1024*1024

// Structure to hold HTTP response data
struct MemoryStruct {
    char *memory;
    size_t size;
};

// Callback function to write received data into memory
static size_t WriteMemoryCallback(void *contents, size_t size, size_t nmemb, struct MemoryStruct *mem) {
    size_t realsize = size * nmemb;
    char *ptr = realloc(mem->memory, mem->size + realsize + 1);
    if(ptr == NULL) {
        fprintf(stderr, "Error: Not enough memory\n");
        return 0;
    }
    mem->memory = ptr;
    memcpy(&(mem->memory[mem->size]), contents, realsize);
    mem->size += realsize;
    mem->memory[mem->size] = 0;
    return realsize;
}

// Function to read entire file content
char* read_file(const char* filename) {
    FILE *file = fopen(filename, "r");
    if (!file) {
        fprintf(stderr, "Error: Cannot open file %s\n", filename);
        return NULL;
    }
    
    fseek(file, 0, SEEK_END);
    long length = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    char *content = malloc(length + 1);
    if (!content) {
        fclose(file);
        return NULL;
    }
    
    fread(content, 1, length, file);
    content[length] = '\0';
    fclose(file);
    return content;
}

// Function to read from stdin
char* read_stdin() {
    size_t bufsize = 1024;
    char *buffer = malloc(bufsize);
    if (!buffer) return NULL;
    
    size_t total_size = 0;
    size_t bytes_read;
    while ((bytes_read = fread(buffer + total_size, 1, bufsize - total_size - 1, stdin)) > 0) {
        total_size += bytes_read;
        if (total_size >= bufsize - 1) {
            bufsize *= 2;
            char *new_buffer = realloc(buffer, bufsize);
            if (!new_buffer) {
                free(buffer);
                return NULL;
            }
            buffer = new_buffer;
        }
    }
    buffer[total_size] = '\0';
    return buffer;
}

int main(int argc, char *argv[]) {
    // Check API key
    char *api_key = getenv("GEMINI_API_KEY");
    if (!api_key) {
        fprintf(stderr, "Error: GEMINI_API_KEY environment variable is required\n");
        exit(1);
    }
    
    // Get model name
    char *model_name = getenv("GEMINI_MODEL");
    if (!model_name) model_name = DEFAULT_MODEL;
    
    // Parse arguments
    char *prompt = NULL;
    char *system_prompt = NULL;
    int i;
    
    // Process command line arguments
    for (i = 1; i < argc; i++) {
        if ((strcmp(argv[i], "--model") == 0 || strcmp(argv[i], "-m") == 0) && i + 1 < argc) {
            model_name = argv[i+1];
            i++; // Skip next argument
        }
        else if ((strcmp(argv[i], "--system") == 0 || strcmp(argv[i], "-s") == 0) && i + 1 < argc) {
            system_prompt = argv[i+1];
            i++; // Skip next argument
        }
        else if ((strcmp(argv[i], "--file") == 0 || strcmp(argv[i], "-f") == 0) && i + 1 < argc) {
            prompt = read_file(argv[i+1]);
            if (!prompt) {
                fprintf(stderr, "Error: Cannot read file %s\n", argv[i+1]);
                exit(1);
            }
            i++; // Skip next argument
        }
        else if (strcmp(argv[i], "--help") == 0 || strcmp(argv[i], "-h") == 0) {
            printf("gemini-ask - CLI tool for Google Gemini API\n\n");
            printf("Usage:\n");
            printf("  gemini-ask \"Your question here\"\n");
            printf("  echo \"Your question\" | gemini-ask\n");
            printf("  gemini-ask --file prompt.txt\n");
            printf("  gemini-ask --model gemini-pro \"Your question\"\n\n");
            printf("Environment:\n");
            printf("  GEMINI_API_KEY - Required API key\n");
            printf("  GEMINI_MODEL   - Optional default model (default: gemini-pro)\n");
            exit(0);
        }
        else {
            // Collect remaining arguments as prompt
            if (!prompt) {
                size_t len = 0;
                for (int j = i; j < argc; j++) {
                    len += strlen(argv[j]) + 1;
                }
                prompt = malloc(len);
                prompt[0] = '\0';
                for (int j = i; j < argc; j++) {
                    strcat(prompt, argv[j]);
                    if (j < argc - 1) strcat(prompt, " ");
                }
                break;
            }
        }
    }
    
    // If no prompt yet, try reading from stdin
    if (!prompt && !isatty(STDIN_FILENO)) {
        prompt = read_stdin();
    }
    
    if (!prompt || strlen(prompt) == 0) {
        fprintf(stderr, "Error: No prompt provided\n");
        fprintf(stderr, "Usage: gemini-ask \"your question\"\n");
        fprintf(stderr, "       gemini-ask --model gemini-pro \"your question\"\n");
        fprintf(stderr, "       echo \"your question\" | gemini-ask\n");
        exit(1);
    }
    
    // Initialize curl
    CURL *curl;
    CURLcode res;
    struct MemoryStruct chunk;
    
    chunk.memory = malloc(1);
    chunk.size = 0;
    
    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();
    
    if(curl) {
        // Build URL
        char url[512];
        snprintf(url, sizeof(url), "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s", 
                 model_name, api_key);
        
        // Build JSON request body
        char *json_request;
        if (system_prompt) {
            json_request = malloc(strlen(prompt) + strlen(system_prompt) + 500);
            sprintf(json_request, 
                "{\"contents\":[{\"role\":\"user\",\"parts\":[{\"text\":\"%s\"}]},{\"role\":\"model\",\"parts\":[{\"text\":\"Understood. I will follow that instruction.\"}]},{\"role\":\"user\",\"parts\":[{\"text\":\"%s\"}]}],\"generationConfig\":{\"maxOutputTokens\":8192,\"temperature\":0.7,\"topP\":0.95}}",
                system_prompt, prompt);
        } else {
            json_request = malloc(strlen(prompt) + 200);
            sprintf(json_request, 
                "{\"contents\":[{\"role\":\"user\",\"parts\":[{\"text\":\"%s\"}]}],\"generationConfig\":{\"maxOutputTokens\":8192,\"temperature\":0.7,\"topP\":0.95}}",
                prompt);
        }
        
        // Set curl options
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_POSTFIELDS, json_request);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteMemoryCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, (void *)&chunk);
        
        // Set headers
        struct curl_slist *headers = NULL;
        headers = curl_slist_append(headers, "Content-Type: application/json");
        curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);
        
        // Perform the request
        res = curl_easy_perform(curl);
        
        if(res != CURLE_OK) {
            fprintf(stderr, "Error: curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            exit(1);
        }
        else {
            // Parse response and extract text
            char *start = strstr(chunk.memory, "\"text\":\"");
            if (start) {
                start += 8; // Move past '"text":"'
                char *end = strchr(start, '"');
                if (end) {
                    *end = '\0';
                    
                    // Print the response (simple version - would need better escaping in production)
                    printf("%s\n", start);
                }
            } else {
                // If we can't parse the structured response, output raw response
                printf("%s\n", chunk.memory);
            }
        }
        
        // Cleanup
        curl_slist_free_all(headers);
        free(json_request);
    }
    
    // Cleanup
    free(chunk.memory);
    curl_easy_cleanup(curl);
    curl_global_cleanup();
    free(prompt);
    
    return 0;
}
